import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/booking.dart';
import '../../data/repositories/booking_repository.dart';
import 'auth_provider.dart';

final bookingRepositoryProvider = Provider<BookingRepository>((ref) {
  return BookingRepository();
});

// Current user's bookings (My Bookings screen)
final userBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];
  return ref.read(bookingRepositoryProvider).getUserBookings(user.id);
});

// Bookings for the manager review queue
final pendingReviewBookingsProvider = FutureProvider<List<Booking>>((ref) async {
  final repo = ref.read(bookingRepositoryProvider);
  // Fetch both pending_payment and fee_under_review statuses for queue
  final response = await SupabaseBookingHelper.getAllPendingForManager();
  return response;
});

// Booking notifier for creating a booking
final bookingNotifierProvider =
    AsyncNotifierProvider<BookingNotifier, void>(() => BookingNotifier());

class BookingNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Booking> createBooking({
    required String stationId,
    required DateTime startTime,
    required DateTime endTime,
    required double durationHours,
    required double totalAmount,
    String? notes,
  }) async {
    final user = ref.read(authStateProvider);
    if (user == null) throw Exception('Not authenticated');

    return ref.read(bookingRepositoryProvider).createBooking(
          userId: user.id,
          stationId: stationId,
          startTime: startTime,
          endTime: endTime,
          durationHours: durationHours,
          totalAmount: totalAmount,
          notes: notes,
        );
  }

  Future<Booking> cancelBooking(String bookingId) async {
    final booking = await ref
        .read(bookingRepositoryProvider)
        .cancelBooking(bookingId);
    ref.invalidate(userBookingsProvider);
    return booking;
  }

  Future<Booking> updateStatus(String bookingId, String newStatus) async {
    final booking = await ref
        .read(bookingRepositoryProvider)
        .updateBookingStatus(bookingId, newStatus);
    ref.invalidate(userBookingsProvider);
    return booking;
  }
}

// Helper to fetch all bookings with pending statuses for manager view
class SupabaseBookingHelper {
  static Future<List<Booking>> getAllPendingForManager() async {
    final BookingRepository repo = BookingRepository();
    // We re-use an internal query for manager role
    try {
      final response = await repo.getPendingPaymentBookingsForManager();
      return response;
    } catch (e) {
      return [];
    }
  }
}
