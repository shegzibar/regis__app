import 'package:supabase_flutter/supabase_flutter.dart';

class AppUser {
  final String id;
  final String? email;
  final String? phone;
  final String? name;
  final String role;
  final String? avatarUrl;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    this.email,
    this.phone,
    this.name,
    required this.role,
    this.avatarUrl,
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
      createdAt: DateTime.tryParse(user.createdAt.toString()) ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'phone': phone,
      'name': name,
      'role': role,
      'avatar_url': avatarUrl,
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
    DateTime? createdAt,
  }) {
    return AppUser(
      id: id ?? this.id,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      role: role ?? this.role,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  bool get isUser => role == 'user';
  bool get isOwner => role == 'owner';
  bool get isManager => role == 'manager';
  bool get isAdmin => role == 'admin';
  bool get isStaff => isOwner || isManager || isAdmin;

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
