import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/data/offline_repository.dart';
import '../../../core/db/app_database.dart';
import '../../../core/db/db_provider.dart';
import '../../../core/network/api_client.dart';
import '../../../core/settings/farm_setup.dart';
import '../domain/nearby_alert.dart';

/// Backed by the backend's spatial clustering of crowdsourced disease
/// detections (see backend/src/routes/alerts.js). Radius is fixed here for
/// simplicity — a settings screen could expose it later.
class DiseaseAlertsRepository implements OfflineRepository<NearbyAlert> {
  DiseaseAlertsRepository(this._db, this._dio);

  final AppDatabase _db;
  final Dio _dio;
  static const double defaultRadiusKm = 25;

  @override
  Stream<List<NearbyAlert>> watchAll() {
    return _db.select(_db.diseaseAlerts).watch().map(
          (rows) => rows
              .map((r) => NearbyAlert(
                    id: r.id,
                    label: r.label,
                    lat: r.lat,
                    lng: r.lng,
                    detectionCount: r.detectionCount,
                    radiusKm: r.radiusKm,
                    windowStart: r.windowStart,
                    fetchedAt: r.fetchedAt,
                  ))
              .toList()
            ..sort((a, b) => b.detectionCount.compareTo(a.detectionCount)),
        );
  }

  /// Asks for location permission — only from a screen the farmer opened
  /// (the alerts screen), never from background/startup sync.
  Future<void> requestLocationPermission() async {
    try {
      if (await Geolocator.checkPermission() == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
    } catch (_) {
      // Platform without location support — refresh() reports it.
    }
  }

  @override
  Future<void> refresh() async {
    // "Nearby" needs a real position. This used to fall back silently to a
    // fixed Delhi coordinate, showing Delhi's outbreaks as "near you"
    // wherever the phone actually was.
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
      throw const LocationUnavailableException('Location permission is needed to find alerts near you.');
    }
    if (!await Geolocator.isLocationServiceEnabled()) {
      throw const LocationUnavailableException('Turn on location to find alerts near you.');
    }
    final Position position;
    try {
      position = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
            locationSettings: const LocationSettings(timeLimit: Duration(seconds: 15)),
          );
    } catch (_) {
      throw const LocationUnavailableException('Could not get a location fix yet. Try again outdoors.');
    }
    final lat = position.latitude;
    final lng = position.longitude;

    final res = await _dio.get('/api/alerts/nearby', queryParameters: {
      'lat': lat,
      'lng': lng,
      'radiusKm': defaultRadiusKm,
    });
    final rows = (res.data as List).cast<Map<String, dynamic>>();
    await _db.batch((b) {
      b.deleteAll(_db.diseaseAlerts);
      b.insertAll(
        _db.diseaseAlerts,
        rows.map(
          (r) => DiseaseAlertsCompanion.insert(
            id: r['id'] as String,
            label: r['label'] as String,
            lat: (r['lat'] as num).toDouble(),
            lng: (r['lng'] as num).toDouble(),
            detectionCount: r['detectionCount'] as int,
            radiusKm: (r['radiusKm'] as num).toDouble(),
            windowStart: DateTime.parse(r['windowStart'] as String),
            fetchedAt: DateTime.now(),
          ),
        ),
      );
    });
    await _db.markSynced('disease_alerts');
  }
}

class LocationUnavailableException implements Exception {
  const LocationUnavailableException(this.message);
  final String message;

  @override
  String toString() => message;
}

final diseaseAlertsRepositoryProvider = Provider<DiseaseAlertsRepository>((ref) {
  return DiseaseAlertsRepository(ref.watch(appDatabaseProvider), ref.watch(apiClientProvider));
});

final nearbyAlertsProvider = StreamProvider<List<NearbyAlert>>((ref) {
  return ref.watch(diseaseAlertsRepositoryProvider).watchAll();
});

/// Locally-fused alerts from this device's own P2P packet cache — see
/// docs/P2P_ALERT_PROTOCOL.md §6. Independent of nearbyAlertsProvider (and
/// never wiped by it) since P2pAggregatedAlerts is its own table, not
/// comingled with the backend-mirrored DiseaseAlerts table — see the
/// P2pAggregatedAlerts class doc in app_database.dart for why.
final p2pAlertsProvider = StreamProvider<List<NearbyAlert>>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return db.select(db.p2pAggregatedAlerts).watch().map(
        (rows) => rows
            .map((r) => NearbyAlert(
                  id: r.id,
                  label: r.label,
                  lat: r.lat,
                  lng: r.lng,
                  detectionCount: r.detectionCount,
                  radiusKm: r.radiusKm,
                  windowStart: r.windowStart,
                  fetchedAt: r.fetchedAt,
                  source: NearbyAlertSource.p2pNearby,
                ))
            .toList(),
      );
});

/// An outbreak the central server knows about anywhere — including regions
/// far beyond Bluetooth range.
class RegionalOutbreak {
  const RegionalOutbreak({
    required this.label,
    required this.cropId,
    required this.region,
    required this.reportCount,
    required this.latestAt,
    required this.distanceKm,
  });
  final String label;
  final String? cropId;
  final String region;
  final int reportCount;
  final DateTime latestAt;
  final int? distanceKm;

  static RegionalOutbreak fromJson(Map<String, dynamic> j) => RegionalOutbreak(
        label: j['label'] as String,
        cropId: j['cropId'] as String?,
        region: j['region'] as String,
        reportCount: j['reportCount'] as int,
        latestAt: DateTime.parse(j['latestAt'] as String),
        distanceKm: j['distanceKm'] as int?,
      );
}

class RegionalOutbreaks {
  const RegionalOutbreaks(this.items, this.fetchedAt, {required this.fromCache});
  final List<RegionalOutbreak> items;
  final DateTime fetchedAt;
  final bool fromCache;
}

/// Server-only feature: needs the AgriEdge server once; the last result is
/// kept on the phone so it still shows offline.
final regionalOutbreaksProvider = FutureProvider<RegionalOutbreaks?>((ref) async {
  const key = 'regional_outbreaks_v1';
  final prefs = await SharedPreferences.getInstance();
  final loc = ref.watch(farmSetupProvider.select((s) => s.location));
  try {
    final dio = ref.watch(apiClientProvider);
    final res = await dio.get('/api/alerts/regions', queryParameters: {
      if (loc != null) 'lat': loc.lat,
      if (loc != null) 'lng': loc.lng,
    });
    await prefs.setString(key, jsonEncode({'at': DateTime.now().toIso8601String(), 'items': res.data}));
    return RegionalOutbreaks(
      [for (final j in (res.data as List).cast<Map<String, dynamic>>()) RegionalOutbreak.fromJson(j)],
      DateTime.now(),
      fromCache: false,
    );
  } catch (_) {
    final saved = prefs.getString(key);
    if (saved == null) return null;
    final m = jsonDecode(saved) as Map<String, dynamic>;
    return RegionalOutbreaks(
      [for (final j in (m['items'] as List).cast<Map<String, dynamic>>()) RegionalOutbreak.fromJson(j)],
      DateTime.parse(m['at'] as String),
      fromCache: true,
    );
  }
});
