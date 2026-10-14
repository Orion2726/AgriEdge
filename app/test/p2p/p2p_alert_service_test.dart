import 'dart:async';
import 'dart:typed_data';

import 'package:agriedge/core/db/app_database.dart';
import 'package:agriedge/core/p2p/aggregation/local_aggregator.dart';
import 'package:agriedge/core/p2p/p2p_alert_service.dart';
import 'package:agriedge/core/p2p/relevance/farmer_profile.dart';
import 'package:agriedge/core/p2p/relevance/relevance_engine.dart';
import 'package:agriedge/core/p2p/security/device_identity.dart';
import 'package:agriedge/core/p2p/store/p2p_packet_store.dart';
import 'package:agriedge/core/p2p/transport/ble_framing.dart';
import 'package:agriedge/core/p2p/transport/p2p_transport.dart';
import 'package:agriedge/core/p2p/transport/transport_manager.dart';
import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// In-memory stand-in for the radio, used only to test P2pAlertService's
/// delivery logic (ack-gated marking, no echo, dedupe, retry). It is not
/// evidence that BLE works — that was tested on two physical phones.
class _MemoryTransport implements P2pTransport {
  _MemoryTransport(this.name);
  final String name;
  final Map<PeerId, _MemoryTransport> links = {};
  DatagramHandler? _handler;
  String? localId;
  int failNextSends = 0;
  final sendLog = <String>[];
  final _discovered = StreamController<PeerId>.broadcast();

  void connect(_MemoryTransport other) {
    final peer = PeerId('mem', other.name);
    links[peer] = other;
    _discovered.add(peer);
  }

  @override
  String get transportId => 'mem';
  @override
  Future<bool> isAvailable() async => true;
  @override
  Stream<PeerId> get peerDiscovered => _discovered.stream;
  @override
  Stream<PeerId> get peerLost => const Stream.empty();
  @override
  Stream<void> get statusChanged => const Stream.empty();
  @override
  P2pTransportState get state => P2pTransportState.running;
  @override
  String? get stateDetail => null;
  @override
  List<PeerStatus> get peers => const [];
  @override
  Set<PeerId> get knownPeers => links.keys.toSet();
  @override
  set datagramHandler(DatagramHandler? handler) => _handler = handler;
  @override
  Future<void> start({required Uint8List localDeviceId}) async => localId = hexOf(localDeviceId);
  @override
  Future<void> stop() async {}
  @override
  Future<String> resolveDeviceId(PeerId peer) async => links[peer]!.localId!;
  @override
  Future<String> send(PeerId peer, Uint8List datagram) async {
    if (failNextSends > 0) {
      failNextSends--;
      throw StateError('simulated link failure');
    }
    final other = links[peer]!;
    sendLog.add(other.name);
    await other._handler!(ReceivedDatagram(from: PeerId('mem', name), senderDeviceId: localId!, bytes: datagram));
    return other.localId!;
  }
}

class _Node {
  _Node(this.db, this.store, this.transport, this.service);
  final AppDatabase db;
  final P2pPacketStore store;
  final _MemoryTransport transport;
  final P2pAlertService service;
}

Future<_Node> _node(String name) async {
  FlutterSecureStorage.setMockInitialValues({});
  final identity = await DeviceIdentity.loadOrCreate(const FlutterSecureStorage());
  final db = AppDatabase.forTesting(NativeDatabase.memory());
  final store = P2pPacketStore(db);
  final transport = _MemoryTransport(name);
  final service = P2pAlertService(
    transportManager: TransportManager([transport]),
    packetStore: store,
    aggregator: LocalAggregator(store, db),
    relevanceEngine: const RelevanceEngine(),
    deviceIdentity: identity,
    farmerProfile: FarmerProfile(await SharedPreferences.getInstance()),
    locate: () async => null, // no location fix — must still forward
    resyncInterval: const Duration(hours: 1), // resync driven manually below
  );
  await service.start();
  return _Node(db, store, transport, service);
}

