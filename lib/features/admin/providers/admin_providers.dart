import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final pendingPaymentsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client.from('payments').select('''
    id, amount, method, status, created_at, screenshot_url, rejection_reason, user_id,
    bookings!inner(
      id, user_id, start_time, end_time, status,
      stations(
        id,
        rooms(
          id, name, type,
          cybers(id, name, city)
        )
      )
    )
  ''').eq('status', 'pending').order('created_at', ascending: true);

  final paymentList = (data as List)
      .map((p) => Map<String, dynamic>.from(p as Map<String, dynamic>))
      .toList();
  final userIds = paymentList
      .map((p) => p['user_id'] as String?)
      .where((id) => id != null)
      .cast<String>()
      .toSet()
      .toList();

  Map<String, Map<String, dynamic>> userProfiles = {};
  if (userIds.isNotEmpty) {
    try {
      final profiles = await Supabase.instance.client
          .from('profiles')
          .select('id, name, phone')
          .inFilter('id', userIds);

      for (var profile in profiles) {
        userProfiles[profile['id']] = profile;
      }
    } catch (e) {
      // If query fails, we'll just use unknown names
    }
  }

  // Merge profile data into payments
  for (var payment in paymentList) {
    final userId = payment['user_id'] as String?;
    final profile = userId != null && userProfiles.containsKey(userId)
        ? userProfiles[userId]
        : null;
    
    String displayName = 'Unknown User';
    if (profile != null) {
      final name = profile['name'] as String?;
      final phone = profile['phone'] as String?;
      if (name != null && name.trim().isNotEmpty) {
        displayName = name;
      } else if (phone != null && phone.trim().isNotEmpty) {
        displayName = phone;
      }
    }
    
    payment['profiles'] = {'name': displayName};
  }

  return paymentList;
});

final paymentStatsProvider =
    FutureProvider.autoDispose<Map<String, num>>((ref) async {
  final db = Supabase.instance.client;

  final pending = await db
      .from('payments')
      .select('id')
      .eq('status', 'pending')
      .count(CountOption.exact);
  final confirmed = await db
      .from('payments')
      .select('id')
      .eq('status', 'approved')
      .count(CountOption.exact);
  final rejected = await db
      .from('payments')
      .select('id')
      .eq('status', 'rejected')
      .count(CountOption.exact);

  // Calculate total revenue (approved payments sum)
  final approvedPayments =
      await db.from('payments').select('amount').eq('status', 'approved');
  double rev = 0;
  for (var p in approvedPayments) {
    rev += (p['amount'] as num?)?.toDouble() ?? 0.0;
  }

  return {
    'pending': pending.count,
    'confirmed': confirmed.count,
    'rejected': rejected.count,
    'revenue': rev,
  };
});

// Wallet & Points Statistics Provider
final walletStatsProvider =
    FutureProvider.autoDispose<Map<String, dynamic>>((ref) async {
  final db = Supabase.instance.client;

  try {
    // Get total users with wallets
    final walletsCountResult =
        await db.from('wallets').select('id').count(CountOption.exact);
    final usersWithWallets = walletsCountResult.count;

    // Get all transactions to calculate points
    final transactionsData = await db
        .from('wallet_transactions')
        .select('id, type, amount, wallet_id');

    var totalPointsEarned = 0;
    var totalPointsRedeemed = 0;
    var walletsWithActivity = <String>{};

    for (var tx in transactionsData) {
      final type = tx['type'] as String?;
      final amount = (tx['amount'] as num?)?.toInt() ?? 0;
      final walletId = tx['wallet_id'] as String?;

      if (walletId != null) {
        walletsWithActivity.add(walletId);
      }

      if (type == 'earned') {
        totalPointsEarned += amount;
      } else if (type == 'redeemed') {
        totalPointsRedeemed += amount;
      }
    }

    return {
      'usersWithWallets': usersWithWallets,
      'usersWithActivity': walletsWithActivity.length,
      'totalPointsEarned': totalPointsEarned,
      'totalPointsRedeemed': totalPointsRedeemed,
      'netPointsCirculating': totalPointsEarned - totalPointsRedeemed,
    };
  } catch (e) {
    // Return default values if there's an error (e.g., tables don't exist yet)
    return {
      'usersWithWallets': 0,
      'usersWithActivity': 0,
      'totalPointsEarned': 0,
      'totalPointsRedeemed': 0,
      'netPointsCirculating': 0,
    };
  }
});
