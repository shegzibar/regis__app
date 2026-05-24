import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class FavoriteCenterCard extends StatelessWidget {
  final String name;
  final double rating;
  final double distance;
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
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              height: 50,
              decoration: BoxDecoration(
                color: AppColors.darkSurface,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.videogame_asset,
                color: AppColors.green,
                size: 20,
              ),
            ),

            const SizedBox(height: 6),

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

            const SizedBox(height: 3),

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
                      rating.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                const Spacer(),

                // Distance
                Text(
                  '${distance}km',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 3),

            // Open Status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              decoration: BoxDecoration(
                color: isOpen
                    ? AppColors.green.withOpacity(0.2)
                    : AppColors.error.withOpacity(0.2),
                borderRadius: BorderRadius.circular(3),
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
