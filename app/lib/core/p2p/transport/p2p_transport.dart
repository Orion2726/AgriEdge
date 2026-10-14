import 'dart:typed_data';

/// Opaque per-transport peer handle. Two peers seen on different transports
/// (e.g. this device sees the same phone via BLE now, Wi-Fi Direct later)
/// are NOT unified here — that's TransportManager's job, once a second
/// transport exists (see docs/P2P_ALERT_PROTOCOL.md §9 phase 6, not yet
/// implemented). For now there's exactly one transport (BLE) so PeerId is
/// just that transport's own peer identifier.
class PeerId {
  const PeerId(this.transportId, this.value);
  final String transportId;
  final String value;

  @override
  bool operator ==(Object other) =>
      other is PeerId && other.transportId == transportId && other.value == value;

  @override
  int get hashCode => Object.hash(transportId, value);

  @override
  String toString() => '$transportId:$value';
}

class ReceivedDatagram {
  const ReceivedDatagram({required this.from, required this.bytes});
  final PeerId from;
  final Uint8List bytes;
}

/// Uniform interface over heterogeneous P2P radios — the "OS-agnostic
/// network stack" from docs/P2P_ALERT_PROTOCOL.md §2. Everything above this
/// layer (relevance engine, packet store, aggregation) talks only to this
/// interface and never touches a platform BLE/Wi-Fi API directly.
abstract class P2pTransport {
  String get transportId;

  /// Whether this transport is usable on the current platform/hardware.
  /// Checked once at startup by TransportManager — does not reflect
  /// permission state, which is handled by start() throwing.
  Future<bool> isAvailable();

  Stream<PeerId> get peerDiscovered;
  Stream<PeerId> get peerLost;
  Stream<ReceivedDatagram> get incoming;

  /// Peers currently considered reachable (seen within this transport's
  /// own liveness window). Lets a caller forward an already-cached packet
  /// to peers met *before* that packet existed, not just ones met after —
  /// see P2pAlertService.broadcastDetection.
  Set<PeerId> get knownPeers;

  /// Starts discovery/advertising. Throws if required permissions aren't
  /// granted — callers should request permissions before calling this.
  Future<void> start();
  Future<void> stop();

  Future<void> send(PeerId peer, Uint8List datagram);
}
