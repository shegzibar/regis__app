import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/localization/app_localization.dart';
import '../../../shared/widgets/deposit_review_card.dart';
import '../../../shared/widgets/summary_card.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  // Mock data
  final List<Map<String, dynamic>> _pendingReviews = [
    {
      'id': '1',
      'userName': 'Ahmed Hassan',
      'initials': 'AH',
      'timeAgo': '2m ago',
      'paymentMethod': 'InstaPay',
      'gamingLounge': 'Matrix Gaming Lounge',
      'bookingTime': 'Today, 4:00 PM - 6:00 PM',
      'isApproved': false,
      'isRejected': false,
    },
    {
      'id': '2',
      'userName': 'Mohamed Eid',
      'initials': 'ME',
      'timeAgo': '5m ago',
      'paymentMethod': 'Vodafone Cash',
      'gamingLounge': 'Cyber Zone Heliopolis',
      'bookingTime': 'Today, 8:00 PM - 11:00 PM',
      'isApproved': false,
      'isRejected': false,
    },
    {
      'id': '3',
      'userName': 'Sarah Khalil',
      'initials': 'SK',
      'timeAgo': '12m ago',
      'paymentMethod': 'Fawry Pay',
      'gamingLounge': 'Pro Gaming Center',
      'bookingTime': 'Today, 2:00 PM - 4:00 PM',
      'isApproved': false,
      'isRejected': false,
    },
  ];

  // Summary statistics
  final int _pendingCount = 12;
  final int _confirmedCount = 148;
  final int _rejectedCount = 3;
  final double _revenue = 740.0;

  void _approveDeposit(String depositId) {
    setState(() {
      final deposit = _pendingReviews.firstWhere((d) => d['id'] == depositId);
      deposit['isApproved'] = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Deposit approved successfully'),
        backgroundColor: AppColors.green,
      ),
    );
  }

  void _rejectDeposit(String depositId) {
    setState(() {
      final deposit = _pendingReviews.firstWhere((d) => d['id'] == depositId);
      deposit['isRejected'] = true;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Deposit rejected'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  void _viewReceipt(String depositId) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Viewing receipt for deposit: $depositId')),
    );
  }

  void _refreshData() {
    // TODO: Implement data refresh
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refreshing data...')),
    );
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
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalization.feeQueue,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppLocalization.manageFees,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _refreshData,
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

            // Info Card
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.green.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.green.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: const Icon(
                        Icons.info_outline,
                        color: AppColors.green,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        AppLocalization.verifyReceipts,
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Summary Cards
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      title: AppLocalization.pending,
                      value: _pendingCount.toString(),
                      valueColor: Colors.orange,
                      icon: Icons.pending,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCard(
                      title: AppLocalization.confirmed,
                      value: _confirmedCount.toString(),
                      valueColor: AppColors.green,
                      icon: Icons.check_circle,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Row(
                children: [
                  Expanded(
                    child: SummaryCard(
                      title: AppLocalization.rejected,
                      value: _rejectedCount.toString(),
                      valueColor: AppColors.error,
                      icon: Icons.cancel,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SummaryCard(
                      title: AppLocalization.revenue,
                      value: '${_revenue.toInt()} ${AppLocalization.egp}',
                      valueColor: AppColors.green,
                      icon: Icons.account_balance_wallet,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Pending Review Section
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pending Review ($_pendingCount)',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            const Text(
                              'Newest first',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(
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
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0),
                      itemCount: _pendingReviews.length,
                      itemBuilder: (context, index) {
                        final review = _pendingReviews[index];

                        // Skip if already processed
                        if (review['isApproved'] || review['isRejected']) {
                          return const SizedBox.shrink();
                        }

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12.0),
                          child: DepositReviewCard(
                            userName: review['userName'],
                            initials: review['initials'],
                            timeAgo: review['timeAgo'],
                            paymentMethod: review['paymentMethod'],
                            gamingLounge: review['gamingLounge'],
                            bookingTime: review['bookingTime'],
                            onViewReceipt: () => _viewReceipt(review['id']),
                            onApprove: () => _approveDeposit(review['id']),
                            onReject: () => _rejectDeposit(review['id']),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
