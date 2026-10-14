/// Central place for values that would otherwise be magic strings/numbers
/// scattered across features.
class AppConstants {
  AppConstants._();

  /// The local Node server described in backend/README.md — there is no
  /// public deployment. Empty by default (a shared APK must not point at one
  /// developer's laptop); set it in More → Sync & server, or at build time
  /// with `--dart-define=AGRIEDGE_BACKEND_URL=http://192.168.x.y:4001`.
  static const String defaultBackendBaseUrl = String.fromEnvironment('AGRIEDGE_BACKEND_URL');

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
