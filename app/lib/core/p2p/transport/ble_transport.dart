import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

import 'p2p_transport.dart';

/// BLE transport — the cross-platform baseline (§1, §2 of
/// docs/P2P_ALERT_PROTOCOL.md). Runs BOTH BLE roles simultaneously, which
/// is required for symmetric phone-to-phone discovery: this device's
/// PeripheralManager advertises + exposes an inbox characteristic so other
/// AgriEdge phones can find and write to it, while its CentralManager scans
/// for and writes to other phones' inboxes. A central-only BLE package
/// (flutter_blue_plus) cannot do this — two phones running central-only
/// would each be able to scan, but neither would be discoverable to the
/// other.
///
/// ⚠️ UNVERIFIED: this environment has no physical BLE hardware and no
/// second device, so actual peer discovery/exchange over the air has not
/// been tested. Everything above the radio boundary (packet codec, signing,
/// relevance scoring, storage, aggregation) is unit-tested; this file is
/// not. Phase 1 of §9 — a real two-device test — is still required before
/// trusting this in the field.
///
/// Service/characteristic UUIDs below are arbitrary 16-bit "short" values
/// picked for prototyping. Before any deployment alongside other BLE apps,
/// replace with a randomly-generated 128-bit UUID to avoid collisions.
class BleTransport implements P2pTransport {
  BleTransport()
      : _central = CentralManager(),
        _peripheral = PeripheralManager();

  static final _serviceUuid = UUID.short(0xfea6);
  static final _inboxCharacteristicUuid = UUID.short(0xfea7);

  final CentralManager _central;
  final PeripheralManager _peripheral;

  final _peerDiscoveredController = StreamController<PeerId>.broadcast();
  final _peerLostController = StreamController<PeerId>.broadcast();
  final _incomingController = StreamController<ReceivedDatagram>.broadcast();

  final Map<String, Peripheral> _peripheralsByUuid = {};
  final Map<String, GATTCharacteristic> _inboxByPeripheralUuid = {};
  final Map<String, DateTime> _lastSeenByUuid = {};
  final Map<String, Uint8List> _reassemblyBuffer = {};
  final Map<String, int> _reassemblyExpectedLength = {};

  StreamSubscription? _discoveredSub;
  StreamSubscription? _writeRequestedSub;
  Timer? _peerLostTimer;

  static const _peerTimeout = Duration(seconds: 30);

  @override
  String get transportId => 'ble';

  @override
  Future<bool> isAvailable() async {
    try {
      // Throws on platforms with no BLE hardware/support at all; a real
      // "not supported" state otherwise surfaces via .state below.
      return Platform.isAndroid || Platform.isIOS;
    } catch (_) {
      return false;
    }
  }

  @override
  Stream<PeerId> get peerDiscovered => _peerDiscoveredController.stream;

  @override
  Stream<PeerId> get peerLost => _peerLostController.stream;

  @override
  Stream<ReceivedDatagram> get incoming => _incomingController.stream;

  @override
  Set<PeerId> get knownPeers =>
      _lastSeenByUuid.keys.map((uuid) => PeerId(transportId, uuid)).toSet();

  @override
  Future<void> start() async {
    await _startPeripheralRole();
    await _startCentralRole();
    _peerLostTimer = Timer.periodic(const Duration(seconds: 10), (_) => _checkStalePeers());
  }

  /// Both startAdvertising and startDiscovery hang indefinitely (never
  /// throw, never return) if the adapter isn't actually poweredOn —
  /// confirmed empirically on iOS Simulator, which has no real BLE
  /// hardware: state sits at `unsupported` forever and the platform call
  /// just never completes. Fail fast with a clear error instead of hanging
  /// the whole P2P session (and the UI's "Starting…" spinner) forever.
  Future<void> _awaitPoweredOn(
    BluetoothLowEnergyManager manager, {
    Duration timeout = const Duration(seconds: 8),
  }) async {
    if (manager.state == BluetoothLowEnergyState.poweredOn) return;
    if (manager.state == BluetoothLowEnergyState.unauthorized && Platform.isAndroid) {
      await manager.authorize();
      if (manager.state == BluetoothLowEnergyState.poweredOn) return;
    }

    final completer = Completer<void>();
    final sub = manager.stateChanged.listen((event) {
      if (event.state == BluetoothLowEnergyState.poweredOn && !completer.isCompleted) {
        completer.complete();
      }
    });
    try {
      await completer.future.timeout(timeout);
    } on TimeoutException {
      throw StateError(
        'Bluetooth did not reach poweredOn within $timeout (state: ${manager.state}). '
        'On a simulator this is expected — no real BLE hardware. On a real device, '
        'check Bluetooth is on and the permission prompt was accepted.',
      );
    } finally {
      await sub.cancel();
    }
  }

  Future<void> _startPeripheralRole() async {
    _writeRequestedSub = _peripheral.characteristicWriteRequested.listen((event) async {
      final senderUuid = event.central.uuid.toString();
      _onChunkReceived(senderUuid, event.request.value);
      await _peripheral.respondWriteRequest(event.request);
    });

    await _awaitPoweredOn(_peripheral);
    await _peripheral.removeAllServices();
    final inbox = GATTCharacteristic.mutable(
      uuid: _inboxCharacteristicUuid,
      properties: [
        GATTCharacteristicProperty.write,
        GATTCharacteristicProperty.writeWithoutResponse,
      ],
      permissions: [GATTCharacteristicPermission.write],
      descriptors: [],
    );
    await _peripheral.addService(GATTService(
      uuid: _serviceUuid,
      isPrimary: true,
      includedServices: [],
      characteristics: [inbox],
    ));
    // No `name` on Android: bluetooth_low_energy_android implements an
    // advertised name by calling BluetoothAdapter.setName(), which
    // permanently renames the phone's Bluetooth adapter system-wide (e.g.
    // "OnePlus Nord" → "AgriEdge") — a side effect on an unrelated setting.
    // Discovery filters on the service UUID, so the name isn't needed.
    await _peripheral.startAdvertising(Advertisement(
      name: Platform.isAndroid ? null : 'AgriEdge',
      serviceUUIDs: [_serviceUuid],
    ));
  }

