import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/booking.dart';
import '../constants/cd_colors.dart';
import '../providers/cd_providers.dart';
import '../widgets/session_details_sheet.dart';

class SchedulePage extends ConsumerStatefulWidget {
  const SchedulePage({super.key});

  @override
  ConsumerState<SchedulePage> createState() => _SchedulePageState();
}

class _SchedulePageState extends ConsumerState<SchedulePage> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(allBookingsProvider);
    final isAr = context.locale.languageCode == 'ar';

    return Scaffold(
      backgroundColor: kBg,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header & Tabs
          Container(
            padding: const EdgeInsets.only(top: kPadding, left: kPadding, right: kPadding, bottom: 8),
            decoration: BoxDecoration(
              color: kWhite,
              border: Border(bottom: BorderSide(color: kBorder, width: 0.5)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'cyber.schedule'.tr(),
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: kSidebarText,
                          ),
                        ),
                        Text(
                          'cyber.manage_your_daily_weekly'.tr(),
                          style: const TextStyle(fontSize: 13, color: kGray),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: kPurple),
                      tooltip: 'cyber.refresh'.tr(),
                      onPressed: () => ref.invalidate(allBookingsProvider),
                      style: IconButton.styleFrom(
                        backgroundColor: kPurple.withValues(alpha: 0.1),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                TabBar(
                  controller: _tabController,
                  isScrollable: true,
                  labelColor: kPurple,
                  unselectedLabelColor: kGray,
                  indicatorColor: kPurple,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  dividerColor: Colors.transparent,
                  tabAlignment: TabAlignment.start,
                  tabs: [
                    Tab(text: 'cyber.today'.tr()),
                    Tab(text: 'cyber.this_week'.tr()),
                    Tab(text: 'cyber.this_month'.tr()),
                  ],
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: bookingsAsync.when(
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (allBookings) {
                return TabBarView(
                  controller: _tabController,
                  children: [
                    _buildTodayView(allBookings, isAr),
                    _buildWeeklyView(allBookings, isAr),
                    _buildMonthlyView(allBookings, isAr),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isAr, String message) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Container(
        margin: const EdgeInsets.all(kPadding),
        padding: const EdgeInsets.all(40),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(color: kBorder, width: 0.5),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kPurple.withValues(alpha: 0.05),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.event_busy, size: 48, color: kGray),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: kSidebarText,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'cyber.no_bookings_found_for'.tr(),
                style: const TextStyle(fontSize: 13, color: kGray),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Today View (Grouped by Hour) ──────────────────────────────────────────

  Widget _buildTodayView(List<Booking> allBookings, bool isAr) {
    final now = DateTime.now();
    final todayBookings = allBookings.where((b) {
      final start = b.startTime.toLocal();
      return start.year == now.year && start.month == now.month && start.day == now.day;
    }).toList();

    if (todayBookings.isEmpty) {
      return _buildEmptyState(isAr, 'cyber.no_bookings_today'.tr());
    }

    // Group by hour
    final grouped = <int, List<Booking>>{};
    for (var b in todayBookings) {
      final h = b.startTime.toLocal().hour;
      if (!grouped.containsKey(h)) grouped[h] = [];
      grouped[h]!.add(b);
    }
    final sortedHours = grouped.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(allBookingsProvider),
      child: ListView.builder(
        padding: const EdgeInsets.all(kPadding),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: sortedHours.length,
        itemBuilder: (context, i) {
          final h = sortedHours[i];
          final hourBookings = grouped[h]!;
          final timeLabel = DateFormat('hh:00 a').format(DateTime(2000, 1, 1, h));

          return _buildGroupContainer(
            title: timeLabel,
            bookings: hourBookings,
            isAr: isAr,
          );
        },
      ),
    );
  }

  // ─── Weekly View (Grouped by Day) ──────────────────────────────────────────

  Widget _buildWeeklyView(List<Booking> allBookings, bool isAr) {
    final now = DateTime.now();
    final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
    final endOfWeek = startOfWeek.add(const Duration(days: 6, hours: 23, minutes: 59));

    final weeklyBookings = allBookings.where((b) {
      final start = b.startTime.toLocal();
      return start.isAfter(startOfWeek.subtract(const Duration(days: 1))) && start.isBefore(endOfWeek);
    }).toList();

    if (weeklyBookings.isEmpty) {
      return _buildEmptyState(isAr, 'cyber.no_bookings_this_week'.tr());
    }

    // Group by date string (e.g. "2023-10-12")
    final grouped = <String, List<Booking>>{};
    for (var b in weeklyBookings) {
      final start = b.startTime.toLocal();
      final dateKey = DateFormat('yyyy-MM-dd').format(start);
      if (!grouped.containsKey(dateKey)) grouped[dateKey] = [];
      grouped[dateKey]!.add(b);
    }
    
    final sortedDates = grouped.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(allBookingsProvider),
      child: ListView.builder(
        padding: const EdgeInsets.all(kPadding),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: sortedDates.length,
        itemBuilder: (context, i) {
          final dateKey = sortedDates[i];
          final dayBookings = grouped[dateKey]!;
          final dt = DateTime.parse(dateKey);
          
          String displayTitle;
          if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
             displayTitle = 'cyber.today'.tr();
          } else {
             displayTitle = DateFormat('EEEE, MMM d').format(dt);
          }

          return _buildGroupContainer(
            title: displayTitle,
            bookings: dayBookings,
            isAr: isAr,
          );
        },
      ),
    );
  }

  // ─── Monthly View (Grouped by Day) ─────────────────────────────────────────

  Widget _buildMonthlyView(List<Booking> allBookings, bool isAr) {
    final now = DateTime.now();
    
    final monthlyBookings = allBookings.where((b) {
      final start = b.startTime.toLocal();
      return start.year == now.year && start.month == now.month;
    }).toList();

    if (monthlyBookings.isEmpty) {
      return _buildEmptyState(isAr, 'cyber.no_bookings_this_month'.tr());
    }

    final grouped = <String, List<Booking>>{};
    for (var b in monthlyBookings) {
      final start = b.startTime.toLocal();
      final dateKey = DateFormat('yyyy-MM-dd').format(start);
      if (!grouped.containsKey(dateKey)) grouped[dateKey] = [];
      grouped[dateKey]!.add(b);
    }
    
    final sortedDates = grouped.keys.toList()..sort();

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(allBookingsProvider),
      child: ListView.builder(
        padding: const EdgeInsets.all(kPadding),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: sortedDates.length,
        itemBuilder: (context, i) {
          final dateKey = sortedDates[i];
          final dayBookings = grouped[dateKey]!;
          final dt = DateTime.parse(dateKey);
          
          String displayTitle;
          if (dt.year == now.year && dt.month == now.month && dt.day == now.day) {
             displayTitle = 'cyber.today'.tr();
          } else {
             displayTitle = DateFormat('EEE, MMM d').format(dt);
          }

          return _buildGroupContainer(
            title: displayTitle,
            bookings: dayBookings,
            isAr: isAr,
          );
        },
      ),
    );
  }

  // ─── UI Helpers ────────────────────────────────────────────────────────────

  Widget _buildGroupContainer({
    required String title,
    required List<Booking> bookings,
    required bool isAr,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kBorder, width: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: kBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(kRadius)),
              border: Border(bottom: BorderSide(color: kBorder, width: 0.5)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            child: Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 14, color: kPurple),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kPurple,
                  ),
                ),
              ],
            ),
          ),
          ...bookings.asMap().entries.map((entry) {
            final idx = entry.key;
            final b = entry.value;
            return Column(
              children: [
                _buildBookingCard(context, ref, b, isAr),
                if (idx < bookings.length - 1)
                  const Divider(height: 0.5, thickness: 0.5),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildBookingCard(BuildContext context, WidgetRef ref, Booking b, bool isAr) {
    final statusColor = b.isConfirmed
        ? kTeal
        : b.isPendingPayment || b.isFeeUnderReview
            ? kAmber
            : b.isRejected || b.isCancelled
                ? kRed
                : kGray;

    return InkWell(
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => SessionDetailsSheet(
            booking: b, 
            isAr: isAr,
            onAdded: () {
              ref.invalidate(allBookingsProvider);
            },
          ),
        );
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Time line
            SizedBox(
              width: 50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(DateFormat('HH:mm').format(b.startTime.toLocal()),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold, color: kSidebarText)),
                  const SizedBox(height: 2),
                  Text(DateFormat('HH:mm').format(b.endTime.toLocal()),
                      style: const TextStyle(fontSize: 11, color: kGray)),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Vertical Status Line
            Container(
              width: 3,
              height: 42,
              decoration: BoxDecoration(
                color: statusColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        b.userName ??
                            (b.source == 'manual'
                                ? ('cyber.walkin'.tr())
                                : ('cyber.app_user'.tr())),
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600, color: kSidebarText),
                      ),
                      Text(
                        '${b.totalAmount.toInt()} EGP',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: kTeal),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: kBg,
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: kBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.computer, size: 12, color: kGray),
                            const SizedBox(width: 4),
                            Text(
                              b.stationName != null 
                                  ? '${b.stationName} ${b.roomName != null ? '(${b.roomName})' : ''}'
                                  : ('cyber.station_booked'.tr()),
                              style: const TextStyle(fontSize: 11, color: kGray, fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          b.source == 'manual'
                              ? ('cyber.manual'.tr())
                              : b.statusDisplay,
                          style: TextStyle(
                              fontSize: 11,
                              color: statusColor,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

