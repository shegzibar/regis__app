import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/models/booking.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../data/repositories/cyber_repository.dart';

final ownerCybersProvider = FutureProvider.autoDispose((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];
  return CyberRepository().getCybersByOwner(user.id);
});

final ownerRecentBookingsProvider =
    FutureProvider.autoDispose<List<Booking>>((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];
  final response = await BookingRepository().getUserBookings(user.id);
  return response.take(5).toList();
});

class OwnerHomeScreen extends ConsumerWidget {
  const OwnerHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final cybersAsync = ref.watch(ownerCybersProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.green,
          backgroundColor: AppColors.darkCard,
          onRefresh: () async {
            ref.invalidate(ownerCybersProvider);
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.store,
                          color: AppColors.green, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome back,',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 13),
                        ),
                        Text(
                          user?.name ?? 'Owner',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Stats Cards
                cybersAsync.when(
                  loading: () => const _StatsShimmer(),
                  error: (_, __) => const _StatsError(),
                  data: (cybers) => _StatsRow(cyberCount: cybers.length),
                ),

                const SizedBox(height: 28),

                // Quick Actions
                const Text(
                  'Quick Actions',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.calendar_view_day,
                        label: 'Schedule',
                        color: AppColors.green,
                        onTap: () => context.push('/owner/schedule'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.pending_actions,
                        label: 'Requests',
                        color: AppColors.purple,
                        onTap: () => context.push('/owner/requests'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _QuickActionCard(
                        icon: Icons.computer,
                        label: 'Stations',
                        color: Colors.amber,
                        onTap: () => context.push('/owner/stations'),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // My Cybers
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'My Gaming Centers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                cybersAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator(color: AppColors.green)),
                  error: (e, _) => Text('Error: $e',
                      style: const TextStyle(color: AppColors.error)),
                  data: (cybers) {
                    if (cybers.isEmpty) {
                      return const _EmptyCard(
                        icon: Icons.store_mall_directory_outlined,
                        message: 'No gaming centers yet',
                        sub: 'Contact admin to register your center',
                      );
                    }
                    return Column(
                      children: cybers
                          .map((cyber) => _CyberSummaryCard(
                                name: cyber.name,
                                city: cyber.city ?? 'Cairo',
                                rating: cyber.rating,
                                isActive: cyber.isActive,
                              ))
                          .toList(),
                    );
                  },
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  final int cyberCount;
  const _StatsRow({required this.cyberCount});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'Centers',
            value: '$cyberCount',
            icon: Icons.store,
            color: AppColors.green,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: _StatCard(
            label: 'Today\'s Sessions',
            value: '—',
            icon: Icons.calendar_today,
            color: AppColors.purple,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: _StatCard(
            label: 'Pending',
            value: '—',
            icon: Icons.pending_actions,
            color: Colors.amber,
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CyberSummaryCard extends StatelessWidget {
  final String name;
  final String city;
  final double rating;
  final bool isActive;

  const _CyberSummaryCard({
    required this.name,
    required this.city,
    required this.rating,
    required this.isActive,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.videogame_asset,
                color: AppColors.green, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    )),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        size: 12, color: AppColors.textMuted),
                    const SizedBox(width: 3),
                    Text(city,
                        style: const TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                children: [
                  const Icon(Icons.star_rounded,
                      size: 14, color: Colors.amber),
                  const SizedBox(width: 3),
                  Text(
                    rating.toStringAsFixed(1),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isActive
                      ? AppColors.green.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isActive ? AppColors.green : AppColors.error,
                  ),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    color: isActive ? AppColors.green : AppColors.error,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final IconData icon;
  final String message;
  final String sub;
  const _EmptyCard(
      {required this.icon, required this.message, required this.sub});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        children: [
          Icon(icon, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(message,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w600,
                  fontSize: 15)),
          const SizedBox(height: 4),
          Text(sub,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13)),
        ],
      ),
    );
  }
}

class _StatsShimmer extends StatelessWidget {
  const _StatsShimmer();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
          3,
          (_) => Expanded(
                child: Container(
                  margin: const EdgeInsets.only(right: 12),
                  height: 90,
                  decoration: BoxDecoration(
                    color: AppColors.darkCard,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.darkBorder),
                  ),
                ),
              )),
    );
  }
}

class _StatsError extends StatelessWidget {
  const _StatsError();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error),
      ),
      child: const Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 20),
          SizedBox(width: 8),
          Text('Could not load stats',
              style: TextStyle(color: AppColors.error)),
        ],
      ),
    );
  }
}
