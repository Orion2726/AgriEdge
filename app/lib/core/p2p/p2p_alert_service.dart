import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'aggregation/local_aggregator.dart';
import 'packet/p2p_packet.dart';
import 'relevance/farmer_profile.dart';
import 'relevance/relevance_engine.dart';
import 'security/device_identity.dart';
import 'store/p2p_packet_store.dart';
import 'transport/p2p_transport.dart';
import 'transport/transport_manager.dart';

/// Default disease-alert TTL — see docs/P2P_ALERT_PROTOCOL.md §3/§21.
/// Matches the 72-hour example in the invention disclosure's §14.
const defaultAlertTtl = Duration(hours: 72);

/// Ties transport + packet store + relevance engine + aggregation together
/// — the public surface the rest of the app (disease_detection,
/// disease_alerts) calls. See docs/P2P_ALERT_PROTOCOL.md §9 for the phased
/// build order this implements (phases 1-5; phase 6 — Wi-Fi Direct/
/// Multipeer — is not built).
class P2pAlertService {
  P2pAlertService({
    required TransportManager transportManager,
    required P2pPacketStore packetStore,
    required LocalAggregator aggregator,
    required RelevanceEngine relevanceEngine,
    required DeviceIdentity deviceIdentity,
    required FarmerProfile farmerProfile,
  })  : _transportManager = transportManager,
        _packetStore = packetStore,
        _aggregator = aggregator,
        _relevanceEngine = relevanceEngine,
        _deviceIdentity = deviceIdentity,
        _farmerProfile = farmerProfile;

  final TransportManager _transportManager;
  final P2pPacketStore _packetStore;
  final LocalAggregator _aggregator;
  final RelevanceEngine _relevanceEngine;
  final DeviceIdentity _deviceIdentity;
  final FarmerProfile _farmerProfile;

  StreamSubscription? _incomingSub;
  StreamSubscription? _peerDiscoveredSub;
  Timer? _sweepTimer;
  bool _started = false;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    _incomingSub = _transportManager.incoming.listen(_onDatagramReceived);
    _peerDiscoveredSub = _transportManager.peerDiscovered.listen(_onPeerDiscovered);
    _sweepTimer = Timer.periodic(const Duration(minutes: 15), (_) async {
      await _packetStore.sweepExpired();
      await _aggregator.recompute();
    });