  Future<void> _startCentralRole() async {
    _discoveredSub = _central.discovered.listen((event) {
      final uuid = event.peripheral.uuid.toString();
      _peripheralsByUuid[uuid] = event.peripheral;
      final isNew = !_lastSeenByUuid.containsKey(uuid);
      _lastSeenByUuid[uuid] = DateTime.now();
      if (isNew) {
        _peerDiscoveredController.add(PeerId(transportId, uuid));
      }
    });
    await _awaitPoweredOn(_central);
    await _central.startDiscovery(serviceUUIDs: [_serviceUuid]);
  }

  void _checkStalePeers() {
    final now = DateTime.now();
    final stale = _lastSeenByUuid.entries
        .where((e) => now.difference(e.value) > _peerTimeout)
        .map((e) => e.key)
        .toList();
    for (final uuid in stale) {
      _lastSeenByUuid.remove(uuid);
      _peripheralsByUuid.remove(uuid);
      _inboxByPeripheralUuid.remove(uuid);
      _peerLostController.add(PeerId(transportId, uuid));
    }
  }

  /// Envelope: first chunk from a given sender is prefixed with a 4-byte
  /// big-endian total length; subsequent chunks append directly until that
  /// many bytes have accumulated. GATT writes to one characteristic from
  /// one sender arrive in order, so a plain running buffer is sufficient —
  /// no sequence numbers needed.
  void _onChunkReceived(String senderUuid, Uint8List chunk) {
    var buffer = _reassemblyBuffer[senderUuid];
    if (buffer == null) {
      if (chunk.length < 4) return; // malformed — drop
      final totalLength = ByteData.sublistView(chunk).getUint32(0);
      _reassemblyExpectedLength[senderUuid] = totalLength;
      buffer = Uint8List.sublistView(chunk, 4);
    } else {
      final combined = Uint8List(buffer.length + chunk.length);
      combined.setRange(0, buffer.length, buffer);
      combined.setRange(buffer.length, combined.length, chunk);
      buffer = combined;
    }
    final expected = _reassemblyExpectedLength[senderUuid] ?? 0;
    if (buffer.length >= expected) {
      _reassemblyBuffer.remove(senderUuid);
      _reassemblyExpectedLength.remove(senderUuid);
      _incomingController.add(ReceivedDatagram(
        from: PeerId(transportId, senderUuid),
        bytes: Uint8List.sublistView(buffer, 0, expected),
      ));
    } else {
      _reassemblyBuffer[senderUuid] = buffer;
    }
  }

  Future<GATTCharacteristic> _ensureConnectedWithInbox(String peripheralUuid) async {
    final cached = _inboxByPeripheralUuid[peripheralUuid];
    if (cached != null) return cached;

    final peripheral = _peripheralsByUuid[peripheralUuid];
    if (peripheral == null) {
      throw StateError('Unknown BLE peer: $peripheralUuid (not currently discovered)');
    }
    await _central.connect(peripheral);
    final services = await _central.discoverGATT(peripheral);
    final service = services.firstWhere(
      (s) => s.uuid == _serviceUuid,
      orElse: () => throw StateError('Peer $peripheralUuid has no AgriEdge GATT service'),
    );
    final characteristic = service.characteristics.firstWhere(
      (c) => c.uuid == _inboxCharacteristicUuid,
      orElse: () => throw StateError('Peer $peripheralUuid has no inbox characteristic'),
    );
    _inboxByPeripheralUuid[peripheralUuid] = characteristic;
    return characteristic;
  }

  @override
  Future<void> send(PeerId peer, Uint8List datagram) async {
    if (peer.transportId != transportId) {
      throw ArgumentError('PeerId ${peer.transportId} is not a BLE peer');
    }
    final peripheral = _peripheralsByUuid[peer.value];
    if (peripheral == null) {
      throw StateError('Peer ${peer.value} is not currently reachable');
    }
    final characteristic = await _ensureConnectedWithInbox(peer.value);

    final envelope = Uint8List(4 + datagram.length);
    ByteData.sublistView(envelope).setUint32(0, datagram.length);
    envelope.setRange(4, envelope.length, datagram);

    const writeType = GATTCharacteristicWriteType.withResponse;
    final fragmentSize = await _central.getMaximumWriteLength(peripheral, type: writeType);
    var start = 0;
    while (start < envelope.length) {
      final end = (start + fragmentSize < envelope.length) ? start + fragmentSize : envelope.length;
      await _central.writeCharacteristic(
        peripheral,
        characteristic,
        value: Uint8List.sublistView(envelope, start, end),
        type: writeType,
      );
      start = end;
    }
  }

  @override
  Future<void> stop() async {
    _peerLostTimer?.cancel();
    await _discoveredSub?.cancel();
    await _writeRequestedSub?.cancel();
    await _central.stopDiscovery();
    await _peripheral.stopAdvertising();
  }
}
