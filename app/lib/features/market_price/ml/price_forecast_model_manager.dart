import 'dart:convert';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../../core/network/api_client.dart';

enum PriceForecastModelSource { downloaded, bundled, none }

class VolatilityBand {
  const VolatilityBand({required this.p10, required this.p90});
  final double p10;
  final double p90;
}

class ActivePriceForecastModel {
  const ActivePriceForecastModel({
    required this.source,
    required this.version,
    this.file,
    this.commodityOrder,
    this.volatilityBands,
  });

  final PriceForecastModelSource source;
  final String version;
  final File? file;
  final List<String>? commodityOrder;

  /// commodity -> 7 bands (day-ahead 1..7), empirical p10/p90 price ratios
  /// from real historical data. Not a model output — see manifest.json's
  /// note on why the point forecast alone isn't enough.
  final Map<String, List<VolatilityBand>>? volatilityBands;

  bool get isUsable =>
      source != PriceForecastModelSource.none && file != null && commodityOrder != null;
}

/// Same resolve-then-download pattern as the other ModelManager-style
/// classes in this app (bundled asset vs runtime-downloaded) — kept as its
/// own small class per the established precedent (crop recommendation) of
/// not generalizing the disease ModelManager across unrelated model shapes.
class PriceForecastModelManager {
  PriceForecastModelManager(this._dio);

  final Dio _dio;
  static const _assetDir = 'assets/ml/price_forecast';

  Future<Directory> _modelDir() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'models', 'price_forecast'));
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir;
  }

  Future<ActivePriceForecastModel> resolveActiveModel() async {
    final downloaded = await _downloadedModel();
    if (downloaded != null) return downloaded;
    return _bundledModel();
  }

  Map<String, List<VolatilityBand>> _parseBands(String raw) {
    final json = jsonDecode(raw) as Map<String, dynamic>;
    return json.map((commodity, bands) => MapEntry(
          commodity,
          (bands as List)
              .map((b) => VolatilityBand(
                    p10: (b['p10'] as num).toDouble(),
                    p90: (b['p90'] as num).toDouble(),
                  ))
              .toList(),
        ));
  }

  Future<ActivePriceForecastModel?> _downloadedModel() async {
    final dir = await _modelDir();
    final modelFile = File(p.join(dir.path, 'model.tflite'));
    final manifestFile = File(p.join(dir.path, 'manifest.json'));
    final labelsFile = File(p.join(dir.path, 'labels.txt'));
    final bandsFile = File(p.join(dir.path, 'volatility_bands.json'));
    if (![modelFile, manifestFile, labelsFile, bandsFile].every((f) => f.existsSync())) {
      return null;
    }
    try {
      final manifest = jsonDecode(await manifestFile.readAsString());
      final labels = (await labelsFile.readAsString())
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .toList();
      return ActivePriceForecastModel(
        source: PriceForecastModelSource.downloaded,
        version: manifest['version'] as String? ?? 'unknown',
        file: modelFile,
        commodityOrder: labels,
        volatilityBands: _parseBands(await bandsFile.readAsString()),
      );
    } catch (_) {
      return null;
    }
  }

  Future<ActivePriceForecastModel> _bundledModel() async {
    try {
      final manifestRaw = await rootBundle.loadString('$_assetDir/manifest.json');
      final manifest = jsonDecode(manifestRaw);
      if (manifest['isPlaceholder'] == true) {
        return const ActivePriceForecastModel(
          source: PriceForecastModelSource.none,
          version: 'placeholder',
        );
      }
      final bytes = await rootBundle.load('$_assetDir/model.tflite');
      final labelsRaw = await rootBundle.loadString('$_assetDir/labels.txt');
      final bandsRaw = await rootBundle.loadString('$_assetDir/volatility_bands.json');
      final docs = await getApplicationDocumentsDirectory();
      final tempFile = File(p.join(docs.path, 'models', 'price_forecast', 'bundled.tflite'));
      tempFile.parent.createSync(recursive: true);
      await tempFile.writeAsBytes(bytes.buffer.asUint8List(), flush: true);
      return ActivePriceForecastModel(
        source: PriceForecastModelSource.bundled,
        version: manifest['version'] as String? ?? 'unknown',
        file: tempFile,
        commodityOrder:
            labelsRaw.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList(),
        volatilityBands: _parseBands(bandsRaw),
      );
    } catch (_) {
      return const ActivePriceForecastModel(source: PriceForecastModelSource.none, version: 'none');
    }
  }

  /// Manual "download updated model" action, exposed from the sync/settings
  /// screen. Hits the backend's /api/models/price-forecast endpoints.
  Future<void> downloadModel() async {
    final dir = await _modelDir();

    final response = await _dio.get<List<int>>(
      '/api/models/price-forecast',
      options: Options(responseType: ResponseType.bytes),
    );
    await File(p.join(dir.path, 'model.tflite')).writeAsBytes(response.data!, flush: true);

    final manifestResponse = await _dio.get('/api/models/price-forecast/manifest');
    await File(p.join(dir.path, 'manifest.json')).writeAsString(jsonEncode(manifestResponse.data));

    final labelsResponse = await _dio.get<String>('/api/models/price-forecast/labels');
    await File(p.join(dir.path, 'labels.txt')).writeAsString(labelsResponse.data ?? '');

    final bandsResponse = await _dio.get('/api/models/price-forecast/volatility-bands');
    await File(p.join(dir.path, 'volatility_bands.json'))
        .writeAsString(jsonEncode(bandsResponse.data));
  }
}

final priceForecastModelManagerProvider = Provider<PriceForecastModelManager>((ref) {
  return PriceForecastModelManager(ref.watch(apiClientProvider));
});

final priceForecastModelStatusProvider = FutureProvider<ActivePriceForecastModel>((ref) {
  return ref.watch(priceForecastModelManagerProvider).resolveActiveModel();
});
