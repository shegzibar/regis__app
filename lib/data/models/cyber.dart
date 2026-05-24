class Cyber {
  final String id;
  final String? ownerId;
  final String name;
  final String? description;
  final String? address;
  final String? city;
  final double? lat;
  final double? lng;
  final List<String> images;
  final double rating;
  final int reviewCount;
  final String workingHoursFrom;
  final String workingHoursTo;
  final bool isActive;
  final DateTime createdAt;

  const Cyber({
    required this.id,
    this.ownerId,
    required this.name,
    this.description,
    this.address,
    this.city,
    this.lat,
    this.lng,
    this.images = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.workingHoursFrom = '10:00',
    this.workingHoursTo = '02:00',
    this.isActive = true,
    required this.createdAt,
  });

  factory Cyber.fromMap(Map<String, dynamic> map) {
    return Cyber(
      id: map['id'] as String,
      ownerId: map['owner_id'] as String?,
      name: map['name'] as String,
      description: map['description'] as String?,
      address: map['address'] as String?,
      city: map['city'] as String?,
      lat: (map['lat'] as num?)?.toDouble(),
      lng: (map['lng'] as num?)?.toDouble(),
      images: List<String>.from(map['images'] as List? ?? []),
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: map['review_count'] as int? ?? 0,
      workingHoursFrom: map['working_hours_from'] as String? ?? '10:00',
      workingHoursTo: map['working_hours_to'] as String? ?? '02:00',
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_id': ownerId,
      'name': name,
      'description': description,
      'address': address,
      'city': city,
      'lat': lat,
      'lng': lng,
      'images': images,
      'rating': rating,
      'review_count': reviewCount,
      'working_hours_from': workingHoursFrom,
      'working_hours_to': workingHoursTo,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Cyber copyWith({
    String? id,
    String? ownerId,
    String? name,
    String? description,
    String? address,
    String? city,
    double? lat,
    double? lng,
    List<String>? images,
    double? rating,
    int? reviewCount,
    String? workingHoursFrom,
    String? workingHoursTo,
    bool? isActive,
    DateTime? createdAt,
  }) {
    return Cyber(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      description: description ?? this.description,
      address: address ?? this.address,
      city: city ?? this.city,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
      images: images ?? this.images,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      workingHoursFrom: workingHoursFrom ?? this.workingHoursFrom,
      workingHoursTo: workingHoursTo ?? this.workingHoursTo,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get hasLocation => lat != null && lng != null;
  bool get hasImages => images.isNotEmpty;
  bool get isOpenNow {
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    if (workingHoursFrom.compareTo(workingHoursTo) < 0) {
      // Same day (e.g., 10:00 - 22:00)
      return currentTime.compareTo(workingHoursFrom) >= 0 && currentTime.compareTo(workingHoursTo) <= 0;
    } else {
      // Overnight (e.g., 10:00 - 02:00)
      return currentTime.compareTo(workingHoursFrom) >= 0 || currentTime.compareTo(workingHoursTo) <= 0;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Cyber && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Cyber(id: $id, name: $name, city: $city, rating: $rating)';
  }
}
