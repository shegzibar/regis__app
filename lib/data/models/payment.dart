class Payment {
  final String id;
  final String bookingId;
  final String userId;
  final double amount;
  final String method;
  final String? screenshotUrl;
  final String status;
  final String? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final DateTime createdAt;

  const Payment({
    required this.id,
    required this.bookingId,
    required this.userId,
    required this.amount,
    required this.method,
    this.screenshotUrl,
    this.status = 'pending',
    this.reviewedBy,
    this.reviewedAt,
    this.rejectionReason,
    required this.createdAt,
  });

  factory Payment.fromMap(Map<String, dynamic> map) {
    return Payment(
      id: map['id'] as String,
      bookingId: map['booking_id'] as String,
      userId: map['user_id'] as String,
      amount: (map['amount'] as num).toDouble(),
      method: map['method'] as String,
      screenshotUrl: map['screenshot_url'] as String?,
      status: map['status'] as String? ?? 'pending',
      reviewedBy: map['reviewed_by'] as String?,
      reviewedAt: map['reviewed_at'] != null 
          ? DateTime.parse(map['reviewed_at'] as String)
          : null,
      rejectionReason: map['rejection_reason'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'booking_id': bookingId,
      'user_id': userId,
      'amount': amount,
      'method': method,
      'screenshot_url': screenshotUrl,
      'status': status,
      'reviewed_by': reviewedBy,
      'reviewed_at': reviewedAt?.toIso8601String(),
      'rejection_reason': rejectionReason,
      'created_at': createdAt.toIso8601String(),
    };
  }

  Payment copyWith({
    String? id,
    String? bookingId,
    String? userId,
    double? amount,
    String? method,
    String? screenshotUrl,
    String? status,
    String? reviewedBy,
    DateTime? reviewedAt,
    String? rejectionReason,
    DateTime? createdAt,
  }) {
    return Payment(
      id: id ?? this.id,
      bookingId: bookingId ?? this.bookingId,
      userId: userId ?? this.userId,
      amount: amount ?? this.amount,
      method: method ?? this.method,
      screenshotUrl: screenshotUrl ?? this.screenshotUrl,
      status: status ?? this.status,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isPending => status == 'pending';
  bool get isApproved => status == 'approved';
  bool get isRejected => status == 'rejected';
  bool get hasScreenshot => screenshotUrl != null && screenshotUrl!.isNotEmpty;

  String get statusDisplay {
    switch (status) {
      case 'pending':
        return 'Pending Review';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      default:
        return status;
    }
  }

  String get methodDisplay {
    switch (method.toLowerCase()) {
      case 'instapay':
        return 'InstaPay';
      case 'vodafone_cash':
        return 'Vodafone Cash';
      case 'fawry':
        return 'Fawry';
      default:
        return method;
    }
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Payment && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Payment(id: $id, amount: $amount, method: $method, status: $status)';
  }
}
