import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/offline_repository.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/network/api_client.dart';
import '../domain/market_price_entry.dart';

class MarketPriceRepository implements OfflineRepository<MarketPriceEntry> {
  MarketPriceRepository(this._db, this._dio);

  final AppDatabase _db;
  final Dio _dio;

  @override
  Stream<List<MarketPriceEntry>> watchAll() {
    return _db.select(_db.marketPrices).watch().map(
          (rows) => rows.map(_toEntry).toList()
            ..sort((a, b) => a.commodity.compareTo(b.commodity)),
        );
  }

  @override
  Future<void> refresh() async {
    final res = await _dio.get('/api/prices');
    final rows = (res.data as List).cast<Map<String, dynamic>>();
    await _db.batch((b) {
      b.deleteAll(_db.marketPrices);
      b.insertAll(
        _db.marketPrices,
        rows.map(
          (r) => MarketPricesCompanion.insert(
            commodity: r['commodity'] as String,
            mandi: r['mandi'] as String,
            pricePerQuintal: (r['pricePerQuintal'] as num).toDouble(),
            priceDate: DateTime.parse(r['priceDate'] as String),
            fetchedAt: DateTime.now(),
          ),
        ),
      );
    });
    await _db.markSynced('market_price');
  }

  MarketPriceEntry _toEntry(MarketPrice row) => MarketPriceEntry(
        commodity: row.commodity,
        mandi: row.mandi,
        pricePerQuintal: row.pricePerQuintal,
        priceDate: row.priceDate,
        fetchedAt: row.fetchedAt,
      );
}

final marketPriceRepositoryProvider = Provider<MarketPriceRepository>((ref) {
  return MarketPriceRepository(ref.watch(appDatabaseProvider), ref.watch(apiClientProvider));
});

final marketPricesProvider = StreamProvider<List<MarketPriceEntry>>((ref) {
  return ref.watch(marketPriceRepositoryProvider).watchAll();
});

final marketPriceLastSyncedProvider = FutureProvider<DateTime?>((ref) {
  return ref.watch(appDatabaseProvider).lastSyncedAt('market_price');
});
