import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/payment_provider.dart';
import '../../../core/utils/role_utils.dart';
import '../../../data/models/booking.dart';
import '../../../data/supabase/supabase_client.dart';
import '../../../data/repositories/booking_repository.dart';

final ownerPaymentsQueueProvider =
    FutureProvider.autoDispose<List<Booking>>((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];

  try {
    final response = await SupabaseService()
        .from('bookings')
        .select('''
          *,
          stations!inner(
            id, name,
            rooms!inner(
              id, name,
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

class OwnerPaymentsScreen extends ConsumerWidget {
  const OwnerPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authStateProvider);
    final canApprove = canApproveOnlineBookings(user);
    final queueAsync = ref.watch(ownerPaymentsQueueProvider);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Text(
                'owner_dashboard.payments'.tr(),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              if (!canApprove)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFEDD5),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'owner_dashboard.view_only'.tr(),
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFFC2410C),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            canApprove
                ? 'owner_dashboard.payments'.tr()
                : 'owner_dashboard.payments_readonly'.tr(),
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: queueAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(child: Text('$e')),
              data: (bookings) {
                if (bookings.isEmpty) {
                  return Center(
                    child: Text('owner_dashboard.no_bookings_today'.tr()),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(ownerPaymentsQueueProvider),
                  child: ListView.separated(
                    itemCount: bookings.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, i) => _PaymentQueueCard(
                      booking: bookings[i],
                      showActions: canApprove,
                      onChanged: () =>
                          ref.invalidate(ownerPaymentsQueueProvider),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _PaymentQueueCard extends ConsumerStatefulWidget {
  final Booking booking;
  final bool showActions;
  final VoidCallback onChanged;

  const _PaymentQueueCard({
    required this.booking,
    required this.showActions,
    required this.onChanged,
  });

  @override
  ConsumerState<_PaymentQueueCard> createState() => _PaymentQueueCardState();
}

class _PaymentQueueCardState extends ConsumerState<_PaymentQueueCard> {
  bool _busy = false;

  Future<void> _decision(String status) async {
    setState(() => _busy = true);
    try {
      await BookingRepository().updateBookingStatus(
        widget.booking.id,
        status,
        confirmedAt: status == 'confirmed' ? DateTime.now() : null,
      );
      widget.onChanged();
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _viewReceipt(String? url) {
    if (url == null) return;
    showDialog(
      context: context,
      builder: (_) => Dialog(
        child: InteractiveViewer(
          child: Image.network(url),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final paymentAsync = ref.watch(bookingPaymentProvider(widget.booking.id));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '#${widget.booking.id.substring(0, 8)}',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Text(
            '${widget.booking.durationHours.toInt()}h • ${widget.booking.totalAmount.round()} ${'common.egp'.tr()}',
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
          paymentAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (payment) {
              if (payment?.screenshotUrl == null) {
                return const SizedBox.shrink();
              }
              return TextButton.icon(
                onPressed: () => _viewReceipt(payment!.screenshotUrl),
                icon: const Icon(Icons.image_outlined, size: 18),
                label: Text('admin.view_receipt'.tr()),
              );
            },
          ),
          if (widget.showActions && !_busy)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _decision('rejected'),
                    child: Text('owner_dashboard.deny'.tr()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _decision('confirmed'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                    child: Text('owner_dashboard.approve'.tr()),
                  ),
                ),
              ],
            ),
          if (_busy) const LinearProgressIndicator(color: AppColors.primary),
        ],
      ),
    );
  }
}
