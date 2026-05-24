import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class DurationButton extends StatelessWidget {
  final int duration;
  final bool isSelected;
  final VoidCallback onTap;

  const DurationButton({
    super.key,
    required this.duration,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
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
        child: Text(
          '${duration}hr',
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
