import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/cyber.dart';
import '../../../data/repositories/cyber_repository.dart';
import '../providers/admin_accounts_providers.dart';

class AdminEditSubscriptionSheet extends ConsumerStatefulWidget {
  final Cyber cyber;

  const AdminEditSubscriptionSheet({super.key, required this.cyber});

  @override
  ConsumerState<AdminEditSubscriptionSheet> createState() => _AdminEditSubscriptionSheetState();
}

class _AdminEditSubscriptionSheetState extends ConsumerState<AdminEditSubscriptionSheet> {
  late String _selectedPlan;
  late String _selectedBilling;
  late DateTime? _endDate;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedPlan = widget.cyber.subscriptionPlan;
    _selectedBilling = widget.cyber.subscriptionBilling;
    _endDate = widget.cyber.subscriptionEndDate;
  }

  void _addMonths(int months) {
    setState(() {
      final baseDate = (_endDate != null && _endDate!.isAfter(DateTime.now())) 
          ? _endDate! 
          : DateTime.now();
      
      _endDate = DateTime(
        baseDate.year, 
        baseDate.month + months, 
        baseDate.day,
      );
    });
  }

  void _addYears(int years) {
    setState(() {
      final baseDate = (_endDate != null && _endDate!.isAfter(DateTime.now())) 
          ? _endDate! 
          : DateTime.now();
      
      _endDate = DateTime(
        baseDate.year + years, 
        baseDate.month, 
        baseDate.day,
      );
    });
  }

  Future<void> _save() async {
    setState(() => _isLoading = true);
    try {
      await CyberRepository().updateCyberSubscription(
        cyberId: widget.cyber.id,
        subscriptionPlan: _selectedPlan,
        subscriptionBilling: _selectedBilling,
        subscriptionEndDate: _endDate,
      );
      
      ref.invalidate(allCybersProvider);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription updated successfully'),
            backgroundColor: AppColors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.fromLTRB(24, 24, 24, 24 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
            Row(
              children: [
                const Text(
                  'Edit Subscription',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            // Cyber name + live countdown banner
            _SubscriptionCountdownBanner(cyber: widget.cyber),
            const SizedBox(height: 20),
            
            const Text('Plan', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                _ChoiceChip(
                  label: 'Starter',
                  isSelected: _selectedPlan == 'starter',
                  onSelected: () => setState(() => _selectedPlan = 'starter'),
                  color: Colors.orange,
                ),
                const SizedBox(width: 8),
                _ChoiceChip(
                  label: 'Growth',
                  isSelected: _selectedPlan == 'growth',
                  onSelected: () => setState(() => _selectedPlan = 'growth'),
                  color: Colors.blue,
                ),
                const SizedBox(width: 8),
                _ChoiceChip(
                  label: 'Custom',
                  isSelected: _selectedPlan == 'custom',
                  onSelected: () => setState(() => _selectedPlan = 'custom'),
                  color: Colors.purple,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            const Text('Billing Cycle', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 8),
            Row(
              children: [
                _ChoiceChip(
                  label: 'Monthly',
                  isSelected: _selectedBilling == 'monthly',
                  onSelected: () => setState(() => _selectedBilling = 'monthly'),
                  color: AppColors.green,
                ),
                const SizedBox(width: 8),
                _ChoiceChip(
                  label: 'Yearly',
                  isSelected: _selectedBilling == 'yearly',
                  onSelected: () => setState(() => _selectedBilling = 'yearly'),
                  color: AppColors.green,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            const Text('End Date', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _endDate == null 
                          ? 'No end date set' 
                          : '${_endDate!.day}/${_endDate!.month}/${_endDate!.year}',
                      style: const TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ),
                  if (_endDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.red, size: 20),
                      onPressed: () => setState(() => _endDate = null),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _addMonths(1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.darkBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('+1 Month'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _addYears(1),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: AppColors.darkBorder),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('+1 Year'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.black, strokeWidth: 2),
                      )
                    : const Text('Save Subscription', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _ChoiceChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onSelected;
  final Color color;

  const _ChoiceChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onSelected,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.15) : AppColors.darkBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : AppColors.darkBorder,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? color : AppColors.textMuted,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

class _SubscriptionCountdownBanner extends StatelessWidget {
  final Cyber cyber;
  const _SubscriptionCountdownBanner({required this.cyber});

  @override
  Widget build(BuildContext context) {
    final Color color;
    final IconData icon;
    switch (cyber.expiryUrgency) {
      case 3:
        color = AppColors.red;
        icon = Icons.warning_amber_rounded;
        break;
      case 2:
        color = Colors.amber;
        icon = Icons.hourglass_bottom_rounded;
        break;
      case 1:
        color = AppColors.green;
        icon = Icons.verified_outlined;
        break;
      default:
        color = AppColors.textMuted;
        icon = Icons.schedule;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cyber.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  cyber.expiryLabel,
                  style: TextStyle(
                    color: color,
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
