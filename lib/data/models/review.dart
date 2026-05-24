class Review {
  final String id;
  final String userId;
  final String cyberId;
  final String? bookingId;
  final int rating;
  final String? comment;
  final DateTime createdAt;

  const Review({
    required this.id,
    required this.userId,
    required this.cyberId,
    this.bookingId,
    required this.rating,
    this.comment,
    required this.createdAt,
  });

  factory Review.fromMap(Map<String, dynamic> map) {
    return Review(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      cyberId: map['cyber_id'] as String,
      bookingId: map['booking_id'] as String?,
      rating: map['rating'] as int,
      comment: map['comment'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'cyber_id': cyberId,
      'booking_id': bookingId,
      'rating': rating,
      'comment': comment,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Review copyWith({
    String? id,
    String? userId,
    String? cyberId,
    String? bookingId,
    int? rating,
    String? comment,
    DateTime? createdAt,
  }) {
    return Review(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      cyberId: cyberId ?? this.cyberId,
      bookingId: bookingId ?? this.bookingId,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  String get ratingStars {
    return '⭐' * rating + '☆' * (5 - rating);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Review && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Review(id: $id, rating: $rating, comment: $comment)';
  }
}
