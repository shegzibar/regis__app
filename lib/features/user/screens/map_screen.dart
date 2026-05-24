import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/map_marker.dart';
import '../../../shared/widgets/gaming_center_bottom_sheet.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _showBottomSheet = false;
  String? _selectedCenterId;

  // Mock gaming centers data
  final List<Map<String, dynamic>> _gamingCenters = [
    {
      'id': '1',
      'name': 'CyberZone Maadi',
      'address': 'Street 9, Maadi, Cairo',
      'distance': 2.3,
      'rating': 4.8,
      'isOpen': true,
      'priceRange': '40-60 EGP/hr',
      'consoles': ['PC', 'PS5', 'VIP'],
      'latitude': 30.0459,
      'longitude': 31.2359,
    },
    {
      'id': '2',
      'name': 'Matrix Gaming Lounge',
      'address': 'Nasr City, Cairo',
      'distance': 3.7,
      'rating': 4.5,
      'isOpen': true,
      'priceRange': '35-55 EGP/hr',
      'consoles': ['PC', 'PS4'],
      'latitude': 30.0636,
      'longitude': 31.3219,
    },
    {
      'id': '3',
      'name': 'Pro Gaming Center',
      'address': 'Heliopolis, Cairo',
      'distance': 5.2,
      'rating': 4.6,
      'isOpen': false,
      'priceRange': '45-65 EGP/hr',
      'consoles': ['PC', 'PS5', 'Xbox'],
      'latitude': 30.0954,
      'longitude': 31.3156,
    },
  ];

  void _onMarkerTap(String centerId) {
    setState(() {
      _selectedCenterId = centerId;
      _showBottomSheet = true;
    });
  }

  void _onCenterTap() {
    if (_selectedCenterId != null) {
      // TODO: Navigate to center details
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navigating to center details...')),
      );
    }
  }

  void _onFilterTap() {
    // TODO: Show filter dialog
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filter options coming soon!')),
    );
  }

  void _onRecenterTap() {
    // TODO: Recenter map to user location
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Recentering map...')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Stack(
          children: [
            // Map View
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: const Color(0xFF1E1E1E),
                borderRadius: BorderRadius.circular(0),
              ),
              child: Stack(
                children: [
                  // Map Background (simulated)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          const Color(0xFF2A2A2A),
                          const Color(0xFF1A1A1A),
                        ],
                      ),
                    ),
                    child: CustomPaint(
                      painter: MapPainter(),
                      size: Size.infinite,
                    ),
                  ),

                  // Gaming Center Markers
                  ..._gamingCenters.map((center) {
                    return Positioned(
                      top: _getMarkerPosition(
                              center['latitude'], center['longitude'])
                          .dy,
                      left: _getMarkerPosition(
                              center['latitude'], center['longitude'])
                          .dx,
                      child: MapMarker(
                        name: center['name'],
                        isOpen: center['isOpen'],
                        isSelected: center['id'] == _selectedCenterId,
                        onTap: () => _onMarkerTap(center['id']),
                      ),
                    );
                  }),

                  // Map Controls
                  Positioned(
                    right: 16,
                    bottom: _showBottomSheet ? 200 : 100,
                    child: Column(
                      children: [
                        // Zoom In Button
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.darkBorder),
                          ),
                          child: const Icon(
                            Icons.add,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Zoom Out Button
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.darkBorder),
                          ),
                          child: const Icon(
                            Icons.remove,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),

                        const SizedBox(height: 8),

                        // Recenter Button
                        GestureDetector(
                          onTap: _onRecenterTap,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.darkCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.darkBorder),
                            ),
                            child: const Icon(
                              Icons.my_location,
                              color: AppColors.green,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Current Location Marker
                  Positioned(
                    top: 250,
                    left: 180,
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.white, width: 3),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Header with Search
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppColors.darkBg.withOpacity(0.95),
                      AppColors.darkBg.withOpacity(0.8),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    // Header Row
                    Row(
                      children: [
                        const Text(
                          'Gaming Centers Map',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: _onFilterTap,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.darkCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.darkBorder),
                            ),
                            child: const Icon(
                              Icons.filter_list,
                              color: Colors.white,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Search Bar
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 16),
                        decoration: InputDecoration(
                          hintText: 'Search location...',
                          hintStyle:
                              const TextStyle(color: AppColors.textMuted),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppColors.textMuted,
                            size: 24,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Bottom Sheet
            if (_showBottomSheet && _selectedCenterId != null)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: GamingCenterBottomSheet(
                  center: _gamingCenters
                      .firstWhere((c) => c['id'] == _selectedCenterId),
                  onTap: _onCenterTap,
                  onClose: () => setState(() => _showBottomSheet = false),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Offset _getMarkerPosition(double latitude, double longitude) {
    // Simulate marker positioning based on lat/lng
    // This is a simplified calculation for demo purposes
    final x = ((longitude - 31.2) * 100).clamp(20.0, 340.0);
    final y = ((30.2 - latitude) * 100).clamp(100.0, 400.0);
    return Offset(x, y);
  }
}

// Custom painter for map background
class MapPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFF3A3A3A)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    // Draw simulated roads
    final path = Path();

    // Horizontal roads
    path.moveTo(0, 150);
    path.lineTo(size.width, 150);

    path.moveTo(0, 250);
    path.lineTo(size.width, 250);

    path.moveTo(0, 350);
    path.lineTo(size.width, 350);

    // Vertical roads
    path.moveTo(100, 0);
    path.lineTo(100, size.height);

    path.moveTo(200, 0);
    path.lineTo(200, size.height);

    path.moveTo(300, 0);
    path.lineTo(300, size.height);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
