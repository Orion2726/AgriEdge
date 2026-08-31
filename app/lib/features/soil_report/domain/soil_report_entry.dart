class SoilReportEntry {
  const SoilReportEntry({
    required this.id,
    required this.nitrogen,
    required this.phosphorus,
    required this.potassium,
    required this.ph,
    required this.organicCarbon,
    required this.rainfallMm,
    required this.temperatureC,
    required this.humidityPct,
    required this.createdAt,
    required this.syncStatus,
  });

  final String id;
  final double nitrogen;
  final double phosphorus;
  final double potassium;
  final double ph;
  final double organicCarbon;
  final double rainfallMm;
  final double temperatureC;
  final double humidityPct;
  final DateTime createdAt;
  final String syncStatus;
}
