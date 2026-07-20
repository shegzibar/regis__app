import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/wallet_provider.dart';
import '../providers/cd_providers.dart';

class WalletPointsPage extends ConsumerStatefulWidget {
  const WalletPointsPage({super.key});

  @override
  ConsumerState<WalletPointsPage> createState() => _WalletPointsPageState();
}

class _WalletPointsPageState extends ConsumerState<WalletPointsPage> {
  final _shortIdController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();
  bool _isLoading = false;
  String _transactionType = 'earned'; // 'earned' or 'redeemed'

  @override
  void dispose() {
    _shortIdController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  Future<void> _submitTransaction() async {
    final shortId = _shortIdController.text.trim();
    final amountText = _amountController.text.trim();
    final note = _noteController.text.trim();

    if (shortId.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter User ID and Amount')),
      );
      return;
    }

    final amount = int.tryParse(amountText);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be a valid positive number')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final cyber = await ref.read(currentCyberProvider.future);
      
      await ref.read(walletRepositoryProvider).addWalletTransaction(
        shortId: shortId,
        type: _transactionType,
        amount: amount,
        note: note.isNotEmpty ? note : null,
        cyberName: cyber?.name,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transaction added successfully!'),
            backgroundColor: AppColors.green,
          ),
        );
        _shortIdController.clear();
        _amountController.clear();
        _noteController.clear();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: Center(
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            padding: const EdgeInsets.all(36),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                )
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Wallet Points Management',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.dark,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                const Text(
                  'Add or redeem points for a user using their 6-character short ID.',
                  style: TextStyle(color: AppColors.gray),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 36),
                
                Row(
                  children: [
                    Expanded(
                      child: _TypeButton(
                        title: 'Add Points (Earned)',
                        isSelected: _transactionType == 'earned',
                        color: AppColors.green,
                        onTap: () => setState(() => _transactionType = 'earned'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: _TypeButton(
                        title: 'Redeem Points',
                        isSelected: _transactionType == 'redeemed',
                        color: AppColors.error,
                        onTap: () => setState(() => _transactionType = 'redeemed'),
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 28),
                
                TextField(
                  controller: _shortIdController,
                  decoration: InputDecoration(
                    labelText: 'User Short ID (e.g. ab12c3)',
                    prefixIcon: Icon(Icons.qr_code, color: AppColors.green),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                  textCapitalization: TextCapitalization.none,
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _amountController,
                  decoration: InputDecoration(
                    labelText: 'Amount (Points)',
                    prefixIcon: Icon(Icons.stars, color: AppColors.green),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                
                TextField(
                  controller: _noteController,
                  decoration: InputDecoration(
                    labelText: 'Note (Optional)',
                    prefixIcon: const Icon(Icons.note, color: AppColors.gray),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                  ),
                ),
                
                const SizedBox(height: 36),
                
                ElevatedButton(
                  onPressed: _isLoading ? null : _submitTransaction,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _transactionType == 'earned' ? AppColors.green : AppColors.error,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          _transactionType == 'earned' ? 'Add Points' : 'Redeem Points',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final String title;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _TypeButton({
    required this.title,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : AppColors.gray.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: isSelected ? color : AppColors.gray,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
