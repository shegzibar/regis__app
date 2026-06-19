import '../models/wallet.dart';
import '../models/wallet_transaction.dart';
import '../supabase/supabase_client.dart';

class WalletRepository {
  final SupabaseService _supabase = SupabaseService();

  Future<Wallet?> getWallet(String userId) async {
    try {
      final response = await _supabase
          .from('wallets')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response != null) {
        return Wallet.fromMap(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch wallet: $e');
    }
  }

  Future<List<WalletTransaction>> getWalletTransactions(String walletId) async {
    try {
      final response = await _supabase
          .from('wallet_transactions')
          .select()
          .eq('wallet_id', walletId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((tx) => WalletTransaction.fromMap(tx))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch transactions: $e');
    }
  }

  Future<String?> getUserShortId(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select('short_id')
          .eq('id', userId)
          .maybeSingle();

      return response?['short_id'] as String?;
    } catch (e) {
      // In case short_id column is not there or another error
      print('Failed to fetch short_id: $e');
      return null;
    }
  }

  Future<void> addWalletTransaction({
    required String shortId,
    required String type, // 'earned' or 'redeemed'
    required int amount,
    String? note,
    String? cyberName,
  }) async {
    try {
      final supabase = _supabase.client;

      // Step 1: Find the user by short_id
      final profile = await supabase
          .from('profiles')
          .select('id')
          .eq('short_id', shortId.toLowerCase())
          .single();

      final userId = profile['id'] as String;

      // Step 2: Get their current wallet balance
      final walletData = await supabase
          .from('wallets')
          .select('id, balance')
          .eq('user_id', userId)
          .single();

      final walletId = walletData['id'] as String;
      final currentBalance = walletData['balance'] as int;

      // Step 3: Calculate new balance
      final newBalance = type == 'earned'
          ? currentBalance + amount
          : currentBalance - amount;

      if (newBalance < 0) {
        throw Exception('Insufficient balance. Current balance: $currentBalance pts');
      }

      // Step 4: The database trigger will automatically update the balance 
      // when we insert the transaction, so we don't need to manually update it here.

      // Step 5: Insert transaction record for history
      await supabase.from('wallet_transactions').insert({
        'wallet_id': walletId,
        'type': type,
        'amount': amount,
        'note': note,
        'cyber_name': cyberName,
      });
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('No rows') || msg.contains('0 rows')) {
        throw Exception('User not found. Please check the short ID.');
      }
      if (msg.contains('Insufficient')) {
        throw Exception(msg.replaceAll('Exception: ', ''));
      }
      throw Exception('Failed to add points: $msg');
    }
  }
}
