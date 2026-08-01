import 'package:supabase_flutter/supabase_flutter.dart';

class AppUser {
  final String id;
  final String? email;
  final String? phone;
  final String? name;
  final String role;
  final String? avatarUrl;
  final String? fcmToken;
  final String? shortId;
  final String? cyberId;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    this.email,
    this.phone,
    this.name,
    required this.role,
    this.avatarUrl,
    this.fcmToken,
    this.shortId,
    this.cyberId,
    required this.createdAt,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      id: map['id'] as String,
      email: map['email'] as String?,
      phone: map['phone'] as String?,
      name: map['name'] as String?,
      role: map['role'] as String? ?? 'user',
      avatarUrl: map['avatar_url'] as String?,
      fcmToken: map['fcm_token'] as String?,
      shortId: map['short_id'] as String?,
      cyberId: map['cyber_id'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  factory AppUser.fromSupabase(User user) {
    return AppUser(
      id: user.id,
      email: user.email,
      phone: user.phone,
      name: user.userMetadata?['name'],
      role: user.userMetadata?['role'] ?? 'user',
      avatarUrl: user.userMetadata?['avatar_url'],
      fcmToken: user.userMetadata?['fcm_token'],
      shortId: user.userMetadata?['short_id'],
      cyberId: user.userMetadata?['cyber_id'],
      createdAt: DateTime.tryParse(user.createdAt.toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'phone': phone,
      'name': name,
      'role': role,
      'avatar_url': avatarUrl,
      'fcm_token': fcmToken,
      'short_id': shortId,
      'cyber_id': cyberId,
      'created_at': createdAt.toIso8601String(),
    };
  }

  AppUser copyWith({
    String? id,
    String? email,
    String? phone,
    String? name,
    String? role,
    String? avatarUrl,
    String? fcmToken,
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isUser => role == 'user';
  bool get isOwner => role == 'owner';
  bool get isManager => role == 'manager';
  bool get isWorker => role == 'worker';
  bool get isAdmin => role == 'admin';
  bool get isStaff => isOwner || isManager || isWorker || isAdmin;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AppUser && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'AppUser(id: $id, phone: $phone, name: $name, role: $role)';
  }
}
