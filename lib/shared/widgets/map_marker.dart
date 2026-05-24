import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MapMarker extends StatelessWidget {
  final String name;
  final bool isOpen;
  final bool isSelected;
  final VoidCallback onTap;

  const MapMarker({
    super.key,
    required this.name,
    required this.isOpen,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          // Marker Pin
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.green 
                  : (isOpen ? AppColors.green : AppColors.error),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? Colors.white : Colors.transparent,
                width: 3,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Icon(
              Icons.videogame_asset,
              color: Colors.white,
              size: 20,
            ),
          ),
          
          // Marker Point
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isSelected 
                  ? AppColors.green 
                  : (isOpen ? AppColors.green : AppColors.error),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          
          const SizedBox(height: 4),
          
          // Name Label
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.darkCard,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(
                color: isSelected ? AppColors.green : AppColors.darkBorder,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Text(
              name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
