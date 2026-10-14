import 'dart:convert';
import 'dart:io' show gzip;

import 'package:drift/drift.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/live_feeds.dart';
import '../db/app_database.dart';
import '../p2p/relevance/relevance_engine.dart' show haversineKm;
import '../settings/farm_setup.dart';
import 'p2p_log.dart';

/// Kinds of everyday data phones pass to each other over Bluetooth, so a
/// phone that was offline still gets recent prices, MSP, weather and news
/// from a neighbour that synced. (Treatment guide, crop calendar and FAQ
/// are built into every copy of the app, so they are never sent.)
enum SnapshotKind { prices, msp, weather, news, regions, uploaded }

/// SharedPreferences key of the server's regional outbreak list (see
/// regionalOutbreaksProvider).
const regionalOutbreaksCacheKey = 'regional_outbreaks_v1';

class DataSnapshot {
  const DataSnapshot(this.kind, this.dataAt, this.data);
  final SnapshotKind kind;

  /// When the data was originally fetched from its source (not when it was
  /// relayed) — the receiver keeps whichever copy is newer.
  final DateTime dataAt;
  final Object? data;

  Map<String, Object?> toPayload(String sourceDeviceId) => {
        'kind': kind.name,
        'dataAt': dataAt.toUtc().millisecondsSinceEpoch,
        'z': gzip.encode(utf8.encode(jsonEncode(data))),
        'sourceDeviceId': sourceDeviceId,
      };

  static DataSnapshot fromPayload(Map<String, Object?> p) => DataSnapshot(
        SnapshotKind.values.byName(p['kind'] as String),
        DateTime.fromMillisecondsSinceEpoch(p['dataAt'] as int, isUtc: true),
        jsonDecode(utf8.decode(gzip.decode((p['z'] as List).cast<int>()))),
      );
}

/// Reads this phone's snapshots and applies received ones (newer-wins).
class SnapshotSync {
  SnapshotSync(this._db, this._farm);
  final AppDatabase _db;
  final FarmLocation? Function() _farm;

  static String _recvKey(SnapshotKind k) => 'snap_recv_${k.name}';

  Future<List<DataSnapshot>> current() async {
    final out = <DataSnapshot>[];
    final pricesAt = await _db.lastSyncedAt('market_price');
    final prices = await _db.select(_db.marketPrices).get();
    if (pricesAt != null && prices.isNotEmpty) {
      out.add(DataSnapshot(SnapshotKind.prices, pricesAt, [
        for (final p in prices)
          {'c': p.commodity, 'm': p.mandi, 'p': p.pricePerQuintal, 'd': p.priceDate.toIso8601String()}
      ]));
    }
    final mspAt = await _db.lastSyncedAt('msp');
    final msp = await _db.select(_db.mspRates).get();
    if (mspAt != null && msp.isNotEmpty) {
      out.add(DataSnapshot(SnapshotKind.msp, mspAt, [
        for (final m in msp) {'c': m.crop, 's': m.season, 'y': m.year, 'p': m.pricePerQuintal}
      ]));
    }
    final prefs = await SharedPreferences.getInstance();
    final farm = _farm();
    if (farm != null) {
      final w = prefs.getString(weatherCacheKey(farm.lat, farm.lng));
      if (w != null) {
        final m = jsonDecode(w) as Map<String, dynamic>;
        out.add(DataSnapshot(SnapshotKind.weather, DateTime.parse(m['at'] as String),
            {'lat': farm.lat, 'lng': farm.lng, 'raw': m['raw']}));
      }
    }
    final rg = prefs.getString(regionalOutbreaksCacheKey);
    if (rg != null) {
      final m = jsonDecode(rg) as Map<String, dynamic>;
      out.add(DataSnapshot(SnapshotKind.regions, DateTime.parse(m['at'] as String), m['items']));
    }
    // Which reports this phone has delivered to the server, so phones that
    // handed them over know they arrived. "Version" = how many there are
    // (only grows), so it's re-sent only when more get uploaded.
    final uploaded = await (_db.select(_db.p2pPackets)..where((t) => t.syncedToBackend.equals(true))).get();
    if (uploaded.isNotEmpty) {
      out.add(DataSnapshot(SnapshotKind.uploaded, DateTime.fromMillisecondsSinceEpoch(uploaded.length, isUtc: true),
          [for (final r in uploaded.take(300)) r.packetId]));
    }
    final n = prefs.getString(newsCacheKey);
    if (n != null) {
      final m = jsonDecode(n) as Map<String, dynamic>;
      out.add(DataSnapshot(SnapshotKind.news, DateTime.parse(m['at'] as String), m['raw']));
    }
    return out;
  }

