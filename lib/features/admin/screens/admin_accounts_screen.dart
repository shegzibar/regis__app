import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/cyber.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/cyber_repository.dart';
import '../../../data/repositories/user_repository.dart';

// â”€â”€â”€ Providers â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final _allCybersProvider = FutureProvider.autoDispose<List<Cyber>>((ref) async {
  return await CyberRepository().getAllCybers();
});

final _allUsersProvider =
    FutureProvider.autoDispose<List<AppUser>>((ref) async {
  return await UserRepository().getAllUsers();
});

/// Provider that fetches enriched bookings for a given userId.
final _userBookingsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final data = await Supabase.instance.client.from('bookings').select('''
    id, status, start_time, end_time, total_amount, booking_fee,
    created_at, notes, confirmed_at,
    stations(
      name,
      rooms(
        name, type,
        cybers(name, city)
      )
    )
  ''').eq('user_id', userId).order('created_at', ascending: false);
  return (data as List).cast<Map<String, dynamic>>();
});

// â”€â”€â”€ Screen â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class AdminAccountsScreen extends ConsumerStatefulWidget {
  const AdminAccountsScreen({super.key});

  @override
  ConsumerState<AdminAccountsScreen> createState() =>
      _AdminAccountsScreenState();
}

class _AdminAccountsScreenState extends ConsumerState<AdminAccountsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // â”€â”€ Header â”€â”€
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Accounts & Directory',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Manage all cybers and user accounts',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: () {
                      ref.invalidate(_allCybersProvider);
                      ref.invalidate(_allUsersProvider);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: const Icon(
                        Icons.refresh,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // â”€â”€ Tabs â”€â”€
            TabBar(
              controller: _tabController,
              indicatorColor: AppColors.green,
              labelColor: AppColors.green,
              unselectedLabelColor: AppColors.textMuted,
              dividerColor: AppColors.darkBorder,
              tabs: const [
                Tab(text: 'Cyber CafÃ©s', icon: Icon(Icons.store_outlined)),
                Tab(text: 'Users & Owners', icon: Icon(Icons.people_outline)),
              ],
            ),

            // â”€â”€ Tab Views â”€â”€
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _CybersTab(),
                  _UsersTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// â”€â”€â”€ Cybers Tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _CybersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(_allCybersProvider);

    return asyncData.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            const Text('Failed to load cybers',
                style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Text(err.toString(),
                style: const TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
      data: (cybers) {
        if (cybers.isEmpty) {
          return const Center(
            child: Text('No cyber cafÃ©s found',
                style: TextStyle(color: AppColors.textMuted)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: cybers.length,
          itemBuilder: (context, index) {
            final cyber = cybers[index];
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.green.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.computer, color: AppColors.green),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cyber.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.location_city,
                                size: 14, color: AppColors.textMuted),
                            const SizedBox(width: 4),
                            Text(
                              cyber.city ?? 'No city set',
                              style: const TextStyle(
                                  color: AppColors.textMuted, fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: cyber.isActive
                          ? AppColors.green.withValues(alpha: 0.1)
                          : AppColors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      cyber.isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        color: cyber.isActive ? AppColors.green : AppColors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// â”€â”€â”€ Users Tab â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _UsersTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncData = ref.watch(_allUsersProvider);

    return asyncData.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: AppColors.green),
      ),
      error: (err, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: 48),
            const SizedBox(height: 12),
            const Text('Failed to load users',
                style: TextStyle(color: Colors.white)),
            const SizedBox(height: 8),
            Text(err.toString(),
                style: const TextStyle(color: AppColors.textMuted)),
          ],
        ),
      ),
      data: (users) {
        if (users.isEmpty) {
          return const Center(
            child: Text('No users found',
                style: TextStyle(color: AppColors.textMuted)),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];

            Color roleColor;
            switch (user.role) {
              case 'admin':
                roleColor = AppColors.purple;
                break;
              case 'owner':
                roleColor = AppColors.amber;
                break;
              case 'manager':
                roleColor = Colors.blue;
                break;
              default:
                roleColor = AppColors.green;
            }

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _showUserBookings(context, user, roleColor),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: roleColor.withValues(alpha: 0.15),
                      radius: 24,
                      child: Text(
                        (user.name ?? '?').isNotEmpty
                            ? (user.name ?? '?')[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: roleColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name ?? 'Unknown',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Icon(Icons.phone,
                                  size: 14, color: AppColors.textMuted),
                              const SizedBox(width: 4),
                              Text(
                                (user.phone?.isEmpty ?? true)
                                    ? 'No phone'
                                    : user.phone!,
                                style: const TextStyle(
                                    color: AppColors.textMuted, fontSize: 13),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: roleColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(
                        user.role.toUpperCase(),
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.chevron_right,
                        color: AppColors.textMuted, size: 20),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showUserBookings(BuildContext context, AppUser user, Color roleColor) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AdminUserBookingsSheet(user: user, roleColor: roleColor),
    );
  }
}

// â”€â”€â”€ User Bookings Bottom Sheet â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _AdminUserBookingsSheet extends ConsumerWidget {
  final AppUser user;
  final Color roleColor;

  const _AdminUserBookingsSheet({
    required this.user,
    required this.roleColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBookings = ref.watch(_userBookingsProvider(user.id));

    return DraggableScrollableSheet(
      initialChildSize: 0.75,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (_, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColors.darkBg,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // â”€â”€ Drag handle â”€â”€
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.darkBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),

              // â”€â”€ User header â”€â”€
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: roleColor.withValues(alpha: 0.15),
                      child: Text(
                        (user.name ?? '?').isNotEmpty
                            ? (user.name ?? '?')[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            user.name ?? 'Unknown User',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: roleColor.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: roleColor.withValues(alpha: 0.3)),
                                ),
                                child: Text(
                                  user.role.toUpperCase(),
                                  style: TextStyle(
                                    color: roleColor,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              if (user.phone != null &&
                                  user.phone!.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                const Icon(Icons.phone,
                                    size: 12, color: AppColors.textMuted),
                                const SizedBox(width: 4),
                                Text(
                                  user.phone!,
                                  style: const TextStyle(
                                      color: AppColors.textMuted, fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 8),
              const Divider(color: AppColors.darkBorder, height: 1),
              const SizedBox(height: 4),

              // â”€â”€ Section label â”€â”€
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  children: [
                    const Icon(Icons.receipt_long_outlined,
                        color: AppColors.textMuted, size: 16),
                    const SizedBox(width: 8),
                    const Text(
                      'Booking History',
                      style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const Spacer(),
                    asyncBookings.maybeWhen(
                      data: (list) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          '${list.length} bookings',
                          style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 12,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      orElse: () => const SizedBox.shrink(),
                    ),
                  ],
                ),
              ),

              // â”€â”€ Booking list â”€â”€
              Expanded(
                child: asyncBookings.when(
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.green),
                  ),
                  error: (err, _) => Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline,
                            color: AppColors.error, size: 48),
                        const SizedBox(height: 12),
                        const Text('Failed to load bookings',
                            style: TextStyle(color: Colors.white)),
                        const SizedBox(height: 8),
                        Text(err.toString(),
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12),
                            textAlign: TextAlign.center),
                      ],
                    ),
                  ),
                  data: (bookings) {
                    if (bookings.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                color:
                                    AppColors.textMuted.withValues(alpha: 0.4),
                                size: 56),
                            const SizedBox(height: 16),
                            const Text(
                              'No bookings yet',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 15),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView.builder(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      itemCount: bookings.length,
                      itemBuilder: (context, index) {
                        final b = bookings[index];
                        return _BookingCard(booking: b);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// â”€â”€â”€ Booking Card â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class _BookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  const _BookingCard({required this.booking});

  Color _statusColor(String status) {
    switch (status) {
      case 'confirmed':
        return AppColors.statusConfirmed;
      case 'completed':
        return AppColors.statusCompleted;
      case 'rejected':
        return AppColors.statusRejected;
      case 'cancelled':
        return AppColors.statusCancelled;
      case 'fee_under_review':
        return Colors.blue;
      default:
        return AppColors.statusPending;
    }
  }

  IconData _typeIcon(String? type) {
    switch (type) {
      case 'ps5':
        return Icons.sports_esports;
      case 'vip':
        return Icons.star_outline;
      default:
        return Icons.computer;
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = booking['status'] as String? ?? 'pending_payment';
    final statusColor = _statusColor(status);
    final station = booking['stations'] as Map<String, dynamic>?;
    final room = station?['rooms'] as Map<String, dynamic>?;
    final cyber = room?['cybers'] as Map<String, dynamic>?;
    final startTime = booking['start_time'] != null
        ? DateTime.tryParse(booking['start_time'])
        : null;
    final endTime = booking['end_time'] != null
        ? DateTime.tryParse(booking['end_time'])
        : null;
    final amount = (booking['total_amount'] as num?)?.toDouble() ?? 0.0;
    final fee = (booking['booking_fee'] as num?)?.toDouble() ?? 0.0;
    final roomType = room?['type'] as String?;

    final dateFmt = DateFormat('MMM d, yyyy');
    final timeFmt = DateFormat('h:mm a');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        children: [
          // Top row: cyber + status
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(_typeIcon(roomType), color: statusColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cyber?['name'] ?? 'Unknown Cyber',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                      if (cyber?['city'] != null)
                        Text(
                          cyber!['city'],
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border:
                        Border.all(color: statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    status.replaceAll('_', ' ').toUpperCase(),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, color: AppColors.darkBorder),

          // Bottom row: room, date, time, price
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
            child: Row(
              children: [
                // Room info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (room != null)
                        Text(
                          '${room['name'] ?? ''} Â· ${(roomType ?? '').toUpperCase()}',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                      if (station != null)
                        Text(
                          station['name'] ?? '',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                // Date & time
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    if (startTime != null)
                      Row(
                        children: [
                          const Icon(Icons.calendar_month_outlined,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            dateFmt.format(startTime.toLocal()),
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    if (startTime != null && endTime != null)
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${timeFmt.format(startTime.toLocal())} â€“ ${timeFmt.format(endTime.toLocal())}',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    const SizedBox(height: 4),
                    Text(
                      'SAR ${amount.toStringAsFixed(0)}'
                      '${fee > 0 ? '  (+${fee.toStringAsFixed(0)} fee)' : ''}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