Future<void> _settle() => Future<void>.delayed(const Duration(milliseconds: 200));

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true; // one in-memory DB per simulated phone
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('A→B delivery is stored, verified, marked delivered and never echoed back', () async {
    final a = await _node('A');
    final b = await _node('B');
    a.transport.connect(b.transport);
    b.transport.connect(a.transport);

    final packet = await a.service.broadcastDetection(
        cropId: 'potato', label: 'Potato___Late_blight', confidence: 0.9, severity: 'high', lat: 12.8, lng: 80.1);
    await _settle();

    final rowB = (await b.store.allUnexpiredRows()).single;
    expect(rowB.packetId, packet.packetIdHex);
    expect(rowB.verified, isTrue);
    expect(rowB.receivedFromPeerId, 'dev:${a.transport.localId}');

    final rowA = (await a.store.allUnexpiredRows()).single;
    expect(a.store.forwardedTo(rowA), ['dev:${b.transport.localId}']);
    expect(b.transport.sendLog, isEmpty, reason: 'B must not echo the packet back to A');
  });

  test('a failed send is not marked delivered and is retried on the next pass', () async {
    final a = await _node('A');
    final b = await _node('B');
    a.transport.connect(b.transport);
    a.transport.failNextSends = 1;

    await a.service.broadcastDetection(
        cropId: 'rice', label: 'blast', confidence: 0.8, severity: 'medium', lat: 12.8, lng: 80.1);
    await _settle();
    expect(await b.store.allUnexpiredRows(), isEmpty);
    expect(a.store.forwardedTo((await a.store.allUnexpiredRows()).single), isEmpty);

    a.transport.connect(b.transport); // rediscovery triggers a fresh offer
    await _settle();
    expect(await b.store.allUnexpiredRows(), hasLength(1));
  });

  test('a duplicate delivery is acknowledged without a second row', () async {
    final a = await _node('A');
    final b = await _node('B');
    a.transport.connect(b.transport);
    final packet = await a.service.broadcastDetection(
        cropId: 'wheat', label: 'Yellow Rust', confidence: 0.7, severity: 'medium', lat: 12.8, lng: 80.1);
    await _settle();
    // Resend the identical bytes, as after a lost acknowledgment.
    await a.transport.send(PeerId('mem', 'B'), packet.encode());
    expect(await b.store.allUnexpiredRows(), hasLength(1));
  });

  test('A→B→C store-and-forward keeps the original signature and stops at the hop budget', () async {
    final a = await _node('A');
    final b = await _node('B');
    final c = await _node('C');
    a.transport.connect(b.transport);
    await a.service.broadcastDetection(
        cropId: 'cotton', label: 'Bacterial Blight', confidence: 0.85, severity: 'high', lat: 12.8, lng: 80.1);
    await _settle();
    expect(await c.store.allUnexpiredRows(), isEmpty, reason: 'C has not met anyone yet');

    b.transport.connect(c.transport); // later, B meets C
    await _settle();
    final rowC = (await c.store.allUnexpiredRows()).single;
    expect(rowC.verified, isTrue, reason: "A's signature must survive the relay");
    expect(rowC.receivedFromPeerId, 'dev:${b.transport.localId}');
    expect(P2pPacketStore.decodeRow(rowC).ttlHops, 9);
  });

  test('undecodable datagrams are acknowledged and dropped', () async {
    final b = await _node('B');
    final a = _MemoryTransport('A')..localId = '0102030405060708';
    b.transport.links[PeerId('mem', 'A')] = a;
    await b.transport._handler!(ReceivedDatagram(
        from: PeerId('mem', 'A'), senderDeviceId: a.localId!, bytes: Uint8List.fromList([1, 2, 3])));
    expect(await b.store.allUnexpiredRows(), isEmpty);
  });
}
