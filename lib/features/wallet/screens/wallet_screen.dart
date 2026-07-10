import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:intl/intl.dart';
import 'package:easy_localization/easy_localization.dart';

import '../../../core/constants/app_colors.dart';
import '../../../core/providers/wallet_provider.dart';
import '../../../data/models/wallet_transaction.dart';
import '../../../shared/widgets/loading_widget.dart';
import '../../../shared/widgets/empty_state.dart';

class WalletScreen extends ConsumerWidget {
  const WalletScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final walletAsync = ref.watch(userWalletProvider);
    final shortIdAsync = ref.watch(userShortIdProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        title: Text('wallet.my_wallet'.tr(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: RefreshIndicator(
        color: AppColors.green,
        backgroundColor: AppColors.darkCard,
        onRefresh: () async {
          ref.invalidate(userWalletProvider);
          ref.invalidate(userShortIdProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Wallet Header Card ---
              Container(
                margin: const EdgeInsets.all(24),
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [AppColors.darkCard, Color(0xFF1E2822)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: AppColors.green.withValues(alpha: 0.3)),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.green.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    )
                  ],
                ),
                child: Column(
                  children: [
                    Text('wallet.total_balance'.tr(), style: const TextStyle(color: AppColors.textMuted, fontSize: 16)),
                    const SizedBox(height: 8),
                    walletAsync.when(
                      loading: () => const LoadingWidget(),
                      error: (err, _) => const Text('Error', style: TextStyle(color: AppColors.error)),
                      data: (wallet) => Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Icon(Icons.stars, color: AppColors.green, size: 36),
                          const SizedBox(width: 8),
                          Text(
                            wallet != null ? '${wallet.balance}' : '0',
                            style: const TextStyle(color: Colors.white, fontSize: 42, fontWeight: FontWeight.bold, height: 1.0),
                          ),
                          const SizedBox(width: 6),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Text('wallet.pts'.tr(), style: const TextStyle(color: AppColors.green, fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    
                    // --- QR Code & Short ID ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: shortIdAsync.when(
                        loading: () => const SizedBox(height: 150, child: LoadingWidget()),
                        error: (_, __) => SizedBox(height: 150, child: Center(child: Text('wallet.error_loading_id'.tr()))),
                        data: (shortId) {
                          if (shortId == null) {
                            return SizedBox(height: 150, child: Center(child: Text('wallet.no_id_generated'.tr())));
                          }
                          return Column(
                            children: [
                              QrImageView(
                                data: shortId,
                                version: QrVersions.auto,
                                size: 150.0,
                                backgroundColor: Colors.white,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    shortId,
                                    style: const TextStyle(
                                      color: AppColors.dark,
                                      fontSize: 24,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 2,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  GestureDetector(
                                    onTap: () {
                                      Clipboard.setData(ClipboardData(text: shortId));
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('wallet.id_copied'.tr())),
                                      );
                                    },
                                    child: const Icon(Icons.copy, color: AppColors.gray, size: 20),
                                  ),
                                ],
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text('wallet.show_qr'.tr(), 
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                    ),
                  ],
                ),
              ),

              // --- Transactions Section ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('wallet.recent_transactions'.tr(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              
              walletAsync.when(
                loading: () => const Padding(padding: EdgeInsets.all(32), child: LoadingWidget()),
                error: (err, _) => Center(child: Text('Error loading transactions: $err')),
                data: (wallet) {
                  if (wallet == null) {
                     return EmptyState(
                      icon: Icons.receipt_long,
                      title: 'wallet.no_wallet_found'.tr(),
                      subtitle: 'wallet.no_wallet_subtitle'.tr(),
                    );
                  }
                  
                  return _TransactionsList(walletId: wallet.id);
                },
              ),
              
              const SizedBox(height: 24),
              
              // --- How It Works Section ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('wallet.how_it_works'.tr(), style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),
              _buildHowItWorksCard(Icons.store_outlined, 'wallet.step1_title'.tr(), 'wallet.step1_subtitle'.tr()),
              _buildHowItWorksCard(Icons.qr_code, 'wallet.step2_title'.tr(), 'wallet.step2_subtitle'.tr()),
              _buildHowItWorksCard(Icons.add_circle_outline, 'wallet.step3_title'.tr(), 'wallet.step3_subtitle'.tr()),
              _buildHowItWorksCard(Icons.card_giftcard, 'wallet.step4_title'.tr(), 'wallet.step4_subtitle'.tr()),
              
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHowItWorksCard(IconData icon, String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 0, 24, 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.green, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionsList extends ConsumerWidget {
  final String walletId;
  const _TransactionsList({required this.walletId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(walletTransactionsProvider(walletId));

    return transactionsAsync.when(
      loading: () => const Padding(padding: EdgeInsets.all(24), child: LoadingWidget()),
      error: (err, _) => Center(child: Text('Error: $err')),
      data: (transactions) {
        if (transactions.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: EmptyState(
              icon: Icons.receipt_long,
              title: 'wallet.no_transactions'.tr(),
              subtitle: 'wallet.no_transactions_subtitle'.tr(),
            ),
          );
        }

        return ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          itemCount: transactions.length,
          itemBuilder: (context, index) {
            final tx = transactions[index];
            final isEarned = tx.type == 'earned';
            final color = isEarned ? AppColors.green : AppColors.error;
            final sign = isEarned ? '+' : '-';
            
            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.darkBorder),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isEarned ? Icons.add_circle : Icons.remove_circle,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          tx.note ?? (isEarned ? 'wallet.points_earned'.tr() : 'wallet.points_redeemed'.tr()),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          tx.cyberName != null 
                              ? '${tx.cyberName} • ${DateFormat('MMM d, yyyy').format(tx.createdAt)}'
                              : DateFormat('MMM d, yyyy').format(tx.createdAt),
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '$sign${tx.amount}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
