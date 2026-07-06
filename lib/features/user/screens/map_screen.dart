import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/cyber_provider.dart';
import '../../../shared/widgets/map_marker.dart';
import '../../../shared/widgets/gaming_center_bottom_sheet.dart';

class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  final MapController _mapController = MapController();
  late AnimationController _animationController;

  bool _isMapReady = false; // true once FlutterMap fires onMapReady
  LatLng? _pendingCenter; // location received before map was ready

  bool _showBottomSheet = false;
  String? _selectedCenterId;
  Position? _currentPosition;
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _handleLocationPermission().then((hasPermission) {
      if (hasPermission) {
        _getCurrentLocation();
      } else {
        setState(() => _isLoadingLocation = false);
      }
    });
    _searchController.addListener(() {
      setState(() {}); // Rebuild to filter cybers when searching
    });
    _searchFocusNode.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocusNode.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<bool> _handleLocationPermission() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Location services are disabled. Please enable the services')));
      }
      return false;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')));
        }
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'Location permissions are permanently denied, we cannot request permissions.')));
      }
      return false;
    }
    return true;
  }

  Future<void> _getCurrentLocation() async {
    try {
      // 1. First attempt to get the last known position for a quick initial load
      Position? position = await Geolocator.getLastKnownPosition();
      if (position != null && mounted) {
        _updateLocationState(position);
        return; // Return immediately to prevent any lag!
      }

      // 2. Fallback to a fast, low-accuracy fetch
      position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
        timeLimit: const Duration(seconds: 5),
      );
      
      if (mounted) {
        _updateLocationState(position);
      }
    } catch (e) {
      debugPrint("Error fetching location: $e");
      if (mounted) setState(() => _isLoadingLocation = false);
    }
  }

  void _updateLocationState(Position position) {
    if (!mounted) return;
    final center = LatLng(position.latitude, position.longitude);
    setState(() {
      _currentPosition = position;
      _isLoadingLocation = false;
    });

    if (_isMapReady) {
      _mapController.move(center, 16.0);
    } else {
      // Map not ready yet — store and move once onMapReady fires
      _pendingCenter = center;
    }
  }

  void _onMarkerTap(String centerId, double lat, double lng) {
    setState(() {
      _selectedCenterId = centerId;
      _showBottomSheet = true;
    });

    _animationController.forward(from: 0.0);

    if (_isMapReady) {
      _mapController.move(LatLng(lat, lng), 15.0);
    }
  }

  void _onCenterTap() {
    if (_selectedCenterId != null) {
      context.push('/cyber/$_selectedCenterId');
    }
  }

  void _onFilterTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filter options coming soon!')),
    );
  }

  void _onRecenterTap() {
    if (_currentPosition != null && _isMapReady) {
      _mapController.move(
          LatLng(_currentPosition!.latitude, _currentPosition!.longitude),
          16.0);
    } else if (_currentPosition == null) {
      _getCurrentLocation();
    }
  }

  @override
  Widget build(BuildContext context) {
    final cybersAsync = ref.watch(cybersProvider);
    final allCybers = cybersAsync.valueOrNull ?? [];
    final query = _searchController.text.toLowerCase();
    final cybers = allCybers.where((cyber) {
      return cyber.name.toLowerCase().contains(query) ||
          (cyber.address?.toLowerCase().contains(query) ?? false);
    }).toList();

    final initialCenter = _currentPosition != null
        ? LatLng(_currentPosition!.latitude, _currentPosition!.longitude)
        : const LatLng(30.0444, 31.2357); // Cairo default

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Stack(
          children: [
            // Map
            cybersAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.green)),
              error: (err, _) => Center(
                  child: Text('Error: $err',
                      style: const TextStyle(color: Colors.red))),
              data: (allCybers) {
                // Filter based on search query is handled at the top of build

                // Find currently selected cyber mapping for bottom sheet
                Map<String, dynamic>? selectedMap;
                if (_selectedCenterId != null) {
                  try {
                    final sel =
                        allCybers.firstWhere((c) => c.id == _selectedCenterId);
                    selectedMap = {
                      'id': sel.id,
                      'name': sel.name,
                      'address': sel.address ?? 'Cairo, Egypt',
                      'distance': 1.5, // Mock distance
                      'rating': 4.8,
                      'isOpen': true,
                      'priceRange': '40-60 EGP/hr',
                      'consoles': ['PC', 'PS5', 'VIP'],
                      'latitude': sel.lat ?? 30.0444,
                      'longitude': sel.lng ?? 31.2357,
                    };
                  } catch (_) {}
                }

                return Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: initialCenter,
                        initialZoom: 12.0,
                        onMapReady: () {
                          setState(() => _isMapReady = true);
                          // If location arrived before the map was ready, move now
                          if (_pendingCenter != null) {
                            _mapController.move(_pendingCenter!, 16.0);
                            _pendingCenter = null;
                          }
                        },
                        onTap: (_, __) {
                          if (_showBottomSheet) {
                            setState(() {
                              _showBottomSheet = false;
                              _selectedCenterId = null;
                            });
                          }
                        },
                      ),
                      children: [
                        TileLayer(
                          urlTemplate:
                              'https://cartodb-basemaps-{s}.global.ssl.fastly.net/dark_all/{z}/{x}/{y}.png',
                          subdomains: const ['a', 'b', 'c', 'd'],
                          userAgentPackageName: 'com.example.gaming_hub',
                          tileBuilder: (context, widget, tile) {
                            return ColorFiltered(
                              colorFilter: const ColorFilter.matrix([
                                1, 0, 0, 0, 20, // Slightly brighten Red
                                0, 1, 0, 0, 25, // Slightly brighten Green
                                0, 0, 1, 0, 35, // Brighten Blue slightly more for that Uber texture
                                0, 0, 0, 1,  0,
                              ]),
                              child: widget,
                            );
                          },
                        ),
                        MarkerLayer(
                          markers: [
                            // Cyber Markers
                            ...cybers
                                .where((c) => c.lat != null && c.lng != null)
                                .map((cyber) {
                              final lat = cyber.lat!;
                              final lng = cyber.lng!;
                              return Marker(
                                point: LatLng(lat, lng),
                                width: 160,
                                height: 130,
                                child: MapMarker(
                                  name: cyber.name,
                                  isOpen: cyber.isOpenNow,
                                  isSelected: cyber.id == _selectedCenterId,
                                  rating: cyber.rating,
                                  onTap: () => _onMarkerTap(cyber.id, lat, lng),
                                ),
                              );
                            }),

                            // User Location Marker
                            if (_currentPosition != null)
                              Marker(
                                point: LatLng(_currentPosition!.latitude,
                                    _currentPosition!.longitude),
                                width: 30,
                                height: 30,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.blue,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                        color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.blue.withValues(alpha: 0.5),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(Icons.person,
                                      color: Colors.white, size: 18),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),

                    // Bottom Sheet
                    if (_showBottomSheet && selectedMap != null)
                      Positioned(
                        bottom: 0,
                        left: 0,
                        right: 0,
                        child: GamingCenterBottomSheet(
                          center: selectedMap,
                          onTap: _onCenterTap,
                          onClose: () => setState(() {
                            _showBottomSheet = false;
                            _selectedCenterId = null;
                          }),
                        ),
                      ),
                  ],
                );
              },
            ),

            // Header with Search (must be on top of map stack)
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
                      AppColors.darkBg.withValues(alpha: 0.98),
                      AppColors.darkBg.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Expanded(
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                'Explore',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(width: 8),
                              Text(
                                'Gaming Centers',
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w300,
                                  color: AppColors.green,
                                  letterSpacing: -0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        GestureDetector(
                          onTap: _onFilterTap,
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: AppColors.darkCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.darkBorder),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.green.withValues(alpha: 0.1),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.filter_list,
                              color: AppColors.green,
                              size: 24,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 18),

                    // Modern Search Bar with shadow
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: AppColors.darkBorder,
                          width: 1.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.green.withValues(alpha: 0.15),
                            blurRadius: 12,
                            spreadRadius: 0,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Search centers...',
                          hintStyle: const TextStyle(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w400,
                          ),
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(left: 16, right: 12),
                            child: Icon(
                              Icons.location_on_outlined,
                              color: AppColors.green,
                              size: 22,
                            ),
                          ),
                          suffixIcon: _searchController.text.isNotEmpty
                              ? GestureDetector(
                                  onTap: () {
                                    _searchController.clear();
                                    _searchFocusNode.unfocus();
                                    setState(() {});
                                  },
                                  child: const Padding(
                                    padding: EdgeInsets.only(right: 16),
                                    child: Icon(
                                      Icons.close_rounded,
                                      color: AppColors.textMuted,
                                      size: 20,
                                    ),
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 0,
                            vertical: 16,
                          ),
                        ),
                      ),
                    ),

                    if (_searchController.text.isNotEmpty && _searchFocusNode.hasFocus)
                      Container(
                        margin: const EdgeInsets.only(top: 8),
                        constraints: const BoxConstraints(maxHeight: 250),
                        decoration: BoxDecoration(
                          color: AppColors.darkCard,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: AppColors.darkBorder, width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: cybers.isEmpty
                            ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Text('No centers found', style: TextStyle(color: AppColors.textMuted)),
                              )
                            : ListView.builder(
                                padding: EdgeInsets.zero,
                                shrinkWrap: true,
                                itemCount: cybers.length,
                                itemBuilder: (context, index) {
                                  final cyber = cybers[index];
                                  return ListTile(
                                    leading: const Icon(Icons.location_on, color: AppColors.green),
                                    title: Text(cyber.name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
                                    subtitle: Text(cyber.address ?? 'Unknown Location', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                                    onTap: () {
                                      _searchController.clear();
                                      _searchFocusNode.unfocus();
                                      if (cyber.lat != null && cyber.lng != null) {
                                        _onMarkerTap(cyber.id, cyber.lat!, cyber.lng!);
                                      }
                                    },
                                  );
                                },
                              ),
                      ),


                  ],
                ),
              ),
            ),

            // Map Controls
            Positioned(
              right: 16,
              bottom: _showBottomSheet ? 280 : 32,
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () {
                      final zoom = _mapController.camera.zoom;
                      _mapController.move(
                          _mapController.camera.center, zoom + 1);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child:
                          const Icon(Icons.add, color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GestureDetector(
                    onTap: () {
                      final zoom = _mapController.camera.zoom;
                      _mapController.move(
                          _mapController.camera.center, zoom - 1);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: const Icon(Icons.remove,
                          color: Colors.white, size: 24),
                    ),
                  ),
                  const SizedBox(height: 8),
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
                      child: _isLoadingLocation
                          ? const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.green,
                              ),
                            )
                          : const Icon(Icons.my_location,
                              color: AppColors.green, size: 24),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

}
