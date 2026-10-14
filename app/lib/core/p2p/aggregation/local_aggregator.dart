import 'package:cryptography/cryptography.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/app_database.dart';
import '../../db/db_provider.dart';
import '../store/p2p_packet_store.dart';

/// Ports the exact grid-cell clustering from backend/src/routes/alerts.js
/// to run locally against this device's P2pPackets cache — see
/// docs/P2P_ALERT_PROTOCOL.md §6. Buckets by (cropId, label, cell) rather
/// than alerts.js's (label, cell) alone, since a P2P mesh can carry labels
/// from crop models that don't all use crop-prefixed label strings (e.g.
/// cotton's "Healthy" vs rice's "normal") — cropId disambiguates regardless
/// of each model's label convention.
class LocalAggregator {
  LocalAggregator(this._store, this._db);

  final P2pPacketStore _store;
  final AppDatabase _db;

  static const gridDegrees = 0.05; // ~5.5km per cell, same as alerts.js
  static const minClusterSize = 2;
  static const displayRadiusKm = 25.0; // informational only, matches DiseaseAlertsRepository

  /// Recomputes all local clusters from scratch and replaces
  /// P2pAggregatedAlerts with the result. Cheap enough to call on every
  /// packet receive and on a periodic timer — this device's packet cache is
  /// small (TTL-bounded, see P2pPacketStore.sweepExpired).
  Future<void> recompute() async {
    final rows = await _store.allUnexpiredRows();

    final buckets = <String, List<P2pPacket>>{};
    for (final row in rows) {
      final cellLat = (row.lat / gridDegrees).round();
      final cellLng = (row.lng / gridDegrees).round();
      final key = '${row.cropId}|${row.label}|$cellLat|$cellLng';
      buckets.putIfAbsent(key, () => []).add(row);
    }

    final companions = <P2pAggregatedAlertsCompanion>[];
    for (final entry in buckets.entries) {
      final points = entry.value;
      if (points.length < minClusterSize) continue;

      final parts = entry.key.split('|');
      final cropId = parts[0];
      final label = parts[1];
      final centroidLat = points.map((p) => p.lat).reduce((a, b) => a + b) / points.length;
      final centroidLng = points.map((p) => p.lng).reduce((a, b) => a + b) / points.length;
      final earliest = points.map((p) => p.observedAt).reduce((a, b) => a.isBefore(b) ? a : b);
      final groupId = await _hashKey(entry.key);

      await _store.setAggregationGroup(points.map((p) => p.packetId).toList(), groupId);

      companions.add(P2pAggregatedAlertsCompanion.insert(
        id: groupId,
        label: label,
        cropId: cropId,
        lat: centroidLat,
        lng: centroidLng,
        detectionCount: points.length,
        radiusKm: displayRadiusKm,
        windowStart: earliest,
        fetchedAt: DateTime.now(),
      ));
    }

    await _db.batch((b) {
      b.deleteAll(_db.p2pAggregatedAlerts);
      b.insertAll(_db.p2pAggregatedAlerts, companions);
    });
  }

  Future<String> _hashKey(String key) async {
    final digest = await Sha256().hash(key.codeUnits);
    return digest.bytes
        .take(8)
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
  }
}

final localAggregatorProvider = Provider<LocalAggregator>((ref) {
  return LocalAggregator(ref.watch(p2pPacketStoreProvider), ref.watch(appDatabaseProvider));
});
