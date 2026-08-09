import '../../core/utils/cyber_time_format.dart';

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
  final String? coverImage;
  final double rating;
  final int reviewCount;
  final String workingHoursFrom;
  final String workingHoursTo;
  final bool isFeatured;
  final bool isActive;
  final DateTime createdAt;
  final String subscriptionPlan;
  final String subscriptionBilling;
  final DateTime? subscriptionEndDate;

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
    this.coverImage,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.workingHoursFrom = '10:00',
    this.workingHoursTo = '02:00',
    this.isFeatured = false,
    this.isActive = true,
    required this.createdAt,
    this.subscriptionPlan = 'starter',
    this.subscriptionBilling = 'monthly',
    this.subscriptionEndDate,
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
      coverImage: map['cover_image'] as String?,
      rating: (map['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: map['review_count'] as int? ?? 0,
      workingHoursFrom:
          CyberTimeFormat.toDisplay(map['working_hours_from']),
      workingHoursTo: CyberTimeFormat.toDisplay(map['working_hours_to']),
      isFeatured: map['is_featured'] as bool? ?? false,
      isActive: map['is_active'] as bool? ?? true,
      createdAt: DateTime.parse(map['created_at'] as String),
      subscriptionPlan: map['subscription_plan'] as String? ?? 'starter',
      subscriptionBilling: map['subscription_billing'] as String? ?? 'monthly',
      subscriptionEndDate: map['subscription_end_date'] != null
          ? DateTime.parse(map['subscription_end_date'] as String)
          : null,
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
      'cover_image': coverImage,
      'rating': rating,
      'review_count': reviewCount,
      'working_hours_from': workingHoursFrom,
      'working_hours_to': workingHoursTo,
      'is_featured': isFeatured,
      'is_active': isActive,
      'created_at': createdAt.toIso8601String(),
      'subscription_plan': subscriptionPlan,
      'subscription_billing': subscriptionBilling,
      'subscription_end_date': subscriptionEndDate?.toIso8601String(),
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
    String? coverImage,
    double? rating,
    int? reviewCount,
    String? workingHoursFrom,
    String? workingHoursTo,
    bool? isFeatured,
    bool? isActive,
    DateTime? createdAt,
    String? subscriptionPlan,
    String? subscriptionBilling,
    DateTime? subscriptionEndDate,
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
      coverImage: coverImage ?? this.coverImage,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      workingHoursFrom: workingHoursFrom ?? this.workingHoursFrom,
      workingHoursTo: workingHoursTo ?? this.workingHoursTo,
      isFeatured: isFeatured ?? this.isFeatured,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      subscriptionPlan: subscriptionPlan ?? this.subscriptionPlan,
      subscriptionBilling: subscriptionBilling ?? this.subscriptionBilling,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
    );
  }

  bool get hasLocation => lat != null && lng != null;
  bool get hasImages => images.isNotEmpty;
  bool get isHighlyRated => rating >= 4.0;
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

  bool get isSubscriptionActive {
    if (subscriptionEndDate == null) return true; // If no end date, assume active (or change this logic if you prefer default inactive)
    return subscriptionEndDate!.isAfter(DateTime.now());
  }

  int get daysUntilExpiry {
    if (subscriptionEndDate == null) return 0;
    final diff = subscriptionEndDate!.difference(DateTime.now());
    return diff.inDays > 0 ? diff.inDays : 0;
  }

  /// Human-readable time remaining, e.g. "2 months 5 days left", "7 days left", "Expires today", "Expired 3 days ago"
  String get expiryLabel {
    if (subscriptionEndDate == null) return 'No end date';
    final now = DateTime.now();
    final diff = subscriptionEndDate!.difference(now);

    if (diff.isNegative) {
      final pastDays = diff.inDays.abs();
      if (pastDays == 0) return 'Expired today';
      if (pastDays < 30) return 'Expired $pastDays day${pastDays == 1 ? '' : 's'} ago';
      final months = (pastDays / 30).floor();
      return 'Expired $months month${months == 1 ? '' : 's'} ago';
    }

    final totalDays = diff.inDays;
    if (totalDays == 0) return 'Expires today';
    if (totalDays == 1) return '1 day left';
    if (totalDays < 30) return '$totalDays days left';

    final months = (totalDays / 30).floor();
    final remainingDays = totalDays % 30;
    if (remainingDays == 0) return '$months month${months == 1 ? '' : 's'} left';
    return '$months month${months == 1 ? '' : 's'} $remainingDays day${remainingDays == 1 ? '' : 's'} left';
  }

  /// 0 = no date, 1 = safe (>30 days), 2 = warning (7–30 days), 3 = critical (≤7 days or expired)
  int get expiryUrgency {
    if (subscriptionEndDate == null) return 0;
    final days = daysUntilExpiry;
    if (!isSubscriptionActive) return 3;
    if (days <= 7) return 3;
    if (days <= 30) return 2;
    return 1;
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
