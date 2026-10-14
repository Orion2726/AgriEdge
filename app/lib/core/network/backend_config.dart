import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

/// Which AgriEdge backend this phone talks to. A phone can't reach the dev
/// machine's `localhost`, so the address is configurable: at build time via
/// `--dart-define=AGRIEDGE_BACKEND_URL=http://<lan-ip>:4001`, and at run time
/// from Sync & Data (persisted, and also read by the background-sync
/// isolate — see background_sync.dart).
class BackendUrlController extends Notifier<String> {
  static const prefsKey = 'backend_base_url';

  Completer<void> _loaded = Completer<void>();

  /// Completes once a persisted override (if any) has been applied.
  Future<void> get loaded => _loaded.future;

  @override
  String build() {
    _loaded = Completer<void>();
    unawaited(_load());
    return AppConstants.defaultBackendBaseUrl;
  }

  Future<void> _load() async {
    try {
      final persisted = await readPersistedBackendUrl();
      if (persisted != null) state = persisted;
    } finally {
      if (!_loaded.isCompleted) _loaded.complete();
    }
  }

  /// Validates, persists and applies [input]. Throws [FormatException] with a
  /// user-readable message if it isn't a usable http(s) server address.
  Future<void> set(String input) async {
    final url = normalizeBackendUrl(input);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(prefsKey, url);
    state = url;
  }

  Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(prefsKey);
    state = AppConstants.defaultBackendBaseUrl;
  }
}

/// The persisted override, or null if none (or prefs are unavailable, e.g.
/// under `flutter test`).
Future<String?> readPersistedBackendUrl() async {
  // (empty default = "not configured"; see AppConstants.defaultBackendBaseUrl)
  try {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(BackendUrlController.prefsKey);
    return (value == null || value.isEmpty) ? null : value;
  } catch (_) {
    return null;
  }
}

/// Accepts "192.168.1.5:4001", "http://host:4001/", etc. and returns a
/// canonical "scheme://host[:port]" base URL.
String normalizeBackendUrl(String input) {
  var text = input.trim();
  if (text.isEmpty) throw const FormatException('Enter the server address, e.g. http://192.168.1.5:4001');
  if (!text.contains('://')) text = 'http://$text';
  final uri = Uri.tryParse(text);
  if (uri == null || uri.host.isEmpty) {
    throw FormatException('"$input" is not a valid server address');
  }
  if (uri.scheme != 'http' && uri.scheme != 'https') {
    throw FormatException('Server address must start with http:// or https://');
  }
  if (uri.path.isNotEmpty && uri.path != '/' || uri.hasQuery || uri.hasFragment) {
    throw FormatException('Enter only the server address (no path), e.g. ${uri.scheme}://${uri.authority}');
  }
  return '${uri.scheme}://${uri.authority}';
}

final backendUrlProvider = NotifierProvider<BackendUrlController, String>(BackendUrlController.new);
