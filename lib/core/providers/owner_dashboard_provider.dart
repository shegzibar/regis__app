import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cyber.dart';
import '../../data/models/owner_booking_item.dart';
import '../../data/repositories/owner_repository.dart';
import 'auth_provider.dart';

final ownerRepositoryProvider = Provider((ref) => OwnerRepository());

final ownerCybersProvider = FutureProvider.autoDispose<List<Cyber>>((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];
  return ref.read(ownerRepositoryProvider).getOwnerCybers(user.id);
});

/// True when the logged-in owner already has at least one cyber center.
final ownerHasCyberProvider = Provider<bool?>((ref) {
  final cybers = ref.watch(ownerCybersProvider);
  return cybers.when(
    data: (list) => list.isNotEmpty,
    loading: () => null,
    error: (_, __) => false,
  );
});

final ownerPrimaryCyberProvider = Provider<Cyber?>((ref) {
  final cybers = ref.watch(ownerCybersProvider).valueOrNull;
  if (cybers == null || cybers.isEmpty) return null;
  return cybers.first;
});

final ownerDashboardStatsProvider =
    FutureProvider.autoDispose<OwnerDashboardStats>((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return const OwnerDashboardStats();
  return ref.read(ownerRepositoryProvider).getDashboardStats(user.id);
});

final ownerTimelineStreamProvider =
    StreamProvider.autoDispose<List<OwnerBookingItem>>((ref) {
  final user = ref.watch(authStateProvider);
  if (user == null) return const Stream.empty();
  return ref.read(ownerRepositoryProvider).watchOwnerTodayBookings(user.id);
});

final ownerRoomsProvider = FutureProvider.autoDispose((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];
  return ref.read(ownerRepositoryProvider).getOwnerRooms(user.id);
});
