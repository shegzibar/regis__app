import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/user.dart';
import '../supabase/supabase_client.dart';

class UserRepository {
  final SupabaseService _supabase = SupabaseService();

  // Get user by ID
  Future<AppUser?> getUserById(String userId) async {
    try {
      final response =
          await _supabase.from('users').select().eq('id', userId).maybeSingle();

      if (response != null) {
        return AppUser.fromMap(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user: $e');
    }
  }

  // Create new user
  Future<AppUser> createUser({
    required String id,
    required String email,
    String? name,
    required String role,
    String? phone,
  }) async {
    try {
      final userData = {
        'id': id,
        'email': email,
        'name': name,
        'role': role,
        'phone': phone,
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('users').insert(userData);

      return AppUser.fromMap(userData);
    } catch (e) {
      throw Exception('Failed to create user: $e');
    }
  }

  // Update user profile
  Future<AppUser> updateUser({
    required String userId,
    String? name,
    String? phone,
    String? avatarUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (phone != null) updateData['phone'] = phone;
      if (avatarUrl != null) updateData['avatar_url'] = avatarUrl;

      await _supabase.from('users').update(updateData).eq('id', userId);

      final updated = await getUserById(userId);
      if (updated == null) throw Exception('User not found');
      return updated;
    } catch (e) {
      throw Exception('Failed to update user: $e');
    }
  }

  // Get user by email
  Future<AppUser?> getUserByEmail(String email) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('email', email)
          .maybeSingle();

      if (response != null) {
        return AppUser.fromMap(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch user by email: $e');
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      await _supabase.from('users').delete().eq('id', userId);
    } catch (e) {
      throw Exception('Failed to delete user: $e');
    }
  }
}
