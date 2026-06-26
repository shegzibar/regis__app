import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/user.dart';
import '../providers/admin_accounts_providers.dart';

class AdminUserBookingsSheet extends ConsumerWidget {
  final AppUser user;
  final Color roleColor;

  const AdminUserBookingsSheet({
    super.key,
    required this.user,
    required this.roleColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncBookings = ref.watch(userBookingsProvider(user.id));

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
              // ── Drag handle ──
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

              // ── User header ──
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

              // ── Section label ──
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

              // ── Booking list ──
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
                        return AdminBookingCard(booking: b);
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

class AdminBookingCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  const AdminBookingCard({super.key, required this.booking});

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
                          '${room['name'] ?? ''} • ${(roomType ?? '').toUpperCase()}',
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
                          const Icon(Icons.calendar_today,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            dateFmt.format(startTime.toLocal()),
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                    const SizedBox(height: 2),
                    if (startTime != null && endTime != null)
                      Row(
                        children: [
                          const Icon(Icons.access_time,
                              size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Text(
                            '${timeFmt.format(startTime.toLocal())} - ${timeFmt.format(endTime.toLocal())}',
                            style: const TextStyle(
                                color: AppColors.textMuted, fontSize: 12),
                          ),
                        ],
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Pricing row if applicable
          if (amount > 0 || fee > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(14)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (fee > 0)
                    Text(
                      'Fee: ${fee.toStringAsFixed(0)} EGP',
                      style: TextStyle(
                        color: Colors.orange.shade300,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    const SizedBox.shrink(),
                  if (amount > 0)
                    Text(
                      'Total: ${amount.toStringAsFixed(0)} EGP',
                      style: const TextStyle(
                        color: AppColors.green,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
