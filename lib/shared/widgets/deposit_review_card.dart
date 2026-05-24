import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class DepositReviewCard extends StatelessWidget {
  final String userName;
  final String initials;
  final String timeAgo;
  final String paymentMethod;
  final String gamingLounge;
  final String bookingTime;
  final VoidCallback onViewReceipt;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const DepositReviewCard({
    super.key,
    required this.userName,
    required this.initials,
    required this.timeAgo,
    required this.paymentMethod,
    required this.gamingLounge,
    required this.bookingTime,
    required this.onViewReceipt,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User Info Row
          Row(
            children: [
              // Avatar
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.green.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: AppColors.green,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // User Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeAgo,
                      style: const TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              
              // Payment Method
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.darkSurface,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  paymentMethod,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Booking Details
          Row(
            children: [
              const Icon(
                Icons.videogame_asset,
                color: AppColors.textMuted,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  gamingLounge,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 6),
          
          Row(
            children: [
              const Icon(
                Icons.access_time,
                color: AppColors.textMuted,
                size: 16,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  bookingTime,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Action Buttons
          Row(
            children: [
              // View Receipt Button
              OutlinedButton(
                onPressed: onViewReceipt,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.green),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  'View Receipt',
                  style: TextStyle(
                    color: AppColors.green,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Reject Button
              GestureDetector(
                onTap: onReject,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.close,
                    color: AppColors.error,
                    size: 20,
                  ),
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Approve Button
              GestureDetector(
                onTap: onApprove,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppColors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.green.withOpacity(0.3)),
                  ),
                  child: const Icon(
                    Icons.check,
                    color: AppColors.green,
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
