import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:bluetooth_low_energy/bluetooth_low_energy.dart';

import '../p2p_log.dart';
import 'ble_framing.dart';
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
/// GATT layout:
/// - inbox (write): datagrams, framed by [BleFraming]. The write response
///   to a message's last chunk is sent only after the receiving app has
///   processed (stored) the datagram, so a successful send() is an
///   end-to-end acknowledgment, not just a radio-level one.
/// - identity (read): this device's 8-byte P2P id, so a sender knows who it
///   is talking to even though Android rotates advertised addresses.
///
/// Service/characteristic UUIDs below are arbitrary 16-bit "short" values
/// picked for prototyping. Before any deployment alongside other BLE apps,
/// replace with a randomly-generated 128-bit UUID to avoid collisions.
class BleTransport implements P2pTransport {
  BleTransport({CentralManager? central, PeripheralManager? peripheral})
      : _central = central ?? CentralManager(),
        _peripheral = peripheral ?? PeripheralManager();

  static final _serviceUuid = UUID.short(0xfea6);
  static final _inboxCharacteristicUuid = UUID.short(0xfea7);
  static final _identityCharacteristicUuid = UUID.short(0xfea8);

  /// A peer not heard from (advertisement or write) for this long is
  /// considered gone. Android reports matching advertisements several times
  /// a second while scanning in the foreground.
  static const _peerTimeout = Duration(seconds: 30);
  static const _connectTimeout = Duration(seconds: 12);
  static const _operationTimeout = Duration(seconds: 10);

  /// A message's last chunk is answered only once the receiving app stored
  /// it, so allow close to the 30 s ATT transaction limit.
  static const _ackTimeout = Duration(seconds: 25);

  /// Links are dropped after this long without traffic — Android allows only
  /// a handful of simultaneous GATT connections.
  static const _idleDisconnectAfter = Duration(seconds: 20);

  final CentralManager _central;
  final PeripheralManager _peripheral;

  final _peerDiscoveredController = StreamController<PeerId>.broadcast();
  final _peerLostController = StreamController<PeerId>.broadcast();
  final _statusController = StreamController<void>.broadcast();

  final Map<String, _PeerLink> _links = {};
  final BleReassembler _reassembler = BleReassembler();
  final Map<String, Future<void>> _sendQueues = {};
  final List<StreamSubscription> _subs = [];
  StreamSubscription? _adapterSub;
  Timer? _housekeepingTimer;

  DatagramHandler? _handler;
  Uint8List? _localDeviceId;
  int _nextMsgId = Random().nextInt(0xFFFF);
  bool _rolesRunning = false;

  P2pTransportState _state = P2pTransportState.stopped;
  String? _stateDetail;

  @override
  String get transportId => 'ble';

  @override
  Future<bool> isAvailable() async => Platform.isAndroid || Platform.isIOS;

  @override
  Stream<PeerId> get peerDiscovered => _peerDiscoveredController.stream;

  @override
  Stream<PeerId> get peerLost => _peerLostController.stream;

  @override
  Stream<void> get statusChanged => _statusController.stream;

  @override
  P2pTransportState get state => _state;

  @override
  String? get stateDetail => _stateDetail;

  @override
  List<PeerStatus> get peers => _links.values.map((l) => l.status).toList(growable: false);

  @override
  Set<PeerId> get knownPeers => _links.values.map((l) => l.status.peer).toSet();

  @override
  set datagramHandler(DatagramHandler? handler) => _handler = handler;

  void _setState(P2pTransportState state, [String? detail]) {
    if (_state != state || _stateDetail != detail) {
      p2pLog('ble state ${_state.name} -> ${state.name}${detail == null ? '' : ' ($detail)'}');
    }
    _state = state;
    _stateDetail = detail;
    _notify();
  }

  void _notify() {
    if (!_statusController.isClosed) _statusController.add(null);
  }

