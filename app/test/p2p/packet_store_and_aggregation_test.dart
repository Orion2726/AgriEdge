import 'package:agriedge/core/db/app_database.dart';
import 'package:agriedge/core/p2p/aggregation/local_aggregator.dart';
import 'package:agriedge/core/p2p/packet/p2p_packet.dart';
import 'package:agriedge/core/p2p/store/p2p_packet_store.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

Future<P2pAlertPacket> buildPacket({
  required String cropId,
  required String label,
  required double lat,
  required double lng,
  double confidence = 0.9,
  String severity = 'high',
  DateTime? observedAt,
  Duration ttl = const Duration(hours: 72),
}) async {
  final now = observedAt ?? DateTime.now().toUtc();
  final payload = DiseaseAlertPayload(
    cropId: cropId,
    label: label,
    confidence: confidence,
    severity: severity,
    latE6: (lat * 1e6).round(),
    lngE6: (lng * 1e6).round(),
    observedAt: now,
    expiresAt: now.add(ttl),
    sourceDeviceId: 'test-device',
  );
  final nonce = P2pAlertPacket.randomNonce();
  final packetId = await P2pAlertPacket.computePacketId(
    type: P2pAlertPacketType.diseaseAlert,
    createdAt: now,
    nonce: nonce,
    payload: payload.toMap(),
  );
  return P2pAlertPacket(
    version: 1,
    type: P2pAlertPacketType.diseaseAlert,
    ttlHops: 10,
    createdAt: now,
    nonce: nonce,
    packetId: packetId,
    payload: payload.toMap(),
  );
}

