import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/models/booking.dart';
import '../../../data/repositories/booking_repository.dart';

// Provider for user bookings
final userBookingsProvider = FutureProvider.autoDispose<List<Booking>>((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];
  return BookingRepository().getUserBookings(user.id);
});

class MyBookingsScreen extends ConsumerStatefulWidget {
  const MyBookingsScreen({super.key});

  @override
  ConsumerState<MyBookingsScreen> createState() => _MyBookingsScreenState();
}

class _MyBookingsScreenState extends ConsumerState<MyBookingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync = ref.watch(userBookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  const Text(
                    'My Bookings',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () => ref.invalidate(userBookingsProvider),
                    icon: const Icon(Icons.refresh, color: Colors.white),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Tab Bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.darkCard,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.darkBorder),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicator: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  indicatorSize: TabBarIndicatorSize.tab,
                  dividerColor: Colors.transparent,
                  labelColor: Colors.white,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: const [
                    Tab(text: 'Upcoming'),
                    Tab(text: 'Past'),
                    Tab(text: 'Cancelled'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Content
            Expanded(
              child: bookingsAsync.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.green),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Could not load bookings',
                        style: const TextStyle(
                            color: Colors.white, fontSize: 16),
                      ),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () => ref.invalidate(userBookingsProvider),
                        child: const Text('Retry',
                            style: TextStyle(color: AppColors.green)),
                      ),
                    ],
                  ),
                ),
                data: (bookings) {
                  final upcoming = bookings
                      .where((b) =>
                          !b.isCancelled &&
                          !b.isCompleted &&
                          (b.isUpcoming || b.isOngoing))
                      .toList();
                  final past = bookings
                      .where((b) => b.isCompleted || b.isPast)
                      .toList();
                  final cancelled = bookings
                      .where((b) => b.isCancelled || b.isRejected)
                      .toList();

                  return TabBarView(
                    controller: _tabController,
                    children: [
                      _BookingList(
                        bookings: upcoming,
                        emptyMessage: 'No upcoming bookings',
                        emptyIcon: Icons.calendar_today_outlined,
                        showCancelButton: true,
                        showPayButton: true,
                      ),
                      _BookingList(
                        bookings: past,
                        emptyMessage: 'No past bookings',
                        emptyIcon: Icons.history,
                        showReviewButton: true,
                      ),
                      _BookingList(
                        bookings: cancelled,
                        emptyMessage: 'No cancelled bookings',
                        emptyIcon: Icons.cancel_outlined,
                      ),
                    ],
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

class _BookingList extends ConsumerWidget {
  final List<Booking> bookings;
  final String emptyMessage;
  final IconData emptyIcon;
  final bool showCancelButton;
  final bool showPayButton;
  final bool showReviewButton;

  const _BookingList({
    required this.bookings,
    required this.emptyMessage,
    required this.emptyIcon,
    this.showCancelButton = false,
    this.showPayButton = false,
    this.showReviewButton = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (bookings.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(emptyIcon, color: AppColors.textMuted, size: 56),
            const SizedBox(height: 16),
            Text(
              emptyMessage,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Head to Explore to book a session',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: bookings.length,
      itemBuilder: (context, index) {
        final booking = bookings[index];
        return _BookingCard(
          booking: booking,
          showCancelButton: showCancelButton && booking.isPendingPayment,
          showPayButton: showPayButton && booking.isPendingPayment,
          showReviewButton: showReviewButton && booking.isCompleted,
          onActionDone: () => ref.invalidate(userBookingsProvider),
        );
      },
    );
  }
}

class _BookingCard extends StatelessWidget {
  final Booking booking;
  final bool showCancelButton;
  final bool showPayButton;
  final bool showReviewButton;
  final VoidCallback onActionDone;

  const _BookingCard({
    required this.booking,
    required this.showCancelButton,
    required this.showPayButton,
    required this.showReviewButton,
    required this.onActionDone,
  });

  Color get _statusColor {
    switch (booking.status) {
      case 'confirmed':
        return AppColors.statusConfirmed;
      case 'pending_payment':
      case 'fee_under_review':
        return AppColors.statusPending;
      case 'rejected':
      case 'cancelled':
        return AppColors.statusRejected;
      case 'completed':
        return AppColors.statusCompleted;
      default:
        return AppColors.gray;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.videogame_asset,
                  color: AppColors.green,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Booking #${booking.id.substring(0, 8).toUpperCase()}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDate(booking.startTime),
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              // Status pill
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _statusColor.withOpacity(0.4)),
                ),
                child: Text(
                  booking.statusDisplay,
                  style: TextStyle(
                    color: _statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),
          const Divider(color: AppColors.darkBorder, height: 1),
          const SizedBox(height: 14),

          // Details
          Row(
            children: [
              _InfoItem(
                icon: Icons.access_time,
                label: 'Duration',
                value: '${booking.durationHours.toInt()}h',
              ),
              const SizedBox(width: 24),
              _InfoItem(
                icon: Icons.schedule,
                label: 'Time',
                value: _formatTime(booking.startTime),
              ),
              const SizedBox(width: 24),
              _InfoItem(
                icon: Icons.payments_outlined,
                label: 'Fee',
                value: 'EGP ${booking.bookingFee.toStringAsFixed(0)}',
              ),
            ],
          ),

          // Action buttons
          if (showPayButton || showCancelButton || showReviewButton) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                if (showCancelButton)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _cancelBooking(context),
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                            color: AppColors.error.withOpacity(0.6)),
                        foregroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Cancel',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ),
                if (showCancelButton && showPayButton)
                  const SizedBox(width: 12),
                if (showPayButton)
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          context.push('/payment/${booking.id}?amount=${booking.totalAmount}'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      child: const Text('Pay Now',
                          style: TextStyle(fontSize: 13)),
                    ),
                  ),
                if (showReviewButton)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.star_outline, size: 16),
                      label: const Text('Leave Review',
                          style: TextStyle(fontSize: 13)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _cancelBooking(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.darkCard,
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Cancel Booking',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'Are you sure you want to cancel this booking?',
          style: TextStyle(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('No', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Yes, Cancel',
                style: TextStyle(color: AppColors.error)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await BookingRepository().cancelBooking(booking.id);
        onActionDone();
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to cancel: $e')),
          );
        }
      }
    }
  }

  String _formatDate(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 11)),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
