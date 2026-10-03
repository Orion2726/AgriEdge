import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'price_forecast_model_manager.dart';

class DayForecast {
  const DayForecast({required this.price, required this.lowerBound, required this.upperBound});

  /// Point forecast. Ties the naive "same as today" baseline on held-out
  /// data (see manifest.json's note) — a plausible central estimate, not a
  /// confident prediction. [lowerBound]/[upperBound] (from real historical
  /// volatility, not the model) are the more trustworthy part of this.
  final double price;
  final double lowerBound;
  final double upperBound;
}

class _Loaded {
  _Loaded({required this.interpreter, required this.commodityOrder, required this.bands, required this.version});
  final Interpreter interpreter;
  final List<String> commodityOrder;
  final Map<String, List<VolatilityBand>> bands;
  final String version;
}

/// On-device 7-day price forecast, anchored to today's cached price (no
/// local price history needed — see docs/MODEL_SPECS.md section 3 for why).
class PriceForecastMlService {
  PriceForecastMlService(this._modelManager);

  final PriceForecastModelManager _modelManager;
  _Loaded? _cache;

  Future<_Loaded?> _ensureLoaded() async {
    final active = await _modelManager.resolveActiveModel();
    if (!active.isUsable) {
      _cache?.interpreter.close();
      _cache = null;
      return null;
    }
    final cached = _cache;
    if (cached != null && cached.version == active.version) return cached;
    cached?.interpreter.close();
    final loaded = _Loaded(
      interpreter: Interpreter.fromFile(active.file!),
      commodityOrder: active.commodityOrder!,
      bands: active.volatilityBands ?? {},
      version: active.version,
    );
    _cache = loaded;
    return loaded;
  }

  /// Returns null if the commodity isn't one the model was trained on, or
  /// no model/history is resolvable at all.
  Future<List<DayForecast>?> forecast({
    required String commodity,
    required double todayPrice,
    required DateTime asOf,
  }) async {
    final loaded = await _ensureLoaded();
    if (loaded == null) return null;
    final commodityIdx = loaded.commodityOrder.indexOf(commodity);
    if (commodityIdx == -1) return null;

    final monthAngle = 2 * pi * asOf.month / 12;
    final input = [
      List.generate(loaded.commodityOrder.length, (i) => i == commodityIdx ? 1.0 : 0.0) +
          [sin(monthAngle), cos(monthAngle), todayPrice],
    ];
    final output = [List.filled(7, 0.0)];
    loaded.interpreter.run(input, output);

    final bands = loaded.bands[commodity];
    return List.generate(7, (i) {
      final band = bands != null && i < bands.length ? bands[i] : null;
      return DayForecast(
        price: output[0][i],
        lowerBound: band != null ? todayPrice * band.p10 : output[0][i],
        upperBound: band != null ? todayPrice * band.p90 : output[0][i],
      );
    });
  }
}

final priceForecastMlServiceProvider = Provider<PriceForecastMlService>((ref) {
  return PriceForecastMlService(ref.watch(priceForecastModelManagerProvider));
});
