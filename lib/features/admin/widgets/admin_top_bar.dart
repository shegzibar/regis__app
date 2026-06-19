import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/providers/auth_provider.dart';

class AdminTopBar extends ConsumerWidget {
  const AdminTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 70,
      decoration: const BoxDecoration(
        color: AppColors.darkCard,
        border: Border(
          bottom: BorderSide(
            color: AppColors.darkBorder,
            width: 1,
          ),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          // Logo/Brand
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.sports_esports,
              color: AppColors.green,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          const Text(
            'GamingHub Admin',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const Spacer(),

          // Actions
          _ActionButton(
            icon: Icons.add_business,
            label: 'Create Cyber Account',
            onTap: () => context.go('/admin/create-cyber'),
            isPrimary: true,
          ),
          const SizedBox(width: 16),
          _ActionButton(
            icon: Icons.logout,
            label: 'Sign Out',
            onTap: () => ref.read(authControllerProvider.notifier).signOut(),
            isPrimary: false,
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isPrimary;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.isPrimary,
  });

  @override
  Widget build(BuildContext context) {
    final fgColor = isPrimary ? Colors.white : AppColors.textMuted;
    final bgColor = isPrimary ? AppColors.green : AppColors.darkBg;
    final borderColor = isPrimary ? Colors.transparent : AppColors.darkBorder;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, color: fgColor, size: 18),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: fgColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
