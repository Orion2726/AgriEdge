import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/app_constants.dart';
import '../domain/disease_detection_entry.dart';

/// Bundled, always-available treatment advice — this is what keeps disease
/// detection 100% usable offline once a label comes back from the model.
/// Namespaced by crop (not just by label) because label strings aren't
/// unique across crops' models — e.g. rice's "blast" and wheat's "Blast",
/// or the generic "Healthy" used by several crop models — so a flat
/// label-only lookup would silently collide.
class TreatmentKnowledgeBase {
  Map<String, Map<String, TreatmentAdvice>>? _cache;

  Future<Map<String, Map<String, TreatmentAdvice>>> _load() async {
    if (_cache != null) return _cache!;
    final raw = await rootBundle.loadString(AppConstants.treatmentsAssetPath);
    final json = jsonDecode(raw) as Map<String, dynamic>;
    _cache = json.map((cropId, labelMap) => MapEntry(
          cropId,
          (labelMap as Map<String, dynamic>)
              .map((label, value) => MapEntry(label, TreatmentAdvice.fromJson(value))),
        ));
    return _cache!;
  }

  Future<TreatmentAdvice?> lookup(String cropId, String label) async {
    final all = await _load();
    return all[cropId]?[label];
  }
}

final treatmentKnowledgeBaseProvider = Provider<TreatmentKnowledgeBase>((ref) {
  return TreatmentKnowledgeBase();
});
