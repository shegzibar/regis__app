import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/cyber.dart';
import '../providers/admin_accounts_providers.dart';
import 'admin_edit_subscription_sheet.dart';
import 'admin_edit_cyber_sheet.dart';

class AdminCybersTab extends ConsumerWidget {
  const AdminCybersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(allCybersProvider);

    return asyncData.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            const Text('Failed to load cybers',
                style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Text(err.toString(),
                style: const TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
      data: (cybers) {
        if (cybers.isEmpty) {
          return const Center(
            child: Text('No cyber cafés found',
                style: TextStyle(color: AppColors.textMuted)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: cybers.length,
          itemBuilder: (context, index) {
            final cyber = cybers[index];
              return InkWell(
                onTap: () => _showEditSubscriptionSheet(context, ref, cyber),
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.computer, color: AppColors.green),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    cyber.name,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, size: 18, color: AppColors.textMuted),
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: () {
                                    showModalBottomSheet(
                                      context: context,
                                      isScrollControlled: true,
                                      backgroundColor: Colors.transparent,
                                      builder: (context) => AdminEditCyberSheet(cyber: cyber),
                                    );
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(Icons.location_city,
                                    size: 14, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  cyber.city ?? 'No city set',
                                  style: const TextStyle(
                                      color: AppColors.textMuted, fontSize: 13),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                _PlanBadge(plan: cyber.subscriptionPlan),
                                const SizedBox(width: 8),
                                Text(
                                  cyber.subscriptionBilling,
                                  style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: cyber.isSubscriptionActive
                                  ? AppColors.green.withValues(alpha: 0.1)
                                  : AppColors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              cyber.isSubscriptionActive ? 'Active' : 'Expired',
                              style: TextStyle(
                                color: cyber.isSubscriptionActive ? AppColors.green : AppColors.red,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                          if (cyber.subscriptionEndDate != null)
                            _ExpiryBadge(cyber: cyber),
                        ],
                      ),
                    ],
                  ),
                ),
              );
          },
        );
      },
    );
  }
}

class _PlanBadge extends StatelessWidget {
  final String plan;
  const _PlanBadge({required this.plan});

  @override
  Widget build(BuildContext context) {
    Color color;
    String label;
    switch (plan.toLowerCase()) {
      case 'growth':
        color = Colors.blue;
        label = 'Growth';
        break;
      case 'custom':
        color = Colors.purple;
        label = 'Custom';
        break;
      case 'starter':
      default:
        color = Colors.orange;
        label = 'Starter';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ExpiryBadge extends StatelessWidget {
  final Cyber cyber;
  const _ExpiryBadge({required this.cyber});

  @override
  Widget build(BuildContext context) {
    final Color color;
    switch (cyber.expiryUrgency) {
      case 3:
        color = AppColors.red;
        break;
      case 2:
        color = Colors.amber;
        break;
      default:
        color = AppColors.green;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.schedule, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            cyber.expiryLabel,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

void _showEditSubscriptionSheet(BuildContext context, WidgetRef ref, Cyber cyber) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.darkCard,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) => AdminEditSubscriptionSheet(cyber: cyber),
  );
}

