import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/profile_provider.dart';
import '../../../core/utils/date_utils.dart' as app_date;
import '../../../shared/widgets/favorite_center_card.dart';
import '../../../shared/widgets/activity_item.dart';
import '../../../shared/widgets/language_switcher.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../widgets/profile_user_info_card.dart';
import '../widgets/profile_menu_section.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  EdgeInsets _getResponsivePadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      return const EdgeInsets.all(16.0);
    } else if (screenWidth < 1200) {
      return const EdgeInsets.all(24.0);
    } else {
      return const EdgeInsets.all(32.0);
    }
  }

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
          ref.invalidate(profileDataProvider);
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
    final profileAsync = ref.watch(profileDataProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.green,
          backgroundColor: AppColors.darkCard,
          onRefresh: () async {
            ref.invalidate(profileDataProvider);
            await ref.read(profileDataProvider.future);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
                          'common.profile'.tr(),
                          style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width < 600
                                ? 20
                                : 24,
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
                ProfileUserInfoCard(onEditProfile: _onEditProfile),

                SizedBox(
                    height: _getResponsiveSpacing(context,
                        mobile: 20, tablet: 24, desktop: 28)),

                Text(
                  'profile.favorite_centers'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                SizedBox(
                    height: _getResponsiveSpacing(context,
                        mobile: 12, tablet: 16, desktop: 20)),

                profileAsync.when(
                  loading: () => const SizedBox(
                    height: 140,
                    child: Center(child: LoadingWidget()),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (profile) {
                    if (profile.favoriteCenters.isEmpty) {
                      return EmptyState(
                        icon: Icons.favorite_border,
                        title: 'errors.no_data_available'.tr(),
                        subtitle:
                            'Book a session to see your top centers here.',
                      );
                    }
                    return SizedBox(
                      height: 140,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: profile.favoriteCenters.length,
                        itemBuilder: (context, index) {
                          final center = profile.favoriteCenters[index];
                          return Padding(
                            padding: EdgeInsets.only(
                                right: _getResponsiveSpacing(context,
                                    mobile: 8, tablet: 12, desktop: 16)),
                            child: FavoriteCenterCard(
                              name: center.name,
                              rating: center.rating,
                              distance: center.distanceKm,
                              isOpen: center.isOpen,
                              onTap: () => context.push('/cyber/${center.id}'),
                            ),
                          );
                        },
                      ),
                    );
                  },
                ),

                SizedBox(
                    height: _getResponsiveSpacing(context,
                        mobile: 20, tablet: 32, desktop: 40)),

                Text(
                  'profile.recent_activity'.tr(),
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),

                SizedBox(
                    height: _getResponsiveSpacing(context,
                        mobile: 12, tablet: 16, desktop: 20)),

                profileAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: LoadingWidget(),
                  ),
                  error: (_, __) => const SizedBox.shrink(),
                  data: (profile) {
                    if (profile.recentActivities.isEmpty) {
                      return EmptyState(
                        icon: Icons.history,
                        title: 'errors.no_data_available'.tr(),
                        subtitle: 'Your bookings and reviews will appear here.',
                      );
                    }
                    return Column(
                      children: profile.recentActivities.map((activity) {
                        return Padding(
                          padding: EdgeInsets.only(
                              bottom: _getResponsiveSpacing(context,
                                  mobile: 8, tablet: 12, desktop: 16)),
                          child: ActivityItem(
                            icon: activity.icon,
                            color: activity.color,
                            title: activity.title,
                            subtitle: activity.subtitle,
                            time: app_date.DateUtils.getRelativeTime(
                                activity.createdAt),
                            onTap: () {
                              if (activity.routeCyberId != null) {
                                context.push('/cyber/${activity.routeCyberId}');
                              }
                            },
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),

                SizedBox(
                    height: _getResponsiveSpacing(context,
                        mobile: 20, tablet: 32, desktop: 40)),

                // Menu Items
                ProfileMenuSection(onLogout: _onLogout),

                SizedBox(
                    height: _getResponsiveSpacing(context,
                        mobile: 20, tablet: 32, desktop: 40)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
