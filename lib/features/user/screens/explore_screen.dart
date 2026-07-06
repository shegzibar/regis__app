import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/location_provider.dart';
import '../../../core/providers/cyber_provider.dart';
import '../../../core/providers/wallet_provider.dart';
import '../../../shared/widgets/gaming_center_card.dart';
import '../../../shared/widgets/category_chip.dart';

class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> with WidgetsBindingObserver {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Request location immediately on startup
    Future.microtask(() => ref.read(locationProvider.notifier).requestAndGetLocation());
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Re-fetch location when app comes back to foreground
    if (state == AppLifecycleState.resumed) {
      ref.read(locationProvider.notifier).requestAndGetLocation();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _searchController.dispose();
    super.dispose();
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Forya',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            size: 16,
                            color: AppColors.textMuted,
                          ),
                          const SizedBox(width: 4),
                          const Text(
                            'Maadi, Cairo',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Wallet Card
                  Consumer(
                    builder: (context, ref, child) {
                      final walletAsync = ref.watch(userWalletProvider);
                      
                      return GestureDetector(
                        onTap: () => context.push('/wallet'),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.green.withValues(alpha: 0.1),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.green.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.account_balance_wallet, color: AppColors.green, size: 16),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('My Wallet', style: TextStyle(color: AppColors.textMuted, fontSize: 10)),
                                  walletAsync.when(
                                    loading: () => const SizedBox(
                                      width: 20, 
                                      height: 14, 
                                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.green)
                                    ),
                                    error: (_, __) => const Text('Error', style: TextStyle(color: AppColors.error, fontSize: 14, fontWeight: FontWeight.bold)),
                                    data: (wallet) => Text(
                                      '${wallet?.balance ?? 0} pts',
                                      style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            // Search Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: TextField(
                  controller: _searchController,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'Search gaming centers...',
                    hintStyle: const TextStyle(color: AppColors.textMuted),
                    prefixIcon: const Icon(
                      Icons.search,
                      color: AppColors.textMuted,
                      size: 24,
                    ),
                    suffixIcon: Container(
                      margin: const EdgeInsets.all(8),
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.green,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.tune,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 16),
                  ),
                ),
              ),
            ),



            const SizedBox(height: 24),

            // Content
            Expanded(
              child: Consumer(
                builder: (context, ref, child) {
                  final cybersAsync = ref.watch(cyberSearchProvider(_searchQuery));
                  final featuredAsync = ref.watch(featuredCybersProvider);

                  return cybersAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(color: AppColors.green),
                    ),
                    error: (err, stack) => Center(
                      child: Text(
                        'Error loading centers: $err',
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                    data: (unfilteredCybers) {
                      final location = ref.watch(locationProvider).value;
                      final cybers = unfilteredCybers.where((cyber) {
                        if (location == null) return true; // Show all if location not available
                        if (cyber.lat == null || cyber.lng == null) return false; // Hide if cyber has no location
                        
                        final distance = Geolocator.distanceBetween(
                          location.latitude,
                          location.longitude,
                          cyber.lat!,
                          cyber.lng!,
                        );
                        return distance <= 10000; // 10 km in meters
                      }).toList();

                      if (cybers.isEmpty) {
                        return const Center(
                          child: Text(
                            'No gaming centers found',
                            style: TextStyle(color: AppColors.textMuted, fontSize: 16),
                          ),
                        );
                      }

                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // All Centers Horizontal List (only if not searching)
                            if (_searchQuery.isEmpty) ...[
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        const Text(
                                          'All Gaming Centers',
                                          style: TextStyle(
                                            fontSize: 20,
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
                                  ),
                                  const SizedBox(height: 16),
                                  SizedBox(
                                    height: 200,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      physics: const AlwaysScrollableScrollPhysics(),
                                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                      itemCount: unfilteredCybers.length,
                                      itemBuilder: (context, index) {
                                        final cyber = unfilteredCybers[index];
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 16.0),
                                          child: GamingCenterCard(
                                            isFeatured: true,
                                            name: cyber.name,
                                            rating: cyber.rating,
                                            location: cyber.address ?? cyber.city ?? '',
                                            price: 'From EGP 15/hr', // Default room pricing
                                            imageUrl: cyber.coverImage ?? (cyber.images.isNotEmpty 
                                                ? cyber.images[0] 
                                                : 'https://picsum.photos/seed/${cyber.id}/300/150'),
                                            isAvailable: cyber.isActive,
                                            onTap: () => context.push('/cyber/${cyber.id}'),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                ],
                              ),
                            ],

                            // Nearby You / Search Results Header
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Text(
                                _searchQuery.isEmpty ? 'Nearby You' : 'Search Results',
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),

                            const SizedBox(height: 16),

                            // Centers List
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 24.0),
                              child: Column(
                                children: cybers.map((cyber) {
                                  return Padding(
                                    padding: const EdgeInsets.only(bottom: 16.0),
                                    child: GamingCenterCard(
                                      isFeatured: false,
                                      name: cyber.name,
                                      rating: cyber.rating,
                                      reviewCount: cyber.reviewCount,
                                      location: cyber.address ?? cyber.city ?? '',
                                      price: 'EGP 15 per hour',
                                      imageUrl: cyber.coverImage ?? (cyber.images.isNotEmpty 
                                          ? cyber.images[0] 
                                          : 'https://picsum.photos/seed/${cyber.id}/80/80'),
                                      consoles: const ['PS5', 'PC'], // Mock capabilities
                                      onTap: () => context.push('/cyber/${cyber.id}'),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(height: 32),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
