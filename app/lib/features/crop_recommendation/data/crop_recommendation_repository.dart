import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../domain/crop_suggestion.dart';

/// Read-only: SoilReportRepository owns writing into CropRecommendations
/// (it caches whatever the backend returns from the combined
/// POST /api/soil-reports call). This just watches that cache for whichever
/// soil report is currently "latest".
class CropRecommendationRepository {
  CropRecommendationRepository(this._db);

  final AppDatabase _db;

  Stream<List<CropSuggestion>> watchForSoilReport(String soilReportId) {
    return (_db.select(_db.cropRecommendations)
          ..where((t) => t.soilReportId.equals(soilReportId))
          ..orderBy([(t) => OrderingTerm.asc(t.rankPosition)]))
        .watch()
        .map((rows) => rows.map(_toSuggestion).toList());
  }

  CropSuggestion _toSuggestion(CropRecommendation row) => CropSuggestion(
        cropName: row.cropName,
        rank: row.rankPosition,
        suitabilityScore: row.suitabilityScore,
        nutrientAdvice: (jsonDecode(row.nutrientAdviceJson) as List).cast<String>(),
        cachedAt: row.cachedAt,
      );
}

final cropRecommendationRepositoryProvider = Provider<CropRecommendationRepository>((ref) {
  return CropRecommendationRepository(ref.watch(appDatabaseProvider));
});

final cropSuggestionsProvider =
    StreamProvider.autoDispose.family<List<CropSuggestion>, String>((ref, soilReportId) {
  return ref.watch(cropRecommendationRepositoryProvider).watchForSoilReport(soilReportId);
});
