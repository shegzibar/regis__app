import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class RoomCard extends StatelessWidget {
  final String name;
  final IconData icon;
  final Color iconColor;
  final int availableStations;
  final int pricePerHour;
  final bool isSelected;
  final VoidCallback onTap;

  const RoomCard({
    super.key,
    required this.name,
    required this.icon,
    required this.iconColor,
    required this.availableStations,
    required this.pricePerHour,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected 
              ? AppColors.green.withOpacity(0.1) 
              : AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.green : AppColors.darkBorder,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: isSelected 
                    ? AppColors.green.withOpacity(0.2) 
                    : AppColors.darkSurface,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppColors.green : iconColor,
                size: 28,
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Room Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$availableStations stations available',
                    style: const TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            // Price
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '$pricePerHour EGP',
                  style: TextStyle(
                    color: isSelected ? AppColors.green : Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  'per hour',
                  style: TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
