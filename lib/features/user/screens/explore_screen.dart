import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';

  final List<String> _categories = ['All', 'PS5', 'PC Gaming', 'VIP Rooms'];

  @override
  void initState() {
    super.initState();
    // Request location on startup
    Future.microtask(() => ref.read(locationProvider.notifier).requestAndGetLocation());
    
    _searchController.addListener(() {
      setState(() {
        _searchQuery = _searchController.text.trim();
      });
    });
  }

  @override
  void dispose() {
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
                        'GamingHub',
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

            // Categories
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const AlwaysScrollableScrollPhysics(),
                  itemCount: _categories.length,
                  itemBuilder: (context, index) {
                    final category = _categories[index];
                    final isSelected = category == _selectedCategory;

                    return Padding(
                      padding: const EdgeInsets.only(right: 12.0),
                      child: CategoryChip(
                        label: category,
                        isSelected: isSelected,
                        onTap: () {
                          setState(() {
                            _selectedCategory = category;
                          });
                        },
                      ),
                    );
                  },
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
                    data: (cybers) {
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
                            // Featured Centers Header (only if not searching)
                            if (_searchQuery.isEmpty) ...[
                              featuredAsync.when(
                                data: (featured) {
                                  if (featured.isEmpty) return const SizedBox.shrink();
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Padding(
                                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                                        child: Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              'Featured Centers',
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
                                          itemCount: featured.length,
                                          itemBuilder: (context, index) {
                                            final cyber = featured[index];
                                            return Padding(
                                              padding: const EdgeInsets.only(right: 16.0),
                                              child: GamingCenterCard(
                                                isFeatured: true,
                                                name: cyber.name,
                                                rating: cyber.rating,
                                                location: cyber.address ?? cyber.city ?? '',
                                                price: 'From EGP 15/hr', // Default room pricing
                                                imageUrl: cyber.images.isNotEmpty 
                                                    ? cyber.images[0] 
                                                    : 'https://picsum.photos/seed/${cyber.id}/300/150',
                                                isAvailable: cyber.isActive,
                                                onTap: () => context.push('/cyber/${cyber.id}'),
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
                                error: (e, s) => const SizedBox.shrink(),
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
                                      imageUrl: cyber.images.isNotEmpty 
                                          ? cyber.images[0] 
                                          : 'https://picsum.photos/seed/${cyber.id}/80/80',
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
