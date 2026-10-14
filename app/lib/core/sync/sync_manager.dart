import 'dart:async';
import 'dart:developer' as dev;

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../db/app_database.dart';
import '../db/db_provider.dart';
import '../network/connectivity_service.dart';

typedef SyncJob = Future<void> Function();

/// Thrown by a sync job that processed its queue but couldn't upload every
/// item — the domain must not be reported as synced in that case.
class SyncIncompleteException implements Exception {
  SyncIncompleteException(this.what, this.cause);
  final String what;
  final Object cause;

  @override
  String toString() => 'Could not upload $what: ${describeSyncError(cause)}';
}

/// Human-readable reason for a failed sync, for the Sync & Data screen.
String describeSyncError(Object error) {
  if (error is SyncIncompleteException) return error.toString();
  if (error is DioException) {
    if (error.requestOptions.baseUrl.isEmpty) {
      return 'No AgriEdge server set — add one in More → Sync & server';
    }
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return 'Server unreachable (${error.requestOptions.uri.origin})';
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return 'Server timed out';
      case DioExceptionType.badResponse:
        return 'Server error ${error.response?.statusCode}';
      default:
        return error.message ?? error.type.name;
    }
  }
  return '$error';
}

class SyncDomainStatus {
  const SyncDomainStatus({
    required this.domain,
    required this.lastSyncedAt,
    required this.isSyncing,
    this.lastError,
    this.lastAttemptAt,
  });
  final String domain;
  final DateTime? lastSyncedAt;
  final bool isSyncing;

  /// Set when the most recent attempt failed; cleared by the next success.
  final String? lastError;
  final DateTime? lastAttemptAt;
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
  final Map<String, String> _lastErrors = {};
  final Map<String, DateTime> _lastAttempts = {};
  final _changes = StreamController<String>.broadcast();

  void register(String domain, SyncJob job) => _jobs[domain] = job;

  List<String> get domains => _jobs.keys.toList(growable: false);

  bool isSyncing(String domain) => _inFlight.contains(domain);

  /// Emits a domain name whenever that domain's status changes.
  Stream<String> get changes => _changes.stream;

  /// Returns true if the job completed; false if it failed (the reason is
  /// kept for [status]) or was already running.
  Future<bool> syncDomain(String domain) async {
    final job = _jobs[domain];
    if (job == null || _inFlight.contains(domain)) return false;
    _inFlight.add(domain);
    _changes.add(domain);
    try {
      await job();
      await _db.markSynced(domain);
      _lastErrors.remove(domain);
      return true;
    } catch (e, st) {
      // Previously markSynced ran regardless and "Last synced" claimed
      // success while the backend was unreachable.
      _lastErrors[domain] = describeSyncError(e);
      dev.log('Sync failed for $domain', error: e, stackTrace: st, name: 'SyncManager');
      return false;
    } finally {
      _lastAttempts[domain] = DateTime.now();
      _inFlight.remove(domain);
      _changes.add(domain);
    }
  }

  Future<void> syncAll() async {
    for (final domain in _jobs.keys) {
      await syncDomain(domain);
    }
  }

  Future<DateTime?> lastSyncedAt(String domain) => _db.lastSyncedAt(domain);

  Future<SyncDomainStatus> status(String domain) async => SyncDomainStatus(
        domain: domain,
        lastSyncedAt: await _db.lastSyncedAt(domain),
        isSyncing: _inFlight.contains(domain),
        lastError: _lastErrors[domain],
        lastAttemptAt: _lastAttempts[domain],
      );

  void dispose() => _changes.close();
}

final domainLastSyncedProvider = FutureProvider.family<DateTime?, String>((ref, domain) {
  return ref.watch(syncManagerProvider).lastSyncedAt(domain);
});

/// Re-evaluates whenever the domain's sync state changes.
final domainSyncStatusProvider = StreamProvider.family<SyncDomainStatus, String>((ref, domain) async* {
  final manager = ref.watch(syncManagerProvider);
  yield await manager.status(domain);
  await for (final changed in manager.changes) {
    if (changed == domain) yield await manager.status(domain);
  }
});

final syncManagerProvider = Provider<SyncManager>((ref) {
  final manager = SyncManager(ref.watch(appDatabaseProvider));
  ref.onDispose(manager.dispose);
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
