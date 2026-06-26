import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../shared/widgets/deposit_review_card.dart';
import '../providers/admin_providers.dart';

class AdminPendingReviewsSection extends ConsumerStatefulWidget {
  const AdminPendingReviewsSection({super.key});

  @override
  ConsumerState<AdminPendingReviewsSection> createState() => _AdminPendingReviewsSectionState();
}

class _AdminPendingReviewsSectionState extends ConsumerState<AdminPendingReviewsSection> {
  Future<void> _approveDeposit(String depositId) async {
    try {
      await PaymentRepository()
          .updatePaymentStatus(paymentId: depositId, status: 'approved');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deposit approved successfully'),
            backgroundColor: AppColors.green,
          ),
        );
      }
      ref.invalidate(pendingPaymentsProvider);
      ref.invalidate(paymentStatsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _rejectDeposit(String depositId) async {
    try {
      await PaymentRepository()
          .updatePaymentStatus(paymentId: depositId, status: 'rejected');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deposit rejected'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      ref.invalidate(pendingPaymentsProvider);
      ref.invalidate(paymentStatsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _viewReceipt(String depositId, String? screenshotUrl) {
    if (screenshotUrl == null || screenshotUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No receipt image available for this deposit.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(screenshotUrl, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.darkCard),
              child: const Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(dynamic raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw.toString();
    }
  }

  String _getTimeAgo(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt.toString()).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(pendingPaymentsProvider);
    final statsAsync = ref.watch(paymentStatsProvider);
    final pendingCount = statsAsync.value?['pending'] ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Pending Review ($pendingCount)',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Row(
                children: [
                  Text(
                    'Oldest first',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                  SizedBox(width: 4),
                  Icon(
                    Icons.filter_list,
                    color: AppColors.textMuted,
                    size: 16,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Pending Reviews List
        pendingAsync.when(
          loading: () => const Center(
            child: Padding(
              padding: EdgeInsets.all(32.0),
              child: CircularProgressIndicator(color: AppColors.green),
            ),
          ),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'Failed to load pending fees: $e',
                style: const TextStyle(color: AppColors.error),
              ),
            ),
          ),
          data: (pendingReviews) {
            if (pendingReviews.isEmpty) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(32.0),
                  child: Text(
                    'No pending fees',
                    style: TextStyle(color: AppColors.textMuted),
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              itemCount: pendingReviews.length,
              itemBuilder: (context, index) {
                final payment = pendingReviews[index];

                final userProfile =
                    payment['profiles'] as Map<String, dynamic>?;
                final booking = payment['bookings'] as Map<String, dynamic>?;
                final station = booking?['stations'] as Map<String, dynamic>?;
                final room = station?['rooms'] as Map<String, dynamic>?;
                final cyber = room?['cybers'] as Map<String, dynamic>?;

                final userName = userProfile?['name'] ?? 'Unknown User';
                final initials = userName.toString().isNotEmpty
                    ? userName.toString()[0].toUpperCase()
                    : '?';

                final bookingTime =
                    '${_formatDateTime(booking?['start_time'])} - ${_formatDateTime(booking?['end_time'])}';

                final bookingStatus =
                    (booking?['status'] ?? 'Unknown').toString().toUpperCase();

                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: DepositReviewCard(
                    userName: userName,
                    initials: initials,
                    timeAgo: _getTimeAgo(payment['created_at']),
                    paymentMethod: (payment['method'] ?? 'Unknown')
                        .toString()
                        .toUpperCase(),
                    gamingLounge: cyber?['name'] ?? 'Unknown Cyber',
                    bookingTime: bookingTime,
                    bookingStatus: 'Booking Status: $bookingStatus',
                    onApprove: () => _approveDeposit(payment['id']),
                    onReject: () => _rejectDeposit(payment['id']),
                    onViewReceipt: () =>
                        _viewReceipt(payment['id'], payment['screenshot_url']),
                  ),
                );
              },
            );
          },
        ),
        const SizedBox(height: 24),
      ],
    );
  }
}
