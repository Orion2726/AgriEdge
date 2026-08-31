import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../constants/app_constants.dart';
import '../network/api_client.dart';

enum ModelSource { downloaded, bundled, none }

class ActiveModel {
  const ActiveModel({required this.source, required this.version, this.file});

  final ModelSource source;
  final String version;
  final File? file;

  bool get isUsable => source != ModelSource.none && file != null;
}

/// Resolves which disease-detection model to use, in priority order:
/// 1. A model downloaded at runtime into app-documents (supports the
///    "models should be downloadable" requirement — updated models don't
///    need an app store release).
/// 2. The model bundled in assets/ml/disease/ at build time.
/// 3. Neither — caller falls back to a mocked prediction.
///
/// Trained models are dropped in at assets/ml/disease/model.tflite (bundled)
/// or served from the backend's /api/models/disease (downloaded). See
/// docs/MODEL_SPECS.md for the exact contract.
class ModelManager {
  ModelManager(this._dio);

  final Dio _dio;

  Future<Directory> _modelsDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'models', 'disease'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  Future<ActiveModel> resolveActiveModel() async {
    final downloaded = await _downloadedModel();
    if (downloaded != null) return downloaded;
    return _bundledModel();
  }

  Future<ActiveModel?> _downloadedModel() async {
    final dir = await _modelsDir();
    final modelFile = File(p.join(dir.path, 'model.tflite'));
    final manifestFile = File(p.join(dir.path, 'manifest.json'));
    if (!modelFile.existsSync() || !manifestFile.existsSync()) return null;
    try {
      final manifest = jsonDecode(await manifestFile.readAsString());
      return ActiveModel(
        source: ModelSource.downloaded,
        version: manifest['version'] as String? ?? 'unknown',
        file: modelFile,
      );
    } catch (_) {
      return null;
    }
  }

  Future<ActiveModel> _bundledModel() async {
    try {
      final manifestRaw =
          await rootBundle.loadString(AppConstants.diseaseManifestAssetPath);
      final manifest = jsonDecode(manifestRaw);
      if (manifest['isPlaceholder'] == true) {
        return ActiveModel(source: ModelSource.none, version: 'placeholder');
      }
      // Bundled asset exists and is a real model: copy the byte data out to
      // a temp file so the tflite interpreter (which needs a file path or
      // buffer) can load it uniformly with the downloaded-model path.
      final bytes = await rootBundle.load(AppConstants.diseaseModelAssetPath);
      final docs = await getApplicationDocumentsDirectory();
      final tempFile = File(p.join(docs.path, 'models', 'disease', 'bundled.tflite'));
      tempFile.parent.createSync(recursive: true);
      await tempFile.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      return ActiveModel(
        source: ModelSource.bundled,
        version: manifest['version'] as String? ?? 'unknown',
        file: tempFile,
      );
    } catch (_) {
      // No bundled model.tflite present (still a placeholder-only build).
      return const ActiveModel(source: ModelSource.none, version: 'none');
    }
  }

  /// Manual "download updated model" action, exposed from the sync/settings
  /// screen. Hits the backend's /api/models/disease endpoint.
  Future<void> downloadLatestModel() async {
    final dir = await _modelsDir();
    final response = await _dio.get<List<int>>(
      '/api/models/disease',
      options: Options(responseType: ResponseType.bytes),
    );
    final modelFile = File(p.join(dir.path, 'model.tflite'));
    await modelFile.writeAsBytes(response.data!, flush: true);

    final manifestResponse = await _dio.get('/api/models/disease/manifest');
    final manifestFile = File(p.join(dir.path, 'manifest.json'));
    await manifestFile.writeAsString(jsonEncode(manifestResponse.data));
  }
}

final modelManagerProvider = Provider<ModelManager>((ref) {
  return ModelManager(ref.watch(apiClientProvider));
});
