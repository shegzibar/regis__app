import '../models/user.dart';
import '../supabase/supabase_client.dart';

class UserRepository {
  final SupabaseService _supabase = SupabaseService();

  // Get profile by ID
  Future<AppUser?> getUserById(String userId) async {
    try {
      final response = await _supabase
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        return AppUser.fromMap(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch profile: $e');
    }
  }

  // Get all users (profiles)
  Future<List<AppUser>> getAllUsers() async {
    try {
      final response = await _supabase.from('profiles').select();
      return (response as List).map((e) => AppUser.fromMap(e)).toList();
    } catch (e) {
      throw Exception('Failed to fetch users: $e');
    }
  }

  // Create new profile
  Future<AppUser> createUser({
    required String id,
    String? email, // not stored in profiles, kept for API compat
    String? name,
    required String role,
    String? phone,
  }) async {
    try {
      final profileData = {
        'id': id,
        'name': name,
        'role': role,
        'phone': phone ?? '',
        'created_at': DateTime.now().toIso8601String(),
      };

      await _supabase.from('profiles').insert(profileData);

      return AppUser.fromMap(profileData);
    } catch (e) {
      throw Exception('Failed to create profile: $e');
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

      await _supabase.from('profiles').update(updateData).eq('id', userId);

      final updated = await getUserById(userId);
      if (updated == null) throw Exception('Profile not found');
      return updated;
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Get user by email — profiles has no email column; returns null gracefully.
  Future<AppUser?> getUserByEmail(String email) async {
    // profiles table does not store email. Use auth.currentUser.email instead.
    return null;
  }

  // Delete profile
  Future<void> deleteUser(String userId) async {
    try {
      await _supabase.from('profiles').delete().eq('id', userId);
    } catch (e) {
      throw Exception('Failed to delete profile: $e');
    }
  }
}
