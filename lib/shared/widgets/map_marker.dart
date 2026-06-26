import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class MapMarker extends StatefulWidget {
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
          children: [
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

            const SizedBox(height: 6),

            // Name Label with backdrop
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
