/// Central place for values that would otherwise be magic strings/numbers
/// scattered across features. Backend base URL points at the local Node
/// dev server described in backend/README.md — there is no deployment yet.
class AppConstants {
  AppConstants._();

  static const String backendBaseUrl = 'http://localhost:4001';

  static const String treatmentsAssetPath =
      'assets/knowledge_base/treatments.json';
  static const String offlineFaqAssetPath =
      'assets/knowledge_base/offline_faq.json';
  static const String cropCalendarAssetPath =
      'assets/knowledge_base/crop_calendar.json';

  /// All disease models (every crop) take 224x224 RGB input. Normalization
  /// convention varies per crop and is read from that crop's manifest.json
  /// (see TFLiteDiseaseService) — see docs/MODEL_SPECS.md.
  static const int diseaseModelInputSize = 224;

  static const Duration syncInterval = Duration(minutes: 30);
  static const Duration staleAfter = Duration(hours: 6);
}
