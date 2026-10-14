import 'dart:typed_data';

/// Opaque per-transport peer handle. Two peers seen on different transports
/// (e.g. this device sees the same phone via BLE now, Wi-Fi Direct later)
/// are NOT unified here — that's TransportManager's job, once a second
/// transport exists (see docs/P2P_ALERT_PROTOCOL.md §9 phase 6, not yet
/// implemented). For now there's exactly one transport (BLE) so PeerId is
/// just that transport's own peer identifier (for BLE: the advertising
/// address, which Android rotates — use [PeerStatus.deviceId] for a stable
/// identity).
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
  const ReceivedDatagram({required this.from, required this.senderDeviceId, required this.bytes});

  /// Transport-level link the datagram arrived on (for BLE, the writer's
  /// current address — not the address it advertises with).
  final PeerId from;

  /// Stable identity of the sending device (hex of the first 8 bytes of its
  /// Ed25519 public key), carried in the frame header.
  final String senderDeviceId;
  final Uint8List bytes;
}

/// Called for every complete datagram. The transport acknowledges the
/// datagram to the sender only after this completes; throwing makes the
/// sender's send() fail so it retries later.
typedef DatagramHandler = Future<void> Function(ReceivedDatagram datagram);

enum P2pTransportState {
  stopped,
  starting,
  running,
  permissionDenied,
  bluetoothOff,
  unsupported,
  failed,
}

/// Snapshot of one nearby peer, for status UI and diagnostics.
class PeerStatus {
  PeerStatus({required this.peer, required this.lastSeen});

  final PeerId peer;
  DateTime lastSeen;
  int? rssi;

  /// Learned by reading the peer's identity characteristic on first
  /// connection, or from the header of a datagram it sent us.
  String? deviceId;
  bool connected = false;
  int sent = 0;
  int received = 0;
  DateTime? lastSentAt;
  DateTime? lastReceivedAt;
  String? lastError;
}

class P2pTransportException implements Exception {
  const P2pTransportException(this.state, this.message);
  final P2pTransportState state;
  final String message;

  @override
  String toString() => message;
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

  /// Fires whenever [state], [stateDetail] or any [peers] entry changes.
  Stream<void> get statusChanged;

  P2pTransportState get state;
  String? get stateDetail;
  List<PeerStatus> get peers;

  /// Peers currently considered reachable (seen within this transport's
  /// own liveness window). Lets a caller forward an already-cached packet
  /// to peers met *before* that packet existed, not just ones met after —
  /// see P2pAlertService.broadcastDetection.
  Set<PeerId> get knownPeers;

  set datagramHandler(DatagramHandler? handler);

  /// Starts discovery/advertising, requesting runtime permissions first
  /// where the platform needs them. Throws [P2pTransportException] naming
  /// the actual reason (permission denied, Bluetooth off, …) on failure.
  Future<void> start({required Uint8List localDeviceId});
  Future<void> stop();

  /// Delivers [datagram] to [peer] and completes once the peer's handler
  /// accepted it. Returns the peer's stable device id.
  Future<String> send(PeerId peer, Uint8List datagram);

  /// The peer's stable device id, connecting to ask for it if not yet known.
  Future<String> resolveDeviceId(PeerId peer);
}
