import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localization.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../shared/widgets/profile_stat_card.dart';
import '../../../shared/widgets/favorite_center_card.dart';
import '../../../shared/widgets/activity_item.dart';
import '../../../shared/widgets/language_switcher.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  // Controllers for edit profile dialog
  final _nameController = TextEditingController();

  // Mock gaming statistics (connect to real data later)
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

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  /// Get responsive padding based on screen width
  EdgeInsets _getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      // Mobile: 16px
      return const EdgeInsets.all(16.0);
    } else if (screenWidth < 1200) {
      // Tablet: 24px
      return const EdgeInsets.all(24.0);
    } else {
      // Desktop: 32px
      return const EdgeInsets.all(32.0);
    }
  }

  /// Get responsive spacing based on screen width
  double _getResponsiveSpacing(BuildContext context,
      {double mobile = 12, double tablet = 16, double desktop = 24}) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      return mobile;
    } else if (screenWidth < 1200) {
      return tablet;
    } else {
      return desktop;
    }
  }

  Future<void> _onEditProfile() async {
    final user = ref.read(authStateProvider);
    _nameController.text = user?.name ?? '';

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title:
            const Text('Edit Profile', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Display Name',
                labelStyle: const TextStyle(color: AppColors.textMuted),
                filled: true,
                fillColor: AppColors.darkBg,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.darkBorder),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: const BorderSide(color: AppColors.green),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Save',
                style: TextStyle(
                    color: AppColors.green, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (saved == true && mounted) {
      final newName = _nameController.text.trim();
      if (newName.isNotEmpty) {
        try {
          await ref
              .read(authControllerProvider.notifier)
              .updateProfile(name: newName);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Profile updated successfully!'),
                backgroundColor: AppColors.green,
              ),
            );
          }
        } catch (e) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update: $e'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      }
    }
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
              ref.read(authControllerProvider.notifier).signOut();
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
    // Read real user from Supabase auth state
    final user = ref.watch(authStateProvider);
    final displayName = user?.name?.isNotEmpty == true ? user!.name! : 'Gamer';
    final phone =
        user?.phone?.isNotEmpty == true ? user!.phone : 'No phone set';
    final memberSince = user != null
        ? '${_monthName(user.createdAt.month)} ${user.createdAt.year}'
        : '';

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: _getResponsivePadding(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              SizedBox(
                width: double.infinity,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        AppLocalization.profile,
                        style: TextStyle(
                          fontSize:
                              MediaQuery.of(context).size.width < 600 ? 20 : 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    SizedBox(
                        width: _getResponsiveSpacing(context,
                            mobile: 4, tablet: 8, desktop: 12)),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const LanguageButton(),
                        SizedBox(
                            width: _getResponsiveSpacing(context,
                                mobile: 6, tablet: 12, desktop: 16)),
                        GestureDetector(
                          onTap: _onSettingsTap,
                          child: Container(
                            width: MediaQuery.of(context).size.width < 600
                                ? 40
                                : 48,
                            height: MediaQuery.of(context).size.width < 600
                                ? 40
                                : 48,
                            decoration: BoxDecoration(
                              color: AppColors.darkCard,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.darkBorder),
                            ),
                            child: const Icon(
                              Icons.settings,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(
                  height: _getResponsiveSpacing(context,
                      mobile: 16, tablet: 24, desktop: 32)),

              // Profile Header
              Container(
                padding: EdgeInsets.all(_getResponsiveSpacing(context,
                    mobile: 16, tablet: 24, desktop: 32)),
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
                          child: user?.avatarUrl != null
                              ? ClipOval(
                                  child: Image.network(
                                    user!.avatarUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => const Icon(
                                      Icons.person,
                                      size: 40,
                                      color: AppColors.green,
                                    ),
                                  ),
                                )
                              : const Icon(
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

                    // User Name (live from Supabase)
                    Text(
                      displayName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Phone Number (live from Supabase)
                    Text(
                      phone ?? '',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: AppColors.green,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Role badge
                    if (user?.role != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: AppColors.green.withOpacity(0.4)),
                        ),
                        child: Text(
                          user!.role.toUpperCase(),
                          style: const TextStyle(
                            color: AppColors.green,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ),

                    const SizedBox(height: 12),

                    // Member since (live from Supabase)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.calendar_today,
                            color: AppColors.textMuted, size: 14),
                        const SizedBox(width: 6),
                        Text(
                          'Member since $memberSince',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              SizedBox(
                  height: _getResponsiveSpacing(context,
                      mobile: 20, tablet: 24, desktop: 28)),

              // Gaming Statistics
              Text(
                AppLocalization.gamingStatistics,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              SizedBox(
                  height: _getResponsiveSpacing(context,
                      mobile: 12, tablet: 16, desktop: 20)),

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
                  SizedBox(
                      width: _getResponsiveSpacing(context,
                          mobile: 8, tablet: 12, desktop: 16)),
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

              SizedBox(
                  height: _getResponsiveSpacing(context,
                      mobile: 8, tablet: 12, desktop: 16)),

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
                  SizedBox(
                      width: _getResponsiveSpacing(context,
                          mobile: 8, tablet: 12, desktop: 16)),
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

              SizedBox(
                  height: _getResponsiveSpacing(context,
                      mobile: 20, tablet: 32, desktop: 40)),

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

              SizedBox(
                  height: _getResponsiveSpacing(context,
                      mobile: 12, tablet: 16, desktop: 20)),

              // Favorite Centers List
              SizedBox(
                height: 140,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _favoriteCenters.length,
                  itemBuilder: (context, index) {
                    final center = _favoriteCenters[index];
                    return Padding(
                      padding: EdgeInsets.only(
                          right: _getResponsiveSpacing(context,
                              mobile: 8, tablet: 12, desktop: 16)),
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

              SizedBox(
                  height: _getResponsiveSpacing(context,
                      mobile: 20, tablet: 32, desktop: 40)),

              // Recent Activity
              const Text(
                'Recent Activity',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              SizedBox(
                  height: _getResponsiveSpacing(context,
                      mobile: 12, tablet: 16, desktop: 20)),

              // Activity List
              ..._recentActivities.map((activity) {
                return Padding(
                  padding: EdgeInsets.only(
                      bottom: _getResponsiveSpacing(context,
                          mobile: 8, tablet: 12, desktop: 16)),
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

              SizedBox(
                  height: _getResponsiveSpacing(context,
                      mobile: 20, tablet: 32, desktop: 40)),

              // Menu Items
              const Text(
                'Settings',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),

              SizedBox(
                  height: _getResponsiveSpacing(context,
                      mobile: 12, tablet: 16, desktop: 20)),

              _buildMenuItem(
                icon: Icons.person_outline,
                title: 'Personal Information',
                onTap: () {},
              ),

              SizedBox(
                  height: _getResponsiveSpacing(context,
                      mobile: 8, tablet: 12, desktop: 16)),

              _buildMenuItem(
                icon: Icons.payment_outlined,
                title: 'Payment Methods',
                onTap: () {},
              ),

              SizedBox(
                  height: _getResponsiveSpacing(context,
                      mobile: 8, tablet: 12, desktop: 16)),

              _buildMenuItem(
                icon: Icons.history_outlined,
                title: 'Booking History',
                onTap: () {},
              ),

              SizedBox(
                  height: _getResponsiveSpacing(context,
                      mobile: 8, tablet: 12, desktop: 16)),

              _buildMenuItem(
                icon: Icons.help_outline,
                title: 'Help & Support',
                onTap: () {},
              ),

              SizedBox(
                  height: _getResponsiveSpacing(context,
                      mobile: 8, tablet: 12, desktop: 16)),

              _buildMenuItem(
                icon: Icons.logout,
                title: 'Logout',
                onTap: _onLogout,
                isDestructive: true,
              ),

              SizedBox(
                  height: _getResponsiveSpacing(context,
                      mobile: 20, tablet: 32, desktop: 40)),
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
        padding: EdgeInsets.all(_getResponsiveSpacing(context,
            mobile: 12, tablet: 16, desktop: 20)),
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
            SizedBox(
                width: _getResponsiveSpacing(context,
                    mobile: 12, tablet: 16, desktop: 20)),
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

  String _monthName(int month) {
    const months = [
      '',
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return months[month];
  }
}
