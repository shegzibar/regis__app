import '../models/booking.dart';
import '../supabase/supabase_client.dart';

class BookingRepository {
  final SupabaseService _supabase = SupabaseService();

  // Get all bookings for a user
  Future<List<Booking>> getUserBookings(String userId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((booking) => Booking.fromMap(booking))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch user bookings: $e');
    }
  }

  // Get booking by ID
  Future<Booking?> getBookingById(String bookingId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('id', bookingId)
          .maybeSingle();

      if (response != null) {
        return Booking.fromMap(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch booking: $e');
    }
  }

  // Get bookings for a station (to check availability)
  Future<List<Booking>> getStationBookings(
    String stationId, {
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    try {
      var query = _supabase
          .from('bookings')
          .select()
          .eq('station_id', stationId)
          .eq('status', 'confirmed');

      if (startDate != null) {
        query = query.gte('start_time', startDate.toIso8601String());
      }

      if (endDate != null) {
        query = query.lte('end_time', endDate.toIso8601String());
      }

      final response = await query;

      return (response as List)
          .map((booking) => Booking.fromMap(booking))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch station bookings: $e');
    }
  }

  // Create booking
  Future<Booking> createBooking({
    required String userId,
    required String stationId,
    required DateTime startTime,
    required DateTime endTime,
    required double durationHours,
    required double totalAmount,
    double bookingFee = 5.0,
    String? notes,
  }) async {
    try {
      final bookingData = {
        'user_id': userId,
        'station_id': stationId,
        'start_time': startTime.toIso8601String(),
        'end_time': endTime.toIso8601String(),
        'duration_hours': durationHours,
        'total_amount': totalAmount,
        'booking_fee': bookingFee,
        'status': 'pending_payment',
        'notes': notes,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('bookings')
          .insert(bookingData)
          .select()
          .single();

      return Booking.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create booking: $e');
    }
  }

  // Update booking status
  Future<Booking> updateBookingStatus(
    String bookingId,
    String newStatus, {
    DateTime? confirmedAt,
    DateTime? expiresAt,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'status': newStatus,
      };
      if (confirmedAt != null) {
        updateData['confirmed_at'] = confirmedAt.toIso8601String();
      }
      if (expiresAt != null) {
        updateData['expires_at'] = expiresAt.toIso8601String();
      }

      final response = await _supabase
          .from('bookings')
          .update(updateData)
          .eq('id', bookingId)
          .select()
          .single();

      return Booking.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update booking status: $e');
    }
  }

  // Cancel booking
  Future<Booking> cancelBooking(String bookingId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .update({'status': 'cancelled'})
          .eq('id', bookingId)
          .select()
          .single();

      return Booking.fromMap(response);
    } catch (e) {
      throw Exception('Failed to cancel booking: $e');
    }
  }

  // Get user booking history (completed bookings)
  Future<List<Booking>> getUserBookingHistory(String userId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('user_id', userId)
          .eq('status', 'completed')
          .order('created_at', ascending: false);

      return (response as List)
          .map((booking) => Booking.fromMap(booking))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch booking history: $e');
    }
  }

  // Get pending payments
  Future<List<Booking>> getPendingPaymentBookings(String userId) async {
    try {
      final response = await _supabase
          .from('bookings')
          .select()
          .eq('user_id', userId)
          .inFilter('status', ['pending_payment', 'fee_under_review']).order(
              'created_at',
              ascending: false);

      return (response as List)
          .map((booking) => Booking.fromMap(booking))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch pending payments: $e');
    }
  }

  // Delete booking
  Future<void> deleteBooking(String bookingId) async {
    try {
      await _supabase.from('bookings').delete().eq('id', bookingId);
    } catch (e) {
      throw Exception('Failed to delete booking: $e');
    }
  }
}
