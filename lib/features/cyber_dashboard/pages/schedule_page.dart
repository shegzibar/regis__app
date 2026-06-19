import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/booking.dart';
import '../constants/cd_colors.dart';
import '../providers/cd_providers.dart';

class SchedulePage extends ConsumerWidget {
  const SchedulePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(cdLangProvider);
    final isAr = lang == 'ar';
    final bookingsAsync = ref.watch(todayBookingsProvider);

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(todayBookingsProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(kPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Page Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAr ? 'الجدول الزمني لليوم' : "Today's Schedule",
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: kSidebarText),
                    ),
                    Text(
                      isAr ? 'جميع حجوزات اليوم مرتبة حسب الوقت' : 'All bookings for today ordered by time',
                      style: const TextStyle(fontSize: 12, color: kGray),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.refresh, color: kPurple),
                  tooltip: isAr ? 'تحديث' : 'Refresh',
                  onPressed: () => ref.invalidate(todayBookingsProvider),
                ),
              ],
            ),
            const SizedBox(height: 20),

            bookingsAsync.when(
              loading: () => const Center(
                  child: Padding(
                padding: EdgeInsets.all(40),
                child: CircularProgressIndicator(),
              )),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (bookings) {
                if (bookings.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(40),
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.circular(kRadius),
                      border: Border.all(color: kBorder, width: 0.5),
                    ),
                    child: Center(
                      child: Column(
                        children: [
                          const Icon(Icons.event_available,
                              size: 48, color: kGray),
                          const SizedBox(height: 12),
                          Text(
                            isAr
                                ? 'لا توجد حجوزات اليوم'
                                : 'No bookings today',
                            style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: kSidebarText),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                // Group by hour
                final grouped = <int, List<Booking>>{};
                for (var b in bookings) {
                  final h = b.startTime.toLocal().hour;
                  if (!grouped.containsKey(h)) grouped[h] = [];
                  grouped[h]!.add(b);
                }

                final sortedHours = grouped.keys.toList()..sort();

                return Container(
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(kRadius),
                    border: Border.all(color: kBorder, width: 0.5),
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: sortedHours.length,
                    itemBuilder: (context, i) {
                      final h = sortedHours[i];
                      final hourBookings = grouped[h]!;
                      final timeLabel = DateFormat('hh:00 a')
                          .format(DateTime(2000, 1, 1, h));

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: double.infinity,
                            color: kBg,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 8),
                            child: Text(
                              timeLabel,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: kPurple),
                            ),
                          ),
                          ...hourBookings.map((b) => _buildBookingCard(b, isAr)),
                          if (i < sortedHours.length - 1)
                            const Divider(height: 0.5, thickness: 0.5),
                        ],
                      );
                    },
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking b, bool isAr) {
    final statusColor = b.isConfirmed
        ? kTeal
        : b.isPendingPayment || b.isFeeUnderReview
            ? kAmber
            : b.isRejected || b.isCancelled
                ? kRed
                : kGray;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time line
          SizedBox(
            width: 50,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('HH:mm').format(b.startTime),
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.bold)),
                const SizedBox(height: 2),
                Text(DateFormat('HH:mm').format(b.endTime),
                    style: const TextStyle(fontSize: 11, color: kGray)),
              ],
            ),
          ),
          const SizedBox(width: 12),

          // Divider
          Container(
            width: 2,
            height: 40,
            color: statusColor.withValues(alpha: 0.5),
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
                              ? (isAr ? 'عميل حضوري' : 'Walk-in')
                              : (isAr ? 'مستخدم تطبيق' : 'App user')),
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600),
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: kBg,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: kBorder),
                      ),
                      child: Text(
                        b.stationName != null 
                            ? '${b.stationName} ${b.roomName != null ? '(${b.roomName})' : ''}'
                            : (isAr ? 'محطة محجوزة' : 'Station booked'),
                        style: const TextStyle(fontSize: 10, color: kGray),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        b.source == 'manual'
                            ? (isAr ? 'يدوي' : 'Manual')
                            : b.statusDisplay,
                        style: TextStyle(
                            fontSize: 10,
                            color: statusColor,
                            fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
