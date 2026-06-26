import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class FavoriteCenterCard extends StatelessWidget {
  final String name;
  final double rating;
  final double? distance;
  final bool isOpen;
  final VoidCallback onTap;

  const FavoriteCenterCard({
    super.key,
    required this.name,
    required this.rating,
    required this.distance,
    required this.isOpen,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Center Image Placeholder
            Container(
              width: double.infinity,
              height: 40,
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.videogame_asset,
                color: AppColors.green,
                size: 18,
              ),
            ),

            const SizedBox(height: 4),

            // Center Name
            Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),

            const SizedBox(height: 2),

            // Rating and Distance
            Row(
              children: [
                // Rating
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 10,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Distance
                Text(
                  distance != null ? '${distance!.toStringAsFixed(1)} km' : '—',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 2),

            // Open Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
              decoration: BoxDecoration(
                color: isOpen
                    ? AppColors.green.withValues(alpha: 0.2)
                    : AppColors.error.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
                border: Border.all(
                  color: isOpen ? AppColors.green : AppColors.error,
                  width: 0.5,
                ),
              ),
              child: Text(
                isOpen ? 'Open' : 'Closed',
                style: TextStyle(
                  color: isOpen ? AppColors.green : AppColors.error,
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
