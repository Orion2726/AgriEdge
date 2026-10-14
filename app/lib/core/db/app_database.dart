import 'package:drift/drift.dart';

import 'connection/connection.dart' as impl;

part 'app_database.g.dart';

// ---------------------------------------------------------------------------
// Tables. Every feature reads from here first; network is only used to
// refresh what's already on disk (see core/sync/sync_manager.dart).
// ---------------------------------------------------------------------------

class MarketPrices extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get commodity => text()();
  TextColumn get mandi => text()();
  RealColumn get pricePerQuintal => real()();
  DateTimeColumn get priceDate => dateTime()();
  DateTimeColumn get fetchedAt => dateTime()();
}

class MspRates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get crop => text()();
  TextColumn get season => text()();
  IntColumn get year => integer()();
  RealColumn get pricePerQuintal => real()();
  DateTimeColumn get fetchedAt => dateTime()();
}

class SoilReports extends Table {
  TextColumn get id => text()();
  RealColumn get nitrogen => real()();
  RealColumn get phosphorus => real()();
  RealColumn get potassium => real()();
  RealColumn get ph => real()();
  RealColumn get organicCarbon => real()();
  RealColumn get rainfallMm => real().withDefault(const Constant(0))();
  RealColumn get temperatureC => real().withDefault(const Constant(0))();
  RealColumn get humidityPct => real().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

class CropRecommendations extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get soilReportId => text()();
  TextColumn get cropName => text()();
  IntColumn get rankPosition => integer()();
  RealColumn get suitabilityScore => real()();
  TextColumn get nutrientAdviceJson => text().withDefault(const Constant('[]'))();
  DateTimeColumn get cachedAt => dateTime()();
}

class DiseaseDetections extends Table {
  TextColumn get id => text()();
  TextColumn get cropId => text().withDefault(const Constant('potato'))();
  TextColumn get label => text()();
  RealColumn get confidence => real()();
  TextColumn get imagePath => text().nullable()();
  RealColumn get lat => real().nullable()();
  RealColumn get lng => real().nullable()();
  BoolColumn get consentShared => boolean().withDefault(const Constant(false))();
  BoolColumn get isMock => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

class Products extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get category => text()();
  RealColumn get pricePerUnit => real()();
  TextColumn get unit => text()();
  TextColumn get imageUrl => text().nullable()();
  TextColumn get description => text().nullable()();

  @override
  Set<Column> get primaryKey => {id};
}

class Orders extends Table {
  TextColumn get id => text()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get status => text().withDefault(const Constant('placed'))();
  RealColumn get totalAmount => real()();
  TextColumn get syncStatus => text().withDefault(const Constant('pending'))();

  @override
  Set<Column> get primaryKey => {id};
}

class OrderItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get orderId => text()();
  TextColumn get productId => text()();
  TextColumn get productName => text()();
  IntColumn get quantity => integer()();
  RealColumn get unitPrice => real()();
}

class DiseaseAlerts extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  IntColumn get detectionCount => integer()();
  RealColumn get radiusKm => real()();
  DateTimeColumn get windowStart => dateTime()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Raw P2P disease-alert packets this device has originated, received, or
/// relayed — see docs/P2P_ALERT_PROTOCOL.md §5. Primary-keyed by the
/// deterministic packetId so receiving the same packet via two different
/// peers/transports is a no-op insert, not a duplicate.
class P2pPackets extends Table {
  TextColumn get packetId => text()();

  /// Full encoded wire packet (CBOR, signature intact) — needed to forward
  /// this packet on to another peer unchanged. The columns below are a
  /// flattened projection of its payload for querying (relevance filtering,
  /// aggregation) without decoding the blob on every read.
  BlobColumn get rawBytes => blob()();
  IntColumn get type => integer()();
  TextColumn get cropId => text()();
  TextColumn get label => text()();
  RealColumn get confidence => real()();
  TextColumn get severity => text()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  DateTimeColumn get observedAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime()();
  TextColumn get sourceDeviceId => text()();
  TextColumn get receivedFromPeerId => text().nullable()();
  TextColumn get forwardedToPeerIdsJson => text().withDefault(const Constant('[]'))();
  TextColumn get aggregationGroupId => text().nullable()();
  BoolColumn get verified => boolean().withDefault(const Constant(false))();
  BoolColumn get syncedToBackend => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {packetId};
}

/// Locally-fused regional events from P2pPackets — see §6. Same shape as
/// the backend-driven DiseaseAlerts table above (both ultimately render
/// through the same NearbyAlert domain class) but kept as its own table
/// rather than merged into DiseaseAlerts, since that table is wiped and
/// fully replaced on every backend sync (see DiseaseAlertsRepository.refresh)
/// — comingling would silently drop P2P-only events the backend doesn't
/// know about yet.
class P2pAggregatedAlerts extends Table {
  TextColumn get id => text()();
  TextColumn get label => text()();
  TextColumn get cropId => text()();
  RealColumn get lat => real()();
  RealColumn get lng => real()();
  IntColumn get detectionCount => integer()();
  RealColumn get radiusKm => real()();
  DateTimeColumn get windowStart => dateTime()();
  DateTimeColumn get fetchedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}

/// Outbound queue for anything that must survive being offline: orders and
/// disease-detection events. Appended, never overwritten — SyncManager drains
/// this and marks rows synced, matching the queued-append conflict strategy.
class SyncQueueItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get type => text()(); // 'order' | 'detection'
  TextColumn get refId => text()(); // id of the Order/DiseaseDetection row
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get attempts => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('pending'))(); // pending|syncing|synced|failed
}

/// Per-domain "last synced" bookkeeping, drives staleness indicators and the
/// manual per-service sync screen.
class SyncMeta extends Table {
  TextColumn get domain => text()();
  DateTimeColumn get lastSyncedAt => dateTime().nullable()();

  @override
  Set<Column> get primaryKey => {domain};
}

@DriftDatabase(tables: [
  MarketPrices,
  MspRates,
  SoilReports,
  CropRecommendations,
  DiseaseDetections,
  Products,
  Orders,
  OrderItems,
  DiseaseAlerts,
  P2pPackets,
  P2pAggregatedAlerts,
  SyncQueueItems,
  SyncMeta,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(impl.openConnection());

  /// For tests only — e.g. `AppDatabase.forTesting(NativeDatabase.memory())`.
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 3;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) => m.createAll(),
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.addColumn(diseaseDetections, diseaseDetections.cropId);
          }
          if (from < 3) {
            await m.createTable(p2pPackets);
            await m.createTable(p2pAggregatedAlerts);
          }
        },
      );

  Future<DateTime?> lastSyncedAt(String domain) async {
    final row = await (select(syncMeta)..where((t) => t.domain.equals(domain)))
        .getSingleOrNull();
    return row?.lastSyncedAt;
  }

  Future<void> markSynced(String domain, {DateTime? at}) {
    return into(syncMeta).insertOnConflictUpdate(
      SyncMetaCompanion.insert(
        domain: domain,
        lastSyncedAt: Value(at ?? DateTime.now()),
      ),
    );
  }
}
