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
    return GestureDetector(
      onTap: canSelect ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.green 
              : (canSelect ? AppColors.darkCard : AppColors.darkSurface),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.green : AppColors.darkBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              time,
              style: TextStyle(
                color: isSelected 
                    ? Colors.white 
                    : (canSelect ? Colors.white : AppColors.textMuted),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isPast ? 'Past' : (isAvailable ? 'Available' : 'Occupied'),
              style: TextStyle(
                color: isSelected 
                    ? Colors.white 
                    : (canSelect ? AppColors.green : AppColors.textMuted),
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
