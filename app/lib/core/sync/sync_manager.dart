import 'dart:developer' as dev;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../db/db_provider.dart';
import '../network/connectivity_service.dart';

typedef SyncJob = Future<void> Function();

class SyncDomainStatus {
  const SyncDomainStatus({required this.domain, required this.lastSyncedAt, required this.isSyncing});
  final String domain;
  final DateTime? lastSyncedAt;
  final bool isSyncing;
}

/// Generic registry of per-domain sync jobs. Features register their own
/// refresh() function under a domain name (e.g. "market_price") at provider
/// wiring time — core never imports feature code, keeping the dependency
/// direction one-way. Drives both the opportunistic background sync
/// (core/sync/background_sync.dart) and the manual "sync now" screen.
class SyncManager {
  SyncManager(this._db);

  final AppDatabase _db;
  final Map<String, SyncJob> _jobs = {};
  final Set<String> _inFlight = {};

  void register(String domain, SyncJob job) => _jobs[domain] = job;

  List<String> get domains => _jobs.keys.toList(growable: false);

  bool isSyncing(String domain) => _inFlight.contains(domain);

  Future<void> syncDomain(String domain) async {
    final job = _jobs[domain];
    if (job == null || _inFlight.contains(domain)) return;
    _inFlight.add(domain);
    try {
      await job();
      await _db.markSynced(domain);
    } catch (e, st) {
      dev.log('Sync failed for $domain', error: e, stackTrace: st, name: 'SyncManager');
    } finally {
      _inFlight.remove(domain);
    }
  }

  Future<void> syncAll() async {
    for (final domain in _jobs.keys) {
      await syncDomain(domain);
    }
  }

  Future<DateTime?> lastSyncedAt(String domain) => _db.lastSyncedAt(domain);
}

final domainLastSyncedProvider = FutureProvider.family<DateTime?, String>((ref, domain) {
  return ref.watch(syncManagerProvider).lastSyncedAt(domain);
});

final syncManagerProvider = Provider<SyncManager>((ref) {
  final manager = SyncManager(ref.watch(appDatabaseProvider));
  // Opportunistic sync the moment connectivity comes back.
  ref.listen(isOnlineProvider, (previous, next) {
    final wasOffline = previous?.value == false;
    final nowOnline = next.value == true;
    if (wasOffline && nowOnline) {
      manager.syncAll();
    }
  });
  return manager;
});
