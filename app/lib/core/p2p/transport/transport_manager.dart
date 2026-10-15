import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ble_transport.dart';
import 'p2p_transport.dart';

/// Starts whichever transports are available and fans their streams out as
/// one combined surface — the single integration point the relevance engine
/// and packet store talk to. Only BLE is implemented (§9 phase 1-5); Wi-Fi
/// Direct/Multipeer (§9 phase 6) would register here once built, without
/// any change to callers.
class TransportManager {
  TransportManager(this._transports);

  final List<P2pTransport> _transports;
  final List<StreamSubscription> _subs = [];

  final _peerDiscoveredController = StreamController<PeerId>.broadcast();
  final _peerLostController = StreamController<PeerId>.broadcast();
  final _statusController = StreamController<void>.broadcast();

  bool _started = false;

  Stream<PeerId> get peerDiscovered => _peerDiscoveredController.stream;
  Stream<PeerId> get peerLost => _peerLostController.stream;
  Stream<void> get statusChanged => _statusController.stream;

  Set<PeerId> get knownPeers => _transports.expand((t) => t.knownPeers).toSet();
  List<PeerStatus> get peers => _transports.expand((t) => t.peers).toList(growable: false);

  /// The single transport's state while BLE is the only one; with several,
  /// "running" if any is.
  P2pTransportState get state {
    if (_transports.any((t) => t.state == P2pTransportState.running)) {
      return P2pTransportState.running;
    }
    return _transports.isEmpty ? P2pTransportState.unsupported : _transports.first.state;
  }

  String? get stateDetail => _transports.isEmpty ? null : _transports.first.stateDetail;

  set datagramHandler(DatagramHandler? handler) {
    for (final t in _transports) {
      t.datagramHandler = handler;
    }
  }

  Future<void> start({required Uint8List localDeviceId}) async {
    if (_started) return;
    _started = true;
    for (final transport in _transports) {
      if (!await transport.isAvailable()) continue;
      _subs.add(transport.peerDiscovered.listen(_peerDiscoveredController.add));
      _subs.add(transport.peerLost.listen(_peerLostController.add));
      _subs.add(transport.statusChanged.listen(_statusController.add));
    }
    // A failed start (permission denied, Bluetooth off) still leaves the
    // status subscriptions in place so the UI sees later recovery.
    for (final transport in _transports) {
      if (!await transport.isAvailable()) continue;
      await transport.start(localDeviceId: localDeviceId);
    }
  }

  /// Asks Bluetooth to advertise again after running scan-only.
  Future<void> retryAdvertising() async {
    for (final t in _transports) {
      if (t is BleTransport) await t.retryAdvertising();
    }
  }

  Future<void> stop() async {
    _started = false;
    for (final transport in _transports) {
      await transport.stop();
    }
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
    _statusController.add(null);
  }

  P2pTransport _transportFor(PeerId peer) => _transports.firstWhere(
        (t) => t.transportId == peer.transportId,
        orElse: () => throw StateError('No transport registered for ${peer.transportId}'),
      );

  Future<String> send(PeerId peer, Uint8List datagram) => _transportFor(peer).send(peer, datagram);

  Future<String> resolveDeviceId(PeerId peer) => _transportFor(peer).resolveDeviceId(peer);
}

final transportManagerProvider = Provider<TransportManager>((ref) {
  return TransportManager([BleTransport()]);
});
