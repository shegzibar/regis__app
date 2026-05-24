import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/models/booking.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../data/supabase/supabase_client.dart';

final ownerPendingRequestsProvider =
    FutureProvider.autoDispose<List<Booking>>((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];

  try {
    final response = await SupabaseService()
        .from('bookings')
        .select('''
          *,
          stations!inner(
            id, name, room_id,
            rooms!inner(
              id, name, type,
              cybers!inner(id, name, owner_id)
            )
          )
        ''')
        .inFilter('status', ['pending_payment', 'fee_under_review'])
        .eq('stations.rooms.cybers.owner_id', user.id)
        .order('created_at', ascending: false);

    return (response as List).map((b) => Booking.fromMap(b)).toList();
  } catch (_) {
    return [];
  }
});

class OwnerRequestsScreen extends ConsumerWidget {
  const OwnerRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requestsAsync = ref.watch(ownerPendingRequestsProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
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
                    'Booking Requests',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  requestsAsync.maybeWhen(
                    data: (list) => list.isNotEmpty
                        ? Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.purple.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              '${list.length} pending',
                              style: const TextStyle(
                                color: AppColors.purple,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          )
                        : const SizedBox.shrink(),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Review and approve or reject incoming bookings',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),

            const SizedBox(height: 20),
            const Divider(color: AppColors.lightGray, height: 1),

            // Content
            Expanded(
              child: requestsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.teal)),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      const Text('Failed to load requests',
                          style: TextStyle(color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () =>
                            ref.invalidate(ownerPendingRequestsProvider),
                        child: const Text('Retry',
                            style: TextStyle(color: AppColors.teal)),
                      ),
                    ],
                  ),
                ),
                data: (requests) {
                  if (requests.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.teal.withOpacity(0.08),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check_circle_outline,
                                color: AppColors.teal, size: 40),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'All caught up!',
                            style: TextStyle(
                              color: AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'No pending booking requests',
                            style: TextStyle(
                                color: AppColors.textSecondary, fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(ownerPendingRequestsProvider),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(24),
                      itemCount: requests.length,
                      itemBuilder: (context, index) {
                        return _RequestCard(
                          booking: requests[index],
                          onDecision: () =>
                              ref.invalidate(ownerPendingRequestsProvider),
                        );
                      },
                    ),
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

class _RequestCard extends StatefulWidget {
  final Booking booking;
  final VoidCallback onDecision;

  const _RequestCard({required this.booking, required this.onDecision});

  @override
  State<_RequestCard> createState() => _RequestCardState();
}

class _RequestCardState extends State<_RequestCard> {
  bool _isProcessing = false;

  Future<void> _handleDecision(BuildContext context, String newStatus) async {
    setState(() => _isProcessing = true);
    try {
      await BookingRepository().updateBookingStatus(
        widget.booking.id,
        newStatus,
        confirmedAt: newStatus == 'confirmed' ? DateTime.now() : null,
      );
      widget.onDecision();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(newStatus == 'confirmed'
                ? 'Booking confirmed ✓'
                : 'Booking rejected'),
            backgroundColor:
                newStatus == 'confirmed' ? AppColors.teal : AppColors.error,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final booking = widget.booking;
    final isUnderReview = booking.isFeeUnderReview;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        children: [
          // Status bar top
          Container(
            height: 4,
            decoration: BoxDecoration(
              color: isUnderReview
                  ? AppColors.purple
                  : AppColors.statusPending,
              borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(16)),
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.teal.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.person_outline,
                          color: AppColors.teal, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Booking #${booking.id.substring(0, 8).toUpperCase()}',
                            style: const TextStyle(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                          Text(
                            isUnderReview
                                ? 'Fee Under Review'
                                : 'Pending Payment',
                            style: TextStyle(
                              color: isUnderReview
                                  ? AppColors.purple
                                  : AppColors.statusPending,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),
                const Divider(color: AppColors.lightGray, height: 1),
                const SizedBox(height: 14),

                // Info grid
                Row(
                  children: [
                    Expanded(
                      child: _InfoRow(
                          icon: Icons.schedule,
                          label: _formatDateTime(booking.startTime)),
                    ),
                    Expanded(
                      child: _InfoRow(
                          icon: Icons.timelapse,
                          label:
                              '${booking.durationHours.toInt()}h session'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _InfoRow(
                          icon: Icons.payments_outlined,
                          label:
                              'EGP ${booking.totalAmount.toStringAsFixed(0)} total'),
                    ),
                    Expanded(
                      child: _InfoRow(
                          icon: Icons.confirmation_number_outlined,
                          label:
                              'Fee: EGP ${booking.bookingFee.toStringAsFixed(0)}'),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Action buttons
                if (_isProcessing)
                  const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.teal))
                else
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              _handleDecision(context, 'rejected'),
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            side: BorderSide(
                                color: AppColors.error.withOpacity(0.5)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () =>
                              _handleDecision(context, 'confirmed'),
                          icon: const Icon(Icons.check, size: 16),
                          label: const Text('Confirm'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.teal,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding:
                                const EdgeInsets.symmetric(vertical: 12),
                          ),
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

  String _formatDateTime(DateTime dt) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '${dt.day} ${months[dt.month - 1]}  $h:$m $period';
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
