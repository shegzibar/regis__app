import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../data/models/booking.dart';
import '../../../data/supabase/supabase_client.dart';
import '../repositories/cd_booking_repository.dart';
import 'cd_providers.dart';

// ─── Period Enum ────────────────────────────────────────────────────────────

enum AccountingPeriod { today, week, month, year }

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
      final weekday = now.weekday;
      start = DateTime(now.year, now.month, now.day)
          .subtract(Duration(days: weekday - 1));
      end = start.add(const Duration(days: 7));
      break;
    case AccountingPeriod.month:
      start = DateTime(now.year, now.month, 1);
      end = DateTime(now.year, now.month + 1, 1);
      break;
    case AccountingPeriod.year:
      start = DateTime(now.year, 1, 1);
      end = DateTime(now.year + 1, 1, 1);
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
  final double inventoryRevenue;
  final double inventoryCost;
  final double inventoryProfit;
  final int totalSessions;
  final int appSessions;
  final int walkInSessions;
  final Map<String, double> revenueByRoom;
  final Map<DateTime, double> revenueByDay;
  final AccountingPeriod period;

  const AccountingSummary({
    required this.totalRevenue,
    required this.sessionRevenue,
    required this.pointsRevenue,
    required this.inventoryRevenue,
    required this.inventoryCost,
    required this.inventoryProfit,
    required this.totalSessions,
    required this.appSessions,
    required this.walkInSessions,
    required this.revenueByRoom,
    required this.revenueByDay,
    required this.period,
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
    case AccountingPeriod.year:
      start = DateTime(now.year, 1, 1);
      end = DateTime(now.year + 1, 1, 1);
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

final accountingInventorySalesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final bookingsAsync = ref.watch(accountingBookingsProvider);
  if (bookingsAsync.isLoading || bookingsAsync.hasError) return [];
  
  final bookings = bookingsAsync.value!;
  if (bookings.isEmpty) return [];

  // Group booking IDs into chunks of 100 to avoid URL length issues
  final bookingIds = bookings.map((b) => b.id).toList();
  final supabase = SupabaseService().client;
  
  List<Map<String, dynamic>> allItems = [];
  for (var i = 0; i < bookingIds.length; i += 100) {
    final chunk = bookingIds.skip(i).take(100).toList();
    final res = await supabase.from('booking_items')
        .select('total_price, cost_at_time, quantity')
        .inFilter('booking_id', chunk);
    allItems.addAll(List<Map<String, dynamic>>.from(res as List));
  }

  return allItems;
});

// ─── Summary Provider ────────────────────────────────────────────────────────

final accountingSummaryProvider =
    Provider.autoDispose<AsyncValue<AccountingSummary>>((ref) {
  final bookingsAsync = ref.watch(accountingBookingsProvider);
  final pointsAsync = ref.watch(accountingPointsProvider);
  final inventoryAsync = ref.watch(accountingInventorySalesProvider);
  final period = ref.watch(accountingPeriodProvider);

  if (bookingsAsync.isLoading || pointsAsync.isLoading || inventoryAsync.isLoading) {
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
  final inventoryItems = inventoryAsync.value ?? [];

  double inventoryRevenue = 0.0;
  double inventoryCost = 0.0;
  for (final item in inventoryItems) {
    inventoryRevenue += (item['total_price'] as num?)?.toDouble() ?? 0.0;
    final costAtTime = (item['cost_at_time'] as num?)?.toDouble() ?? 0.0;
    final quantity = (item['quantity'] as num?)?.toInt() ?? 0;
    inventoryCost += costAtTime * quantity;
  }
  final inventoryProfit = inventoryRevenue - inventoryCost;

  final confirmed = bookings
      .where((b) => b.isConfirmed || b.isCompleted)
      .toList();

  final sessionRevenue = confirmed.fold<double>(
      0.0, (sum, b) => sum + b.roomCost);
      
  final totalRevenue = sessionRevenue + inventoryRevenue;

  final appSessions = confirmed.where((b) => b.source == 'app').length;
  final walkInSessions = confirmed.where((b) => b.source == 'manual').length;

  // Revenue per room
  final revenueByRoom = <String, double>{};
  for (final b in confirmed) {
    final room = b.roomName ?? 'Unknown';
    revenueByRoom[room] = (revenueByRoom[room] ?? 0.0) + b.roomCost;
  }

  // Revenue per day/month depending on period
  // For year: key is first day of each month. For others: key is midnight of each day.
  final revenueByDay = <DateTime, double>{};
  for (final b in confirmed) {
    final localTime = b.startTime.toLocal();
    final DateTime key;
    if (period == AccountingPeriod.year) {
      key = DateTime(localTime.year, localTime.month, 1);
    } else {
      key = DateTime(localTime.year, localTime.month, localTime.day);
    }
    revenueByDay[key] = (revenueByDay[key] ?? 0.0) + b.roomCost;
  }

  return AsyncValue.data(AccountingSummary(
    totalRevenue: totalRevenue,
    sessionRevenue: sessionRevenue,
    pointsRevenue: pointsRevenue,
    inventoryRevenue: inventoryRevenue,
    inventoryCost: inventoryCost,
    inventoryProfit: inventoryProfit,
    totalSessions: confirmed.length,
    appSessions: appSessions,
    walkInSessions: walkInSessions,
    revenueByRoom: revenueByRoom,
    revenueByDay: revenueByDay,
    period: period,
  ));
});
