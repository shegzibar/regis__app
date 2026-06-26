import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/summary_card.dart';
import '../providers/admin_providers.dart';

class AdminSummarySection extends ConsumerWidget {
  const AdminSummarySection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(paymentStatsProvider);

    final pendingCount = statsAsync.value?['pending'] ?? 0;
    final confirmedCount = statsAsync.value?['confirmed'] ?? 0;
    final rejectedCount = statsAsync.value?['rejected'] ?? 0;
    final revenue = statsAsync.value?['revenue'] ?? 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: 'admin.pending'.tr(),
                  value: pendingCount.toString(),
                  valueColor: Colors.orange,
                  icon: Icons.pending,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  title: 'admin.confirmed'.tr(),
                  value: confirmedCount.toString(),
                  valueColor: AppColors.green,
                  icon: Icons.check_circle,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: 'admin.rejected'.tr(),
                  value: rejectedCount.toString(),
                  valueColor: AppColors.error,
                  icon: Icons.cancel,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  title: 'admin.revenue'.tr(),
                  value: '${revenue.toInt()} ${'common.egp'.tr()}',
                  valueColor: AppColors.green,
                  icon: Icons.account_balance_wallet,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
