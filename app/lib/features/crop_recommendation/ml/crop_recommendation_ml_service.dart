import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tflite_flutter/tflite_flutter.dart';

import 'crop_recommendation_model_manager.dart';

class ScoredCrop {
  const ScoredCrop({required this.cropName, required this.suitabilityScore});
  final String cropName;
  final double suitabilityScore;
}

class CropRecommendationResult {
  const CropRecommendationResult({required this.suggestions, required this.nutrientAdvice});
  final List<ScoredCrop> suggestions;
  final List<String> nutrientAdvice;
}

class _Loaded {
  _Loaded({required this.interpreter, required this.labels, required this.version});
  final Interpreter interpreter;
  final List<String> labels;
  final String version;
}

/// On-device crop recommendation. The trained model's Normalization layer
/// is baked into the graph, so this feeds raw (unnormalized) feature values
/// straight from the soil report — see docs/MODEL_SPECS.md and
/// assets/ml/crop_recommendation/manifest.json for the exact contract.
///
/// Falls back to a rule-based nearest-ideal-range scorer (ported from the
/// backend's original placeholder, backend/src/ml_bridge/crop_recommendation/predict.js)
/// if no trained model can be resolved, so the feature never hard-fails.
class CropRecommendationMlService {
  CropRecommendationMlService(this._modelManager);

  final CropRecommendationModelManager _modelManager;
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
      labels: active.labels!,
      version: active.version,
    );
    _cache = loaded;
    return loaded;
  }

  Future<CropRecommendationResult> predict({
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double ph,
    required double organicCarbon,
    required double rainfallMm,
    required double temperatureC,
    required double humidityPct,
  }) async {
    final nutrientAdvice = _buildNutrientAdvice(
      nitrogen: nitrogen,
      phosphorus: phosphorus,
      potassium: potassium,
      ph: ph,
      organicCarbon: organicCarbon,
    );

    final loaded = await _ensureLoaded();
    if (loaded == null) {
      return CropRecommendationResult(
        suggestions: _fallbackPredict(
          nitrogen: nitrogen,
          phosphorus: phosphorus,
          potassium: potassium,
          ph: ph,
        ),
        nutrientAdvice: nutrientAdvice,
      );
    }

    // Order fixed by training — see FEATURE_ORDER in the training notebook
    // and inputFeatureOrder in manifest.json: [N, P, K, temperature, humidity, ph, rainfall].
    final input = [
      [nitrogen, phosphorus, potassium, temperatureC, humidityPct, ph, rainfallMm],
    ];
    final output = [List.filled(loaded.labels.length, 0.0)];
    loaded.interpreter.run(input, output);

    final scores = output[0];
    final ranked = List.generate(
      loaded.labels.length,
      (i) => ScoredCrop(cropName: loaded.labels[i], suitabilityScore: scores[i]),
    )..sort((a, b) => b.suitabilityScore.compareTo(a.suitabilityScore));

    return CropRecommendationResult(
      suggestions: ranked.take(5).toList(),
      nutrientAdvice: nutrientAdvice,
    );
  }

  List<String> _buildNutrientAdvice({
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double ph,
    required double organicCarbon,
  }) {
    final advice = <String>[];
    if (nitrogen < 80) advice.add('Nitrogen looks low — consider applying urea (~50kg/acre).');
    if (phosphorus < 40) advice.add('Phosphorus looks low — consider applying DAP (~40kg/acre).');
    if (potassium < 40) advice.add('Potassium looks low — consider applying MOP (~30kg/acre).');
    if (ph < 5.5) advice.add('Soil is acidic — consider liming to raise pH.');
    if (ph > 8) advice.add('Soil is alkaline — consider gypsum application.');
    if (organicCarbon < 0.5) {
      advice.add('Organic carbon is low — add farmyard manure or compost.');
    }
    if (advice.isEmpty) advice.add('Soil nutrient levels look balanced for most crops.');
    return advice;
  }

  static const _fallbackProfiles = [
    (name: 'Rice', n: (80.0, 120.0), p: (40.0, 60.0), k: (40.0, 60.0), ph: (5.5, 7.0)),
    (name: 'Wheat', n: (100.0, 140.0), p: (50.0, 70.0), k: (40.0, 60.0), ph: (6.0, 7.5)),
    (name: 'Maize', n: (100.0, 140.0), p: (50.0, 70.0), k: (40.0, 60.0), ph: (5.5, 7.5)),
    (name: 'Cotton', n: (80.0, 120.0), p: (40.0, 60.0), k: (40.0, 60.0), ph: (6.0, 8.0)),
    (name: 'Mustard', n: (60.0, 100.0), p: (30.0, 50.0), k: (30.0, 50.0), ph: (6.0, 7.5)),
    (name: 'Potato', n: (100.0, 150.0), p: (60.0, 90.0), k: (100.0, 150.0), ph: (5.0, 6.5)),
    (name: 'Tomato', n: (100.0, 150.0), p: (60.0, 90.0), k: (100.0, 150.0), ph: (6.0, 7.0)),
    (name: 'Soybean', n: (20.0, 40.0), p: (40.0, 60.0), k: (40.0, 60.0), ph: (6.0, 7.5)),
  ];

  double _scoreRange(double value, (double, double) range) {
    final (min, max) = range;
    if (value >= min && value <= max) return 1;
    final span = (max - min) == 0 ? 1 : (max - min);
    final distance = value < min ? min - value : value - max;
    return (1 - distance / span).clamp(0.0, 1.0);
  }

  List<ScoredCrop> _fallbackPredict({
    required double nitrogen,
    required double phosphorus,
    required double potassium,
    required double ph,
  }) {
    final scored = _fallbackProfiles
        .map((crop) => ScoredCrop(
              cropName: crop.name,
              suitabilityScore: (_scoreRange(nitrogen, crop.n) +
                      _scoreRange(phosphorus, crop.p) +
                      _scoreRange(potassium, crop.k) +
                      _scoreRange(ph, crop.ph)) /
                  4,
            ))
        .toList()
      ..sort((a, b) => b.suitabilityScore.compareTo(a.suitabilityScore));
    return scored.take(5).toList();
  }
}

final cropRecommendationMlServiceProvider = Provider<CropRecommendationMlService>((ref) {
  return CropRecommendationMlService(ref.watch(cropRecommendationModelManagerProvider));
});
