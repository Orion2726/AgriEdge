import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../network/api_client.dart';

enum ModelSource { downloaded, bundled, none }

class ActiveModel {
  const ActiveModel({
    required this.source,
    required this.version,
    this.file,
    this.labels,
    this.inputNormalization,
  });

  final ModelSource source;
  final String version;
  final File? file;
  final List<String>? labels;

  /// '[-1,1]' (app must pre-normalize pixels before inference) or
  /// 'raw_0_255' (model has rescaling baked into the graph — feed raw
  /// pixel values as float32). Read from the model's manifest so each
  /// crop's model can declare whichever convention it was trained with.
  final String? inputNormalization;

  bool get isUsable => source != ModelSource.none && file != null && labels != null;
}

/// Resolves which disease-detection model to use for a given crop, in
/// priority order:
/// 1. A model downloaded at runtime into app-documents (supports the
///    "models should be downloadable" requirement — updated models don't
///    need an app store release).
/// 2. The model bundled in assets/ml/disease/{cropId}/ at build time.
/// 3. Neither — caller falls back to a mocked prediction.
///
/// Trained models are dropped in at assets/ml/disease/{cropId}/model.tflite
/// (bundled) or served from the backend's /api/models/disease/{cropId}
/// (downloaded). See docs/MODEL_SPECS.md for the exact contract.
class ModelManager {
  ModelManager(this._dio);

  final Dio _dio;

  Future<Directory> _modelsDir(String cropId) async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'models', 'disease', cropId));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  Future<ActiveModel> resolveActiveModel(String cropId) async {
    final downloaded = await _downloadedModel(cropId);
    if (downloaded != null) return downloaded;
    return _bundledModel(cropId);
  }

  Future<ActiveModel?> _downloadedModel(String cropId) async {
    final dir = await _modelsDir(cropId);
    final modelFile = File(p.join(dir.path, 'model.tflite'));
    final manifestFile = File(p.join(dir.path, 'manifest.json'));
    final labelsFile = File(p.join(dir.path, 'labels.txt'));
    if (!modelFile.existsSync() || !manifestFile.existsSync() || !labelsFile.existsSync()) {
      return null;
    }
    try {
      final manifest = jsonDecode(await manifestFile.readAsString());
      final labels = await _parseLabels(labelsFile.readAsString());
      return ActiveModel(
        source: ModelSource.downloaded,
        version: manifest['version'] as String? ?? 'unknown',
        file: modelFile,
        labels: labels,
        inputNormalization: manifest['inputNormalization'] as String? ?? '[-1,1]',
      );
    } catch (_) {
      return null;
    }
  }

  Future<ActiveModel> _bundledModel(String cropId) async {
    try {
      final manifestRaw = await rootBundle.loadString('assets/ml/disease/$cropId/manifest.json');
      final manifest = jsonDecode(manifestRaw);
      if (manifest['isPlaceholder'] == true) {
        return ActiveModel(source: ModelSource.none, version: 'placeholder');
      }
      // Bundled asset exists and is a real model: copy the byte data out to
      // a temp file so the tflite interpreter (which needs a file path or
      // buffer) can load it uniformly with the downloaded-model path.
      final bytes = await rootBundle.load('assets/ml/disease/$cropId/model.tflite');
      final labelsRaw = await rootBundle.loadString('assets/ml/disease/$cropId/labels.txt');
      final docs = await getApplicationDocumentsDirectory();
      final tempFile = File(p.join(docs.path, 'models', 'disease', cropId, 'bundled.tflite'));
      tempFile.parent.createSync(recursive: true);
      await tempFile.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      return ActiveModel(
        source: ModelSource.bundled,
        version: manifest['version'] as String? ?? 'unknown',
        file: tempFile,
        labels: _splitLabels(labelsRaw),
        inputNormalization: manifest['inputNormalization'] as String? ?? '[-1,1]',
      );
    } catch (_) {
      // No bundled model.tflite present for this crop (placeholder-only build).
      return const ActiveModel(source: ModelSource.none, version: 'none');
    }
  }

  Future<List<String>> _parseLabels(Future<String> raw) async => _splitLabels(await raw);

  List<String> _splitLabels(String raw) =>
      raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

  /// Manual "download updated model" action, exposed from the sync/settings
  /// screen. Hits the backend's /api/models/disease/{cropId} endpoints.
  Future<void> downloadModel(String cropId) async {
    final dir = await _modelsDir(cropId);

    final response = await _dio.get<List<int>>(
      '/api/models/disease/$cropId',
      options: Options(responseType: ResponseType.bytes),
    );
    final modelFile = File(p.join(dir.path, 'model.tflite'));
    await modelFile.writeAsBytes(response.data!, flush: true);

    final manifestResponse = await _dio.get('/api/models/disease/$cropId/manifest');
    final manifestFile = File(p.join(dir.path, 'manifest.json'));
    await manifestFile.writeAsString(jsonEncode(manifestResponse.data));

    final labelsResponse = await _dio.get<String>('/api/models/disease/$cropId/labels');
    final labelsFile = File(p.join(dir.path, 'labels.txt'));
    await labelsFile.writeAsString(labelsResponse.data ?? '');
  }
}

final modelManagerProvider = Provider<ModelManager>((ref) {
  return ModelManager(ref.watch(apiClientProvider));
});

/// Drives the per-crop status row on the Sync & Data screen. Callers
/// ref.invalidate(cropModelStatusProvider(cropId)) after downloadModel()
/// to refresh it.
final cropModelStatusProvider = FutureProvider.family<ActiveModel, String>((ref, cropId) {
  return ref.watch(modelManagerProvider).resolveActiveModel(cropId);
});
