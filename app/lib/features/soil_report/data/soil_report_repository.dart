import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/data/offline_repository.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/network/api_client.dart';
import '../domain/soil_report_entry.dart';

/// Owns both the soil-report submit flow and caching the crop-recommendation
/// response that comes back from it (POST /api/soil-reports returns ranked
/// crops in one round trip — see backend/src/routes/soil.js). The
/// crop_recommendation feature only reads what's cached here.
class SoilReportRepository implements OfflineRepository<SoilReportEntry> {
  SoilReportRepository(this._db, this._dio);

  final AppDatabase _db;
  final Dio _dio;
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
    await _submitToBackend(id);
    return id;
  }

  Future<void> _submitToBackend(String soilReportId) async {
    final report = await (_db.select(_db.soilReports)..where((t) => t.id.equals(soilReportId)))
        .getSingle();
    try {
      final res = await _dio.post('/api/soil-reports', data: {
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
      await _cacheRecommendations(soilReportId, res.data['recommendations'] as List);
      await (_db.update(_db.soilReports)..where((t) => t.id.equals(soilReportId)))
          .write(const SoilReportsCompanion(syncStatus: Value('synced')));
    } catch (_) {
      // Stays 'pending' — refresh() (SyncManager's soil_report job) retries later.
    }
  }

  Future<void> _cacheRecommendations(String soilReportId, List raw) async {
    await _db.batch((b) {
      b.deleteWhere(_db.cropRecommendations, (t) => t.soilReportId.equals(soilReportId));
      b.insertAll(
        _db.cropRecommendations,
        raw.asMap().entries.map((e) {
          final index = e.key;
          final item = e.value as Map<String, dynamic>;
          return CropRecommendationsCompanion.insert(
            soilReportId: soilReportId,
            cropName: item['cropName'] as String,
            rankPosition: index + 1,
            suitabilityScore: (item['suitabilityScore'] as num).toDouble(),
            nutrientAdviceJson: Value(jsonEncode(item['nutrientAdvice'] ?? [])),
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
    for (final report in pending) {
      await _submitToBackend(report.id);
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
  return SoilReportRepository(ref.watch(appDatabaseProvider), ref.watch(apiClientProvider));
});

final soilReportsProvider = StreamProvider<List<SoilReportEntry>>((ref) {
  return ref.watch(soilReportRepositoryProvider).watchAll();
});

final latestSoilReportProvider = StreamProvider<SoilReportEntry?>((ref) {
  return ref.watch(soilReportRepositoryProvider).watchLatest();
});
