import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'ble_transport.dart';
import 'p2p_transport.dart';

/// Starts whichever transports are available and fans their streams out as
/// one combined stream — the single integration point the relevance engine
/// and packet store talk to. Only BLE is implemented (§9 phase 1-5); Wi-Fi
/// Direct/Multipeer (§9 phase 6) would register here once built, without
/// any change to callers.
class TransportManager {
  TransportManager(this._transports);

  final List<P2pTransport> _transports;
  final List<StreamSubscription> _subs = [];

  final _peerDiscoveredController = StreamController<PeerId>.broadcast();
  final _peerLostController = StreamController<PeerId>.broadcast();
  final _incomingController = StreamController<ReceivedDatagram>.broadcast();

  bool _started = false;

  Stream<PeerId> get peerDiscovered => _peerDiscoveredController.stream;
  Stream<PeerId> get peerLost => _peerLostController.stream;
  Stream<ReceivedDatagram> get incoming => _incomingController.stream;

  Set<PeerId> get knownPeers => _transports.expand((t) => t.knownPeers).toSet();

  Future<void> start() async {
    if (_started) return;
    _started = true;
    for (final transport in _transports) {
      if (!await transport.isAvailable()) continue;
      _subs.add(transport.peerDiscovered.listen(_peerDiscoveredController.add));
      _subs.add(transport.peerLost.listen(_peerLostController.add));
      _subs.add(transport.incoming.listen(_incomingController.add));
      await transport.start();
    }
  }

  Future<void> stop() async {
    _started = false;
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
    for (final transport in _transports) {
      await transport.stop();
    }
  }

  Future<void> send(PeerId peer, Uint8List datagram) async {
    final transport = _transports.firstWhere(
      (t) => t.transportId == peer.transportId,
      orElse: () => throw StateError('No transport registered for ${peer.transportId}'),
    );
    await transport.send(peer, datagram);
  }
}

final transportManagerProvider = Provider<TransportManager>((ref) {
  return TransportManager([BleTransport()]);
});
