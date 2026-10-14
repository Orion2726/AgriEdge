import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart' show Sha256;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../data/live_feeds.dart';
import '../db/db_provider.dart';
import '../../features/disease_alerts/data/disease_alerts_repository.dart' show regionalOutbreaksProvider;
import '../network/api_client.dart';
import '../network/connectivity_service.dart';
import '../sync/sync_manager.dart';
import '../settings/farm_setup.dart';
import 'aggregation/local_aggregator.dart';
import 'p2p_log.dart';
import 'packet/p2p_packet.dart';
import 'relevance/farmer_profile.dart';
import 'relevance/relevance_engine.dart';
import 'security/device_identity.dart';
import 'snapshot_sync.dart';
import 'store/p2p_packet_store.dart';
import 'transport/p2p_transport.dart';
import 'transport/transport_manager.dart';

/// Default disease-alert TTL — see docs/P2P_ALERT_PROTOCOL.md §3/§21.
/// Matches the 72-hour example in the invention disclosure's §14.
const defaultAlertTtl = Duration(hours: 72);

/// sourceDeviceId of official reports published from the AgriEdge server.
const serverSourceId = 'server';

typedef DeviceLocation = ({double lat, double lng});
typedef LocationLookup = Future<DeviceLocation?> Function();

/// Key under which "already sent to / received from this phone" is recorded
/// in P2pPackets.forwardedToPeerIdsJson / receivedFromPeerId. Keyed by the
/// peer's stable device id, not its BLE address (which Android rotates).
String peerDeviceKey(String deviceId) => 'dev:$deviceId';

/// Ties transport + packet store + relevance engine + aggregation together
/// — the public surface the rest of the app (disease_detection,
/// disease_alerts) calls. See docs/P2P_ALERT_PROTOCOL.md §9 for the phased
/// build order this implements (phases 1-5; phase 6 — Wi-Fi Direct/
/// Multipeer — is not built).
///
/// Delivery model: every unexpired packet in the local store is offered to
/// every reachable peer that hasn't acknowledged it yet — when the peer is
/// discovered, right after a packet is created or received, and on a
/// periodic resync. A packet is only marked as delivered to a peer after
/// the peer's app acknowledged storing it (see BleTransport), so a failed
/// or interrupted transfer is simply retried on the next pass.
class P2pAlertService {
  P2pAlertService({
    required TransportManager transportManager,
    required P2pPacketStore packetStore,
    required LocalAggregator aggregator,
    required RelevanceEngine relevanceEngine,
    required DeviceIdentity deviceIdentity,
    required FarmerProfile farmerProfile,
    LocationLookup? locate,
    this.snapshots,
    this.onSnapshotApplied,
    this.onPacketStored,
    this.resyncInterval = const Duration(seconds: 20),
  })  : _transportManager = transportManager,
        _packetStore = packetStore,
        _aggregator = aggregator,
        _relevanceEngine = relevanceEngine,
        _deviceIdentity = deviceIdentity,
        _farmerProfile = farmerProfile,
        _locate = locate ?? _geolocatorLocation;

  final TransportManager _transportManager;
  final P2pPacketStore _packetStore;
  final LocalAggregator _aggregator;
  final RelevanceEngine _relevanceEngine;
  final DeviceIdentity _deviceIdentity;
  final FarmerProfile _farmerProfile;
  final LocationLookup _locate;
  final Duration resyncInterval;

  /// Everyday data (prices, MSP, weather, news) shared alongside alerts.
  final SnapshotSync? snapshots;
  final void Function(SnapshotKind kind)? onSnapshotApplied;

  /// Called after a new report is stored (created here or received), so a
  /// phone with internet uploads it right away — acting as the gateway for
  /// phones that have none.
  final void Function()? onPacketStored;

  /// Which snapshot version (by dataAt) each peer device already acked.
  final Map<String, Map<SnapshotKind, DateTime>> _snapshotsSent = {};

  StreamSubscription? _peerDiscoveredSub;
  Timer? _sweepTimer;
  Timer? _resyncTimer;
  bool _started = false;
  final Set<PeerId> _offering = {};

  DeviceLocation? _cachedLocation;
  DateTime? _cachedLocationAt;

  TransportManager get transportManager => _transportManager;
  String get localDeviceId => _deviceIdentity.shortIdHex;
  bool get isStarted => _started;

