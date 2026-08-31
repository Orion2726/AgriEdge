/// Named MspRateEntry (not MspRate) to avoid colliding with the generated
/// Drift row class `MspRate` produced from the MspRates table.
class MspRateEntry {
  const MspRateEntry({
    required this.crop,
    required this.season,
    required this.year,
    required this.pricePerQuintal,
    required this.fetchedAt,
  });

  final String crop;
  final String season;
  final int year;
  final double pricePerQuintal;
  final DateTime fetchedAt;
}
