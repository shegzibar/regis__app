import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class DateCard extends StatelessWidget {
  final String dayName;
  final String dayNumber;
  final bool isSelected;
  final VoidCallback onTap;

  const DateCard({
    super.key,
    required this.dayName,
    required this.dayNumber,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 70,
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.green 
              : AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.green : AppColors.darkBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              dayName,
              style: TextStyle(
                color: isSelected ? Colors.white : AppColors.textMuted,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              dayNumber,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
