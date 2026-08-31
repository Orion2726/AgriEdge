class NearbyAlert {
  const NearbyAlert({
    required this.id,
    required this.label,
    required this.lat,
    required this.lng,
    required this.detectionCount,
    required this.radiusKm,
    required this.windowStart,
    required this.fetchedAt,
  });

  final String id;
  final String label;
  final double lat;
  final double lng;
  final int detectionCount;
  final double radiusKm;
  final DateTime windowStart;
  final DateTime fetchedAt;
}
