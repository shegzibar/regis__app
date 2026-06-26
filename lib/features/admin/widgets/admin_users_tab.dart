import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user.dart';
import '../providers/admin_accounts_providers.dart';
import 'admin_user_bookings_sheet.dart';

class AdminUsersTab extends ConsumerWidget {
  const AdminUsersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(allUsersProvider);

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
            const Text('Failed to load users',
                style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Text(err.toString(),
                style: const TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
      data: (users) {
        if (users.isEmpty) {
          return const Center(
            child: Text('No users found',
                style: TextStyle(color: AppColors.textMuted)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];

            Color roleColor;
            switch (user.role) {
              case 'admin':
                roleColor = AppColors.purple;
                break;
              case 'owner':
                roleColor = AppColors.amber;
                break;
              case 'manager':
                roleColor = Colors.blue;
                break;
              default:
                roleColor = AppColors.green;
            }

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showUserBookings(context, user, roleColor),
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
                    CircleAvatar(
                      backgroundColor: roleColor.withValues(alpha: 0.15),
                      radius: 24,
                      child: Text(
                        (user.name ?? '?').isNotEmpty
                            ? (user.name ?? '?')[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: roleColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name ?? 'Unknown',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.phone,
                                  size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                (user.phone?.isEmpty ?? true)
                                    ? 'No phone'
                                    : user.phone!,
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: roleColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        user.role.toUpperCase(),
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textMuted, size: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showUserBookings(BuildContext context, AppUser user, Color roleColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AdminUserBookingsSheet(user: user, roleColor: roleColor),
    );
  }
}
