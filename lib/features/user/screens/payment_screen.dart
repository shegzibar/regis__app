import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/payment_provider.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../core/providers/wallet_provider.dart';
import '../../../shared/widgets/payment_method_card.dart';

class PaymentScreen extends ConsumerStatefulWidget {
  final String bookingId;
  final double amount;
  
  const PaymentScreen({
    super.key,
    required this.bookingId,
    required this.amount,
  });

  @override
  ConsumerState<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends ConsumerState<PaymentScreen> {
  int _remainingSeconds = 892; // 14:52 in seconds
  String _selectedPaymentMethod = 'wallet_points';
  bool _isSubmitting = false;
  
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'wallet_points',
      'name': 'Wallet Points',
      'description': 'Pay directly using your GamingHub wallet',
      'icon': Icons.stars,
      'color': AppColors.green,
    },
  ];
  
  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted && _remainingSeconds > 0) {
        setState(() {
          _remainingSeconds--;
        });
        _startTimer();
      }
    });
  }

  void _selectPaymentMethod(String methodId) {
    setState(() {
      _selectedPaymentMethod = methodId;
    });
  }

  Future<void> _confirmPayment() async {

    setState(() => _isSubmitting = true);

    try {
      // Check wallet balance first
      final wallet = await ref.read(userWalletProvider.future);
      if (wallet == null || wallet.balance < widget.amount) {
        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Insufficient Wallet Points. Please recharge your wallet.'),
              backgroundColor: AppColors.error,
            ),
          );
        }
        return;
      }

      // Create payment row in Supabase
      await ref.read(paymentNotifierProvider.notifier).submitPayment(
            bookingId: widget.bookingId,
            amount: widget.amount,
            method: _selectedPaymentMethod,
            screenshotUrl: null, // No screenshot needed for points
          );

      if (_selectedPaymentMethod == 'wallet_points') {
        // Automatically deduct points and confirm booking
        final shortId = await ref.read(userShortIdProvider.future);
        if (shortId != null) {
          await ref.read(walletRepositoryProvider).addWalletTransaction(
            shortId: shortId,
            type: 'redeemed',
            amount: widget.amount.toInt(),
            note: 'Automatic deduction for booking #${widget.bookingId.substring(0, 8)}',
            cyberName: 'GamingHub System',
          );
        }

        await ref.read(bookingNotifierProvider.notifier).updateStatus(widget.bookingId, 'confirmed');

        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment successful! Your booking is confirmed.'),
              backgroundColor: AppColors.green,
            ),
          );
          context.go('/explore');
        }
      } else {
        // Update booking status to fee_under_review for manual methods
        await ref.read(bookingNotifierProvider.notifier).updateStatus(widget.bookingId, 'fee_under_review');

        if (mounted) {
          setState(() => _isSubmitting = false);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment submitted! A manager will review your receipt shortly.'),
              backgroundColor: AppColors.green,
            ),
          );
          // Clear history and navigate to explore/bookings
          context.go('/explore');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSubmitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to submit payment: $e')),
        );
      }
    }
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
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
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Text(
                    'Complete Payment',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            
            // Booking ID
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Booking ID: #${widget.bookingId.substring(0, 8).toUpperCase()}',
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 14,
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Expiration Timer
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B4513).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: const Color(0xFF8B4513).withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: Colors.orange.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Icon(
                              Icons.access_time,
                              color: Colors.orange,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Expires in ${_formatTime(_remainingSeconds)}',
                                  style: const TextStyle(
                                    color: Colors.orange,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                const Text(
                                  'Pay now to lock slot',
                                  style: TextStyle(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Booking Details Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF2D1B69),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: AppColors.darkSurface,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.computer,
                                  color: AppColors.green,
                                  size: 30,
                                ),
                              ),
                              const SizedBox(width: 16),
                              const Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Gaming Hub Station',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'Reserved Slot',
                                      style: TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          
                          const SizedBox(height: 20),
                          const Divider(color: AppColors.darkBorder),
                          const SizedBox(height: 16),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Session Fee', style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                              Text('${widget.amount.toInt()} EGP', style: const TextStyle(color: AppColors.textMuted, fontSize: 14)),
                            ],
                          ),
                          
                          const SizedBox(height: 16),
                          const Divider(color: AppColors.darkBorder),
                          const SizedBox(height: 16),
                          
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total to Pay', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                              Text('${widget.amount.toInt()} EGP', style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                    
                    // Payment Method Selection
                    const Text(
                      'Select Payment Method',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    
                    const SizedBox(height: 16),
                    
                    // Payment Method Cards
                    ..._paymentMethods.map((method) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: PaymentMethodCard(
                          name: method['name'],
                          description: method['description'],
                          icon: method['icon'],
                          iconColor: method['color'],
                          isSelected: method['id'] == _selectedPaymentMethod,
                          onTap: () => _selectPaymentMethod(method['id']),
                        ),
                      );
                    }),
                    
                    const SizedBox(height: 24),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            
            // Bottom Confirm Button
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                border: Border(
                  top: BorderSide(color: AppColors.darkBorder),
                ),
              ),
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _confirmPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Confirm Payment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