  @override
  Future<void> start({required Uint8List localDeviceId}) async {
    if (_state == P2pTransportState.running || _state == P2pTransportState.starting) return;
    _localDeviceId = Uint8List.fromList(localDeviceId);
    _setState(P2pTransportState.starting);
    try {
      await _ensureReady(_central, 'scan for');
      await _ensureReady(_peripheral, 'be found by');
    } on P2pTransportException catch (e) {
      _setState(e.state, e.message);
      if (e.state == P2pTransportState.bluetoothOff) _listenForAdapterChanges();
      rethrow;
    }

    _listenForAdapterChanges();
    _subs.add(_peripheral.characteristicWriteRequested.listen(_onWriteRequested));
    _subs.add(_peripheral.connectionStateChanged.listen((e) {
      if (e.state == ConnectionState.disconnected) {
        _reassembler.dropLink(e.central.uuid.toString());
      }
    }));
    _subs.add(_central.discovered.listen(_onDiscovered));
    _subs.add(_central.connectionStateChanged.listen(_onCentralConnectionChanged));
    _housekeepingTimer = Timer.periodic(const Duration(seconds: 5), (_) => _housekeeping());

    try {
      await _startRoles();
      _setState(P2pTransportState.running);
    } catch (e) {
      _setState(P2pTransportState.failed, 'Could not start Bluetooth advertising/scanning: $e');
      rethrow;
    }
  }

  /// Outlives a failed start(): if the user turns Bluetooth on from the
  /// system shade, the session comes up without reopening the screen; if it
  /// goes off mid-session, peers are dropped and the roles rebuilt later.
  void _listenForAdapterChanges() {
    _adapterSub ??= _central.stateChanged.listen((event) async {
      p2pLog('ble adapter state -> ${event.state.name}');
      if (event.state == BluetoothLowEnergyState.poweredOn &&
          _state == P2pTransportState.bluetoothOff &&
          _localDeviceId != null) {
        if (_subs.isEmpty) {
          // start() bailed out before wiring anything up — do a full start.
          _setState(P2pTransportState.stopped);
          try {
            await start(localDeviceId: _localDeviceId!);
          } catch (e) {
            p2pLog('ble start after adapter on failed: $e');
          }
          return;
        }
        // The GATT server and advertiser died with the adapter; rebuild them.
        try {
          _rolesRunning = false;
          await _startRoles();
          _setState(P2pTransportState.running);
        } catch (e) {
          _setState(P2pTransportState.failed,
              'Could not restart Bluetooth after it was turned back on: $e');
        }
      } else if (event.state == BluetoothLowEnergyState.poweredOff &&
          _state != P2pTransportState.stopped) {
        _rolesRunning = false;
        _reassembler.dropAll();
        _dropAllPeers();
        _setState(P2pTransportState.bluetoothOff, 'Bluetooth is off');
      } else if (event.state == BluetoothLowEnergyState.unauthorized &&
          _state != P2pTransportState.stopped) {
        _rolesRunning = false;
        _dropAllPeers();
        _setState(P2pTransportState.permissionDenied, 'Nearby-devices permission was revoked');
      }
    });
  }

  /// Resolves the adapter/permission state, requesting runtime permissions
  /// when needed. The manager's state is `unknown` until its first platform
  /// callback, so checking `state == unauthorized` once (as this used to)
  /// races that callback and never asks for permission.
  Future<void> _ensureReady(BluetoothLowEnergyManager manager, String purpose) async {
    var state = await _settledState(manager);
    if (state == BluetoothLowEnergyState.unauthorized && Platform.isAndroid) {
      p2pLog('ble requesting runtime permission to $purpose nearby devices');
      final granted = await manager.authorize();
      state = granted ? await _settledState(manager, waitFor: (s) => s != BluetoothLowEnergyState.unauthorized) : manager.state;
    }
    switch (state) {
      case BluetoothLowEnergyState.poweredOn:
        return;
      case BluetoothLowEnergyState.unauthorized:
        throw P2pTransportException(
          P2pTransportState.permissionDenied,
          'AgriEdge needs the "Nearby devices" permission to $purpose other farmers\' phones.',
        );
      case BluetoothLowEnergyState.poweredOff:
        throw const P2pTransportException(
          P2pTransportState.bluetoothOff,
          'Bluetooth is off. Turn it on to exchange alerts with nearby phones.',
        );
      case BluetoothLowEnergyState.unsupported:
        throw const P2pTransportException(
          P2pTransportState.unsupported,
          'This device does not support Bluetooth LE advertising, so nearby phones can\'t find it.',
        );
      case BluetoothLowEnergyState.unknown:
        throw const P2pTransportException(
          P2pTransportState.failed,
          'Bluetooth did not report its state. On a simulator this is expected — no real BLE hardware.',
        );
    }
  }

