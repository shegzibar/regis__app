import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/booking.dart';
import '../../../data/supabase/supabase_client.dart';
import '../repositories/cd_booking_repository.dart';
import 'cd_providers.dart';

// ─── Period Enum ────────────────────────────────────────────────────────────

enum AccountingPeriod { today, week, month }

// ─── Selected Period State ───────────────────────────────────────────────────

final accountingPeriodProvider =
    StateProvider<AccountingPeriod>((ref) => AccountingPeriod.today);

// ─── Bookings for Period ─────────────────────────────────────────────────────

final accountingBookingsProvider =
    FutureProvider.autoDispose<List<Booking>>((ref) async {
  final cyber = await ref.watch(currentCyberProvider.future);
  if (cyber == null) return [];

  final period = ref.watch(accountingPeriodProvider);
  final now = DateTime.now();
  late DateTime start;
  late DateTime end;

  switch (period) {
    case AccountingPeriod.today:
      start = DateTime(now.year, now.month, now.day);
      end = start.add(const Duration(days: 1));
      break;
    case AccountingPeriod.week:
      // Start from Monday of this week
      final weekday = now.weekday;
      start = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: weekday - 1));
      end = start.add(const Duration(days: 7));
      break;
    case AccountingPeriod.month:
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 1);
      break;
  }

  return CdBookingRepository().getBookingsForPeriod(
    cyberId: cyber.id,
    start: start,
    end: end,
  );
});

// ─── Summary Model ───────────────────────────────────────────────────────────

class AccountingSummary {
  final double totalRevenue;
  final double sessionRevenue;
  final double pointsRevenue;
  final int totalSessions;
  final int appSessions;
  final int walkInSessions;
  final Map<String, double> revenueByRoom;
  final Map<DateTime, double> revenueByDay;

  const AccountingSummary({
    required this.totalRevenue,
    required this.sessionRevenue,
    required this.pointsRevenue,
    required this.totalSessions,
    required this.appSessions,
    required this.walkInSessions,
    required this.revenueByRoom,
    required this.revenueByDay,
  });
}

// ─── Summary Provider ────────────────────────────────────────────────────────

final accountingPointsProvider = FutureProvider.autoDispose<double>((ref) async {
  final cyber = await ref.watch(currentCyberProvider.future);
  if (cyber == null) return 0.0;

  final period = ref.watch(accountingPeriodProvider);
  final now = DateTime.now();
  late DateTime start;
  late DateTime end;

  switch (period) {
    case AccountingPeriod.today:
      start = DateTime(now.year, now.month, now.day);
      end = start.add(const Duration(days: 1));
      break;
    case AccountingPeriod.week:
      final weekday = now.weekday;
      start = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: weekday - 1));
      end = start.add(const Duration(days: 7));
      break;
    case AccountingPeriod.month:
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 1);
      break;
  }

  // Fetch wallet_transactions where cyber_name == cyber.name and type == 'earned'
  final supabase = SupabaseService().client;
  final res = await supabase.from('wallet_transactions')
      .select('amount')
      .eq('cyber_name', cyber.name)
      .eq('type', 'earned')
      .gte('created_at', start.toUtc().toIso8601String())
      .lt('created_at', end.toUtc().toIso8601String());

  return (res as List).fold<double>(0.0, (sum, tx) => sum + (tx['amount'] as num).toDouble());
});

// ─── Summary Provider ────────────────────────────────────────────────────────

final accountingSummaryProvider =
    Provider.autoDispose<AsyncValue<AccountingSummary>>((ref) {
  final bookingsAsync = ref.watch(accountingBookingsProvider);
  final pointsAsync = ref.watch(accountingPointsProvider);

  if (bookingsAsync.isLoading || pointsAsync.isLoading) {
    return const AsyncValue.loading();
  }
  
  if (bookingsAsync.hasError) {
    return AsyncValue.error(bookingsAsync.error!, bookingsAsync.stackTrace!);
  }
  if (pointsAsync.hasError) {
    return AsyncValue.error(pointsAsync.error!, pointsAsync.stackTrace!);
  }

  final bookings = bookingsAsync.value!;
  final pointsRevenue = pointsAsync.value!;

  final confirmed = bookings
      .where((b) => b.isConfirmed || b.isCompleted)
      .toList();

  final totalRevenue = confirmed.fold<double>(
      0.0, (sum, b) => sum + b.roomCost);
  final sessionRevenue = totalRevenue;

  final appSessions = confirmed.where((b) => b.source == 'app').length;
  final walkInSessions = confirmed.where((b) => b.source == 'manual').length;

  // Revenue per room
  final revenueByRoom = <String, double>{};
  for (final b in confirmed) {
    final room = b.roomName ?? 'Unknown';
    revenueByRoom[room] = (revenueByRoom[room] ?? 0.0) + b.roomCost;
  }

  // Revenue per day (keyed to midnight of each day)
  final revenueByDay = <DateTime, double>{};
  for (final b in confirmed) {
    final day = DateTime(
      b.startTime.toLocal().year,
      b.startTime.toLocal().month,
      b.startTime.toLocal().day,
    );
    revenueByDay[day] = (revenueByDay[day] ?? 0.0) + b.roomCost;
  }

  return AsyncValue.data(AccountingSummary(
    totalRevenue: totalRevenue,
    sessionRevenue: sessionRevenue,
    pointsRevenue: pointsRevenue,
    totalSessions: confirmed.length,
    appSessions: appSessions,
    walkInSessions: walkInSessions,
    revenueByRoom: revenueByRoom,
    revenueByDay: revenueByDay,
  ));
});
