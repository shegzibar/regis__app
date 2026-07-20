class Room {
  final String id;
  final String cyberId;
  final String name;
  final String type;
  final double pricePerHour;
  final double? bookingFee;
  final String? description;
  final String? imageUrl;
  final List<String> images;
  final bool isActive;

  const Room({
    required this.id,
    required this.cyberId,
    required this.name,
    required this.type,
    required this.pricePerHour,
    this.bookingFee,
    this.description,
    this.imageUrl,
    this.images = const [],
    this.isActive = true,
  });

  factory Room.fromMap(Map<String, dynamic> map) {
    return Room(
      id: map['id'] as String,
      cyberId: map['cyber_id'] as String,
      name: map['name'] as String,
      type: map['type'] as String,
      pricePerHour: (map['price_per_hour'] as num).toDouble(),
      bookingFee: map['booking_fee'] != null ? (map['booking_fee'] as num).toDouble() : null,
      description: map['description'] as String?,
      imageUrl: map['image_url'] as String?,
      images: List<String>.from(map['images'] as List? ?? []),
      isActive: map['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'cyber_id': cyberId,
      'name': name,
      'type': type,
      'price_per_hour': pricePerHour,
      'booking_fee': bookingFee,
      'description': description,
      'image_url': imageUrl,
      'images': images,
      'is_active': isActive,
    };
  }

  Room copyWith({
    String? id,
    String? cyberId,
    String? name,
    String? type,
    double? pricePerHour,
    double? bookingFee,
    String? description,
    String? imageUrl,
    List<String>? images,
    bool? isActive,
  }) {
    return Room(
      id: id ?? this.id,
      cyberId: cyberId ?? this.cyberId,
      name: name ?? this.name,
      type: type ?? this.type,
      pricePerHour: pricePerHour ?? this.pricePerHour,
      bookingFee: bookingFee ?? this.bookingFee,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      isActive: isActive ?? this.isActive,
    );
  }

  String get displayName {
    switch (type.toLowerCase()) {
      case 'ps5':
        return 'PlayStation 5';
      case 'pc':
        return 'Gaming PC';
      case 'vip':
        return 'VIP Room';
      default:
        return name;
    }
  }

  double get effectiveBookingFee {
    if (bookingFee != null && bookingFee! > 0) {
      return bookingFee!;
    }
    // Default fees based on room type
    if (type.toLowerCase() == 'vip') {
      return 8.0;
    }
    return 5.0; // Default for PS5, PC, etc.
  }

  String get typeIcon {
    switch (type.toLowerCase()) {
      case 'ps5':
        return '🎮';
      case 'pc':
        return '💻';
      case 'vip':
        return '⭐';
      default:
        return '🕹️';
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Room && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Room(id: $id, name: $name, type: $type, price: $pricePerHour)';
  }
}