  Future<void> start() async {
    if (_started) return;
    _started = true;
    p2pLog('session start device=$localDeviceId');

    _transportManager.datagramHandler = _onDatagramReceived;
    _peerDiscoveredSub = _transportManager.peerDiscovered.listen((peer) {
      unawaited(_offerCacheTo(peer));
    });
    _sweepTimer = Timer.periodic(const Duration(minutes: 15), (_) async {
      await _packetStore.sweepExpired();
      await _aggregator.recompute();
    });
    _resyncTimer = Timer.periodic(resyncInterval, (_) => unawaited(_resyncAll()));

    await _packetStore.sweepExpired();
    unawaited(_reverifyPending());
    await _transportManager.start(localDeviceId: _deviceIdentity.shortIdBytes);
  }

  Future<void> stop() async {
    if (!_started) return;
    _started = false;
    p2pLog('session stop device=$localDeviceId');
    await _peerDiscoveredSub?.cancel();
    _sweepTimer?.cancel();
    _resyncTimer?.cancel();
    _transportManager.datagramHandler = null;
    await _transportManager.stop();
  }

  /// Originates a new disease-alert packet from a local detection — call
  /// this after a farmer confirms/saves a disease detection with location
  /// sharing enabled. Stores it locally (so it survives app restarts and
  /// gets picked up by future peer encounters) and immediately attempts
  /// forwarding to any already-known peers.
  Future<P2pAlertPacket> broadcastDetection({
    required String cropId,
    required String label,
    required double confidence,
    required String severity,
    required double lat,
    required double lng,
    String? detectionId,
    String? note,
    Uint8List? photoJpeg,
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
      detectionId: detectionId,
      note: (note == null || note.trim().isEmpty) ? null : note.trim(),
      photoJpeg: photoJpeg,
    );

    final packet = await _signed(P2pAlertPacketType.diseaseAlert, payload.toMap(), now, ttlHops: 10);

    await _packetStore.insertIfNew(packet, verified: true);
    await _aggregator.recompute();
    p2pLog('originated packet=${packet.packetIdHex} label="$label" crop=$cropId');
    onPacketStored?.call();
    unawaited(_resyncAll());
    return packet;
  }

  /// Turns an official report fetched from the AgriEdge server into a mesh
  /// packet so phones without internet get it over Bluetooth. Its packet id
  /// is derived only from the server's report (fixed time, nonce from the
  /// report id, sourceDeviceId 'server'), so every online phone that imports
  /// it produces the same id and receivers never see duplicates. This phone
  /// signs it as the relay. Returns true if it was new here.
  Future<bool> importServerReport(Map<String, dynamic> r) async {
    final id = r['id'] as String;
    final createdAt = DateTime.parse(r['createdAt'] as String).toUtc();
    final payload = DiseaseAlertPayload(
      cropId: r['cropId'] as String,
      label: r['label'] as String,
      confidence: 0,
      severity: r['severity'] as String? ?? 'medium',
      latE6: ((r['lat'] as num) * 1e6).round(),
      lngE6: ((r['lng'] as num) * 1e6).round(),
      observedAt: createdAt,
      expiresAt: DateTime.parse(r['expiresAt'] as String).toUtc(),
      sourceDeviceId: serverSourceId,
      detectionId: 'server-$id',
      note: r['note'] as String?,
    );
    final nonce = Uint8List.fromList((await Sha256().hash(utf8.encode(id))).bytes.sublist(0, 8));
    final packet = await _signed(P2pAlertPacketType.diseaseAlert, payload.toMap(), createdAt, ttlHops: 10, nonce: nonce);
    final isNew = await _packetStore.insertIfNew(packet, receivedFromPeerId: serverSourceId, verified: true);
    if (!isNew) return false;
    await _packetStore.markSyncedToBackend(packet.packetIdHex); // it came from there
    await _aggregator.recompute();
    p2pLog('imported server report $id as packet=${packet.packetIdHex}');
    unawaited(_resyncAll());
    return true;
  }

  Future<P2pAlertPacket> _signed(P2pAlertPacketType type, Map<String, Object?> payloadMap, DateTime now,
      {required int ttlHops, Uint8List? nonce}) async {
    nonce ??= P2pAlertPacket.randomNonce();
    final packetId = await P2pAlertPacket.computePacketId(type: type, createdAt: now, nonce: nonce, payload: payloadMap);
    final signature = await _deviceIdentity.sign(P2pAlertPacket.signingInput(
      type: type,
      createdAt: now,
      nonce: nonce,
      packetId: packetId,
      payload: payloadMap,
    ));
    return P2pAlertPacket(
      version: 1,
      type: type,
      ttlHops: ttlHops,
      createdAt: now,
      nonce: nonce,
      packetId: packetId,
      payload: payloadMap,
      signature: signature,
      signerPublicKey: _deviceIdentity.publicKeyBytes,
    );
  }

