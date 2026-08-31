class CatalogItem {
  const CatalogItem({
    required this.id,
    required this.name,
    required this.category,
    required this.pricePerUnit,
    required this.unit,
    this.imageUrl,
    this.description,
  });

  final String id;
  final String name;
  final String category;
  final double pricePerUnit;
  final String unit;
  final String? imageUrl;
  final String? description;
}

class OrderLineItem {
  const OrderLineItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  double get lineTotal => quantity * unitPrice;
}

class FarmOrder {
  const FarmOrder({
    required this.id,
    required this.createdAt,
    required this.status,
    required this.totalAmount,
    required this.syncStatus,
    required this.items,
  });

  final String id;
  final DateTime createdAt;
  final String status;
  final double totalAmount;
  final String syncStatus;
  final List<OrderLineItem> items;
}
