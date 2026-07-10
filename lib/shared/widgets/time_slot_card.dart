import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class TimeSlotCard extends StatelessWidget {
  final String time;
  final bool isAvailable;
  final bool isSelected;
  final bool isPast;
  final VoidCallback onTap;

  const TimeSlotCard({
    super.key,
    required this.time,
    required this.isAvailable,
    required this.isSelected,
    this.isPast = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool canSelect = isAvailable && !isPast;
    
    // Split time for creative layout (e.g., "10:00" and "AM")
    final parts = time.split(' ');
    final timeStr = parts.length > 1 ? parts[0] : time;
    final amPm = parts.length > 1 ? parts[1] : '';

    return GestureDetector(
      onTap: canSelect ? onTap : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOutCubic,
        width: 105,
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.green 
              : (canSelect ? AppColors.darkCard : AppColors.darkSurface.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(26), // Pill shape
          border: Border.all(
            color: isSelected 
                ? AppColors.green.withOpacity(0.8) 
                : (canSelect ? AppColors.darkBorder : Colors.transparent),
            width: isSelected ? 0 : 1,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.green.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  )
                ]
              : [],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Time Text
            RichText(
              text: TextSpan(
                text: timeStr,
                style: TextStyle(
                  color: isSelected 
                      ? Colors.white 
                      : (canSelect ? Colors.white : AppColors.textMuted.withOpacity(0.4)),
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                ),
                children: [
                  TextSpan(
                    text: ' $amPm',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isSelected 
                          ? Colors.white.withOpacity(0.8)
                          : (canSelect ? AppColors.textMuted : AppColors.textMuted.withOpacity(0.3)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Status Dot
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? Colors.white
                    : (canSelect ? AppColors.green : AppColors.textMuted.withOpacity(0.2)),
                boxShadow: (isSelected || canSelect) && !isPast
                    ? [
                        BoxShadow(
                          color: (isSelected ? Colors.white : AppColors.green).withOpacity(0.6),
                          blurRadius: 4,
                        )
                      ]
                    : [],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
