import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'api_client.dart';

/// Whether the AgriEdge server answers right now (not just "has internet").
/// Re-checked every 15 s while a screen is watching it.
final serverReachableProvider = FutureProvider.autoDispose<bool>((ref) async {
  final timer = Timer(const Duration(seconds: 15), ref.invalidateSelf);
  ref.onDispose(timer.cancel);
  final dio = ref.watch(apiClientProvider);
  if (dio.options.baseUrl.isEmpty) return false;
  try {
    await dio.get('/health', options: Options(receiveTimeout: const Duration(seconds: 4)));
    return true;
  } catch (_) {
    return false;
  }
});
