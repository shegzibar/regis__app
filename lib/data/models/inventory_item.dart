class CyberInventoryItem {
  final String id;
  final String cyberId;
  final String name;
  final double price;
  final double costPrice;
  final int stock;
  final int used;
  final bool isActive;

  const CyberInventoryItem({
    required this.id,
    required this.cyberId,
    required this.name,
    required this.price,
    this.costPrice = 0,
    this.stock = 0,
    this.used = 0,
    this.isActive = true,
  });

  factory CyberInventoryItem.fromMap(Map<String, dynamic> map) {
    return CyberInventoryItem(
      id: map['id'] as String,
      cyberId: map['cyber_id'] as String,
      name: map['name'] as String,
      price: (map['price'] as num).toDouble(),
      costPrice: (map['cost_price'] as num?)?.toDouble() ?? 0.0,
      stock: (map['stock'] as num?)?.toInt() ?? 0,
      used: (map['used'] as num?)?.toInt() ?? 0,
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toInsertMap() {
    return {
      'cyber_id': cyberId,
      'name': name,
      'price': price,
      'cost_price': costPrice,
      'stock': stock,
      'used': used,
      'is_active': isActive,
    };
  }

  Map<String, dynamic> toUpdateMap() {
    return {
      'name': name,
      'price': price,
      'cost_price': costPrice,
      'stock': stock,
      'used': used,
      'is_active': isActive,
    };
  }
}

class BookingItem {
  final String id;
  final String bookingId;
  final String itemId;
  final int quantity;
  final double priceAtTime;
  final double costAtTime;
  final double totalPrice;
  final CyberInventoryItem? inventoryItem;

  const BookingItem({
    required this.id,
    required this.bookingId,
    required this.itemId,
    required this.quantity,
    required this.priceAtTime,
    this.costAtTime = 0,
    required this.totalPrice,
    this.inventoryItem,
  });

  factory BookingItem.fromMap(Map<String, dynamic> map) {
    final itemMap = map['cyber_inventory_items'] as Map<String, dynamic>?;
    return BookingItem(
      id: map['id'] as String,
      bookingId: map['booking_id'] as String,
      itemId: map['item_id'] as String,
      quantity: map['quantity'] as int,
      priceAtTime: (map['price_at_time'] as num).toDouble(),
      costAtTime: (map['cost_at_time'] as num?)?.toDouble() ?? 0.0,
      totalPrice: (map['total_price'] as num).toDouble(),
      inventoryItem: itemMap != null ? CyberInventoryItem.fromMap(itemMap) : null,
    );
  }
}
