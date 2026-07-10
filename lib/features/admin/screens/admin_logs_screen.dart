import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/admin_logs_provider.dart';

class AdminLogsScreen extends ConsumerWidget {
  const AdminLogsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsAsync = ref.watch(cyberAnalyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text('Cyber Analytics'),
        backgroundColor: AppColors.darkCard,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.invalidate(cyberAnalyticsProvider),
          )
        ],
      ),
      body: analyticsAsync.when(
        loading: () => const Center(
            child: CircularProgressIndicator(color: AppColors.green)),
        error: (err, stack) => Center(
          child: Text(
            'Error loading analytics:\n$err',
            style: const TextStyle(color: Colors.redAccent),
            textAlign: TextAlign.center,
          ),
        ),
        data: (analytics) {
          if (analytics.isEmpty) {
            return const Center(
              child: Text(
                'No cybers found.',
                style: TextStyle(color: AppColors.textMuted),
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: analytics.length,
            itemBuilder: (context, index) {
              final cyber = analytics[index];
              return Card(
                color: AppColors.darkCard,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.darkBorder),
                ),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    context.go('/admin/logs/detail', extra: cyber);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              cyber.cyberName,
                              style: TextStyle(
                                color: cyber.cyberId == 'unassigned' ? Colors.orangeAccent : Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            if (cyber.cyberId == 'unassigned') ...[
                              const SizedBox(width: 8),
                              const Icon(Icons.public, color: Colors.orangeAccent, size: 18),
                            ]
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _StatBox(
                                title: 'Points Earned',
                                value: cyber.totalPointsGiven.toString(),
                                icon: Icons.stars,
                                color: AppColors.green,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatBox(
                                title: 'Points Redeemed',
                                value: cyber.totalPointsRedeemed.toString(),
                                icon: Icons.redeem,
                                color: Colors.orangeAccent,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: _StatBox(
                                title: 'Users Registered',
                                value: cyber.totalUsersRegistered.toString(),
                                icon: Icons.people,
                                color: Colors.blueAccent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatBox extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _StatBox({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