  Future<void> _applySnapshot(P2pAlertPacket packet, String from) async {
    try {
      if (!await _verify(packet)) {
        p2pLog('snapshot REJECT from=$from (bad signature)');
        return;
      }
      final snap = DataSnapshot.fromPayload(packet.payload);
      // The sender evidently has this version; don't send ours back unless newer.
      (_snapshotsSent[from] ??= {})[snap.kind] = snap.dataAt;
      if (await snapshots!.apply(snap, fromDevice: from)) onSnapshotApplied?.call(snap.kind);
    } catch (e) {
      p2pLog('snapshot DROP from=$from: $e');
    }
  }

  Future<void> _offerSnapshotsTo(PeerId peer, String deviceId) async {
    final sync = snapshots;
    if (sync == null) return;
    final sent = _snapshotsSent[deviceId] ??= {};
    for (final snap in await sync.current()) {
      final prev = sent[snap.kind];
      if (prev != null && !snap.dataAt.isAfter(prev)) continue;
      final packet = await _signed(
          P2pAlertPacketType.dataSnapshot, snap.toPayload(_deviceIdentity.publicKeyHex), DateTime.now().toUtc(),
          ttlHops: 1);
      await _transportManager.send(peer, packet.encode());
      sent[snap.kind] = snap.dataAt;
      p2pLog('snapshot SENT kind=${snap.kind.name} dataAt=${snap.dataAt.toIso8601String()} to=$deviceId');
    }
  }

  Future<void> _onDatagramReceived(ReceivedDatagram datagram) async {
    final from = datagram.senderDeviceId;
    final P2pAlertPacket packet;
    try {
      packet = P2pAlertPacket.decode(datagram.bytes);
      if (packet.type == P2pAlertPacketType.dataSnapshot && snapshots != null) {
        unawaited(_applySnapshot(packet, from)); // acknowledged now, applied after verification
        return;
      }
      if (packet.type != P2pAlertPacketType.diseaseAlert) {
        throw FormatException('unsupported packet type ${packet.type}');
      }
      DiseaseAlertPayload.fromMap(packet.payload); // validates field types
    } catch (e) {
      // Acknowledge and drop: a packet that doesn't decode now never will,
      // so making the sender retry it would just loop.
      p2pLog('rx DROP undecodable datagram from=$from bytes=${datagram.bytes.length}: $e');
      return;
    }

    // Store (as unverified) and acknowledge first; verify afterwards.
    // Ed25519 verification is pure Dart and measured 0.7 s unlocked and
    // 2.4–10 s on a dozing, screen-locked phone, which outran the sender's
    // write timeout and caused needless retries. Relays don't need the
    // result (docs §8 relay-trust asymmetry); clusters only count verified
    // reports, and unverified ones are re-checked on the next session start.
    final clock = Stopwatch()..start();
    final isNew = await _packetStore.insertIfNew(
      packet,
      receivedFromPeerId: peerDeviceKey(from),
      verified: false,
    );
    // Never offer a packet back to the phone that just gave it to us.
    await _packetStore.markForwardedTo(packet.packetIdHex, peerDeviceKey(from));
    p2pLog('rx packet=${packet.packetIdHex} from=$from new=$isNew ttl=${packet.ttlHops} '
        'storeMs=${clock.elapsedMilliseconds}');
    if (!isNew) return;
    unawaited(_verifyStored(packet));
  }

  Future<void> _verifyStored(P2pAlertPacket packet) async {
    final clock = Stopwatch()..start();
    final verified = await _verify(packet);
    await _packetStore.setVerified(packet.packetIdHex, verified);
    p2pLog('verify packet=${packet.packetIdHex} ok=$verified ms=${clock.elapsedMilliseconds}');
    await _aggregator.recompute();
    onPacketStored?.call();
    // Relay onward.
    unawaited(_resyncAll());
  }

