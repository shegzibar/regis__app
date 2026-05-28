import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/payment.dart';
import '../../data/repositories/payment_repository.dart';
import 'auth_provider.dart';

final paymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  return PaymentRepository();
});

// Fetch user payments
final userPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];
  return ref.read(paymentRepositoryProvider).getUserPayments(user.id);
});

// Fetch pending payments (manager queue)
final pendingPaymentsProvider = FutureProvider<List<Payment>>((ref) async {
  return ref.read(paymentRepositoryProvider).getPendingPayments();
});

// Fetch payment by booking ID
final bookingPaymentProvider = FutureProvider.family.autoDispose<Payment?, String>((ref, bookingId) async {
  return ref.read(paymentRepositoryProvider).getPaymentByBookingId(bookingId);
});

// Payment notifier for uploading receipts and managing status
final paymentNotifierProvider =
    AsyncNotifierProvider<PaymentNotifier, void>(() => PaymentNotifier());

class PaymentNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<Payment> submitPayment({
    required String bookingId,
    required double amount,
    required String method,
    String? screenshotUrl,
  }) async {
    final user = ref.read(authStateProvider);
    if (user == null) throw Exception('Not authenticated');

    final payment = await ref.read(paymentRepositoryProvider).createPayment(
          bookingId: bookingId,
          userId: user.id,
          amount: amount,
          method: method,
          screenshotUrl: screenshotUrl,
        );

    ref.invalidate(userPaymentsProvider);
    return payment;
  }

  Future<Payment> approvePayment(String paymentId) async {
    final payment = await ref.read(paymentRepositoryProvider).updatePaymentStatus(
          paymentId: paymentId,
          status: 'approved',
        );
    ref.invalidate(pendingPaymentsProvider);
    return payment;
  }

  Future<Payment> rejectPayment(String paymentId, String reason) async {
    final payment = await ref.read(paymentRepositoryProvider).updatePaymentStatus(
          paymentId: paymentId,
          status: 'rejected',
          rejectionReason: reason,
        );
    ref.invalidate(pendingPaymentsProvider);
    return payment;
  }
}
