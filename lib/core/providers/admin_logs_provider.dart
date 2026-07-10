import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/system_log.dart';
import '../../data/models/cyber_analytics.dart';
import '../../data/repositories/system_log_repository.dart';
import '../../data/supabase/supabase_client.dart';

final systemLogRepositoryProvider = Provider<SystemLogRepository>((ref) {
  return SystemLogRepository();
});

final cyberAnalyticsProvider = FutureProvider.autoDispose<List<CyberAnalytics>>((ref) async {
  final supabase = SupabaseService();

  // 1. Fetch all wallet_transactions grouped by cyber_name
  final txResponse = await supabase
      .from('wallet_transactions')
      .select('amount, type, cyber_name') as List;

  // 2. Fetch all system_logs for USER_REGISTERED events
  List<SystemLog> systemLogs = [];
  try {
    final logsResponse = await supabase
        .from('system_logs')
        .select('*, profiles(name), cybers(name)')
        .order('created_at', ascending: false)
        .limit(1000) as List;
    systemLogs = logsResponse
        .map((log) => SystemLog.fromMap(log as Map<String, dynamic>))
        .toList();
  } catch (_) {}

  // 3. Build a map of cyber_name -> { totalPoints, txCount }
  final Map<String, Map<String, int>> cyberStats = {};
  for (final tx in txResponse) {
    final cyberName = tx['cyber_name'] as String? ?? 'Unknown';
    final amount = (tx['amount'] as num? ?? 0).toInt();
    
    cyberStats.putIfAbsent(cyberName, () => {'total': 0, 'earned': 0, 'redeemed': 0});
    cyberStats[cyberName]!['total'] = cyberStats[cyberName]!['total']! + amount;
    if (tx['type'] == 'earned') {
      cyberStats[cyberName]!['earned'] = cyberStats[cyberName]!['earned']! + amount;
    } else if (tx['type'] == 'redeemed') {
      cyberStats[cyberName]!['redeemed'] = cyberStats[cyberName]!['redeemed']! + amount;
    }
  }

  // 4. Fetch cyber ids to match names (for system_logs USER_REGISTERED counts)
  final cybersResponse = await supabase.from('cybers').select('id, name') as List;
  final Map<String, String> cyberNameToId = {
    for (final c in cybersResponse) (c['name'] as String): (c['id'] as String)
  };

  // 5. Build analytics list from the actual transaction data
  final List<CyberAnalytics> analytics = [];

  for (final entry in cyberStats.entries) {
    final cyberName = entry.key;
    final stats = entry.value;
    final cyberId = cyberNameToId[cyberName] ?? cyberName;

    final cyberLogs = systemLogs
        .where((log) => log.cyberId == cyberNameToId[cyberName])
        .toList();

    final registrations = cyberLogs
        .where((log) => log.eventType == 'USER_REGISTERED')
        .length;

    analytics.add(CyberAnalytics(
      cyberId: cyberId,
      cyberName: cyberName,
      totalPointsGiven: stats['earned'] ?? 0,
      totalPointsRedeemed: stats['redeemed'] ?? 0,
      totalUsersRegistered: registrations,
      recentLogs: cyberLogs,
    ));
  }

  // 6. Also add cybers from DB that have NO transactions yet (so they still appear)
  for (final cyber in cybersResponse) {
    final cyberName = cyber['name'] as String;
    if (!cyberStats.containsKey(cyberName)) {
      analytics.add(CyberAnalytics(
        cyberId: cyber['id'] as String,
        cyberName: cyberName,
        totalPointsGiven: 0,
        totalPointsRedeemed: 0,
        totalUsersRegistered: 0,
        recentLogs: [],
      ));
    }
  }

  // 7. Handle global registrations (no cyber code)
  final unassignedLogs = systemLogs.where((log) => log.cyberId == null).toList();
  if (unassignedLogs.isNotEmpty) {
    final totalRegistrations =
        unassignedLogs.where((l) => l.eventType == 'USER_REGISTERED').length;
    analytics.add(CyberAnalytics(
      cyberId: 'unassigned',
      cyberName: 'Global Platform (No Cyber Code)',
      totalPointsGiven: 0,
      totalPointsRedeemed: 0,
      totalUsersRegistered: totalRegistrations,
      recentLogs: unassignedLogs,
    ));
  }

  // Sort by most points given (earned)
  analytics.sort((a, b) => b.totalPointsGiven.compareTo(a.totalPointsGiven));

  return analytics;
});