  /// Re-checks signed packets left unverified (e.g. the app was killed
  /// between storing and verifying).
  Future<void> _reverifyPending() async {
    for (final row in await _packetStore.unverifiedSignedRows()) {
      await _verifyStored(P2pPacketStore.decodeRow(row));
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

  /// Offer anything new to every phone in range now (instead of waiting for
  /// the periodic resync).
  void shareNow() => unawaited(_resyncAll());

  Future<void> _resyncAll() async {
    if (!_started) return;
    for (final peer in _transportManager.knownPeers) {
      await _offerCacheTo(peer);
    }
  }

  /// Store-carry-forward: offers every unexpired cached packet this peer
  /// hasn't acknowledged yet, gated by relevance. Failures are logged and
  /// retried on the next resync rather than propagated.
  Future<void> _offerCacheTo(PeerId peer) async {
    if (!_started || !_offering.add(peer)) return;
    try {
      // Identify the peer even when there's nothing to send, so the UI can
      // show which phone is in range (one short GATT read, cached).
      final deviceId = await _transportManager.resolveDeviceId(peer);
      final rows = await _packetStore.allUnexpiredRows();
      final key = peerDeviceKey(deviceId);
      DeviceLocation? location;
      var locationLooked = false;

      for (final row in rows) {
        if (!_started) return;
        if (_packetStore.forwardedTo(row).contains(key)) continue;
        if (DeviceIdentity.shortIdOfPublicKeyHex(row.sourceDeviceId) == deviceId) {
          // Their own alert — they already have it.
          await _packetStore.markForwardedTo(row.packetId, key);
          continue;
        }
        var packet = P2pPacketStore.decodeRow(row);
        if (row.receivedFromPeerId != null) {
          if (packet.ttlHops <= 1) continue; // hop budget spent
          packet = packet.copyWithDecrementedTtl();
        }

        if (!locationLooked) {
          location = await _deviceLocation();
          locationLooked = true;
        }
        final shouldForward = _relevanceEngine.shouldForward(
          payload: DiseaseAlertPayload.fromMap(packet.payload),
          deviceLat: location?.lat,
          deviceLng: location?.lng,
          myCropIds: _farmerProfile.myCropIds,
          alreadyForwardedToThisPeer: false,
        );
        if (!shouldForward) {
          p2pLog('fwd SUPPRESS packet=${row.packetId} to=$deviceId (below relevance threshold)');
          continue;
        }

        await _transportManager.send(peer, packet.encode());
        await _packetStore.markForwardedTo(row.packetId, key);
        p2pLog('fwd DELIVERED packet=${row.packetId} to=$deviceId ttl=${packet.ttlHops}');
      }
      await _offerSnapshotsTo(peer, deviceId);
    } catch (e) {
      p2pLog('fwd to $peer failed, will retry on next resync: $e');
    } finally {
      _offering.remove(peer);
    }
  }

  /// Location for the relevance engine's geographic term. Bounded and cached
  /// — this used to call getCurrentPosition() with no time limit for every
  /// packet × peer, which stalls indefinitely indoors or offline.
  Future<DeviceLocation?> _deviceLocation() async {
    final at = _cachedLocationAt;
    if (at != null && DateTime.now().difference(at) < const Duration(minutes: 2)) {
      return _cachedLocation;
    }
    final location = await _locate();
    _cachedLocation = location;
    _cachedLocationAt = DateTime.now();
    if (location == null) {
      p2pLog('no location fix — relevance uses neutral geographic term');
    }
    return location;
  }

  static Future<DeviceLocation?> _geolocatorLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        return null;
      }
      final position = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(timeLimit: Duration(seconds: 5)),
          );
      return (lat: position.latitude, lng: position.longitude);
    } catch (_) {
      return null;
    }
  }
}

/// Async because constructing a P2pAlertService needs this device's signing
/// identity and farmer profile, both of which load from platform secure
/// storage / shared_preferences. Callers (e.g. DiseaseAlertsScreen) await
/// this once, then call .start()/.stop()/.broadcastDetection() on the
/// resolved instance — Riverpod caches it, so repeated reads are free.
final p2pAlertServiceFutureProvider = FutureProvider<P2pAlertService>((ref) async {
  final deviceIdentity = await ref.watch(deviceIdentityProvider.future);
  apiDeviceId = deviceIdentity.shortIdHex;
  final farmerProfile = await ref.watch(farmerProfileProvider.future);
  return P2pAlertService(
    transportManager: ref.watch(transportManagerProvider),
    packetStore: ref.watch(p2pPacketStoreProvider),
    aggregator: ref.watch(localAggregatorProvider),
    relevanceEngine: const RelevanceEngine(),
    deviceIdentity: deviceIdentity,
    farmerProfile: farmerProfile,
    snapshots: SnapshotSync(ref.watch(appDatabaseProvider), () => ref.read(farmSetupProvider).location),
    onSnapshotApplied: (kind) {
      switch (kind) {
        case SnapshotKind.weather:
          ref.invalidate(weatherProvider);
        case SnapshotKind.news:
          ref.invalidate(newsProvider);
        case SnapshotKind.regions:
          ref.invalidate(regionalOutbreaksProvider);
        case SnapshotKind.prices || SnapshotKind.msp || SnapshotKind.uploaded:
          break; // Drift streams update the screens by themselves.
      }
    },
    onPacketStored: () {
      final sync = ref.read(syncManagerProvider);
      if (ref.read(connectivityServiceProvider).isOnline) {
        sync.syncDomain('p2p_alerts').then((ok) => p2pLog('gateway upload ${ok ? 'OK' : 'pending (server unreachable)'}'));
      }
    },
  );
});
