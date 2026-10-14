import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/offline_repository.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/sync/sync_manager.dart';
import '../../crop_recommendation/ml/crop_recommendation_ml_service.dart';
import '../domain/soil_report_entry.dart';

/// Owns both the soil-report submit flow and the crop-recommendation cache.
/// Recommendations are computed on-device (CropRecommendationMlService) the
/// moment a report is submitted, so they're available immediately — even
/// offline. The backend POST (see refresh()) is fire-and-forget, purely for
/// server-side record-keeping; its response is no longer used to populate
/// recommendations, since the on-device model is the source of truth.
class SoilReportRepository implements OfflineRepository<SoilReportEntry> {
  SoilReportRepository(this._db, this._dio, this._mlService);

  final AppDatabase _db;
  final Dio _dio;
  final CropRecommendationMlService _mlService;
  final _uuid = const Uuid();

  @override
  Stream<List<SoilReportEntry>> watchAll() {
    return (_db.select(_db.soilReports)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch()
        .map((rows) => rows.map(_toEntry).toList());
  }

  Stream<SoilReportEntry?> watchLatest() {
    return (_db.select(_db.soilReports)
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(1))
        .watchSingleOrNull()
        .map((row) => row == null ? null : _toEntry(row));
  }

  Future<String> submitReport({
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double ph,
    required double organicCarbon,
    required double rainfallMm,
    required double temperatureC,
    required double humidityPct,
  }) async {
    final id = _uuid.v4();
    final createdAt = DateTime.now();
    await _db.into(_db.soilReports).insert(
          SoilReportsCompanion.insert(
            id: id,
            nitrogen: nitrogen,
            phosphorus: phosphorus,
            potassium: potassium,
            ph: ph,
            organicCarbon: organicCarbon,
            rainfallMm: Value(rainfallMm),
            temperatureC: Value(temperatureC),
            humidityPct: Value(humidityPct),
            createdAt: createdAt,
          ),
        );

    final result = await _mlService.predict(
      nitrogen: nitrogen,
      phosphorus: phosphorus,
      potassium: potassium,
      ph: ph,
      organicCarbon: organicCarbon,
      rainfallMm: rainfallMm,
      temperatureC: temperatureC,
      humidityPct: humidityPct,
    );
    await _cacheRecommendations(id, result);

    return id;
  }

  Future<void> _submitToBackend(String soilReportId) async {
    final report = await (_db.select(_db.soilReports)..where((t) => t.id.equals(soilReportId)))
        .getSingle();
    await _dio.post('/api/soil-reports', data: {
        'id': report.id,
        'nitrogen': report.nitrogen,
        'phosphorus': report.phosphorus,
        'potassium': report.potassium,
        'ph': report.ph,
        'organicCarbon': report.organicCarbon,
        'rainfallMm': report.rainfallMm,
        'temperatureC': report.temperatureC,
        'humidityPct': report.humidityPct,
      });
      await (_db.update(_db.soilReports)..where((t) => t.id.equals(soilReportId)))
          .write(const SoilReportsCompanion(syncStatus: Value('synced')));
  }

  Future<void> _cacheRecommendations(String soilReportId, CropRecommendationResult result) async {
    await _db.batch((b) {
      b.deleteWhere(_db.cropRecommendations, (t) => t.soilReportId.equals(soilReportId));
      b.insertAll(
        _db.cropRecommendations,
        result.suggestions.asMap().entries.map((e) {
          final index = e.key;
          final item = e.value;
          return CropRecommendationsCompanion.insert(
            soilReportId: soilReportId,
            cropName: item.cropName,
            rankPosition: index + 1,
            suitabilityScore: item.suitabilityScore,
            nutrientAdviceJson: Value(index == 0 ? jsonEncode(result.nutrientAdvice) : '[]'),
            cachedAt: DateTime.now(),
          );
        }),
      );
    });
  }

  @override
  Future<void> refresh() async {
    final pending = await (_db.select(_db.soilReports)..where((t) => t.syncStatus.equals('pending')))
        .get();
    Object? firstError;
    var failed = 0;
    for (final report in pending) {
      try {
        await _submitToBackend(report.id);
      } catch (e) {
        // Stays 'pending' — retried on the next soil_report sync.
        failed++;
        firstError ??= e;
      }
    }
    if (firstError != null) {
      throw SyncIncompleteException('$failed of ${pending.length} soil reports', firstError);
    }
  }

  SoilReportEntry _toEntry(SoilReport row) => SoilReportEntry(
        id: row.id,
        nitrogen: row.nitrogen,
        phosphorus: row.phosphorus,
        potassium: row.potassium,
        ph: row.ph,
        organicCarbon: row.organicCarbon,
        rainfallMm: row.rainfallMm,
        temperatureC: row.temperatureC,
        humidityPct: row.humidityPct,
        createdAt: row.createdAt,
        syncStatus: row.syncStatus,
      );
}

final soilReportRepositoryProvider = Provider<SoilReportRepository>((ref) {
  return SoilReportRepository(
    ref.watch(appDatabaseProvider),
    ref.watch(apiClientProvider),
    ref.watch(cropRecommendationMlServiceProvider),
  );
});

final soilReportsProvider = StreamProvider<List<SoilReportEntry>>((ref) {
  return ref.watch(soilReportRepositoryProvider).watchAll();
});

final latestSoilReportProvider = StreamProvider<SoilReportEntry?>((ref) {
  return ref.watch(soilReportRepositoryProvider).watchLatest();
});
