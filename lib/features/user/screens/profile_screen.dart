import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localization.dart';
import '../../../shared/widgets/profile_stat_card.dart';
import '../../../shared/widgets/favorite_center_card.dart';
import '../../../shared/widgets/activity_item.dart';
import '../../../shared/widgets/language_switcher.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Mock user data
  final String _userName = 'Alex Thompson';
  final String _userEmail = 'alex.thompson@email.com';
  final String _userPhone = '+20 1012345678';
  final String _memberSince = 'January 2024';

  // Mock gaming statistics
  final int _totalHoursPlayed = 342;
  final int _totalBookings = 89;
  final int _achievements = 15;

  // Mock favorite gaming centers
  final List<Map<String, dynamic>> _favoriteCenters = [
    {
      'id': '1',
      'name': 'CyberZone Maadi',
      'rating': 4.8,
      'distance': 2.3,
      'isOpen': true,
      'image': 'assets/images/cyberzone.jpg',
    },
    {
      'id': '2',
      'name': 'Matrix Gaming Lounge',
      'rating': 4.5,
      'distance': 3.7,
      'isOpen': true,
      'image': 'assets/images/matrix.jpg',
    },
    {
      'id': '3',
      'name': 'Pro Gaming Center',
      'rating': 4.6,
      'distance': 5.2,
      'isOpen': false,
      'image': 'assets/images/progaming.jpg',
    },
  ];

  // Mock recent activities
  final List<Map<String, dynamic>> _recentActivities = [
    {
      'id': '1',
      'type': 'booking',
      'title': 'Booked VIP Room',
      'center': 'CyberZone Maadi',
      'time': '2 hours ago',
      'icon': Icons.videogame_asset,
      'color': AppColors.green,
    },
    {
      'id': '2',
      'type': 'review',
      'title': 'Reviewed Matrix Gaming',
      'center': 'Matrix Gaming Lounge',
      'time': '1 day ago',
      'icon': Icons.star,
      'color': Colors.amber,
    },
    {
      'id': '3',
      'type': 'achievement',
      'title': 'Achievement Unlocked',
      'center': '100 Hours Played',
      'time': '3 days ago',
      'icon': Icons.emoji_events,
      'color': Colors.purple,
    },
  ];

  void _onEditProfile() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Edit profile coming soon!')),
    );
  }

  void _onSettingsTap() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings coming soon!')),
    );
  }

  void _onLogout() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        title: const Text(
          'Logout',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Are you sure you want to logout?',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textMuted),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              // TODO: Implement logout
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Logging out...')),
              );
            },
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Text(
                    AppLocalization.profile,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  const LanguageButton(),
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _onSettingsTap,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: const Icon(
                        Icons.settings,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Profile Header
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Column(
                  children: [
                    // Avatar and Edit Button
                    Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            color: AppColors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(50),
                            border:
                                Border.all(color: AppColors.green, width: 3),
                          ),
                          child: const Icon(
                            Icons.person,
                            size: 40,
                            color: AppColors.green,
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: GestureDetector(
                            onTap: _onEditProfile,
                            child: Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                color: AppColors.green,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                    color: AppColors.darkCard, width: 2),
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // User Info
                    Text(
                      _userName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 4),

                    Text(
                      _userEmail,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 14,
                      ),
                    ),

                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.phone,
                          color: AppColors.textMuted,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _userPhone,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.calendar_today,
                          color: AppColors.textMuted,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Member since $_memberSince',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Gaming Statistics
              Text(
                AppLocalization.gamingStatistics,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // Stats Grid
              Row(
                children: [
                  Expanded(
                    child: ProfileStatCard(
                      title: AppLocalization.hoursPlayed,
                      value: _totalHoursPlayed.toString(),
                      icon: Icons.videogame_asset,
                      color: AppColors.green,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ProfileStatCard(
                      title: AppLocalization.totalBookings,
                      value: _totalBookings.toString(),
                      icon: Icons.book_online,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12),

              Row(
                children: [
                  Expanded(
                    child: ProfileStatCard(
                      title: AppLocalization.favorites,
                      value: _favoriteCenters.length.toString(),
                      icon: Icons.favorite,
                      color: Colors.red,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ProfileStatCard(
                      title: AppLocalization.achievements,
                      value: _achievements.toString(),
                      icon: Icons.emoji_events,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Favorite Gaming Centers
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Favorite Centers',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  TextButton(
                    onPressed: () {
                      // TODO: Navigate to all favorites
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

              // Favorite Centers List
              SizedBox(
                height: 120,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _favoriteCenters.length,
                  itemBuilder: (context, index) {
                    final center = _favoriteCenters[index];
                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: FavoriteCenterCard(
                        name: center['name'],
                        rating: center['rating'],
                        distance: center['distance'],
                        isOpen: center['isOpen'],
                        onTap: () {
                          // TODO: Navigate to center details
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 32),

              // Recent Activity
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              // Activity List
              ..._recentActivities.map((activity) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: ActivityItem(
                    icon: activity['icon'],
                    color: activity['color'],
                    title: activity['title'],
                    subtitle: activity['center'],
                    time: activity['time'],
                    onTap: () {
                      // TODO: Handle activity tap
                    },
                  ),
                );
              }),

              const SizedBox(height: 32),

              // Menu Items
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 16),

              _buildMenuItem(
                icon: Icons.person_outline,
                title: 'Personal Information',
                onTap: () {},
              ),

              const SizedBox(height: 12),

              _buildMenuItem(
                icon: Icons.payment_outlined,
                title: 'Payment Methods',
                onTap: () {},
              ),

              const SizedBox(height: 12),

              _buildMenuItem(
                icon: Icons.history_outlined,
                title: 'Booking History',
                onTap: () {},
              ),

              const SizedBox(height: 12),

              _buildMenuItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {},
              ),

              const SizedBox(height: 12),

              _buildMenuItem(
                icon: Icons.logout,
                title: 'Logout',
                onTap: _onLogout,
                isDestructive: true,
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isDestructive ? AppColors.error : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: isDestructive ? AppColors.error : Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: AppColors.textMuted,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }
}
