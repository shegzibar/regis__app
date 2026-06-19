import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/wallet.dart';
import '../../data/models/wallet_transaction.dart';
import '../../data/repositories/wallet_repository.dart';
import 'auth_provider.dart';

final walletRepositoryProvider = Provider<WalletRepository>((ref) {
  return WalletRepository();
});

final userWalletProvider = FutureProvider.autoDispose<Wallet?>((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return null;

  return await ref.watch(walletRepositoryProvider).getWallet(user.id);
});

final walletTransactionsProvider = FutureProvider.autoDispose.family<List<WalletTransaction>, String>((ref, walletId) async {
  return await ref.watch(walletRepositoryProvider).getWalletTransactions(walletId);
});

final userShortIdProvider = FutureProvider.autoDispose<String?>((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return null;

  return await ref.watch(walletRepositoryProvider).getUserShortId(user.id);
});
