import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../constants/cd_colors.dart';
import '../providers/cd_providers.dart';

class PaymentsPage extends ConsumerWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(cdLangProvider);
    final isAr = lang == 'ar';
    final paymentsAsync = ref.watch(pendingPaymentsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(kPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Title
          Text(
            isAr ? 'المدفوعات المعلقة' : 'Pending Payments',
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kSidebarText),
          ),
          Text(
            isAr
                ? 'راجع رسوم الحجز (5 جنيهات) للموافقة على الحجوزات'
                : 'Review booking fees (5 EGP) to approve bookings',
            style: const TextStyle(fontSize: 12, color: kGray),
          ),
          const SizedBox(height: 20),

          paymentsAsync.when(
            loading: () => const Center(
                child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (payments) {
              if (payments.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(40),
                  decoration: BoxDecoration(
                    color: kWhite,
                    borderRadius: BorderRadius.circular(kRadius),
                    border: Border.all(color: kBorder, width: 0.5),
                  ),
                  child: Center(
                    child: Column(
                      children: [
                        const Icon(Icons.check_circle_outline,
                            size: 48, color: kTeal),
                        const SizedBox(height: 12),
                        Text(
                          isAr
                              ? 'لا توجد مدفوعات معلقة!'
                              : 'No pending payments!',
                          style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: kSidebarText),
                        ),
                        Text(
                          isAr
                              ? 'لقد قمت بمراجعة كافة طلبات الحجز'
                              : "You've reviewed all booking requests",
                          style: const TextStyle(color: kGray, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: payments.length,
                separatorBuilder: (_, __) => const SizedBox(height: kGap),
                itemBuilder: (context, i) {
                  final p = payments[i];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: kWhite,
                      borderRadius: BorderRadius.circular(kRadius),
                      border: Border.all(color: kBorder, width: 0.5),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Left: details
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    p.userName ??
                                        p.userEmail ??
                                        'Unknown User',
                                    style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600),
                                  ),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: kPurpleLight,
                                      borderRadius:
                                          BorderRadius.circular(kRadiusSm),
                                    ),
                                    child: Text(
                                      '${p.payment.amount.toInt()} EGP Fee',
                                      style: const TextStyle(
                                          fontSize: 10,
                                          color: kPurple,
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              _DetailRow(
                                  icon: Icons.computer,
                                  label:
                                      '${p.roomName ?? 'Unknown'} — ${p.stationName ?? 'Unknown'}'),
                              const SizedBox(height: 4),
                              _DetailRow(
                                  icon: Icons.schedule,
                                  label: p.bookingStart != null &&
                                          p.bookingEnd != null
                                      ? '${DateFormat('MMM d, HH:mm').format(p.bookingStart!)} to ${DateFormat('HH:mm').format(p.bookingEnd!)}'
                                      : 'Unknown time'),
                              const SizedBox(height: 4),
                              _DetailRow(
                                  icon: Icons.payment,
                                  label:
                                      'Method: ${p.payment.methodDisplay}'),
                              const SizedBox(height: 4),
                              _DetailRow(
                                  icon: Icons.attach_money,
                                  label:
                                      'Total booking value: ${p.totalAmount?.toInt() ?? 0} EGP'),
                            ],
                          ),
                        ),

                        // Middle: Receipt Image
                        if (p.payment.screenshotUrl != null &&
                            p.payment.screenshotUrl!.isNotEmpty)
                          GestureDetector(
                            onTap: () {
                              _showReceiptImage(
                                  context, p.payment.screenshotUrl!);
                            },
                            child: Container(
                              width: 100,
                              height: 100,
                              margin:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(kRadiusSm),
                                border: Border.all(color: kBorder),
                                image: DecorationImage(
                                  image: NetworkImage(
                                      p.payment.screenshotUrl!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                              child: const Center(
                                child: Icon(Icons.zoom_in,
                                    color: Colors.white, size: 24),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 100,
                            height: 100,
                            margin:
                                const EdgeInsets.symmetric(horizontal: 16),
                            decoration: BoxDecoration(
                              color: kBg,
                              borderRadius: BorderRadius.circular(kRadiusSm),
                              border: Border.all(color: kBorder),
                            ),
                            child: const Center(
                              child: Icon(Icons.receipt_long, color: kGray),
                            ),
                          ),

                        // Right: Actions
                        Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () async {
                                await ref
                                    .read(cdPaymentRepoProvider)
                                    .confirmPayment(
                                        p.payment.id, p.payment.bookingId);
                                // Refresh immediately without waiting for realtime
                                ref.invalidate(pendingPaymentsProvider);
                                ref.invalidate(todayBookingsProvider);
                                ref.invalidate(todayRevenueProvider);
                              },
                              icon: const Icon(Icons.check, size: 16),
                              label: Text(isAr ? 'موافقة' : 'Approve'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: kTeal,
                                foregroundColor: Colors.white,
                                elevation: 0,
                                minimumSize: const Size(120, 36),
                              ),
                            ),
                            const SizedBox(height: 8),
                            OutlinedButton.icon(
                              onPressed: () async {
                                _showRejectDialog(context, ref, p, isAr);
                              },
                              icon: const Icon(Icons.close, size: 16),
                              label: Text(isAr ? 'رفض' : 'Reject'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: kRed,
                                side: const BorderSide(color: kRed),
                                minimumSize: const Size(120, 36),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  void _showReceiptImage(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            InteractiveViewer(
              child: Image.network(url, fit: BoxFit.contain),
            ),
            IconButton(
              icon: const Icon(Icons.close, color: Colors.white, size: 30),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _showRejectDialog(
      BuildContext context, WidgetRef ref, dynamic p, bool isAr) {
    final reasonController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isAr ? 'سبب الرفض' : 'Rejection Reason'),
        content: TextField(
          controller: reasonController,
          decoration: InputDecoration(
            hintText:
                isAr ? 'مثال: الإيصال غير واضح' : 'e.g. Receipt is unclear',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(isAr ? 'إلغاء' : 'Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ref.read(cdPaymentRepoProvider).rejectPayment(
                    p.payment.id,
                    p.payment.bookingId,
                    reason: reasonController.text.trim().isEmpty
                        ? null
                        : reasonController.text.trim(),
                  );
              // Refresh immediately without waiting for realtime
              ref.invalidate(pendingPaymentsProvider);
              ref.invalidate(todayBookingsProvider);
              ref.invalidate(todayRevenueProvider);
            },
            child: Text(isAr ? 'تأكيد الرفض' : 'Confirm Reject',
                style: const TextStyle(color: kRed)),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _DetailRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: kGray),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12, color: kGray)),
      ],
    );
  }
}
