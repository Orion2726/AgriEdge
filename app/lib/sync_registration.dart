import 'dart:async';
import 'dart:io' show Platform;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/network/api_client.dart';
import 'core/network/backend_config.dart';
import 'core/network/connectivity_service.dart';
import 'core/p2p/p2p_alert_service.dart';
import 'core/p2p/sync/p2p_gateway_sync.dart';
import 'core/sync/sync_manager.dart';
import 'features/disease_alerts/data/disease_alerts_repository.dart';
import 'features/disease_detection/data/disease_detection_repository.dart';
import 'features/market_price/data/market_price_repository.dart';
import 'features/msp/data/msp_repository.dart';
import 'features/orders/data/orders_repository.dart';
import 'features/soil_report/data/soil_report_repository.dart';

/// App-level wiring: this is the one place allowed to import every feature,
/// so it registers each feature's refresh() as a SyncManager job without
/// core/ ever depending on features/ (see core/sync/sync_manager.dart).
/// Read once at startup (see main.dart) to force registration.
final syncRegistrationProvider = Provider<void>((ref) {
  final manager = ref.watch(syncManagerProvider);
  manager.register('market_price', () => ref.read(marketPriceRepositoryProvider).refresh());
  manager.register('msp', () => ref.read(mspRepositoryProvider).refresh());
  manager.register('soil_report', () => ref.read(soilReportRepositoryProvider).refresh());
  manager.register('disease_alerts', () => ref.read(diseaseAlertsRepositoryProvider).refresh());
  manager.register('detections', () => ref.read(diseaseDetectionRepositoryProvider).refresh());
  manager.register('orders', () => ref.read(ordersRepositoryProvider).refresh());
  manager.register('p2p_alerts', () => ref.read(p2pGatewaySyncProvider).refresh());
  manager.register('server_reports', () async {
    // Official reports from the server → into the mesh for offline phones.
    final res = await ref.read(apiClientProvider).get('/api/server-reports');
    final service = await ref.read(p2pAlertServiceFutureProvider.future);
    for (final r in (res.data as List).cast<Map<String, dynamic>>()) {
      await service.importServerReport(r);
    }
  });

  // Opportunistic first-launch sync so a fresh install isn't stuck showing
  // empty screens until the user finds the manual sync button. Each job
  // already swallows its own errors (see SyncManager.syncDomain), so this
  // is a no-op rather than a crash when offline. Skipped under `flutter
  // test` (which sets FLUTTER_TEST=true) — widget tests run inside a
  // fake-async zone that can't resolve real dio sockets/timers, so firing
  // this there leaves a real pending Timer and fails the test binding's
  // "no pending timers" invariant check.
  if (Platform.environment['FLUTTER_TEST'] != 'true') {
    Future.microtask(() async {
      // Wait for a persisted backend address so the first sync doesn't go
      // to the compiled-in default.
      await ref.read(backendUrlProvider.notifier).loaded;
      await manager.syncAll();
    });
    // Retry pending uploads while the app is open (failed ones stay queued).
    final timer = Timer.periodic(const Duration(minutes: 5), (_) => manager.syncAll());
    // Pick up official reports and price changes from the server quickly,
    // so they can be relayed to phones without internet.
    final fast = Timer.periodic(const Duration(seconds: 15), (_) async {
      if (!ref.read(connectivityServiceProvider).isOnline) return;
      for (final d in ['server_reports', 'market_price', 'msp', 'orders']) {
        await manager.syncDomain(d);
      }
      // Pass fresh server data on to nearby phones right away.
      (await ref.read(p2pAlertServiceFutureProvider.future)).shareNow();
    });
    ref.onDispose(() {
      timer.cancel();
      fast.cancel();
    });
  }
});
