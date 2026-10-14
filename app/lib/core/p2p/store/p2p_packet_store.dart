import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../db/app_database.dart';
import '../../db/db_provider.dart';
import '../packet/p2p_packet.dart';

/// Persistent store for received/originated P2P disease-alert packets —
/// see docs/P2P_ALERT_PROTOCOL.md §5. Dedup is keyed on packetId (two
/// peers relaying the same observation produce the same deterministic ID,
/// see P2pAlertPacket.computePacketId), so a duplicate receive is a cheap no-op
/// rather than a second row.
class P2pPacketStore {
  P2pPacketStore(this._db);

  final AppDatabase _db;

  /// Returns true if this was a new packet (false if already present —
  /// caller should not re-forward a duplicate).
  Future<bool> insertIfNew(
    P2pAlertPacket packet, {
    String? receivedFromPeerId,
    required bool verified,
  }) async {
    final packetIdHex = packet.packetIdHex;
    final existing = await (_db.select(_db.p2pPackets)
          ..where((t) => t.packetId.equals(packetIdHex)))
        .getSingleOrNull();
    if (existing != null) return false;

    final payload = DiseaseAlertPayload.fromMap(packet.payload);
    await _db.into(_db.p2pPackets).insert(
          P2pPacketsCompanion.insert(
            packetId: packetIdHex,
            rawBytes: packet.encode(),
            type: packet.type.wireValue,
            cropId: payload.cropId,
            label: payload.label,
            confidence: payload.confidence,
            severity: payload.severity,
            lat: payload.lat,
            lng: payload.lng,
            observedAt: payload.observedAt,
            expiresAt: payload.expiresAt,
            sourceDeviceId: payload.sourceDeviceId,
            receivedFromPeerId: Value(receivedFromPeerId),
            verified: Value(verified),
            createdAt: DateTime.now(),
          ),
        );
    return true;
  }

  /// Peers (see peerDeviceKey) this packet has been delivered to.
  List<String> forwardedTo(P2pPacket row) =>
      (jsonDecode(row.forwardedToPeerIdsJson) as List).cast<String>();

  static P2pAlertPacket decodeRow(P2pPacket row) =>
      P2pAlertPacket.decode(Uint8List.fromList(row.rawBytes));

  /// Newest first — both alerts this phone originated and ones received
  /// from nearby phones, for the alerts screen's per-report list.
  Stream<List<P2pPacket>> watchRecent({int limit = 50}) {
    return (_db.select(_db.p2pPackets)
          ..where((t) => t.expiresAt.isBiggerThanValue(DateTime.now()))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(limit))
        .watch();
  }

  Future<bool> hasForwardedTo(String packetId, String peerId) async {
    final row = await (_db.select(_db.p2pPackets)..where((t) => t.packetId.equals(packetId)))
        .getSingleOrNull();
    if (row == null) return false;
    final forwarded = (jsonDecode(row.forwardedToPeerIdsJson) as List).cast<String>();
    return forwarded.contains(peerId);
  }

  Future<void> markForwardedTo(String packetId, String peerId) async {
    final row = await (_db.select(_db.p2pPackets)..where((t) => t.packetId.equals(packetId)))
        .getSingleOrNull();
    if (row == null) return;
    final forwarded = (jsonDecode(row.forwardedToPeerIdsJson) as List).cast<String>();
    if (forwarded.contains(peerId)) return;
    forwarded.add(peerId);
    await (_db.update(_db.p2pPackets)..where((t) => t.packetId.equals(packetId)))
        .write(P2pPacketsCompanion(forwardedToPeerIdsJson: Value(jsonEncode(forwarded))));
  }

  Future<List<P2pAlertPacket>> unexpired() async {
    final now = DateTime.now();
    final rows =
        await (_db.select(_db.p2pPackets)..where((t) => t.expiresAt.isBiggerThanValue(now))).get();
    return rows.map((r) => P2pAlertPacket.decode(Uint8List.fromList(r.rawBytes))).toList();
  }

  /// Deletes packets past their TTL. Run periodically (see
  /// P2pAlertService) — same role as SyncManager's periodic jobs for other
  /// domains, just local-only (nothing to sync for a deletion).
  Future<int> sweepExpired() async {
    final now = DateTime.now();
    return (_db.delete(_db.p2pPackets)..where((t) => t.expiresAt.isSmallerThanValue(now))).go();
  }

  Future<List<P2pPacket>> unsyncedToBackend() async {
    return (_db.select(_db.p2pPackets)..where((t) => t.syncedToBackend.equals(false))).get();
  }

  Future<void> markSyncedToBackend(String packetId) async {
    await (_db.update(_db.p2pPackets)..where((t) => t.packetId.equals(packetId)))
        .write(const P2pPacketsCompanion(syncedToBackend: Value(true)));
  }

  Future<void> setAggregationGroup(List<String> packetIds, String groupId) async {
    await (_db.update(_db.p2pPackets)..where((t) => t.packetId.isIn(packetIds)))
        .write(P2pPacketsCompanion(aggregationGroupId: Value(groupId)));
  }

  Future<List<P2pPacket>> allUnexpiredRows() async {
    final now = DateTime.now();
    return (_db.select(_db.p2pPackets)..where((t) => t.expiresAt.isBiggerThanValue(now))).get();
  }
}

final p2pPacketStoreProvider = Provider<P2pPacketStore>((ref) {
  return P2pPacketStore(ref.watch(appDatabaseProvider));
});
