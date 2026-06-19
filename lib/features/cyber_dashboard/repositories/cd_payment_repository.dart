import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/payment.dart';

final _db = Supabase.instance.client;

/// A payment enriched with joined user and booking info for the dashboard.
class CdPaymentItem {
  final Payment payment;
  final String? userName;
  final String? userEmail;
  final String? stationName;
  final String? roomName;
  final String? roomType;
  final DateTime? bookingStart;
  final DateTime? bookingEnd;
  final double? totalAmount;
  final String? bookingSource;

  const CdPaymentItem({
    required this.payment,
    this.userName,
    this.userEmail,
    this.stationName,
    this.roomName,
    this.roomType,
    this.bookingStart,
    this.bookingEnd,
    this.totalAmount,
    this.bookingSource,
  });

  factory CdPaymentItem.fromMap(Map<String, dynamic> map) {
    final p = Payment.fromMap(map);
    final booking = map['bookings'] as Map<String, dynamic>?;
    final station = booking?['stations'] as Map<String, dynamic>?;
    final room = station?['rooms'] as Map<String, dynamic>?;
    // Support both 'profiles' (new) and 'users' (legacy) join names
    final userMap = (map['profiles'] ?? map['users']) as Map<String, dynamic>?;

    return CdPaymentItem(
      payment: p,
      userName: userMap?['name'] as String?,
      userEmail: null, // profiles table has no email column
      stationName: station?['name'] as String?,
      roomName: room?['name'] as String?,
      roomType: room?['type'] as String?,
      bookingStart: booking?['start_time'] != null
          ? DateTime.tryParse(booking!['start_time'] as String)
          : null,
      bookingEnd: booking?['end_time'] != null
          ? DateTime.tryParse(booking!['end_time'] as String)
          : null,
      totalAmount: booking?['total_amount'] != null
          ? (booking!['total_amount'] as num).toDouble()
          : null,
      bookingSource: booking?['source'] as String?,
    );
  }
}

class CdPaymentRepository {
  /// Pending payments that belong to this cyber's bookings, oldest first.
  Future<List<CdPaymentItem>> getPendingPayments(String cyberId) async {
    final data = await _db.from('payments').select('''
      *,
      profiles!payments_user_id_fkey ( id, name ),
      bookings (
        id, start_time, end_time, duration_hours,
        total_amount, status, user_id, confirmed_at,
        stations (
          id, name,
          rooms ( id, name, type, cyber_id )
        )
      )
    ''').eq('status', 'pending').order('created_at', ascending: true);

    return (data as List)
        .where(
            (p) => p['bookings']?['stations']?['rooms']?['cyber_id'] == cyberId)
        .map((p) => CdPaymentItem.fromMap(p))
        .toList();
  }

  /// Approve payment and confirm the booking.
  Future<void> confirmPayment(String paymentId, String bookingId) async {
    final reviewerId = _db.auth.currentUser!.id;

    await _db.from('payments').update({
      'status': 'approved',
      'reviewed_by': reviewerId,
      'reviewed_at': DateTime.now().toIso8601String(),
    }).eq('id', paymentId);

    await _db.from('bookings').update({
      'status': 'confirmed',
      'confirmed_at': DateTime.now().toIso8601String(),
    }).eq('id', bookingId);
  }

  /// Reject payment and mark booking as rejected.
  Future<void> rejectPayment(
    String paymentId,
    String bookingId, {
    String? reason,
  }) async {
    final reviewerId = _db.auth.currentUser!.id;

    await _db.from('payments').update({
      'status': 'rejected',
      'reviewed_by': reviewerId,
      'reviewed_at': DateTime.now().toIso8601String(),
      'rejection_reason': reason ?? 'Invalid receipt',
    }).eq('id', paymentId);

    await _db.from('bookings').update({
      'status': 'rejected',
    }).eq('id', bookingId);
  }

  /// Subscribe to new payment inserts for real-time badge updates.
  RealtimeChannel subscribeToPayments(void Function() onUpdate) {
    return _db
        .channel('cd-payments-new')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'payments',
          callback: (_) => onUpdate(),
        )
        .subscribe();
  }
}
