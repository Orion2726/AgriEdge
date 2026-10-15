/// Something a farmer has put up for sale (Farm supplies → Sell).
class Listing {
  const Listing({
    required this.id,
    required this.sellerName,
    required this.title,
    required this.category,
    required this.quantity,
    required this.unit,
    required this.price,
    required this.createdAt,
    this.phone,
    this.place,
    this.note,
    this.status = 'available',
    this.pending = false,
  });

  final String id;
  final String sellerName;
  final String? phone;
  final String title;
  final String category;
  final double quantity;
  final String unit;

  /// ₹ per [unit].
  final double price;
  final String? place;
  final String? note;

  /// available · sold · withdrawn
  final String status;
  final DateTime createdAt;

  /// Posted on this phone but not uploaded yet (no connection).
  final bool pending;

  double get total => price * quantity;

  static const categories = ['Produce', 'Seed', 'Fertilizer', 'Pesticide', 'Equipment', 'Livestock', 'Other'];
  static const units = ['kg', 'quintal', 'bag', 'litre', 'unit', 'dozen'];

  factory Listing.fromJson(Map<String, dynamic> j, {bool pending = false}) => Listing(
        id: j['id'] as String,
        sellerName: j['sellerName'] as String? ?? 'Farmer',
        phone: j['phone'] as String?,
        title: j['title'] as String? ?? '',
        category: j['category'] as String? ?? 'Other',
        quantity: (j['quantity'] as num?)?.toDouble() ?? 0,
        unit: j['unit'] as String? ?? 'unit',
        price: (j['price'] as num?)?.toDouble() ?? 0,
        place: j['place'] as String?,
        note: j['note'] as String?,
        status: j['status'] as String? ?? 'available',
        createdAt: DateTime.tryParse(j['createdAt'] as String? ?? '') ?? DateTime.now(),
        pending: pending,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'sellerName': sellerName,
        'phone': phone,
        'title': title,
        'category': category,
        'quantity': quantity,
        'unit': unit,
        'price': price,
        'place': place,
        'note': note,
        'status': status,
        'createdAt': createdAt.toUtc().toIso8601String(),
      };
}
