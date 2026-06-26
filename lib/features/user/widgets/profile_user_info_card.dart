import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/wallet_provider.dart';

class ProfileUserInfoCard extends ConsumerWidget {
  final VoidCallback onEditProfile;

  const ProfileUserInfoCard({
    super.key,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);

    String displayName = 'Gamer';
    if (user?.name?.isNotEmpty == true) {
      displayName = user!.name!;
    } else if (user?.email?.isNotEmpty == true) {
      displayName = user!.email!.split('@').first;
    } else if (user?.phone?.isNotEmpty == true) {
      displayName = user!.phone!;
    }
    
    final phone =
        user?.phone?.isNotEmpty == true ? user!.phone : 'No phone set';
        
    final memberSince = user != null
        ? '${_monthName(user.createdAt.month)} ${user.createdAt.year}'
        : '';

    final screenWidth = MediaQuery.of(context).size.width;
    double padding = 16.0;
    if (screenWidth >= 600 && screenWidth < 1200) {
      padding = 24.0;
    } else if (screenWidth >= 1200) {
      padding = 32.0;
    }

    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          // Avatar and Edit Button
          Stack(
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppColors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(50),
                  border: Border.all(color: AppColors.green, width: 3),
                ),
                child: user?.avatarUrl != null
                    ? ClipOval(
                        child: Image.network(
                          user!.avatarUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const Icon(
                            Icons.person,
                            size: 40,
                            color: AppColors.green,
                          ),
                        ),
                      )
                    : const Icon(
                        Icons.person,
                        size: 40,
                        color: AppColors.green,
                      ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: GestureDetector(
                  onTap: onEditProfile,
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.darkCard, width: 2),
                    ),
                    child: const Icon(
                      Icons.edit,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // User Name (live from Supabase)
          Text(
            displayName,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 6),

          // Phone Number (live from Supabase)
          Text(
            phone ?? '',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: AppColors.green,
            ),
          ),

          const SizedBox(height: 8),

          // User Short ID (Wallet ID)
          ref.watch(userShortIdProvider).when(
                data: (id) => id != null
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.qr_code,
                                size: 14, color: AppColors.darkBg),
                            const SizedBox(width: 6),
                            Text(
                              'ID: $id',
                              style: const TextStyle(
                                color: AppColors.darkBg,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.5,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      )
                    : const SizedBox.shrink(),
                loading: () => const SizedBox(height: 28),
                error: (_, __) => const SizedBox.shrink(),
              ),

          const SizedBox(height: 12),

          // Role badge
          if (user?.role != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.green.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.green.withValues(alpha: 0.4)),
              ),
              child: Text(
                user!.role.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.green,
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),

          const SizedBox(height: 12),

          // Member since (live from Supabase)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.calendar_today,
                  color: AppColors.textMuted, size: 14),
              const SizedBox(width: 6),
              Text(
                'Member since $memberSince',
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    return month >= 1 && month <= 12 ? months[month] : '';
  }
}
