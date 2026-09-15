import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/network/api_client.dart';

enum CropRecModelSource { downloaded, bundled, none }

class ActiveCropRecModel {
  const ActiveCropRecModel({
    required this.source,
    required this.version,
    this.file,
    this.labels,
    this.featureOrder,
  });

  final CropRecModelSource source;
  final String version;
  final File? file;
  final List<String>? labels;
  final List<String>? featureOrder;

  bool get isUsable => source != CropRecModelSource.none && file != null && labels != null;
}

/// Same resolve-then-download pattern as core/ml/model_manager.dart (bundled
/// asset vs runtime-downloaded, bundled wins only if nothing's downloaded),
/// kept as its own small class rather than generalizing ModelManager — this
/// is a single fixed model (not one per crop), and duplicating ~60 lines
/// here is cheaper than risking a regression in the already-verified
/// per-crop disease model flow.
class CropRecommendationModelManager {
  CropRecommendationModelManager(this._dio);

  final Dio _dio;
  static const _assetDir = 'assets/ml/crop_recommendation';

  Future<Directory> _modelDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'models', 'crop_recommendation'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  Future<ActiveCropRecModel> resolveActiveModel() async {
    final downloaded = await _downloadedModel();
    if (downloaded != null) return downloaded;
    return _bundledModel();
  }

  Future<ActiveCropRecModel?> _downloadedModel() async {
    final dir = await _modelDir();
    final modelFile = File(p.join(dir.path, 'model.tflite'));
    final manifestFile = File(p.join(dir.path, 'manifest.json'));
    final labelsFile = File(p.join(dir.path, 'labels.txt'));
    if (!modelFile.existsSync() || !manifestFile.existsSync() || !labelsFile.existsSync()) {
      return null;
    }
    try {
      final manifest = jsonDecode(await manifestFile.readAsString());
      return ActiveCropRecModel(
        source: CropRecModelSource.downloaded,
        version: manifest['version'] as String? ?? 'unknown',
        file: modelFile,
        labels: _splitLines(await labelsFile.readAsString()),
        featureOrder: (manifest['inputFeatureOrder'] as List?)?.cast<String>(),
      );
    } catch (_) {
      return null;
    }
  }

  Future<ActiveCropRecModel> _bundledModel() async {
    try {
      final manifestRaw = await rootBundle.loadString('$_assetDir/manifest.json');
      final manifest = jsonDecode(manifestRaw);
      if (manifest['isPlaceholder'] == true) {
        return const ActiveCropRecModel(source: CropRecModelSource.none, version: 'placeholder');
      }
      final bytes = await rootBundle.load('$_assetDir/model.tflite');
      final labelsRaw = await rootBundle.loadString('$_assetDir/labels.txt');
      final docs = await getApplicationDocumentsDirectory();
      final tempFile =
          File(p.join(docs.path, 'models', 'crop_recommendation', 'bundled.tflite'));
      tempFile.parent.createSync(recursive: true);
      await tempFile.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      return ActiveCropRecModel(
        source: CropRecModelSource.bundled,
        version: manifest['version'] as String? ?? 'unknown',
        file: tempFile,
        labels: _splitLines(labelsRaw),
        featureOrder: (manifest['inputFeatureOrder'] as List?)?.cast<String>(),
      );
    } catch (_) {
      return const ActiveCropRecModel(source: CropRecModelSource.none, version: 'none');
    }
  }

  List<String> _splitLines(String raw) =>
      raw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

  /// Manual "download updated model" action, exposed from the sync/settings
  /// screen. Hits the backend's /api/models/crop-recommendation endpoints.
  Future<void> downloadModel() async {
    final dir = await _modelDir();

    final response = await _dio.get<List<int>>(
      '/api/models/crop-recommendation',
      options: Options(responseType: ResponseType.bytes),
    );
    await File(p.join(dir.path, 'model.tflite')).writeAsBytes(response.data!, flush: true);

    final manifestResponse = await _dio.get('/api/models/crop-recommendation/manifest');
    await File(p.join(dir.path, 'manifest.json'))
        .writeAsString(jsonEncode(manifestResponse.data));

    final labelsResponse = await _dio.get<String>('/api/models/crop-recommendation/labels');
    await File(p.join(dir.path, 'labels.txt')).writeAsString(labelsResponse.data ?? '');
  }
}

final cropRecommendationModelManagerProvider = Provider<CropRecommendationModelManager>((ref) {
  return CropRecommendationModelManager(ref.watch(apiClientProvider));
});

final cropRecommendationModelStatusProvider = FutureProvider<ActiveCropRecModel>((ref) {
  return ref.watch(cropRecommendationModelManagerProvider).resolveActiveModel();
});
