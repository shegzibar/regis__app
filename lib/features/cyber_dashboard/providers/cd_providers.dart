import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/cyber.dart';
import '../../../data/models/room.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/user.dart';
import '../models/station_live.dart';
import '../repositories/cd_cyber_repository.dart';
import '../repositories/cd_booking_repository.dart';
import '../repositories/cd_payment_repository.dart';

// ─── Navigation ─────────────────────────────────────────────────────────────

/// Currently selected sidebar page key.
final cdSelectedPageProvider = StateProvider<String>((ref) => 'home');

// ─── Repositories ───────────────────────────────────────────────────────────

final cdCyberRepoProvider =
    Provider<CdCyberRepository>((ref) => CdCyberRepository());

final cdBookingRepoProvider =
    Provider<CdBookingRepository>((ref) => CdBookingRepository());

final cdPaymentRepoProvider =
    Provider<CdPaymentRepository>((ref) => CdPaymentRepository());

// ─── Core Data ──────────────────────────────────────────────────────────────

/// The cyber owned by the current logged-in user. Loaded once on start-up.
final currentCyberProvider = FutureProvider<Cyber?>((ref) async {
  final userId = Supabase.instance.client.auth.currentUser?.id;
  if (userId == null) return null;
  return ref.read(cdCyberRepoProvider).getCyberByOwner(userId);
});

/// Active rooms for the current cyber.
final cyberRoomsProvider = FutureProvider<List<Room>>((ref) async {
  final cyber = await ref.watch(currentCyberProvider.future);
  if (cyber == null) return [];
  return ref.read(cdCyberRepoProvider).getRooms(cyber.id);
});

/// Workers (users with cyber_id matching current cyber).
final cyberWorkersProvider = FutureProvider<List<AppUser>>((ref) async {
  final cyber = await ref.watch(currentCyberProvider.future);
  if (cyber == null) return [];
  return ref.read(cdCyberRepoProvider).getWorkers(cyber.id);
});

// ─── Bookings & Revenue ─────────────────────────────────────────────────────

/// All of today's bookings for this cyber — updates in real-time via Supabase.
final todayBookingsProvider =
    FutureProvider.autoDispose<List<Booking>>((ref) async {
  final cyber = await ref.watch(currentCyberProvider.future);
  if (cyber == null) return [];

  // Subscribe to booking changes and invalidate to re-fetch instantly
  final channel = ref
      .read(cdBookingRepoProvider)
      .subscribeToBookings(cyber.id, () => ref.invalidateSelf());
  ref.onDispose(() => Supabase.instance.client.removeChannel(channel));

  return ref.read(cdBookingRepoProvider).getTodayBookings(cyber.id);
});

/// All bookings for this cyber (used for weekly/monthly tabs)
final allBookingsProvider =
    FutureProvider.autoDispose<List<Booking>>((ref) async {
  final cyber = await ref.watch(currentCyberProvider.future);
  if (cyber == null) return [];

  // Reusing the same channel invalidation approach
  final channel = ref
      .read(cdBookingRepoProvider)
      .subscribeToBookings(cyber.id, () => ref.invalidateSelf());
  ref.onDispose(() => Supabase.instance.client.removeChannel(channel));

  return ref.read(cdBookingRepoProvider).getAllBookings(cyber.id);
});

/// Total confirmed revenue for today.
final todayRevenueProvider = FutureProvider.autoDispose<double>((ref) async {
  // Watch bookings so revenue auto-updates when bookings change
  ref.watch(todayBookingsProvider);
  final cyber = await ref.watch(currentCyberProvider.future);
  if (cyber == null) return 0.0;
  return ref.read(cdBookingRepoProvider).getTodayRevenue(cyber.id);
});

// ─── Payments ───────────────────────────────────────────────────────────────

/// Pending payment items — updates in real-time via Supabase.
final pendingPaymentsProvider =
    FutureProvider.autoDispose<List<CdPaymentItem>>((ref) async {
  final cyber = await ref.watch(currentCyberProvider.future);
  if (cyber == null) return [];

  // Re-fetch whenever bookings change (payments are tied to bookings)
  final channel = ref
      .read(cdBookingRepoProvider)
      .subscribeToBookings(cyber.id, () => ref.invalidateSelf());
  ref.onDispose(() => Supabase.instance.client.removeChannel(channel));

  return ref.read(cdPaymentRepoProvider).getPendingPayments(cyber.id);
});

/// Count of pending payments — derived from pendingPaymentsProvider so the
/// sidebar badge is always correct on startup without a realtime event.
final pendingPaymentsCountProvider = Provider<int>((ref) {
  return ref.watch(pendingPaymentsProvider).valueOrNull?.length ?? 0;
});

// ─── Live Station Status ─────────────────────────────────────────────────────

/// Live station status for a given room ID — invalidated on booking changes.
final stationStatusProvider =
    FutureProvider.family<List<StationLive>, String>((ref, roomId) async {
  return ref.read(cdBookingRepoProvider).getLiveStationStatus(roomId);
});