  /// Returns true if applied, false if ignored because ours is as new or newer.
  Future<bool> apply(DataSnapshot s, {required String fromDevice}) async {
    final prefs = await SharedPreferences.getInstance();
    final via = 'nearby phone ${fromDevice.substring(0, 4)}-${fromDevice.substring(4, 8)}';
    bool newer(DateTime? mine) => mine == null || s.dataAt.isAfter(mine.toUtc());

    switch (s.kind) {
      case SnapshotKind.uploaded:
        final ids = (s.data as List).cast<String>();
        final changed = await (_db.update(_db.p2pPackets)
              ..where((t) => t.packetId.isIn(ids) & t.syncedToBackend.equals(false)))
            .write(const P2pPacketsCompanion(syncedToBackend: Value(true)));
        p2pLog('snapshot uploaded-list from=$fromDevice marked=$changed');
        return changed > 0;
      case SnapshotKind.prices:
        if (!newer(await _db.lastSyncedAt('market_price'))) return _ignored(s);
        await _db.batch((b) {
          b.deleteAll(_db.marketPrices);
          b.insertAll(_db.marketPrices, [
            for (final r in (s.data as List).cast<Map>())
              MarketPricesCompanion.insert(
                commodity: r['c'] as String,
                mandi: r['m'] as String,
                pricePerQuintal: (r['p'] as num).toDouble(),
                priceDate: DateTime.parse(r['d'] as String),
                fetchedAt: s.dataAt.toLocal(),
              )
          ]);
        });
        await _db.markSynced('market_price', at: s.dataAt.toLocal());
      case SnapshotKind.msp:
        if (!newer(await _db.lastSyncedAt('msp'))) return _ignored(s);
        await _db.batch((b) {
          b.deleteAll(_db.mspRates);
          b.insertAll(_db.mspRates, [
            for (final r in (s.data as List).cast<Map>())
              MspRatesCompanion.insert(
                crop: r['c'] as String,
                season: r['s'] as String,
                year: r['y'] as int,
                pricePerQuintal: (r['p'] as num).toDouble(),
                fetchedAt: s.dataAt.toLocal(),
              )
          ]);
        });
        await _db.markSynced('msp', at: s.dataAt.toLocal());
      case SnapshotKind.weather:
        final farm = _farm();
        final d = s.data as Map;
        // A forecast only helps if it is for roughly the same place.
        if (farm == null ||
            haversineKm(farm.lat, farm.lng, (d['lat'] as num).toDouble(), (d['lng'] as num).toDouble()) > 50) {
          return _ignored(s, 'different area');
        }
        final key = weatherCacheKey(farm.lat, farm.lng);
        if (!newer(_cachedAt(prefs, key))) return _ignored(s);
        await prefs.setString(key, jsonEncode({'at': s.dataAt.toIso8601String(), 'raw': d['raw'], 'via': via}));
      case SnapshotKind.regions:
        if (!newer(_cachedAt(prefs, regionalOutbreaksCacheKey))) return _ignored(s);
        await prefs.setString(regionalOutbreaksCacheKey,
            jsonEncode({'at': s.dataAt.toIso8601String(), 'items': s.data, 'via': via}));
      case SnapshotKind.news:
        if (!newer(_cachedAt(prefs, newsCacheKey))) return _ignored(s);
        await prefs.setString(newsCacheKey, jsonEncode({'at': s.dataAt.toIso8601String(), 'raw': s.data, 'via': via}));
    }
    await prefs.setString(_recvKey(s.kind), jsonEncode({'from': via, 'at': s.dataAt.toIso8601String()}));
    p2pLog('snapshot APPLY kind=${s.kind.name} dataAt=${s.dataAt.toIso8601String()} from=$fromDevice');
    return true;
  }

  bool _ignored(DataSnapshot s, [String why = 'ours is as new or newer']) {
    p2pLog('snapshot IGNORE kind=${s.kind.name} dataAt=${s.dataAt.toIso8601String()} ($why)');
    return false;
  }

  DateTime? _cachedAt(SharedPreferences prefs, String key) {
    final v = prefs.getString(key);
    return v == null ? null : DateTime.parse((jsonDecode(v) as Map)['at'] as String);
  }

  /// "Prices: received from nearby phone a88a-a81e (data from Oct 14 5:40 PM)".
  static Future<Map<SnapshotKind, ({String from, DateTime dataAt})>> received() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      for (final k in SnapshotKind.values)
        if (prefs.getString(_recvKey(k)) case final v?)
          k: (from: (jsonDecode(v) as Map)['from'] as String, dataAt: DateTime.parse((jsonDecode(v) as Map)['at'] as String)),
    };
  }
}

