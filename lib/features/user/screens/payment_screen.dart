import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/payment_method_card.dart';

class PaymentScreen extends StatefulWidget {
  final String bookingId;
  
  const PaymentScreen({super.key, required this.bookingId});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  int _remainingSeconds = 892; // 14:52 in seconds
  String _selectedPaymentMethod = 'instapay';
  
  final List<Map<String, dynamic>> _paymentMethods = [
    {
      'id': 'instapay',
      'name': 'InstaPay',
      'description': 'Transfer to: gaminghub@instapay',
      'icon': Icons.account_balance_wallet,
      'color': Colors.blue,
    },
    {
      'id': 'vodafone',
      'name': 'Vodafone Cash',
      'description': 'Send to: 01012345678',
      'icon': Icons.phone_android,
      'color': Colors.red,
    },
    {
      'id': 'fawry',
      'name': 'Fawry Pay',
      'description': 'Reference code provided after',
      'icon': Icons.receipt_long,
      'color': Colors.orange,
    },
  ];
  
  // Pricing details
  final double _sessionPrice = 120.00;
  final double _platformFee = 5.00;
  double get _totalToPay => _sessionPrice + _platformFee;

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

  void _confirmPayment() {
    // TODO: Implement payment processing
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Processing payment...')),
    );
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
                  const SizedBox(width: 48), // Balance the header
                ],
              ),
            ),
            
            // Booking ID
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Booking ID: #GH-8829',
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
                          // Cyber Info
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
                                      'CyberZone Maadi',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    SizedBox(height: 4),
                                    Text(
                                      'VIP Room • Station 04',
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
                          
                          // Pricing Breakdown
                          const Divider(color: AppColors.darkBorder),
                          
                          const SizedBox(height: 16),
                          
                          _buildPriceRow('Session Price', _sessionPrice),
                          
                          const SizedBox(height: 12),
                          
                          _buildPriceRow('Platform Fee', _platformFee),
                          
                          const SizedBox(height: 16),
                          
                          const Divider(color: AppColors.darkBorder),
                          
                          const SizedBox(height: 16),
                          
                          _buildPriceRow('Total to Pay', _totalToPay, isTotal: true),
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
                onPressed: _confirmPayment,
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
                child: const Text(
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
  
  Widget _buildPriceRow(String label, double price, {bool isTotal = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isTotal ? Colors.white : AppColors.textMuted,
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        Text(
          '${price.toStringAsFixed(2)} EGP',
          style: TextStyle(
            color: isTotal ? Colors.white : AppColors.textMuted,
            fontSize: isTotal ? 16 : 14,
            fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ],
    );
  }
}