  Future<BluetoothLowEnergyState> _settledState(
    BluetoothLowEnergyManager manager, {
    bool Function(BluetoothLowEnergyState)? waitFor,
    Duration timeout = const Duration(seconds: 4),
  }) async {
    bool done(BluetoothLowEnergyState s) =>
        waitFor?.call(s) ?? s != BluetoothLowEnergyState.unknown;
    if (done(manager.state)) return manager.state;
    try {
      final event = await manager.stateChanged.firstWhere((e) => done(e.state)).timeout(timeout);
      return event.state;
    } on TimeoutException {
      return manager.state;
    }
  }

  Future<void> _startRoles() async {
    if (_rolesRunning) return;
    await _peripheral.removeAllServices();
    await _peripheral.addService(GATTService(
      uuid: _serviceUuid,
      isPrimary: true,
      includedServices: [],
      characteristics: [
        GATTCharacteristic.mutable(
          uuid: _inboxCharacteristicUuid,
          properties: [GATTCharacteristicProperty.write],
          permissions: [GATTCharacteristicPermission.write],
          descriptors: [],
        ),
        GATTCharacteristic.immutable(
          uuid: _identityCharacteristicUuid,
          value: _localDeviceId!,
          descriptors: [],
        ),
      ],
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
    await _central.startDiscovery(serviceUUIDs: [_serviceUuid]);
    _rolesRunning = true;
    p2pLog('ble advertising + scanning as ${hexOf(_localDeviceId!)}');
  }

  // ---------------------------------------------------------------- receive

  Future<void> _onWriteRequested(GATTCharacteristicWriteRequestedEventArgs event) async {
    final linkId = event.central.uuid.toString();
    if (event.characteristic.uuid != _inboxCharacteristicUuid) {
      await _respondError(event.request, GATTError.requestNotSupported);
      return;
    }
    final result = _reassembler.accept(linkId, event.request.value);
    switch (result) {
      case ReassemblyPending():
        await _respondOk(event.request);
      case ReassemblyRejected(:final reason):
        p2pLog('ble rx REJECT link=$linkId: $reason');
        await _respondError(event.request, GATTError.unlikelyError);
      case ReassemblyComplete(:final senderId, :final msgId, :final datagram):
        final senderHex = hexOf(senderId);
        final status = _statusForInbound(linkId, senderHex);
        p2pLog('ble rx msg=$msgId from=$senderHex link=$linkId bytes=${datagram.length}');
        try {
          final handler = _handler;
          if (handler != null) {
            await handler(ReceivedDatagram(
              from: PeerId(transportId, linkId),
              senderDeviceId: senderHex,
              bytes: datagram,
            ));
          }
          status?.received++;
          status?.lastReceivedAt = DateTime.now();
          _notify();
          await _respondOk(event.request);
          p2pLog('ble rx ACK msg=$msgId from=$senderHex');
        } catch (e) {
          p2pLog('ble rx NACK msg=$msgId from=$senderHex: $e');
          await _respondError(event.request, GATTError.unlikelyError);
        }
    }
  }

  /// The writer's address differs from the address it advertises with, so
  /// match the inbound message to a discovered peer by device id.
  PeerStatus? _statusForInbound(String linkId, String senderDeviceId) {
    for (final link in _links.values) {
      if (link.status.deviceId == senderDeviceId) {
        link.status.lastSeen = DateTime.now();
        return link.status;
      }
    }
    return null;
  }

  Future<void> _respondOk(GATTWriteRequest request) async {
    try {
      await _peripheral.respondWriteRequest(request);
    } catch (e) {
      p2pLog('ble respondWriteRequest failed: $e');
    }
  }

  Future<void> _respondError(GATTWriteRequest request, GATTError error) async {
    try {
      await _peripheral.respondWriteRequestWithError(request, error: error);
    } catch (e) {
      p2pLog('ble respondWriteRequestWithError failed: $e');
    }
  }

  // -------------------------------------------------------------- discovery

  void _onDiscovered(DiscoveredEventArgs event) {
    final address = event.peripheral.uuid.toString();
    final existing = _links[address];
    if (existing != null) {
      existing.peripheral = event.peripheral;
      existing.status.lastSeen = DateTime.now();
      existing.status.rssi = event.rssi;
      return;
    }
    final link = _PeerLink(
      peripheral: event.peripheral,
      status: PeerStatus(peer: PeerId(transportId, address), lastSeen: DateTime.now())
        ..rssi = event.rssi,
    );
    _links[address] = link;
    p2pLog('ble discovered peer addr=$address rssi=${event.rssi}');
    _peerDiscoveredController.add(link.status.peer);
    _notify();
  }

  void _onCentralConnectionChanged(PeripheralConnectionStateChangedEventArgs event) {
    final link = _links[event.peripheral.uuid.toString()];
    p2pLog('ble link ${event.peripheral.uuid} -> ${event.state.name}');
    if (link == null) return;
    if (event.state == ConnectionState.disconnected) {
      link.clearGatt();
    } else {
      link.status.connected = true;
    }
    _notify();
  }

  void _housekeeping() {
    _reassembler.dropStale();
    final now = DateTime.now();
    final stale = _links.entries
        .where((e) => !e.value.status.connected && now.difference(e.value.status.lastSeen) > _peerTimeout)
        .map((e) => e.key)
        .toList();
    for (final address in stale) {
      final link = _links.remove(address)!;
      p2pLog('ble peer lost addr=$address device=${link.status.deviceId}');
      _peerLostController.add(link.status.peer);
    }
    if (stale.isNotEmpty) _notify();
  }

  void _dropAllPeers() {
    for (final link in _links.values) {
      _peerLostController.add(link.status.peer);
    }
    _links.clear();
    _notify();
  }

  // ------------------------------------------------------------------- send

  /// GATT operations on one link must not interleave (two concurrent sends
  /// would interleave their chunks), so every operation on a peer runs
  /// through that peer's queue.
  Future<T> _serialized<T>(String address, Future<T> Function() op) {
    final previous = _sendQueues[address] ?? Future<void>.value();
    final result = previous.then((_) => op());
    final tail = result.then((_) {}, onError: (_) {});
    _sendQueues[address] = tail;
    tail.then((_) {
      if (identical(_sendQueues[address], tail)) _sendQueues.remove(address);
    });
    return result;
  }

  _PeerLink _linkFor(PeerId peer) {
    if (peer.transportId != transportId) {
      throw ArgumentError('PeerId ${peer.transportId} is not a BLE peer');
    }
    final link = _links[peer.value];
    if (link == null) throw StateError('Peer ${peer.value} is not currently reachable');
    return link;
  }

  @override
  Future<String> resolveDeviceId(PeerId peer) {
    final known = _links[peer.value]?.status.deviceId;
    if (known != null) return Future.value(known);
    return _serialized(peer.value, () async {
      final link = _linkFor(peer);
      await _ensureGatt(link);
      link.touch(_idleDisconnectAfter, () => _disconnect(link));
      return link.status.deviceId!;
    });
  }

  @override
  Future<String> send(PeerId peer, Uint8List datagram) {
    return _serialized(peer.value, () async {
      final link = _linkFor(peer);
      final msgId = _nextMsgId = (_nextMsgId + 1) & 0xFFFF;
      for (var attempt = 1;; attempt++) {
        try {
          await _ensureGatt(link);
          final maxLength = await _central
              .getMaximumWriteLength(link.peripheral, type: GATTCharacteristicWriteType.withResponse)
              .timeout(_operationTimeout);
          final chunks = BleFraming.fragment(
            datagram: datagram,
            msgId: msgId,
            senderId: _localDeviceId!,
            maxChunkLength: min(maxLength, 512),
          );
          p2pLog('ble tx msg=$msgId to=${link.status.deviceId} addr=${peer.value} '
              'bytes=${datagram.length} chunks=${chunks.length} attempt=$attempt');
          for (final chunk in chunks) {
            await _central
                .writeCharacteristic(
                  link.peripheral,
                  link.inbox!,
                  value: chunk,
                  type: GATTCharacteristicWriteType.withResponse,
                )
                .timeout(identical(chunk, chunks.last) ? _ackTimeout : _operationTimeout);
          }
          link.status
            ..sent += 1
            ..lastSentAt = DateTime.now()
            ..lastError = null;
          link.touch(_idleDisconnectAfter, () => _disconnect(link));
          _notify();
          p2pLog('ble tx ACK msg=$msgId to=${link.status.deviceId}');
          return link.status.deviceId!;
        } catch (e) {
          link.status.lastError = '$e';
          _notify();
          p2pLog('ble tx FAIL msg=$msgId to=${link.status.deviceId} addr=${peer.value} attempt=$attempt: $e');
          await _disconnect(link);
          // One retry over a fresh connection covers the common transient
          // case (stale link after the peer restarted its GATT server).
          if (attempt >= 2) rethrow;
        }
      }
    });
  }

  Future<void> _ensureGatt(_PeerLink link) async {
    if (link.inbox != null && link.status.connected) return;
    final address = link.status.peer.value;
    try {
      await _central.connect(link.peripheral).timeout(_connectTimeout);
    } on TimeoutException {
      throw TimeoutException('connect to $address timed out', _connectTimeout);
    }
    link.status.connected = true;
    try {
      // Fewer, larger writes; harmless if the peer can't do 512.
      final mtu = await _central.requestMTU(link.peripheral, mtu: 517).timeout(_operationTimeout);
      p2pLog('ble link $address mtu=$mtu');
    } catch (e) {
      p2pLog('ble link $address requestMTU failed (using default): $e');
    }
    final services = await _central.discoverGATT(link.peripheral).timeout(_operationTimeout);
    final service = services.where((s) => s.uuid == _serviceUuid).firstOrNull;
    if (service == null) throw StateError('Peer $address has no AgriEdge GATT service');
    final inbox = service.characteristics.where((c) => c.uuid == _inboxCharacteristicUuid).firstOrNull;
    final identity =
        service.characteristics.where((c) => c.uuid == _identityCharacteristicUuid).firstOrNull;
    if (inbox == null || identity == null) {
      throw StateError('Peer $address is running an incompatible AgriEdge version (missing characteristics)');
    }
    final idBytes = await _central.readCharacteristic(link.peripheral, identity).timeout(_operationTimeout);
    if (idBytes.length != BleFraming.senderIdLength) {
      throw StateError('Peer $address sent a malformed identity (${idBytes.length} bytes)');
    }
    link.inbox = inbox;
    final deviceId = hexOf(idBytes);
    link.status.deviceId = deviceId;
    p2pLog('ble link $address identified as device=$deviceId');
    _dedupeByDeviceId(link);
    _notify();
  }

  /// The same phone can show up under a new advertising address after
  /// Android rotates it; keep only the freshest entry per device.
  void _dedupeByDeviceId(_PeerLink fresh) {
    final duplicates = _links.entries
        .where((e) => e.value != fresh && e.value.status.deviceId == fresh.status.deviceId)
        .map((e) => e.key)
        .toList();
    for (final address in duplicates) {
      final old = _links.remove(address)!;
      // Carry the counters over so the UI doesn't reset on rotation.
      fresh.status
        ..sent += old.status.sent
        ..received += old.status.received
        ..lastSentAt ??= old.status.lastSentAt
        ..lastReceivedAt ??= old.status.lastReceivedAt;
      p2pLog('ble peer addr=$address superseded by ${fresh.status.peer.value} (same device)');
      _peerLostController.add(old.status.peer);
    }
  }

  Future<void> _disconnect(_PeerLink link) async {
    link.cancelIdle();
    final wasConnected = link.status.connected;
    link.clearGatt();
    if (!wasConnected) return;
    try {
      await _central.disconnect(link.peripheral).timeout(_operationTimeout);
    } catch (_) {
      // Already gone — nothing to clean up.
    }
    _notify();
  }

  @override
  Future<void> stop() async {
    _housekeepingTimer?.cancel();
    _housekeepingTimer = null;
    await _adapterSub?.cancel();
    _adapterSub = null;
    await _cancelSubs();
    for (final link in _links.values.toList()) {
      await _disconnect(link);
    }
    _links.clear();
    _sendQueues.clear();
    _reassembler.dropAll();
    if (_rolesRunning) {
      _rolesRunning = false;
      for (final step in <Future<void> Function()>[
        _central.stopDiscovery,
        _peripheral.stopAdvertising,
        _peripheral.removeAllServices,
      ]) {
        try {
          await step();
        } catch (e) {
          p2pLog('ble stop step failed: $e');
        }
      }
    }
    _setState(P2pTransportState.stopped);
  }

  Future<void> _cancelSubs() async {
    for (final sub in _subs) {
      await sub.cancel();
    }
    _subs.clear();
  }
}

class _PeerLink {
  _PeerLink({required this.peripheral, required this.status});

  Peripheral peripheral;
  final PeerStatus status;
  GATTCharacteristic? inbox;
  Timer? _idleTimer;

  void touch(Duration idle, void Function() onIdle) {
    _idleTimer?.cancel();
    _idleTimer = Timer(idle, onIdle);
  }

  void cancelIdle() {
    _idleTimer?.cancel();
    _idleTimer = null;
  }

  void clearGatt() {
    inbox = null;
    status.connected = false;
  }
}
