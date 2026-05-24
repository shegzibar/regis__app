import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class TimeSlotCard extends StatelessWidget {
  final String time;
  final bool isAvailable;
  final bool isSelected;
  final VoidCallback onTap;

  const TimeSlotCard({
    super.key,
    required this.time,
    required this.isAvailable,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isAvailable ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.green 
              : (isAvailable ? AppColors.darkCard : AppColors.darkSurface),
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
                    : (isAvailable ? Colors.white : AppColors.textMuted),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isAvailable ? 'Available' : 'Occupied',
              style: TextStyle(
                color: isSelected 
                    ? Colors.white 
                    : (isAvailable ? AppColors.green : AppColors.textMuted),
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
