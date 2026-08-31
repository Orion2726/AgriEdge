import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/disease_detection_entry.dart';

/// Bundled, always-available treatment advice — this is what keeps disease
/// detection 100% usable offline once a label comes back from the model.
class TreatmentKnowledgeBase {
  Map<String, TreatmentAdvice>? _cache;

  Future<Map<String, TreatmentAdvice>> _load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(AppConstants.treatmentsAssetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _cache = json.map((key, value) => MapEntry(key, TreatmentAdvice.fromJson(value)));
    return _cache!;
  }

  Future<TreatmentAdvice?> lookup(String label) async {
    final all = await _load();
    return all[label];
  }
}

final treatmentKnowledgeBaseProvider = Provider<TreatmentKnowledgeBase>((ref) {
  return TreatmentKnowledgeBase();
});
