import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/cyber.dart';
import '../../owner/screens/owner_inventory_screen.dart'; // We can use the inventory provider here
import '../constants/cd_colors.dart';
import '../providers/cd_providers.dart';
import '../widgets/session_details_sheet.dart';
import '../../../core/providers/owner_dashboard_provider.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = context.locale.languageCode == 'ar';
    final bookingsAsync = ref.watch(todayBookingsProvider);
    final revenueAsync = ref.watch(todayRevenueProvider);
    final paymentsAsync = ref.watch(pendingPaymentsProvider);
    final cyberAsync = ref.watch(currentCyberProvider);

    final totalBookings = bookingsAsync.valueOrNull?.length ?? 0;
    final confirmedToday = bookingsAsync.valueOrNull
            ?.where((b) => b.isConfirmed)
            .length ??
        0;
    final revenue = revenueAsync.valueOrNull ?? 0.0;
    final pendingCount = paymentsAsync.valueOrNull?.length ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(kPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Title
          Text(
            'cyber.dashboard'.tr(),
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kSidebarText),
          ),
          Text(
            DateFormat('cyber.eeee_mmmm_d_yyyy'.tr(),
                    'cyber.en'.tr())
                .format(DateTime.now()),
            style: const TextStyle(fontSize: 12, color: kGray),
          ),
          const SizedBox(height: 20),



          // Stats Row
          Row(
            children: [
              _StatCard(
                icon: Icons.attach_money,
                label: isAr ? 'الإيرادات اليوم' : "Today's Revenue",
                value: revenueAsync.when(
                  data: (v) => '${v.toStringAsFixed(0)} EGP',
                  loading: () => '...',
                  error: (_, __) => '—',
                ),
                color: kTeal,
                bgColor: const Color(0xFFE1F5EE),
              ),
              const SizedBox(width: kGap),
              _StatCard(
                icon: Icons.book_online_outlined,
                label: isAr ? 'حجوزات اليوم' : "Today's Bookings",
                value: bookingsAsync.when(
                  data: (b) => '$totalBookings',
                  loading: () => '...',
                  error: (_, __) => '—',
                ),
                color: kPurple,
                bgColor: kPurpleLight,
              ),
              const SizedBox(width: kGap),
              _StatCard(
                icon: Icons.check_circle_outline,
                label: 'cyber.confirmed'.tr(),
                value: '$confirmedToday',
                color: kGreen,
                bgColor: const Color(0xFFE8F5E8),
              ),
              const SizedBox(width: kGap),
              _StatCard(
                icon: Icons.pending_actions_outlined,
                label: 'cyber.pending_review'.tr(),
                value: paymentsAsync.when(
                  data: (p) => '$pendingCount',
                  loading: () => '...',
                  error: (_, __) => '—',
                ),
                color: kAmber,
                bgColor: const Color(0xFFFAEEDA),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Quick Actions
          Text(
            'cyber.quick_actions'.tr(),
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: kSidebarText),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _QuickAction(
                icon: Icons.add_circle_outline,
                label: 'cyber.manual_booking'.tr(),
                color: kPurple,
                onTap: () => ref
                    .read(cdSelectedPageProvider.notifier)
                    .state = 'manual',
              ),
              const SizedBox(width: kGap),
              _QuickAction(
                icon: Icons.payments_outlined,
                label: 'cyber.review_payments_'.tr(args: [pendingCount.toString()]),
                color: kAmber,
                onTap: () => ref
                    .read(cdSelectedPageProvider.notifier)
                    .state = 'payments',
              ),
              const SizedBox(width: kGap),
              _QuickAction(
                icon: Icons.computer_outlined,
                label: 'cyber.station_status'.tr(),
                color: kTeal,
                onTap: () => ref
                    .read(cdSelectedPageProvider.notifier)
                    .state = 'stations',
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Today's Bookings
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isAr ? 'حجوزات اليوم' : "Today's Bookings",
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: kSidebarText),
              ),
              TextButton(
                onPressed: () => ref
                    .read(cdSelectedPageProvider.notifier)
                    .state = 'schedule',
                child: Text(
                  'cyber.view_full_schedule'.tr(),
                  style: const TextStyle(
                      fontSize: 12, color: kPurple),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          bookingsAsync.when(
            loading: () => const Center(
                child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            )),
            error: (e, _) => Text('Error: $e',
                style: const TextStyle(color: kRed)),
            data: (bookings) {
              if (bookings.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(kRadius),
                    border: Border.all(color: kBorder, width: 0.5),
                  ),
                  child: Center(
                    child: Text(
                      'cyber.no_bookings_today'.tr(),
                      style: const TextStyle(color: kGray, fontSize: 13),
                    ),
                  ),
                );
              }
              return Container(
                decoration: BoxDecoration(
                  color: kWhite,
                  borderRadius: BorderRadius.circular(kRadius),
                  border: Border.all(color: kBorder, width: 0.5),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: bookings.take(8).length,
                  separatorBuilder: (_, __) =>
                      Divider(height: 0.5, color: kBorder),
                  itemBuilder: (_, i) {
                    final b = bookings[i];
                    final statusColor = b.isConfirmed
                        ? kTeal
                        : b.isPendingPayment || b.isFeeUnderReview
                            ? kAmber
                            : b.isRejected || b.isCancelled
                                ? kRed
                                : kGray;

                    return InkWell(
                      onTap: () => _showSessionDetails(context, ref, b, isAr),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: statusColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    b.userName ??
                                        (b.source == 'manual'
                                            ? ('cyber.walkin'.tr())
                                            : ('cyber.app_user'.tr())),
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500),
                                  ),
                                  Text(
                                    '${DateFormat('HH:mm').format(b.startTime)} → ${DateFormat('HH:mm').format(b.endTime)}',
                                    style: const TextStyle(
                                        fontSize: 11, color: kGray),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${b.totalAmount.toInt()} EGP',
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: kTeal),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: statusColor.withValues(alpha: 0.1),
                                borderRadius:
                                    BorderRadius.circular(kRadiusSm),
                              ),
                              child: Text(
                                b.source == 'manual'
                                    ? ('cyber.manual'.tr())
                                    : b.statusDisplay,
                                style: TextStyle(
                                    fontSize: 10,
                                    color: statusColor,
                                    fontWeight: FontWeight.w500),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showSessionDetails(BuildContext context, WidgetRef ref, Booking booking, bool isAr) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => SessionDetailsSheet(
        booking: booking, 
        isAr: isAr,
        onAdded: () {
          ref.invalidate(todayBookingsProvider);
          ref.invalidate(todayRevenueProvider);
        },
      ),
    );
  }
}


class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: kWhite,
          borderRadius: BorderRadius.circular(kRadius),
          border: Border.all(color: kBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(kRadiusSm),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color),
            ),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(fontSize: 11, color: kGray)),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(kRadius),
          ),
          child: Row(
            children: [
              Icon(icon, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SubscriptionBanner extends StatelessWidget {
  final Cyber cyber;
  const _SubscriptionBanner({required this.cyber});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    switch (cyber.expiryUrgency) {
      case 3:
        color = kRed;
        icon = Icons.warning_amber_rounded;
        break;
      case 2:
        color = kAmber;
        icon = Icons.hourglass_bottom_rounded;
        break;
      case 1:
        color = kGreen;
        icon = Icons.verified_outlined;
        break;
      default:
        color = kGray;
        icon = Icons.schedule;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Subscription Plan: ${cyber.subscriptionPlan.toUpperCase()} (${cyber.subscriptionBilling})',
                  style: const TextStyle(
                    color: kSidebarText,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  cyber.expiryLabel,
                  style: TextStyle(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          if (cyber.expiryUrgency > 1)
            ElevatedButton(
              onPressed: () {
                // Here the owner could theoretically click to contact admin
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(kRadiusSm)),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                minimumSize: const Size(0, 36),
              ),
              child: const Text('Renew Now', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            ),
        ],
      ),
    );
  }
}
