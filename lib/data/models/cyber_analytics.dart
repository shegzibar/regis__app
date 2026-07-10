import 'package:flutter/foundation.dart';
import 'system_log.dart';

@immutable
class CyberAnalytics {
  final String cyberId;
  final String cyberName;
  final int totalPointsGiven;
  final int totalPointsRedeemed;
  final int totalUsersRegistered;
  final List<SystemLog> recentLogs;

  const CyberAnalytics({
    required this.cyberId,
    required this.cyberName,
    required this.totalPointsGiven,
    required this.totalPointsRedeemed,
    required this.totalUsersRegistered,
    required this.recentLogs,
  });
}
