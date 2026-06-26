import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';

class ProfileMenuSection extends StatelessWidget {
  final VoidCallback onLogout;

  const ProfileMenuSection({super.key, required this.onLogout});

  double _getResponsiveSpacing(BuildContext context,
      {double mobile = 12, double tablet = 16, double desktop = 24}) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      return mobile;
    } else if (screenWidth < 1200) {
      return tablet;
    } else {
      return desktop;
    }
  }

  Widget _buildMenuItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(_getResponsiveSpacing(context,
            mobile: 12, tablet: 16, desktop: 20)),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? AppColors.error : AppColors.textMuted,
              size: 24,
            ),
            SizedBox(
                width: _getResponsiveSpacing(context,
                    mobile: 12, tablet: 16, desktop: 20)),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isDestructive ? AppColors.error : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(
            height: _getResponsiveSpacing(context,
                mobile: 12, tablet: 16, desktop: 20)),
        _buildMenuItem(
          context,
          icon: Icons.person_outline,
          title: 'Personal Information',
          onTap: () => context.push('/personal-info'),
        ),
        SizedBox(
            height: _getResponsiveSpacing(context,
                mobile: 8, tablet: 12, desktop: 16)),
        _buildMenuItem(
          context,
          icon: Icons.history_outlined,
          title: 'profile.booking_history'.tr(),
          onTap: () => context.go('/bookings'),
        ),
        SizedBox(
            height: _getResponsiveSpacing(context,
                mobile: 8, tablet: 12, desktop: 16)),
        _buildMenuItem(
          context,
          icon: Icons.account_balance_wallet_outlined,
          title: 'Wallet & Rewards',
          onTap: () => context.push('/wallet'),
        ),
        SizedBox(
            height: _getResponsiveSpacing(context,
                mobile: 8, tablet: 12, desktop: 16)),
        _buildMenuItem(
          context,
          icon: Icons.help_outline,
          title: 'Help & Support',
          onTap: () {},
        ),
        SizedBox(
            height: _getResponsiveSpacing(context,
                mobile: 8, tablet: 12, desktop: 16)),
        _buildMenuItem(
          context,
          icon: Icons.logout,
          title: 'Logout',
          onTap: onLogout,
          isDestructive: true,
        ),
      ],
    );
  }
}
