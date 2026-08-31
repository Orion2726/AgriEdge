class CropSuggestion {
  const CropSuggestion({
    required this.cropName,
    required this.rank,
    required this.suitabilityScore,
    required this.nutrientAdvice,
    required this.cachedAt,
  });

  final String cropName;
  final int rank;
  final double suitabilityScore;
  final List<String> nutrientAdvice;
  final DateTime cachedAt;
}
