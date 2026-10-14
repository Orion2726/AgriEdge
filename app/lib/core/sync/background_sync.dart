import 'dart:io';

import 'package:dio/dio.dart';
import 'package:workmanager/workmanager.dart';

import '../constants/app_constants.dart';
import '../db/app_database.dart';

const String backgroundSyncTaskName = 'agriedge.periodic_sync';

/// Background isolates get no Riverpod container and no widget tree, so this
/// talks to Dio/Drift directly instead of going through the app's normal
/// repository layer. It only refreshes the read-mostly, no-auth domains
/// (prices, MSP, disease alerts) — orders and detection uploads are queued
/// writes that the foreground SyncManager drains on next app open, since
/// they need the app's in-memory queue state.
@pragma('vm:entry-point')
void backgroundSyncCallbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    if (task != backgroundSyncTaskName) return true;
    final db = AppDatabase();
    final dio = Dio(BaseOptions(baseUrl: AppConstants.backendBaseUrl));
    try {
      await _refreshPrices(db, dio);
      await _refreshMsp(db, dio);
      return true;
    } catch (_) {
      return false; // let workmanager retry with backoff
    } finally {
      await db.close();
    }
  });
}

Future<void> _refreshPrices(AppDatabase db, Dio dio) async {
  final res = await dio.get('/api/prices');
  final rows = (res.data as List).cast<Map<String, dynamic>>();
  await db.batch((b) {
    b.deleteAll(db.marketPrices);
    b.insertAll(
      db.marketPrices,
      rows.map((r) => MarketPricesCompanion.insert(
            commodity: r['commodity'] as String,
            mandi: r['mandi'] as String,
            pricePerQuintal: (r['pricePerQuintal'] as num).toDouble(),
            priceDate: DateTime.parse(r['priceDate'] as String),
            fetchedAt: DateTime.now(),
          )),
    );
  });
  await db.markSynced('market_price');
}

Future<void> _refreshMsp(AppDatabase db, Dio dio) async {
  final res = await dio.get('/api/msp');
  final rows = (res.data as List).cast<Map<String, dynamic>>();
  await db.batch((b) {
    b.deleteAll(db.mspRates);
    b.insertAll(
      db.mspRates,
      rows.map((r) => MspRatesCompanion.insert(
            crop: r['crop'] as String,
            season: r['season'] as String,
            year: r['year'] as int,
            pricePerQuintal: (r['pricePerQuintal'] as num).toDouble(),
            fetchedAt: DateTime.now(),
          )),
    );
  });
  await db.markSynced('msp');
}

/// workmanager's periodic tasks are backed by Android's native WorkManager,
/// which has no iOS equivalent — the iOS plugin side only implements
/// one-off BGTaskScheduler requests, and registering a periodic task there
/// throws a PlatformException ("Unhandled method registerPeriodicTask").
/// Wiring true iOS background refresh needs its own BGTaskScheduler
/// identifier (Info.plist + AppDelegate) which isn't set up here; until
/// then, iOS relies on the foreground auto-sync-on-launch (see
/// sync_registration.dart) plus the manual "sync now" button.
Future<void> initBackgroundSync() async {
  if (!Platform.isAndroid) return;
  await Workmanager().initialize(backgroundSyncCallbackDispatcher);
  await Workmanager().registerPeriodicTask(
    backgroundSyncTaskName,
    backgroundSyncTaskName,
    frequency: AppConstants.syncInterval,
    constraints: Constraints(networkType: NetworkType.connected),
    existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
    backoffPolicy: BackoffPolicy.exponential,
    backoffPolicyDelay: const Duration(minutes: 1),
  );
}
