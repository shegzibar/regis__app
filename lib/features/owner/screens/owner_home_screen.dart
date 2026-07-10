import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/owner_dashboard_provider.dart';
import '../../../data/models/owner_booking_item.dart';
import '../utils/owner_format_utils.dart';

class OwnerHomeScreen extends ConsumerWidget {
  const OwnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(ownerDashboardStatsProvider);
    final timelineAsync = ref.watch(ownerTimelineStreamProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(ownerDashboardStatsProvider);
        ref.invalidate(ownerTimelineStreamProvider);
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            statsAsync.when(
              loading: () => const _MetricsShimmer(),
              error: (_, __) => const SizedBox.shrink(),
              data: (stats) => _MetricsRow(stats: stats),
            ),
            const SizedBox(height: 12),
            LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 720;
                if (wide) {
                  return IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          flex: 5,
                          child: _QuickActionsPanel(
                            pendingReceipts: statsAsync.valueOrNull
                                    ?.pendingReceipts ??
                                0,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 6,
                          child: timelineAsync.when(
                            loading: () => const _TimelineLoading(),
                            error: (_, __) => _TimelinePanel(items: const []),
                            data: (items) => _TimelinePanel(items: items),
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return Column(
                  children: [
                    timelineAsync.when(
                      loading: () => const _TimelineLoading(),
                      error: (_, __) => _TimelinePanel(items: const []),
                      data: (items) => _TimelinePanel(items: items),
                    ),
                    const SizedBox(height: 12),
                    _QuickActionsPanel(
                      pendingReceipts:
                          statsAsync.valueOrNull?.pendingReceipts ?? 0,
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricsRow extends StatelessWidget {
  final OwnerDashboardStats stats;
  const _MetricsRow({required this.stats});

  @override
  Widget build(BuildContext context) {
    final egp = 'common.egp'.tr();
    final changeSign = stats.revenueChangePercent >= 0 ? '+' : '';
    final changeText =
        '$changeSign${formatLocalizedNumber(stats.revenueChangePercent.abs(), context)}% '
        '${'owner_dashboard.revenue_vs_yesterday'.tr()}';

    return Row(
      children: [
        Expanded(
          child: _MetricCard(
            title: 'owner_dashboard.today_revenue'.tr(),
            value:
                '${formatLocalizedNumber(stats.todayRevenue.round(), context)} $egp',
            subtitle: changeText,
            subtitleColor: AppColors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            title: 'owner_dashboard.today_bookings'.tr(),
            value: formatLocalizedNumber(stats.todayBookings, context),
            subtitle:
                '${formatLocalizedNumber(stats.confirmedToday, context)} ${'owner_dashboard.status_confirmed'.tr()} • '
                '${formatLocalizedNumber(stats.pendingToday, context)} ${'owner_dashboard.status_pending_payment'.tr().split(' ').first}',
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            title: 'owner_dashboard.active_now'.tr(),
            value:
                '${formatLocalizedNumber(stats.activeStations, context)}/${formatLocalizedNumber(stats.totalStations, context)}',
            subtitle: 'owner_dashboard.station_busy'.tr(),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _MetricCard(
            title: 'owner_dashboard.manual_today'.tr(),
            value: formatLocalizedNumber(stats.manualBookingsToday, context),
            subtitle: 'owner_dashboard.walk_in_label'.tr(),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final Color? subtitleColor;

  const _MetricCard({
    required this.title,
    required this.value,
    required this.subtitle,
    this.subtitleColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1D21),
              height: 1.1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10,
              color: subtitleColor ?? AppColors.textMuted,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelinePanel extends StatelessWidget {
  final List<OwnerBookingItem> items;
  const _TimelinePanel({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
            child: Text(
              'owner_dashboard.today_schedule'.tr(),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: Color(0xFF1A1D21),
              ),
            ),
          ),
          const Divider(height: 1),
          if (items.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'owner_dashboard.no_bookings_today'.tr(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.all(8),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 6),
              itemBuilder: (context, i) => _TimelineTile(item: items[i]),
            ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final OwnerBookingItem item;
  const _TimelineTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final badge = _statusBadge(context, item);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              formatHourLabel(item.startTime, context),
              style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
                color: AppColors.primary,
              ),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.roomName} • ${item.stationName}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  item.cyberName,
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
          badge,
        ],
      ),
    );
  }

  Widget _statusBadge(BuildContext context, OwnerBookingItem item) {
    late String label;
    late Color bg;
    late Color fg;

    if (item.isManual) {
      label = 'owner_dashboard.status_manual'.tr();
      bg = const Color(0xFFFCE7F3);
      fg = const Color(0xFFBE185D);
    } else {
      switch (item.status) {
        case 'confirmed':
        case 'completed':
          label = 'owner_dashboard.status_confirmed'.tr();
          bg = const Color(0xFFD1FAE5);
          fg = const Color(0xFF047857);
          break;
        case 'fee_under_review':
          label = 'owner_dashboard.status_fee_review'.tr();
          bg = const Color(0xFFEDE9FE);
          fg = const Color(0xFF6D28D9);
          break;
        default:
          label = 'owner_dashboard.status_pending_payment'.tr();
          bg = const Color(0xFFFFEDD5);
          fg = const Color(0xFFC2410C);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
      ),
    );
  }
}

class _QuickActionsPanel extends StatelessWidget {
  final int pendingReceipts;
  const _QuickActionsPanel({required this.pendingReceipts});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'owner_dashboard.quick_actions'.tr(),
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          _ActionCard(
            icon: Icons.person_add_alt_1,
            color: AppColors.primary,
            title: 'owner_dashboard.walk_in_card_title'.tr(),
            subtitle: 'owner_dashboard.walk_in_card_sub'.tr(),
            onTap: () => context.push('/owner/manual-booking'),
          ),
          const SizedBox(height: 8),
          _ActionCard(
            icon: Icons.block,
            color: const Color(0xFFDC2626),
            title: 'owner_dashboard.block_station'.tr(),
            subtitle: 'owner_dashboard.block_station_sub'.tr(),
            onTap: () => context.push('/owner/stations'),
          ),
          const SizedBox(height: 8),
          _ActionCard(
            icon: Icons.receipt_long,
            color: const Color(0xFF2563EB),
            title: 'owner_dashboard.review_receipts'.tr(),
            subtitle:
                '${formatLocalizedNumber(pendingReceipts, context)} ${'owner_dashboard.receipts_waiting'.tr()} • ${'owner_dashboard.view_only'.tr()}',
            onTap: () => context.push('/owner/payments'),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_left, color: color, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetricsShimmer extends StatelessWidget {
  const _MetricsShimmer();
  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        4,
        (_) => Expanded(
          child: Container(
            height: 72,
            margin: const EdgeInsets.only(left: 6),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        ),
      ),
    );
  }
}

class _TimelineLoading extends StatelessWidget {
  const _TimelineLoading();
  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: const CircularProgressIndicator(color: AppColors.primary),
    );
  }
}
