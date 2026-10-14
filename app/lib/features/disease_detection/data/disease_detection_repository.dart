import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/offline_repository.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/sync/sync_manager.dart';
import '../domain/disease_detection_entry.dart';

class DiseaseDetectionRepository implements OfflineRepository<DiseaseDetectionEntry> {
  DiseaseDetectionRepository(this._db, this._dio);

  final AppDatabase _db;
  final Dio _dio;
  final _uuid = const Uuid();

  @override
  Stream<List<DiseaseDetectionEntry>> watchAll() {
    return (_db.select(_db.diseaseDetections)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(_toEntry).toList());
  }

  /// Persists the detection locally and appends it to the outbound sync
  /// queue — it must survive being offline, so this never talks to the
  /// network directly. geotag/image are only attached if [consentShared].
  Future<DiseaseDetectionEntry> recordDetection({
    required String cropId,
    required String label,
    required double confidence,
    required bool isMock,
    String? imagePath,
    double? lat,
    double? lng,
    required bool consentShared,
  }) async {
    final id = _uuid.v4();
    final createdAt = DateTime.now();
    await _db.into(_db.diseaseDetections).insert(
          DiseaseDetectionsCompanion.insert(
            id: id,
            cropId: Value(cropId),
            label: label,
            confidence: confidence,
            isMock: Value(isMock),
            imagePath: Value(consentShared ? imagePath : null),
            lat: Value(consentShared ? lat : null),
            lng: Value(consentShared ? lng : null),
            consentShared: Value(consentShared),
            createdAt: createdAt,
          ),
        );
    await _db.into(_db.syncQueueItems).insert(
          SyncQueueItemsCompanion.insert(
            type: 'detection',
            refId: id,
            createdAt: createdAt,
          ),
        );
    return DiseaseDetectionEntry(
      id: id,
      cropId: cropId,
      label: label,
      confidence: confidence,
      isMock: isMock,
      imagePath: consentShared ? imagePath : null,
      lat: consentShared ? lat : null,
      lng: consentShared ? lng : null,
      consentShared: consentShared,
      createdAt: createdAt,
      syncStatus: 'pending',
    );
  }

  /// Drains queued detection events to the backend. Registered as this
  /// domain's SyncManager job — safe to call repeatedly, already-synced
  /// items are skipped.
  @override
  Future<void> refresh() async {
    final pending = await (_db.select(_db.syncQueueItems)
          ..where((t) => t.type.equals('detection') & t.status.equals('pending')))
        .get();

    Object? firstError;
    var failed = 0;
    for (final item in pending) {
      final detection = await (_db.select(_db.diseaseDetections)
            ..where((t) => t.id.equals(item.refId)))
          .getSingleOrNull();
      if (detection == null) continue;
      try {
        await _dio.post('/api/detections', data: {
          'id': detection.id,
          'cropId': detection.cropId,
          'label': detection.label,
          'confidence': detection.confidence,
          'lat': detection.lat,
          'lng': detection.lng,
          'consentShared': detection.consentShared,
          'createdAt': detection.createdAt.toIso8601String(),
        });
        await (_db.update(_db.syncQueueItems)..where((t) => t.id.equals(item.id)))
            .write(const SyncQueueItemsCompanion(status: Value('synced')));
        await (_db.update(_db.diseaseDetections)..where((t) => t.id.equals(detection.id)))
            .write(const DiseaseDetectionsCompanion(syncStatus: Value('synced')));
      } catch (e) {
        failed++;
        firstError ??= e;
        await (_db.update(_db.syncQueueItems)..where((t) => t.id.equals(item.id))).write(
          SyncQueueItemsCompanion(attempts: Value(item.attempts + 1)),
        );
      }
    }
    if (firstError != null) {
      throw SyncIncompleteException('$failed of ${pending.length} detections', firstError);
    }
  }

  DiseaseDetectionEntry _toEntry(DiseaseDetection row) => DiseaseDetectionEntry(
        id: row.id,
        cropId: row.cropId,
        label: row.label,
        confidence: row.confidence,
        imagePath: row.imagePath,
        lat: row.lat,
        lng: row.lng,
        consentShared: row.consentShared,
        isMock: row.isMock,
        createdAt: row.createdAt,
        syncStatus: row.syncStatus,
      );
}

final diseaseDetectionRepositoryProvider = Provider<DiseaseDetectionRepository>((ref) {
  return DiseaseDetectionRepository(ref.watch(appDatabaseProvider), ref.watch(apiClientProvider));
});

final diseaseDetectionsProvider = StreamProvider<List<DiseaseDetectionEntry>>((ref) {
  return ref.watch(diseaseDetectionRepositoryProvider).watchAll();
});
