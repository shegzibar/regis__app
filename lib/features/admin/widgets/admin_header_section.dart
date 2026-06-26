import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../providers/admin_providers.dart';

class AdminHeaderSection extends ConsumerWidget {
  const AdminHeaderSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    void refreshData() {
      ref.invalidate(pendingPaymentsProvider);
      ref.invalidate(paymentStatsProvider);
      ref.invalidate(walletStatsProvider);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refreshing data...')),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'admin.fee_queue'.tr(),
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'admin.manage_fees'.tr(),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const Spacer(),
          GestureDetector(
            onTap: refreshData,
            child: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: const Icon(
                Icons.refresh,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
