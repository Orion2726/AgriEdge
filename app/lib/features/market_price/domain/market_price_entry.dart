class MarketPriceEntry {
  const MarketPriceEntry({
    required this.commodity,
    required this.mandi,
    required this.pricePerQuintal,
    required this.priceDate,
    required this.fetchedAt,
  });

  final String commodity;
  final String mandi;
  final double pricePerQuintal;
  final DateTime priceDate;
  final DateTime fetchedAt;
}
