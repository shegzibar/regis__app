import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class StatusPill extends StatelessWidget {
  final String status;
  final String? customText;
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final EdgeInsets? padding;

  const StatusPill({
    super.key,
    required this.status,
    this.customText,
    this.backgroundColor,
    this.textColor,
    this.fontSize,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getStatusColors(status);
    final text = customText ?? _getStatusText(status);

    return Container(
      padding: padding ?? const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor ?? colors['background'],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor ?? colors['text'],
          fontSize: fontSize ?? 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Map<String, Color> _getStatusColors(String status) {
    switch (status.toLowerCase()) {
      case 'pending_payment':
      case 'pending':
        return {
          'background': AppColors.amberLight,
          'text': AppColors.amber,
        };
      case 'fee_under_review':
        return {
          'background': AppColors.purpleLight,
          'text': AppColors.purple,
        };
      case 'confirmed':
      case 'approved':
      case 'completed':
        return {
          'background': AppColors.successLight,
          'text': AppColors.success,
        };
      case 'rejected':
      case 'cancelled':
        return {
          'background': AppColors.errorLight,
          'text': AppColors.error,
        };
      case 'active':
        return {
          'background': AppColors.successLight,
          'text': AppColors.success,
        };
      case 'maintenance':
      case 'blocked':
        return {
          'background': AppColors.errorLight,
          'text': AppColors.error,
        };
      default:
        return {
          'background': AppColors.lightGray,
          'text': AppColors.gray,
        };
    }
  }

  String _getStatusText(String status) {
    switch (status.toLowerCase()) {
      case 'pending_payment':
        return 'Pending Payment';
      case 'fee_under_review':
        return 'Under Review';
      case 'confirmed':
        return 'Confirmed';
      case 'approved':
        return 'Approved';
      case 'rejected':
        return 'Rejected';
      case 'cancelled':
        return 'Cancelled';
      case 'completed':
        return 'Completed';
      case 'active':
        return 'Available';
      case 'maintenance':
        return 'Maintenance';
      case 'blocked':
        return 'Blocked';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }
}
