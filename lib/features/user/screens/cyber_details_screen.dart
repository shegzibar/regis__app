import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/cyber_provider.dart';
import '../../../core/providers/room_provider.dart';
import '../../../core/providers/review_provider.dart';
import '../../../shared/widgets/room_card.dart';
import '../../../shared/widgets/review_card.dart';

class CyberDetailsScreen extends ConsumerStatefulWidget {
  final String cyberId;
  
  const CyberDetailsScreen({super.key, required this.cyberId});

  @override
  ConsumerState<CyberDetailsScreen> createState() => _CyberDetailsScreenState();
}

class _CyberDetailsScreenState extends ConsumerState<CyberDetailsScreen> {
  String? _selectedRoomId;
  double _minPrice = 15;

  void _selectRoom(String roomId) {
    setState(() {
      _selectedRoomId = roomId;
    });
  }

  void _bookStation() {
    if (_selectedRoomId != null) {
      context.push('/booking/$_selectedRoomId');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a room first')),
      );
    }
  }

  void _shareCyber() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  IconData _getRoomIcon(String type) {
    switch (type.toLowerCase()) {
      case 'ps5':
        return Icons.sports_esports;
      case 'pc':
        return Icons.computer;
      case 'vip':
        return Icons.star;
      default:
        return Icons.videogame_asset;
    }
  }

  Color _getRoomIconColor(String type) {
    switch (type.toLowerCase()) {
      case 'ps5':
        return Colors.blue;
      case 'pc':
        return AppColors.green;
      case 'vip':
        return Colors.purple;
      default:
        return Colors.amber;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cyberAsync = ref.watch(cyberByIdProvider(widget.cyberId));
    final roomsAsync = ref.watch(cyberRoomsProvider(widget.cyberId));
    final reviewsAsync = ref.watch(cyberReviewsProvider(widget.cyberId));

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const Spacer(),
                  cyberAsync.when(
                    data: (cyber) => Text(
                      cyber?.name ?? 'Details',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    loading: () => const Text('Loading...', style: TextStyle(color: Colors.white)),
                    error: (_, __) => const Text('Details', style: TextStyle(color: Colors.white)),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _shareCyber,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: const Icon(
                        Icons.share,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [

                    // Cover & Gallery Section
                    cyberAsync.when(
                      data: (cyber) {
                        if (cyber == null || cyber.images.isEmpty) return const SizedBox.shrink();
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Gallery',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 120,
                              child: ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: cyber.images.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.only(right: 12.0),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        cyber.images[index],
                                        height: 120,
                                        width: 160,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 32),
                          ],
                        );
                      },
                      loading: () => const SizedBox.shrink(),
                      error: (_, __) => const SizedBox.shrink(),
                    ),

                    // Room Selection
                    const Text(
                      'Available Rooms',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    roomsAsync.when(
                      loading: () => const Center(child: CircularProgressIndicator(color: AppColors.green)),
                      error: (err, _) => Text('Error loading rooms: $err', style: const TextStyle(color: Colors.red)),
                      data: (rooms) {
                        if (rooms.isEmpty) {
                          return const Text('No rooms active at this center.', style: TextStyle(color: AppColors.textMuted));
                        }

                        // Dynamically update minPrice in microtask if needed
                        final currentMin = rooms.map((r) => r.pricePerHour).reduce((a, b) => a < b ? a : b);
                        if (currentMin != _minPrice) {
                          Future.microtask(() {
                            setState(() {
                              _minPrice = currentMin;
                            });
                          });
                        }

                        return Column(
                          children: rooms.map((room) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: RoomCard(
                                name: room.name,
                                icon: _getRoomIcon(room.type),
                                iconColor: _getRoomIconColor(room.type),
                                availableStations: 8, // Default fallback count
                                pricePerHour: room.pricePerHour.toInt(),
                                isSelected: _selectedRoomId == room.id,
                                onTap: () => _selectRoom(room.id),
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // User Reviews Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'User Reviews',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        TextButton(
                          onPressed: () {},
                          child: const Text(
                            'See All',
                            style: TextStyle(
                              color: AppColors.green,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 16),
                    
                    reviewsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (err, _) => Text('Error loading reviews: $err', style: const TextStyle(color: Colors.red)),
                      data: (reviews) {
                        if (reviews.isEmpty) {
                          return const Padding(
                            padding: EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              'No reviews yet. Be the first to review!',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          );
                        }

                        return Column(
                          children: reviews.map((review) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: ReviewCard(
                                userName: 'User', // Fallback, or fetch user profile
                                initials: 'U',
                                timeAgo: 'Recently',
                                rating: review.rating.toDouble(),
                                comment: review.comment ?? 'No comment',
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            // Bottom Booking Bar
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                border: Border(
                  top: BorderSide(color: AppColors.darkBorder),
                ),
              ),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Starting from',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_minPrice.toInt()} EGP/hr',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: _bookStation,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.green,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    ),
                    child: const Text(
                      'Book a Station',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
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
