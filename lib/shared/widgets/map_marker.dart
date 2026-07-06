import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MapMarker extends StatefulWidget {
  final String name;
  final bool isOpen;
  final bool isSelected;
  final VoidCallback onTap;
  final double rating;

  const MapMarker({
    super.key,
    required this.name,
    required this.isOpen,
    required this.isSelected,
    required this.onTap,
    this.rating = 0.0,
  });

  @override
  State<MapMarker> createState() => _MapMarkerState();
}

class _MapMarkerState extends State<MapMarker>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();
  }

  @override
  void didUpdateWidget(MapMarker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected && widget.isSelected) {
      _animationController.forward(from: 0.8);
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Rating Badge (above icon)
            if (widget.rating > 0)
              Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.darkCard.withValues(alpha: 0.95),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBorder, width: 1),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 12),
                    const SizedBox(width: 2),
                    Text(
                      widget.rating.toStringAsFixed(1),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

            // Animated Marker Pin with glow effect
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? AppColors.green
                    : (widget.isOpen ? AppColors.green : AppColors.error),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: widget.isSelected ? Colors.white : Colors.transparent,
                  width: widget.isSelected ? 3 : 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isSelected
                            ? AppColors.green
                            : (widget.isOpen
                                ? AppColors.green
                                : AppColors.error))
                        .withValues(alpha: widget.isSelected ? 0.5 : 0.3),
                    blurRadius: widget.isSelected ? 16 : 8,
                    spreadRadius: widget.isSelected ? 2 : 0,
                    offset: const Offset(0, 4),
                  ),
                  if (widget.isSelected)
                    BoxShadow(
                      color: AppColors.green.withValues(alpha: 0.2),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                ],
              ),
              child: Icon(
                Icons.videogame_asset_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),

            // Marker Point Triangle
            Container(
              width: 10,
              height: 8,
              margin: const EdgeInsets.only(top: 2),
              decoration: BoxDecoration(
                color: widget.isSelected
                    ? AppColors.green
                    : (widget.isOpen ? AppColors.green : AppColors.error),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(2),
                  bottomRight: Radius.circular(2),
                ),
              ),
            ),

            const SizedBox(height: 3),

            // Name Label with backdrop
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.darkCard.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: widget.isSelected
                      ? AppColors.green
                      : AppColors.darkBorder,
                  width: widget.isSelected ? 2 : 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                widget.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
