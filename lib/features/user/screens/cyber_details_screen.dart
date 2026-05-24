import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/room_card.dart';
import '../../../shared/widgets/review_card.dart';

class CyberDetailsScreen extends StatefulWidget {
  final String cyberId;
  
  const CyberDetailsScreen({super.key, required this.cyberId});

  @override
  State<CyberDetailsScreen> createState() => _CyberDetailsScreenState();
}

class _CyberDetailsScreenState extends State<CyberDetailsScreen> {
  final List<Map<String, dynamic>> _rooms = [
    {
      'id': '1',
      'name': 'Pro PC Zone',
      'icon': Icons.computer,
      'iconColor': AppColors.green,
      'availableStations': 12,
      'pricePerHour': 40,
      'isSelected': false,
    },
    {
      'id': '2',
      'name': 'PlayStation 5 VIP',
      'icon': Icons.videogame_asset,
      'iconColor': Colors.blue,
      'availableStations': 8,
      'pricePerHour': 50,
      'isSelected': false,
    },
    {
      'id': '3',
      'name': 'Private Streaming Suite',
      'icon': Icons.live_tv,
      'iconColor': Colors.purple,
      'availableStations': 4,
      'pricePerHour': 60,
      'isSelected': false,
    },
  ];
  
  final List<Map<String, dynamic>> _reviews = [
    {
      'id': '1',
      'userName': 'Ahmed M.',
      'initials': 'AM',
      'timeAgo': '2 days ago',
      'rating': 5.0,
      'comment': 'Amazing gaming experience! The PCs are top-notch and the staff is very helpful. Will definitely come back.',
    },
    {
      'id': '2',
      'userName': 'Sarah K.',
      'initials': 'SK',
      'timeAgo': '1 week ago',
      'rating': 4.5,
      'comment': 'Great atmosphere and comfortable setup. The PS5 VIP room is perfect for competitive gaming.',
    },
    {
      'id': '3',
      'userName': 'Mohamed R.',
      'initials': 'MR',
      'timeAgo': '2 weeks ago',
      'rating': 4.0,
      'comment': 'Good value for money. The equipment is well-maintained and the internet speed is excellent.',
    },
  ];
  
  String? _selectedRoomId;
  int _minPrice = 40;

  @override
  void initState() {
    super.initState();
    // Find the minimum price
    _minPrice = _rooms.map((room) => room['pricePerHour'] as int).reduce((a, b) => a < b ? a : b);
  }

  void _selectRoom(String roomId) {
    setState(() {
      _selectedRoomId = roomId;
      // Update room selection states
      for (var room in _rooms) {
        room['isSelected'] = room['id'] == roomId;
      }
    });
  }

  void _shareCyber() {
    // TODO: Implement share functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality coming soon!')),
    );
  }

  void _bookStation() {
    if (_selectedRoomId != null) {
      // TODO: Navigate to booking screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Navigating to booking...')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a room first')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
                  const Text(
                    'Select Room',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
                    
                    // Room Cards
                    ..._rooms.map((room) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: RoomCard(
                          name: room['name'],
                          icon: room['icon'],
                          iconColor: room['iconColor'],
                          availableStations: room['availableStations'],
                          pricePerHour: room['pricePerHour'],
                          isSelected: room['isSelected'],
                          onTap: () => _selectRoom(room['id']),
                        ),
                      );
                    }),
                    
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
                          onPressed: () {
                            // TODO: Show all reviews
                          },
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
                    
                    // Review Cards
                    ..._reviews.map((review) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: ReviewCard(
                          userName: review['userName'],
                          initials: review['initials'],
                          timeAgo: review['timeAgo'],
                          rating: review['rating'],
                          comment: review['comment'],
                        ),
                      );
                    }),
                    
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
                        '$_minPrice EGP/hr',
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
