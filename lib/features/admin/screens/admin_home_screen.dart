import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/repositories/payment_repository.dart';
import '../../../shared/widgets/deposit_review_card.dart';
import '../../../shared/widgets/summary_card.dart';

// ─── Providers ───────────────────────────────────────────────────────────────

final _pendingPaymentsProvider =
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

final _paymentStatsProvider =
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
final _walletStatsProvider =
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

// ─── Screen ──────────────────────────────────────────────────────────────────

class AdminHomeScreen extends ConsumerStatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  ConsumerState<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends ConsumerState<AdminHomeScreen> {
  Future<void> _approveDeposit(String depositId) async {
    try {
      await PaymentRepository()
          .updatePaymentStatus(paymentId: depositId, status: 'approved');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deposit approved successfully'),
            backgroundColor: AppColors.green,
          ),
        );
      }
      ref.invalidate(_pendingPaymentsProvider);
      ref.invalidate(_paymentStatsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  Future<void> _rejectDeposit(String depositId) async {
    try {
      await PaymentRepository()
          .updatePaymentStatus(paymentId: depositId, status: 'rejected');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Deposit rejected'),
            backgroundColor: AppColors.error,
          ),
        );
      }
      ref.invalidate(_pendingPaymentsProvider);
      ref.invalidate(_paymentStatsProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    }
  }

  void _viewReceipt(String depositId, String? screenshotUrl) {
    if (screenshotUrl == null || screenshotUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No receipt image available for this deposit.')),
      );
      return;
    }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(screenshotUrl, fit: BoxFit.contain),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.darkCard),
              child: const Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _refreshData() {
    ref.invalidate(_pendingPaymentsProvider);
    ref.invalidate(_paymentStatsProvider);
    ref.invalidate(_walletStatsProvider);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Refreshing data...')),
    );
  }

  String _formatDateTime(dynamic raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return '${dt.day}/${dt.month}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw.toString();
    }
  }

  String _getTimeAgo(dynamic createdAt) {
    if (createdAt == null) return '';
    try {
      final dt = DateTime.parse(createdAt.toString()).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(_pendingPaymentsProvider);
    final statsAsync = ref.watch(_paymentStatsProvider);
    final walletStatsAsync = ref.watch(_walletStatsProvider);

    final pendingCount = statsAsync.value?['pending'] ?? 0;
    final confirmedCount = statsAsync.value?['confirmed'] ?? 0;
    final rejectedCount = statsAsync.value?['rejected'] ?? 0;
    final revenue = statsAsync.value?['revenue'] ?? 0.0;

    final usersWithWallets = walletStatsAsync.value?['usersWithWallets'] ?? 0;
    final usersWithActivity = walletStatsAsync.value?['usersWithActivity'] ?? 0;
    final totalPointsEarned = walletStatsAsync.value?['totalPointsEarned'] ?? 0;
    final totalPointsRedeemed =
        walletStatsAsync.value?['totalPointsRedeemed'] ?? 0;
    final netPoints = walletStatsAsync.value?['netPointsCirculating'] ?? 0;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: SingleChildScrollView(
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
                          'admin.fee_queue'.tr(),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'admin.manage_fees'.tr(),
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
                    color: AppColors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: AppColors.green.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.green.withValues(alpha: 0.2),
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
                          'admin.verify_receipts'.tr(),
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
                        title: 'admin.pending'.tr(),
                        value: pendingCount.toString(),
                        valueColor: Colors.orange,
                        icon: Icons.pending,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SummaryCard(
                        title: 'admin.confirmed'.tr(),
                        value: confirmedCount.toString(),
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
                        title: 'admin.rejected'.tr(),
                        value: rejectedCount.toString(),
                        valueColor: AppColors.error,
                        icon: Icons.cancel,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SummaryCard(
                        title: 'admin.revenue'.tr(),
                        value: '${revenue.toInt()} ${'common.egp'.tr()}',
                        valueColor: AppColors.green,
                        icon: Icons.account_balance_wallet,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Points & Wallet System Stats Section
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 32,
                          height: 32,
                          decoration: BoxDecoration(
                            color: AppColors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(
                            Icons.card_giftcard,
                            color: AppColors.green,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Points & Rewards System',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Points stats grid
                    walletStatsAsync.when(
                      loading: () => Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: AppColors.darkCard,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.darkBorder),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: AppColors.green,
                              strokeWidth: 2,
                            ),
                          ),
                        ),
                      ),
                      error: (e, _) => Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Text(
                          'Error loading points stats',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      data: (_) => Column(
                        children: [
                          // First row: Users with wallets & Users with activity
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkCard,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: AppColors.darkBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: Colors.blue
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Icon(
                                              Icons.people,
                                              color: Colors.blue,
                                              size: 14,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            'Users w/ Wallet',
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        usersWithWallets.toString(),
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkCard,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: AppColors.darkBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: AppColors.green
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Icon(
                                              Icons.trending_up,
                                              color: AppColors.green,
                                              size: 14,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            'Using Points',
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        usersWithActivity.toString(),
                                        style: const TextStyle(
                                          fontSize: 28,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.green,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Second row: Points earned & Points redeemed
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkCard,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: AppColors.darkBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: Colors.amber
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Icon(
                                              Icons.add_circle_outline,
                                              color: Colors.amber,
                                              size: 14,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            'Earned',
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        '$totalPointsEarned pts',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.amber,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.darkCard,
                                    borderRadius: BorderRadius.circular(12),
                                    border:
                                        Border.all(color: AppColors.darkBorder),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: BoxDecoration(
                                              color: Colors.red
                                                  .withValues(alpha: 0.2),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                            child: Icon(
                                              Icons.remove_circle_outline,
                                              color: Colors.red,
                                              size: 14,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            'Redeemed',
                                            style: const TextStyle(
                                              color: AppColors.textMuted,
                                              fontSize: 11,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 12),
                                      Text(
                                        '$totalPointsRedeemed pts',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          // Net points circulating
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [
                                  AppColors.green.withValues(alpha: 0.15),
                                  AppColors.green.withValues(alpha: 0.05),
                                ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.green.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 28,
                                      height: 28,
                                      decoration: BoxDecoration(
                                        color: AppColors.green
                                            .withValues(alpha: 0.3),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Icon(
                                        Icons.account_balance,
                                        color: AppColors.green,
                                        size: 14,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      'Net Circulating',
                                      style: const TextStyle(
                                        color: AppColors.textMuted,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  '$netPoints pts',
                                  style: const TextStyle(
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Pending Review Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Pending Review ($pendingCount)',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const Row(
                          children: [
                            Text(
                              'Oldest first',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(width: 4),
                            Icon(
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
                  pendingAsync.when(
                    loading: () => const Center(
                      child: Padding(
                        padding: EdgeInsets.all(32.0),
                        child:
                            CircularProgressIndicator(color: AppColors.green),
                      ),
                    ),
                    error: (e, _) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32.0),
                        child: Text(
                          'Failed to load pending fees: $e',
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    ),
                    data: (pendingReviews) {
                      if (pendingReviews.isEmpty) {
                        return const Center(
                          child: Padding(
                            padding: EdgeInsets.all(32.0),
                            child: Text(
                              'No pending fees',
                              style: TextStyle(color: AppColors.textMuted),
                            ),
                          ),
                        );
                      }

                      return ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24.0),
                        itemCount: pendingReviews.length,
                        itemBuilder: (context, index) {
                          final payment = pendingReviews[index];

                          final userProfile =
                              payment['profiles'] as Map<String, dynamic>?;
                          final booking =
                              payment['bookings'] as Map<String, dynamic>?;
                          final station =
                              booking?['stations'] as Map<String, dynamic>?;
                          final room =
                              station?['rooms'] as Map<String, dynamic>?;
                          final cyber =
                              room?['cybers'] as Map<String, dynamic>?;

                          final userName =
                              userProfile?['name'] ?? 'Unknown User';
                          final initials = userName.toString().isNotEmpty
                              ? userName.toString()[0].toUpperCase()
                              : '?';

                          final bookingTime =
                              '${_formatDateTime(booking?['start_time'])} - ${_formatDateTime(booking?['end_time'])}';

                          final bookingStatus = (booking?['status'] ?? 'Unknown').toString().toUpperCase();

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 16.0),
                            child: DepositReviewCard(
                              userName: userName,
                              initials: initials,
                              timeAgo: _getTimeAgo(payment['created_at']),
                              paymentMethod: (payment['method'] ?? 'Unknown')
                                  .toString()
                                  .toUpperCase(),
                              gamingLounge: cyber?['name'] ?? 'Unknown Cyber',
                              bookingTime: bookingTime,
                              bookingStatus: 'Booking Status: $bookingStatus',
                              onApprove: () => _approveDeposit(payment['id']),
                              onReject: () => _rejectDeposit(payment['id']),
                              onViewReceipt: () => _viewReceipt(
                                  payment['id'], payment['screenshot_url']),
                            ),
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