    await _transportManager.start();
  }

  Future<void> stop() async {
    _started = false;
    await _incomingSub?.cancel();
    await _peerDiscoveredSub?.cancel();
    _sweepTimer?.cancel();
    await _transportManager.stop();
  }

  /// Originates a new disease-alert packet from a local detection — call
  /// this after a farmer confirms/saves a disease detection with location
  /// sharing enabled. Stores it locally (so it survives app restarts and
  /// gets picked up by future peer encounters) and immediately attempts
  /// forwarding to any already-known peers.
  Future<void> broadcastDetection({
    required String cropId,
    required String label,
    required double confidence,
    required String severity,
    required double lat,
    required double lng,
    Duration ttl = defaultAlertTtl,
  }) async {
    final now = DateTime.now().toUtc();
    final payload = DiseaseAlertPayload(
      cropId: cropId,
      label: label,
      confidence: confidence,
      severity: severity,
      latE6: (lat * 1e6).round(),
      lngE6: (lng * 1e6).round(),
      observedAt: now,
      expiresAt: now.add(ttl),
      sourceDeviceId: _deviceIdentity.publicKeyHex,
    );

    final nonce = P2pAlertPacket.randomNonce();
    final payloadMap = payload.toMap();
    final packetId = await P2pAlertPacket.computePacketId(
      type: P2pAlertPacketType.diseaseAlert,
      createdAt: now,
      nonce: nonce,
      payload: payloadMap,
    );
    final signature = await _deviceIdentity.sign(P2pAlertPacket.signingInput(
      type: P2pAlertPacketType.diseaseAlert,
      createdAt: now,
      nonce: nonce,
      packetId: packetId,
      payload: payloadMap,
    ));

    final packet = P2pAlertPacket(
      version: 1,
      type: P2pAlertPacketType.diseaseAlert,
      ttlHops: 10,
      createdAt: now,
      nonce: nonce,
      packetId: packetId,
      payload: payloadMap,
      signature: signature,
      signerPublicKey: _deviceIdentity.publicKeyBytes,
    );

    await _packetStore.insertIfNew(packet, verified: true);
    await _aggregator.recompute();
    await _forwardToAllKnownPeers(packet);
  }

  Future<void> _onDatagramReceived(ReceivedDatagram datagram) async {
    final P2pAlertPacket packet;
    try {
      packet = P2pAlertPacket.decode(datagram.bytes);
    } catch (_) {
      return; // malformed — drop
    }
    if (packet.type != P2pAlertPacketType.diseaseAlert) return;

    final verified = await _verify(packet);
    final isNew = await _packetStore.insertIfNew(
      packet,
      receivedFromPeerId: datagram.from.toString(),
      verified: verified,
    );
    if (!isNew) return;

    await _aggregator.recompute();

    // Relay onward: decrement TTL and offer to every other currently-known
    // peer, gated by relevance — not just the one we received it from.
    if (packet.ttlHops > 1) {
      await _forwardToAllKnownPeers(packet.copyWithDecrementedTtl(), exclude: datagram.from);
    }
  }

  Future<bool> _verify(P2pAlertPacket packet) async {
    if (!packet.isSigned) return false;
    try {
      return await DeviceIdentity.verify(
        P2pAlertPacket.signingInput(
          type: packet.type,
          createdAt: packet.createdAt,
          nonce: packet.nonce,
          packetId: packet.packetId,
          payload: packet.payload,
        ),
        signature: packet.signature!,
        publicKeyBytes: packet.signerPublicKey!,
      );
    } catch (_) {
      return false;
    }
  }


  Future<void> _onPeerDiscovered(PeerId peer) async {
    // A newly-met peer should get a relevance-gated offer of everything
    // currently in the local cache, not just future packets — this is the
    // store-carry-forward behavior: a packet carried for days reaches a
    // relevant peer the moment they're met, not only at creation time.
    final unexpired = await _packetStore.unexpired();
    for (final packet in unexpired) {
      await _maybeForward(packet, peer);
    }
  }

  Future<void> _forwardToAllKnownPeers(P2pAlertPacket packet, {PeerId? exclude}) async {
    for (final peer in _transportManager.knownPeers) {
      if (peer == exclude) continue;
      await _maybeForward(packet, peer);
    }
  }

  Future<void> _maybeForward(P2pAlertPacket packet, PeerId peer) async {
    final payload = DiseaseAlertPayload.fromMap(packet.payload);
    final alreadyForwarded = await _packetStore.hasForwardedTo(packet.packetIdHex, peer.toString());
    if (alreadyForwarded) return;

    double lat, lng;
    try {
      final position = await Geolocator.getCurrentPosition();
      lat = position.latitude;
      lng = position.longitude;
    } catch (_) {
      return; // no location — can't score geographic relevance, skip forwarding
    }

    final myCropIds = _farmerProfile.myCropIds;
    final shouldForward = _relevanceEngine.shouldForward(
      payload: payload,
      deviceLat: lat,
      deviceLng: lng,
      myCropIds: myCropIds,
      alreadyForwardedToThisPeer: alreadyForwarded,
    );
    if (!shouldForward) return;

    await _transportManager.send(peer, packet.encode());
    await _packetStore.markForwardedTo(packet.packetIdHex, peer.toString());
  }
}

/// Async because constructing a P2pAlertService needs this device's signing
/// identity and farmer profile, both of which load from platform secure
/// storage / shared_preferences. Callers (e.g. DiseaseAlertsScreen) await
/// this once, then call .start()/.stop()/.broadcastDetection() on the
/// resolved instance — Riverpod caches it, so repeated reads are free.
final p2pAlertServiceFutureProvider = FutureProvider<P2pAlertService>((ref) async {
  final deviceIdentity = await ref.watch(deviceIdentityProvider.future);
  final farmerProfile = await ref.watch(farmerProfileProvider.future);
  return P2pAlertService(
    transportManager: ref.watch(transportManagerProvider),
    packetStore: ref.watch(p2pPacketStoreProvider),
    aggregator: ref.watch(localAggregatorProvider),
    relevanceEngine: const RelevanceEngine(),
    deviceIdentity: deviceIdentity,
    farmerProfile: farmerProfile,
  );
});
