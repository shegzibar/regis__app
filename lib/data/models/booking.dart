class Booking {
  final String id;
  final String userId;
  final String stationId;
  final DateTime startTime;
  final DateTime endTime;
  final double durationHours;
  final double totalAmount;
  final double bookingFee;
  final String status;
  final String source;   // 'app' | 'manual'
  final String? notes;
  final String? userName;    // joined from profiles table
  final String? stationName; // joined from stations table
  final String? roomName;    // joined from rooms table
  final String? cyberId;     // joined from rooms table
  final DateTime createdAt;
  final DateTime? confirmedAt;
  final DateTime? expiresAt;

  const Booking({
    required this.id,
    required this.userId,
    required this.stationId,
    required this.startTime,
    required this.endTime,
    required this.durationHours,
    required this.totalAmount,
    this.bookingFee = 5.0,
    this.status = 'pending_payment',
    this.source = 'app',
    this.notes,
    this.userName,
    this.stationName,
    this.roomName,
    this.cyberId,
    required this.createdAt,
    this.confirmedAt,
    this.expiresAt,
  });

  factory Booking.fromMap(Map<String, dynamic> map) {
    final stationMap = map['stations'] as Map<String, dynamic>?;
    final roomMap = stationMap?['rooms'] as Map<String, dynamic>?;
    return Booking(
      id: map['id'] as String,
      userId: map['user_id'] as String,
      stationId: map['station_id'] as String,
      startTime: DateTime.parse(map['start_time'] as String),
      endTime: DateTime.parse(map['end_time'] as String),
      durationHours: (map['duration_hours'] as num).toDouble(),
      totalAmount: (map['total_amount'] as num).toDouble(),
      bookingFee: (map['booking_fee'] as num?)?.toDouble() ?? 5.0,
      status: map['status'] as String? ?? 'pending_payment',
      source: map['source'] as String? ?? 'app',
      notes: map['notes'] as String?,
      userName: (map['guest_name'] ?? map['profiles']?['name'] ?? map['users']?['name']) as String?,
      stationName: stationMap?['name'] as String?,
      roomName: roomMap?['name'] as String?,
      cyberId: roomMap?['cyber_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
      confirmedAt: map['confirmed_at'] != null 
          ? DateTime.parse(map['confirmed_at'] as String)
          : null,
      expiresAt: map['expires_at'] != null 
          ? DateTime.parse(map['expires_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'station_id': stationId,
      'start_time': startTime.toIso8601String(),
      'end_time': endTime.toIso8601String(),
      'duration_hours': durationHours,
      'total_amount': totalAmount,
      'booking_fee': bookingFee,
      'status': status,
      'notes': notes,
      'guest_name': source == 'manual' ? userName : null,
      'created_at': createdAt.toIso8601String(),
      'confirmed_at': confirmedAt?.toIso8601String(),
      'expires_at': expiresAt?.toIso8601String(),
    };
  }

  Booking copyWith({
    String? id,
    String? userId,
    String? stationId,
    DateTime? startTime,
    DateTime? endTime,
    double? durationHours,
    double? totalAmount,
    double? bookingFee,
    String? status,
    String? source,
    String? notes,
    String? userName,
    String? stationName,
    String? roomName,
    String? cyberId,
    DateTime? createdAt,
    DateTime? confirmedAt,
    DateTime? expiresAt,
  }) {
    return Booking(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      stationId: stationId ?? this.stationId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      durationHours: durationHours ?? this.durationHours,
      totalAmount: totalAmount ?? this.totalAmount,
      bookingFee: bookingFee ?? this.bookingFee,
      status: status ?? this.status,
      source: source ?? this.source,
      notes: notes ?? this.notes,
      userName: userName ?? this.userName,
      stationName: stationName ?? this.stationName,
      roomName: roomName ?? this.roomName,
      cyberId: cyberId ?? this.cyberId,
      createdAt: createdAt ?? this.createdAt,
      confirmedAt: confirmedAt ?? this.confirmedAt,
      expiresAt: expiresAt ?? this.expiresAt,
    );
  }

  bool get isPendingPayment => status == 'pending_payment';
  bool get isFeeUnderReview => status == 'fee_under_review';
  bool get isConfirmed => status == 'confirmed';
  bool get isRejected => status == 'rejected';
  bool get isCompleted => status == 'completed';
  bool get isCancelled => status == 'cancelled';
  bool get isUpcoming => startTime.isAfter(DateTime.now());
  bool get isOngoing => startTime.isBefore(DateTime.now()) && endTime.isAfter(DateTime.now());
  bool get isPast => endTime.isBefore(DateTime.now());
  bool get isExpired => expiresAt != null && DateTime.now().isAfter(expiresAt!);

  String get statusDisplay {
    switch (status) {
      case 'pending_payment':
        return 'Pending Payment';
      case 'fee_under_review':
        return 'Under Review';
      case 'confirmed':
        return 'Confirmed';
      case 'rejected':
        return 'Rejected';
      case 'completed':
        return 'Completed';
      case 'cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }

  double get roomCost => totalAmount - bookingFee;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Booking && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Booking(id: $id, status: $status, startTime: $startTime)';
  }
}
