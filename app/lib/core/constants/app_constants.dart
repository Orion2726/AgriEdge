/// Central place for values that would otherwise be magic strings/numbers
/// scattered across features. Backend base URL points at the local Node
/// dev server described in backend/README.md — there is no deployment yet.
class AppConstants {
  AppConstants._();

  static const String backendBaseUrl = 'http://localhost:4001';

  static const String diseaseModelAssetPath = 'assets/ml/disease/model.tflite';
  static const String diseaseLabelsAssetPath = 'assets/ml/disease/labels.txt';
  static const String diseaseManifestAssetPath =
      'assets/ml/disease/model_manifest.json';

  static const String treatmentsAssetPath =
      'assets/knowledge_base/treatments.json';
  static const String offlineFaqAssetPath =
      'assets/knowledge_base/offline_faq.json';
  static const String cropCalendarAssetPath =
      'assets/knowledge_base/crop_calendar.json';

  /// Disease model input tensor is 224x224 RGB, normalized to [-1, 1].
  /// Must match whatever preprocessing the trained model actually expects —
  /// see docs/MODEL_SPECS.md before swapping in a real model.
  static const int diseaseModelInputSize = 224;

  static const Duration syncInterval = Duration(minutes: 30);
  static const Duration staleAfter = Duration(hours: 6);
}
