import 'dart:io';
import 'dart:math';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/ml/model_manager.dart';

class DiseasePrediction {
  const DiseasePrediction({required this.label, required this.confidence, required this.isMock});
  final String label;
  final double confidence;
  final bool isMock;
}

/// Wraps tflite_flutter so the rest of the app never has to know whether a
/// real trained model is present. If ModelManager can't resolve a usable
/// .tflite (still a placeholder build), predict() falls back to a labeled
/// mock result instead of crashing or blocking the feature — this is what
/// keeps disease prediction demoable end-to-end before any model is trained.
class TFLiteDiseaseService {
  TFLiteDiseaseService(this._modelManager);

  final ModelManager _modelManager;
  Interpreter? _interpreter;
  List<String>? _labels;
  ModelSource? _loadedSource;

  Future<void> _ensureLoaded() async {
    final active = await _modelManager.resolveActiveModel();
    if (!active.isUsable) {
      _interpreter?.close();
      _interpreter = null;
      _labels = null;
      _loadedSource = null;
      return;
    }
    if (_loadedSource == active.source && _interpreter != null) return;
    _interpreter?.close();
    _interpreter = Interpreter.fromFile(active.file!);
    _labels = await _loadLabels();
    _loadedSource = active.source;
  }

  Future<List<String>> _loadLabels() async {
    final raw = await rootBundle.loadString(AppConstants.diseaseLabelsAssetPath);
    return raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();
  }

  Future<DiseasePrediction> predict(File imageFile) async {
    await _ensureLoaded();
    final interpreter = _interpreter;
    final labels = _labels;
    if (interpreter == null || labels == null) {
      return _mockPredict();
    }

    final input = await _preprocess(imageFile);
    final output = [List.filled(labels.length, 0.0)];
    interpreter.run(input, output);

    final scores = output[0];
    var bestIndex = 0;
    for (var i = 1; i < scores.length; i++) {
      if (scores[i] > scores[bestIndex]) bestIndex = i;
    }
    return DiseasePrediction(label: labels[bestIndex], confidence: scores[bestIndex], isMock: false);
  }

  /// Resize + normalize to [-1, 1], matching the manifest's declared
  /// preprocessing. If a trained model expects different normalization,
  /// update this alongside assets/ml/disease/model_manifest.json.
  Future<List<List<List<List<double>>>>> _preprocess(File file) async {
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      throw const FormatException('Could not decode captured image');
    }
    final size = AppConstants.diseaseModelInputSize;
    final resized = img.copyResize(decoded, width: size, height: size);

    return [
      List.generate(
        size,
        (y) => List.generate(size, (x) {
          final pixel = resized.getPixel(x, y);
          return [
            (pixel.r / 127.5) - 1.0,
            (pixel.g / 127.5) - 1.0,
            (pixel.b / 127.5) - 1.0,
          ];
        }),
      ),
    ];
  }

  static const _mockLabels = [
    'Tomato___Early_blight',
    'Tomato___Healthy',
    'Potato___Late_blight',
    'Maize___Common_Rust',
    'Rice___Leaf_Blast',
    'Cotton___Bacterial_Blight',
  ];

  DiseasePrediction _mockPredict() {
    final rand = Random();
    final label = _mockLabels[rand.nextInt(_mockLabels.length)];
    final confidence = 0.55 + rand.nextDouble() * 0.4;
    return DiseasePrediction(label: label, confidence: confidence, isMock: true);
  }
}

final tfliteDiseaseServiceProvider = Provider<TFLiteDiseaseService>((ref) {
  return TFLiteDiseaseService(ref.watch(modelManagerProvider));
});
