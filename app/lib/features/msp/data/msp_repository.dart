import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/offline_repository.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/network/api_client.dart';
import '../domain/msp_rate.dart';

class MspRepository implements OfflineRepository<MspRateEntry> {
  MspRepository(this._db, this._dio);

  final AppDatabase _db;
  final Dio _dio;

  @override
  Stream<List<MspRateEntry>> watchAll() {
    return _db.select(_db.mspRates).watch().map(
          (rows) => rows.map(_toEntry).toList()..sort((a, b) => a.crop.compareTo(b.crop)),
        );
  }

  @override
  Future<void> refresh() async {
    final res = await _dio.get('/api/msp');
    final rows = (res.data as List).cast<Map<String, dynamic>>();
    await _db.batch((b) {
      b.deleteAll(_db.mspRates);
      b.insertAll(
        _db.mspRates,
        rows.map(
          (r) => MspRatesCompanion.insert(
            crop: r['crop'] as String,
            season: r['season'] as String,
            year: r['year'] as int,
            pricePerQuintal: (r['pricePerQuintal'] as num).toDouble(),
            fetchedAt: DateTime.now(),
          ),
        ),
      );
    });
    await _db.markSynced('msp');
  }

  MspRateEntry _toEntry(MspRate row) => MspRateEntry(
        crop: row.crop,
        season: row.season,
        year: row.year,
        pricePerQuintal: row.pricePerQuintal,
        fetchedAt: row.fetchedAt,
      );
}

final mspRepositoryProvider = Provider<MspRepository>((ref) {
  return MspRepository(ref.watch(appDatabaseProvider), ref.watch(apiClientProvider));
});

final mspRatesProvider = StreamProvider<List<MspRateEntry>>((ref) {
  return ref.watch(mspRepositoryProvider).watchAll();
});

final mspLastSyncedProvider = FutureProvider<DateTime?>((ref) {
  return ref.watch(appDatabaseProvider).lastSyncedAt('msp');
});
