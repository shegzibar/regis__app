import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

class OnboardingStepIndicator extends StatelessWidget {
  final String label;
  final String title;
  final bool active;
  final bool done;

  const OnboardingStepIndicator({
    super.key,
    required this.label,
    required this.title,
    required this.active,
    required this.done,
  });

  @override
  Widget build(BuildContext context) {
    final color = done
        ? AppColors.primary
        : active
            ? AppColors.purple
            : const Color(0xFFE2E8F0);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      decoration: BoxDecoration(
        color: active || done ? color.withValues(alpha: 0.12) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: active || done
                    ? AppColors.textPrimary
                    : AppColors.textMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
