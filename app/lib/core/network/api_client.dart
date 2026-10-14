import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'backend_config.dart';

/// Single dio instance for the whole app. Repositories call this directly —
/// there is no separate "online mode" check here, that's ConnectivityService's
/// job; this client just knows how to reach the configured backend (rebuilt
/// when the address changes in Sync & Data).
final apiClientProvider = Provider<Dio>((ref) {
  return createApiClient(ref.watch(backendUrlProvider));
});

/// This phone's short P2P id, sent so the server's control panel can show
/// which phones are connected. Set once the device identity has loaded.
String? apiDeviceId;

Dio createApiClient(String baseUrl) => Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 5),
        receiveTimeout: const Duration(seconds: 8),
      ),
    )..interceptors.add(InterceptorsWrapper(onRequest: (options, handler) {
        final id = apiDeviceId;
        if (id != null) options.headers['X-AgriEdge-Device'] = id;
        handler.next(options);
      }));
