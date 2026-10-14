import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../network/api_client.dart';
import '../../sync/sync_manager.dart';
import '../packet/p2p_packet.dart';
import '../store/p2p_packet_store.dart';

/// Opportunistic gateway synchronization — docs/P2P_ALERT_PROTOCOL.md §7.
/// Registered as a normal SyncManager job (see sync_registration.dart), same
/// pattern as every other domain: upload what's accumulated locally when
/// online, leave it marked unsynced to retry later on failure. This is the
/// one piece of the disclosure's architecture with no OEPB equivalent to
/// borrow from — OEPB has no concept of a backend at all (see
/// docs/P2P_ALERT_PROTOCOL.md's closing comparison).
class P2pGatewaySync {
  P2pGatewaySync(this._store, this._dio);

  final P2pPacketStore _store;
  final Dio _dio;

  /// Throws after attempting every row if any upload failed, so the
  /// SyncManager doesn't report this domain as synced when it wasn't.
  Future<void> refresh() async {
    final unsynced = await _store.unsyncedToBackend();
    Object? firstError;
    var failed = 0;
    for (final row in unsynced) {
      try {
        final payload = DiseaseAlertPayload.fromMap(P2pPacketStore.decodeRow(row).payload);
        await _dio.post('/api/p2p-events', data: {
          'packetId': row.packetId,
          'cropId': row.cropId,
          'label': row.label,
          'confidence': row.confidence,
          'severity': row.severity,
          'lat': row.lat,
          'lng': row.lng,
          'observedAt': row.observedAt.toUtc().toIso8601String(),
          'expiresAt': row.expiresAt.toUtc().toIso8601String(),
          'sourceDeviceId': row.sourceDeviceId,
          'detectionId': payload.detectionId,
          'verified': row.verified,
        });
        await _store.markSyncedToBackend(row.packetId);
      } catch (e) {
        // Stays unsynced — retried on the next sync pass.
        failed++;
        firstError ??= e;
      }
    }
    if (firstError != null) {
      throw SyncIncompleteException('$failed of ${unsynced.length} nearby-device alerts', firstError);
    }
  }
}

final p2pGatewaySyncProvider = Provider<P2pGatewaySync>((ref) {
  return P2pGatewaySync(ref.watch(p2pPacketStoreProvider), ref.watch(apiClientProvider));
});
