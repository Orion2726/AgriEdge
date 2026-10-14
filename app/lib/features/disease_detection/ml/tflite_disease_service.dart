import 'dart:io';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/ml/model_manager.dart';

class DiseasePrediction {
  const DiseasePrediction({
    required this.label,
    required this.confidence,
    required this.isMock,
    this.runnerUpLabel,
    this.runnerUpConfidence,
  });
  final String label;
  final double confidence;
  final bool isMock;

  /// Second most likely class — shown when the model isn't sure.
  final String? runnerUpLabel;
  final double? runnerUpConfidence;

  /// Below this the app says "not sure" instead of presenting a diagnosis.
  static const confidentAbove = 0.6;
  bool get isConfident => confidence >= confidentAbove;
}

class _LoadedCropModel {
  _LoadedCropModel({
    required this.interpreter,
    required this.labels,
    required this.inputNormalization,
    required this.version,
  });

  final Interpreter interpreter;
  final List<String> labels;
  final String inputNormalization;
  final String version;
}

/// Wraps tflite_flutter so the rest of the app never has to know whether a
/// real trained model is present for a given crop. If ModelManager can't
/// resolve a usable .tflite for that crop (still a placeholder build),
/// predict() falls back to a labeled mock result instead of crashing or
/// blocking the feature. Each crop's model can have been trained with a
/// different preprocessing convention (see ActiveModel.inputNormalization),
/// so preprocessing is resolved per-crop, not globally.
class TFLiteDiseaseService {
  TFLiteDiseaseService(this._modelManager);

  final ModelManager _modelManager;
  final Map<String, _LoadedCropModel> _cache = {};

  Future<_LoadedCropModel?> _ensureLoaded(String cropId) async {
    final active = await _modelManager.resolveActiveModel(cropId);
    if (!active.isUsable) {
      _cache.remove(cropId)?.interpreter.close();
      return null;
    }
    final cached = _cache[cropId];
    if (cached != null && cached.version == active.version) return cached;
    cached?.interpreter.close();
    final loaded = _LoadedCropModel(
      interpreter: Interpreter.fromFile(active.file!),
      labels: active.labels!,
      inputNormalization: active.inputNormalization ?? '[-1,1]',
      version: active.version,
    );
    _cache[cropId] = loaded;
    return loaded;
  }

  Future<DiseasePrediction> predict(String cropId, File imageFile) async {
    final loaded = await _ensureLoaded(cropId);
    if (loaded == null) {
      return _mockPredict(cropId);
    }

    final input = await _preprocess(imageFile, loaded.inputNormalization);
    final output = [List.filled(loaded.labels.length, 0.0)];
    loaded.interpreter.run(input, output);

    final scores = output[0];
    final order = List.generate(scores.length, (i) => i)..sort((a, b) => scores[b].compareTo(scores[a]));
    final best = order.first;
    final second = order.length > 1 ? order[1] : null;
    return DiseasePrediction(
      label: loaded.labels[best],
      confidence: scores[best],
      isMock: false,
      runnerUpLabel: second == null ? null : loaded.labels[second],
      runnerUpConfidence: second == null ? null : scores[second],
    );
  }

  /// Resize to the model's expected input, then normalize according to
  /// that crop's manifest: '[-1,1]' pre-normalizes pixels here (e.g. the
  /// potato MobileNetV2 model, which expects already-scaled input); models
  /// with normalization baked into the graph want the raw [0,255] pixel
  /// values instead (e.g. the MobileNetV3 crop models, which rescale
  /// internally — pre-normalizing those would double-scale and break
  /// inference).
  Future<List<List<List<List<double>>>>> _preprocess(File file, String inputNormalization) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('Could not decode captured image');
    }
    final size = AppConstants.diseaseModelInputSize;
    final resized = img.copyResize(decoded, width: size, height: size);
    final normalize = inputNormalization == 'raw_0_255'
        ? (num v) => v.toDouble()
        : (num v) => (v / 127.5) - 1.0;

    return [
      List.generate(
        size,
        (y) => List.generate(size, (x) {
          final pixel = resized.getPixel(x, y);
          return [normalize(pixel.r), normalize(pixel.g), normalize(pixel.b)];
        }),
      ),
    ];
  }

  static const _mockLabelsByCrop = {
    'potato': ['Potato___Early_blight', 'Potato___Late_blight', 'Potato___Healthy'],
    'cotton': ['Aphids', 'Bacterial Blight', 'Healthy'],
    'rice': ['blast', 'brown_spot', 'normal'],
    'wheat': ['Brown Rust', 'Healthy', 'Septoria'],
    'staple_crops': ['Corn___Common_Rust', 'Rice___Brown_Spot', 'Wheat___Healthy'],
  };

  DiseasePrediction _mockPredict(String cropId) {
    final rand = Random();
    final labels = _mockLabelsByCrop[cropId] ?? const ['Unknown'];
    final label = labels[rand.nextInt(labels.length)];
    final confidence = 0.55 + rand.nextDouble() * 0.4;
    return DiseasePrediction(label: label, confidence: confidence, isMock: true);
  }
}

final tfliteDiseaseServiceProvider = Provider<TFLiteDiseaseService>((ref) {
  return TFLiteDiseaseService(ref.watch(modelManagerProvider));
});
