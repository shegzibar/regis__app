import '../models/payment.dart';
import '../supabase/supabase_client.dart';

class PaymentRepository {
  final SupabaseService _supabase = SupabaseService();

  // Get all payments for a user
  Future<List<Payment>> getUserPayments(String userId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((payment) => Payment.fromMap(payment))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user payments: $e');
    }
  }

  // Get payment by ID
  Future<Payment?> getPaymentById(String paymentId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select()
          .eq('id', paymentId)
          .maybeSingle();

      if (response != null) {
        return Payment.fromMap(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch payment: $e');
    }
  }

  // Get payment by booking ID
  Future<Payment?> getPaymentByBookingId(String bookingId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select()
          .eq('booking_id', bookingId)
          .maybeSingle();

      if (response != null) {
        return Payment.fromMap(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch payment by booking: $e');
    }
  }

  // Create payment receipt
  Future<Payment> createPayment({
    required String bookingId,
    required String userId,
    required double amount,
    required String method,
    String? screenshotUrl,
  }) async {
    try {
      final paymentData = {
        'booking_id': bookingId,
        'user_id': userId,
        'amount': amount,
        'method': method,
        'screenshot_url': screenshotUrl,
        'status': 'pending',
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('payments')
          .insert(paymentData)
          .select()
          .single();

      return Payment.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create payment: $e');
    }
  }

  // Update payment status (admin only)
  Future<Payment> updatePaymentStatus({
    required String paymentId,
    required String status,
    String? rejectionReason,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': status,
        'reviewed_at': DateTime.now().toIso8601String(),
      };
      if (rejectionReason != null) {
        updateData['rejection_reason'] = rejectionReason;
      }

      final response = await _supabase
          .from('payments')
          .update(updateData)
          .eq('id', paymentId)
          .select()
          .single();

      return Payment.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update payment status: $e');
    }
  }

  // Get pending payments (admin/manager)
  Future<List<Payment>> getPendingPayments() async {
    try {
      final response = await _supabase
          .from('payments')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: true);

      return (response as List)
          .map((payment) => Payment.fromMap(payment))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pending payments: $e');
    }
  }

  // Get approved payments
  Future<List<Payment>> getApprovedPayments(String userId) async {
    try {
      final response = await _supabase
          .from('payments')
          .select()
          .eq('user_id', userId)
          .eq('status', 'approved')
          .order('created_at', ascending: false);

      return (response as List)
          .map((payment) => Payment.fromMap(payment))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch approved payments: $e');
    }
  }

  // Delete payment
  Future<void> deletePayment(String paymentId) async {
    try {
      await _supabase.from('payments').delete().eq('id', paymentId);
    } catch (e) {
      throw Exception('Failed to delete payment: $e');
    }
  }
}
