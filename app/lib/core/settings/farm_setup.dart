import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FarmLocation {
  const FarmLocation({required this.lat, required this.lng, required this.label, required this.fromGps});
  final double lat;
  final double lng;
  final String label;
  final bool fromGps;
}

/// Places a farmer can pick when they'd rather not share GPS.
const presetLocations = <FarmLocation>[
  FarmLocation(lat: 12.84, lng: 80.15, label: 'Chengalpattu, Tamil Nadu', fromGps: false),
  FarmLocation(lat: 11.02, lng: 76.96, label: 'Coimbatore, Tamil Nadu', fromGps: false),
  FarmLocation(lat: 10.79, lng: 78.70, label: 'Tiruchirappalli, Tamil Nadu', fromGps: false),
  FarmLocation(lat: 13.08, lng: 80.27, label: 'Chennai, Tamil Nadu', fromGps: false),
  FarmLocation(lat: 12.97, lng: 77.59, label: 'Bengaluru, Karnataka', fromGps: false),
  FarmLocation(lat: 17.39, lng: 78.49, label: 'Hyderabad, Telangana', fromGps: false),
  FarmLocation(lat: 16.51, lng: 80.65, label: 'Vijayawada, Andhra Pradesh', fromGps: false),
  FarmLocation(lat: 19.08, lng: 72.88, label: 'Mumbai, Maharashtra', fromGps: false),
  FarmLocation(lat: 18.52, lng: 73.86, label: 'Pune, Maharashtra', fromGps: false),
  FarmLocation(lat: 22.72, lng: 75.86, label: 'Indore, Madhya Pradesh', fromGps: false),
  FarmLocation(lat: 30.90, lng: 75.85, label: 'Ludhiana, Punjab', fromGps: false),
  FarmLocation(lat: 29.69, lng: 76.99, label: 'Karnal, Haryana', fromGps: false),
  FarmLocation(lat: 28.61, lng: 77.21, label: 'New Delhi', fromGps: false),
  FarmLocation(lat: 26.85, lng: 80.95, label: 'Lucknow, Uttar Pradesh', fromGps: false),
  FarmLocation(lat: 25.59, lng: 85.14, label: 'Patna, Bihar', fromGps: false),
  FarmLocation(lat: 22.57, lng: 88.36, label: 'Kolkata, West Bengal', fromGps: false),
];

class FarmSetupState {
  const FarmSetupState({required this.loaded, required this.setupDone, this.location});
  final bool loaded;
  final bool setupDone;
  final FarmLocation? location;
}

/// First-run setup (location + crops) — skippable, editable later.
class FarmSetupController extends Notifier<FarmSetupState> {
  static const _done = 'setup_done', _lat = 'farm_lat', _lng = 'farm_lng', _label = 'farm_label', _gps = 'farm_gps';

  @override
  FarmSetupState build() {
    _load();
    return const FarmSetupState(loaded: false, setupDone: true);
  }

  Future<void> _load() async {
    try {
      final p = await SharedPreferences.getInstance();
      final lat = p.getDouble(_lat), lng = p.getDouble(_lng);
      state = FarmSetupState(
        loaded: true,
        setupDone: p.getBool(_done) ?? false,
        location: lat == null || lng == null
            ? null
            : FarmLocation(lat: lat, lng: lng, label: p.getString(_label) ?? 'My farm', fromGps: p.getBool(_gps) ?? false),
      );
    } catch (_) {
      state = const FarmSetupState(loaded: true, setupDone: true);
    }
  }

  Future<void> setLocation(FarmLocation l) async {
    final p = await SharedPreferences.getInstance();
    await p.setDouble(_lat, l.lat);
    await p.setDouble(_lng, l.lng);
    await p.setString(_label, l.label);
    await p.setBool(_gps, l.fromGps);
    state = FarmSetupState(loaded: true, setupDone: state.setupDone, location: l);
  }

  Future<void> finish() async {
    final p = await SharedPreferences.getInstance();
    await p.setBool(_done, true);
    state = FarmSetupState(loaded: true, setupDone: true, location: state.location);
  }

  /// Asks for permission and reads GPS. Returns null (with a reason) on failure.
  Future<String?> useGps() async {
    try {
      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) perm = await Geolocator.requestPermission();
      if (perm == LocationPermission.denied || perm == LocationPermission.deniedForever) {
        return 'Location permission was not given. Pick your area from the list instead.';
      }
      if (!await Geolocator.isLocationServiceEnabled()) {
        return 'Location is turned off. Turn it on, or pick your area from the list.';
      }
      final pos = await Geolocator.getLastKnownPosition() ??
          await Geolocator.getCurrentPosition(
              locationSettings: const LocationSettings(timeLimit: Duration(seconds: 15)));
      await setLocation(FarmLocation(lat: pos.latitude, lng: pos.longitude, label: 'Current location', fromGps: true));
      return null;
    } catch (_) {
      return 'Could not get your location. Pick your area from the list instead.';
    }
  }
}

final farmSetupProvider = NotifierProvider<FarmSetupController, FarmSetupState>(FarmSetupController.new);
