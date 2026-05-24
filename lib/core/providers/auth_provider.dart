import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user.dart';
import '../../data/supabase/supabase_client.dart';

// Auth state provider
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AppUser?>((ref) {
  return AuthStateNotifier();
});

class AuthStateNotifier extends StateNotifier<AppUser?> {
  AuthStateNotifier() : super(null) {
    _initializeAuthState();
  }

  void _initializeAuthState() {
    final currentUser = SupabaseService().currentUser;
    if (currentUser != null) {
      state = AppUser.fromSupabase(currentUser);
    }
  }

  // Set user state (for testing/design mode)
  void setUser(AppUser? user) {
    state = user;
  }

  // Clear user state
  void clearUser() {
    state = null;
  }
}

// Auth service provider
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// Auth controller provider
final authControllerProvider = AsyncNotifierProvider<AuthController, void>(() {
  return AuthController();
});

class AuthService {
  final SupabaseService _supabase = SupabaseService();

  // Send OTP
  Future<void> sendOTP(String phone) async {
    try {
      await _supabase.auth.signInWithOtp(
        phone: phone,
        shouldCreateUser: true,
      );
    } catch (e) {
      throw Exception('Failed to send OTP: $e');
    }
  }

  // Verify OTP
  Future<AppUser> verifyOTP(String phone, String token) async {
    try {
      final response = await _supabase.auth.verifyOTP(
        phone: phone,
        token: token,
        type: OtpType.sms,
      );

      if (response.user == null) {
        throw Exception('Verification failed');
      }

      // Check if user exists in database
      final existingUser = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();

      if (existingUser == null) {
        // Create new user in database
        await _supabase.from('users').insert({
          'id': response.user!.id,
          'phone': phone,
          'role': 'user',
        });
      }

      final user = AppUser.fromSupabase(response.user!);
      return user;
    } catch (e) {
      throw Exception('Failed to verify OTP: $e');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _supabase.auth.signOut();
    } catch (e) {
      throw Exception('Failed to sign out: $e');
    }
  }

  // Update user profile
  Future<void> updateProfile({
    String? name,
    String? avatarUrl,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;

      if (updates.isNotEmpty) {
        await _supabase.from('users').update(updates).eq('id', userId);
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  // Get current user from database
  Future<AppUser?> getCurrentUser() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response =
          await _supabase.from('users').select().eq('id', userId).single();

      return AppUser.fromMap(response);
    } catch (e) {
      return null;
    }
  }

  // Listen to auth changes
  Stream<AppUser?> authStateChanges() {
    return _supabase.auth.onAuthStateChange.map((data) {
      final session = data.session;
      if (session?.user == null) return null;
      return AppUser.fromSupabase(session!.user);
    });
  }
}

class AuthController extends AsyncNotifier<void> {
  late final AuthService _authService;

  @override
  Future<void> build() async {
    _authService = ref.read(authServiceProvider);
  }

  // Send OTP
  Future<void> sendOTP(String phone) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authService.sendOTP(phone);
    });
  }

  // Verify OTP
  Future<AppUser> verifyOTP(String phone, String token) async {
    state = const AsyncValue.loading();
    final user = await AsyncValue.guard(() async {
      return await _authService.verifyOTP(phone, token);
    });

    if (user.hasError) {
      state = AsyncValue.error(user.error!, StackTrace.current);
      throw user.error!;
    }

    // Update auth state
    ref.read(authStateProvider.notifier).setUser(user.value);
    return user.value!;
  }

  // Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authService.signOut();
    });

    // Clear auth state
    ref.read(authStateProvider.notifier).clearUser();
  }

  // Update profile
  Future<void> updateProfile({
    String? name,
    String? avatarUrl,
  }) async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authService.updateProfile(name: name, avatarUrl: avatarUrl);
    });

    // Refresh user data
    final updatedUser = await _authService.getCurrentUser();
    if (updatedUser != null) {
      ref.read(authStateProvider.notifier).setUser(updatedUser);
    }
  }
}
