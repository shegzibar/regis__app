import 'package:flutter/foundation.dart';

@immutable
class SystemLog {
  final String id;
  final DateTime createdAt;
  final String eventType;
  final String? userId;
  final String? cyberId;
  final Map<String, dynamic>? details;

  // Additional joined fields from API views if needed
  final String? userName;
  final String? cyberName;

  const SystemLog({
    required this.id,
    required this.createdAt,
    required this.eventType,
    this.userId,
    this.cyberId,
    this.details,
    this.userName,
    this.cyberName,
  });

  factory SystemLog.fromMap(Map<String, dynamic> map) {
    // Supabase joins often return nested objects
    final profileData = map['profiles'] as Map<String, dynamic>?;
    final cyberData = map['cybers'] as Map<String, dynamic>?;

    return SystemLog(
      id: map['id'] as String,
      createdAt: DateTime.parse(map['created_at'] as String),
      eventType: map['event_type'] as String,
      userId: map['user_id'] as String?,
      cyberId: map['cyber_id'] as String?,
      details: map['details'] as Map<String, dynamic>?,
      userName: profileData?['name'] as String?,
      cyberName: cyberData?['name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'event_type': eventType,
      'user_id': userId,
      'cyber_id': cyberId,
      'details': details,
    };
  }
}