void main() {
  late AppDatabase db;
  late P2pPacketStore store;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    store = P2pPacketStore(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('P2pPacketStore', () {
    test('insertIfNew returns true for a new packet, false for a duplicate', () async {
      final packet = await buildPacket(cropId: 'potato', label: 'Potato___Late_blight', lat: 28.6, lng: 77.2);
      expect(await store.insertIfNew(packet, verified: true), isTrue);
      expect(await store.insertIfNew(packet, verified: true), isFalse);
    });

    test('a duplicate packet received from a different peer is still a no-op insert', () async {
      final packet = await buildPacket(cropId: 'potato', label: 'Potato___Late_blight', lat: 28.6, lng: 77.2);
      expect(await store.insertIfNew(packet, receivedFromPeerId: 'peerA', verified: true), isTrue);
      expect(await store.insertIfNew(packet, receivedFromPeerId: 'peerB', verified: true), isFalse);
    });

    test('unexpired excludes packets past their TTL', () async {
      final fresh = await buildPacket(cropId: 'potato', label: 'A', lat: 1, lng: 1, ttl: const Duration(hours: 1));
      final expired = await buildPacket(
        cropId: 'potato',
        label: 'B',
        lat: 1,
        lng: 1,
        observedAt: DateTime.now().toUtc().subtract(const Duration(days: 10)),
        ttl: const Duration(hours: 1), // expired 10 days - 1h ago
      );
      await store.insertIfNew(fresh, verified: true);
      await store.insertIfNew(expired, verified: true);

      final unexpired = await store.unexpired();
      expect(unexpired.map((p) => p.packetIdHex), contains(fresh.packetIdHex));
      expect(unexpired.map((p) => p.packetIdHex), isNot(contains(expired.packetIdHex)));
    });

    test('sweepExpired deletes only expired packets and reports the count', () async {
      final fresh = await buildPacket(cropId: 'potato', label: 'A', lat: 1, lng: 1, ttl: const Duration(hours: 1));
      final expired = await buildPacket(
        cropId: 'potato',
        label: 'B',
        lat: 1,
        lng: 1,
        observedAt: DateTime.now().toUtc().subtract(const Duration(days: 10)),
        ttl: const Duration(hours: 1),
      );
      await store.insertIfNew(fresh, verified: true);
      await store.insertIfNew(expired, verified: true);

      final deletedCount = await store.sweepExpired();
      expect(deletedCount, 1);
      final remaining = await store.allUnexpiredRows();
      expect(remaining.map((r) => r.packetId), [fresh.packetIdHex]);
    });

    test('hasForwardedTo / markForwardedTo round-trip per peer', () async {
      final packet = await buildPacket(cropId: 'potato', label: 'A', lat: 1, lng: 1);
      await store.insertIfNew(packet, verified: true);

      expect(await store.hasForwardedTo(packet.packetIdHex, 'peerA'), isFalse);
      await store.markForwardedTo(packet.packetIdHex, 'peerA');
      expect(await store.hasForwardedTo(packet.packetIdHex, 'peerA'), isTrue);
      expect(await store.hasForwardedTo(packet.packetIdHex, 'peerB'), isFalse);
    });

    test('unsyncedToBackend / markSyncedToBackend round-trip', () async {
      final packet = await buildPacket(cropId: 'potato', label: 'A', lat: 1, lng: 1);
      await store.insertIfNew(packet, verified: true);

      expect((await store.unsyncedToBackend()).map((r) => r.packetId), contains(packet.packetIdHex));
      await store.markSyncedToBackend(packet.packetIdHex);
      expect((await store.unsyncedToBackend()).map((r) => r.packetId), isNot(contains(packet.packetIdHex)));
    });
  });

  group('LocalAggregator', () {
    test('clusters >= minClusterSize same-crop/label/cell packets into one event', () async {
      // All within the same ~0.05deg grid cell.
      final p1 = await buildPacket(cropId: 'potato', label: 'Potato___Late_blight', lat: 28.61, lng: 77.21);
      final p2 = await buildPacket(cropId: 'potato', label: 'Potato___Late_blight', lat: 28.615, lng: 77.215);
      await store.insertIfNew(p1, verified: true);
      await store.insertIfNew(p2, verified: true);

      final aggregator = LocalAggregator(store, db);
      await aggregator.recompute();

      final alerts = await db.select(db.p2pAggregatedAlerts).get();
      expect(alerts, hasLength(1));
      expect(alerts.single.detectionCount, 2);
      expect(alerts.single.cropId, 'potato');
      expect(alerts.single.label, 'Potato___Late_blight');
    });

    test('a single report below minClusterSize produces no aggregated alert', () async {
      final p1 = await buildPacket(cropId: 'potato', label: 'Potato___Late_blight', lat: 28.61, lng: 77.21);
      await store.insertIfNew(p1, verified: true);

      final aggregator = LocalAggregator(store, db);
      await aggregator.recompute();

      expect(await db.select(db.p2pAggregatedAlerts).get(), isEmpty);
    });

    test('different crops at the same location do not merge into one cluster', () async {
      final potato1 = await buildPacket(cropId: 'potato', label: 'Potato___Late_blight', lat: 28.61, lng: 77.21);
      final potato2 = await buildPacket(cropId: 'potato', label: 'Potato___Late_blight', lat: 28.611, lng: 77.211);
      final cotton1 = await buildPacket(cropId: 'cotton', label: 'Healthy', lat: 28.61, lng: 77.21);
      final cotton2 = await buildPacket(cropId: 'cotton', label: 'Healthy', lat: 28.611, lng: 77.211);
      for (final p in [potato1, potato2, cotton1, cotton2]) {
        await store.insertIfNew(p, verified: true);
      }

      final aggregator = LocalAggregator(store, db);
      await aggregator.recompute();

      final alerts = await db.select(db.p2pAggregatedAlerts).get();
      expect(alerts, hasLength(2));
      expect(alerts.map((a) => a.cropId).toSet(), {'potato', 'cotton'});
    });

    test('far-apart reports of the same crop/label do not merge', () async {
      final delhi1 = await buildPacket(cropId: 'potato', label: 'Potato___Late_blight', lat: 28.61, lng: 77.21);
      final delhi2 = await buildPacket(cropId: 'potato', label: 'Potato___Late_blight', lat: 28.611, lng: 77.211);
      final mumbai1 = await buildPacket(cropId: 'potato', label: 'Potato___Late_blight', lat: 19.07, lng: 72.87);
      await store.insertIfNew(delhi1, verified: true);
      await store.insertIfNew(delhi2, verified: true);
      await store.insertIfNew(mumbai1, verified: true);

      final aggregator = LocalAggregator(store, db);
      await aggregator.recompute();

      final alerts = await db.select(db.p2pAggregatedAlerts).get();
      // Delhi cluster (2 points) forms an alert; the lone Mumbai point doesn't.
      expect(alerts, hasLength(1));
      expect(alerts.single.detectionCount, 2);
    });

    test('recompute replaces previous results rather than accumulating', () async {
      final p1 = await buildPacket(cropId: 'potato', label: 'Potato___Late_blight', lat: 28.61, lng: 77.21);
      final p2 = await buildPacket(cropId: 'potato', label: 'Potato___Late_blight', lat: 28.611, lng: 77.211);
      await store.insertIfNew(p1, verified: true);
      await store.insertIfNew(p2, verified: true);

      final aggregator = LocalAggregator(store, db);
      await aggregator.recompute();
      await aggregator.recompute();
      await aggregator.recompute();

      expect(await db.select(db.p2pAggregatedAlerts).get(), hasLength(1));
    });
  });
}
