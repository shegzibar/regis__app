import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user.dart';
import '../../data/supabase/supabase_client.dart';

// Auth state provider
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AppUser?>((ref) {
  return AuthStateNotifier();
});

// Exposes whether the app is still restoring a session on cold start
final authInitializingProvider = Provider<bool>((ref) {
  // Check if a Supabase session exists but AppUser hasn't been hydrated yet
  final user = ref.watch(authStateProvider);
  final supabaseUser = SupabaseService().currentUser;
  return user == null && supabaseUser != null;
});

class AuthStateNotifier extends StateNotifier<AppUser?> {
  StreamSubscription? _authSubscription;

  AuthStateNotifier() : super(null) {
    _initializeAuthState();
  }

  void _initializeAuthState() {
    // Check for an existing session on startup and fetch DB role
    final currentUser = SupabaseService().currentUser;
    if (currentUser != null) {
      _fetchAndSetUser(currentUser.id);
    }

    // Subscribe to future auth state changes (sign-in / sign-out / token refresh)
    _authSubscription = SupabaseService()
        .auth
        .onAuthStateChange
        .listen((data) async {
      final session = data.session;
      if (session?.user == null) {
        state = null;
      } else {
        await _fetchAndSetUser(session!.user.id);
      }
    });
  }

  /// Fetches the full user row (including role) from the `users` table and
  /// sets state. Falls back to a minimal AppUser built from Auth metadata if
  /// the DB fetch fails (e.g. no network on first launch).
  Future<void> _fetchAndSetUser(String userId) async {
    try {
      final response = await SupabaseService()
          .from('users')
          .select()
          .eq('id', userId)
          .single();
      state = AppUser.fromMap(response);
    } catch (_) {
      // Fallback: build from Supabase Auth metadata if DB unavailable
      final authUser = SupabaseService().currentUser;
      if (authUser != null) {
        state = AppUser.fromSupabase(authUser);
      }
    }
  }

  // Set user state manually (used after sign-up / profile update)
  void setUser(AppUser? user) {
    state = user;
  }

  // Clear user state
  void clearUser() {
    state = null;
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
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

  // Verify OTP — fetches the full DB user row so the role is correct
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

      // Upsert user row in case this is a brand-new account
      final existingUser = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .maybeSingle();

      if (existingUser == null) {
        await _supabase.from('users').insert({
          'id': response.user!.id,
          'phone': phone,
          'role': 'user',
        });
      }

      // Always read the authoritative role from the DB table (not metadata)
      final userRow = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single();

      return AppUser.fromMap(userRow);
    } catch (e) {
      throw Exception('Failed to verify OTP: $e');
    }
  }

  // Sign In with Email & Password
  Future<AppUser> signInWithEmailAndPassword(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed');
      }

      // Always read the authoritative role from the DB table
      final userRow = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single();

      return AppUser.fromMap(userRow);
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  // Sign Up with Email & Password
  Future<AppUser> signUpWithEmailAndPassword(String email, String password, String name, String phone) async {
    try {
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
      );

      if (response.user == null) {
        throw Exception('Sign up failed');
      }

      // Create user row
      final userData = {
        'id': response.user!.id,
        'phone': phone,
        'name': name,
        'role': 'user',
      };

      await _supabase.from('users').upsert(userData);

      // Read back to ensure we have the full object
      final userRow = await _supabase
          .from('users')
          .select()
          .eq('id', response.user!.id)
          .single();

      return AppUser.fromMap(userRow);
    } catch (e) {
      throw Exception('Failed to sign up: $e');
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

  // Get current user from database (with correct role)
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

  // Verify OTP — role is now fetched from DB inside AuthService
  Future<AppUser> verifyOTP(String phone, String token) async {
    state = const AsyncValue.loading();
    final user = await AsyncValue.guard(() async {
      return await _authService.verifyOTP(phone, token);
    });

    if (user.hasError) {
      state = AsyncValue.error(user.error!, StackTrace.current);
      throw user.error!;
    }

    // Push the correct user (with DB role) into the auth state notifier
    ref.read(authStateProvider.notifier).setUser(user.value);
    return user.value!;
  }

  // Sign In with Email & Password
  Future<AppUser> signInWithEmailAndPassword(String email, String password) async {
    state = const AsyncValue.loading();
    final user = await AsyncValue.guard(() async {
      return await _authService.signInWithEmailAndPassword(email, password);
    });

    if (user.hasError) {
      state = AsyncValue.error(user.error!, StackTrace.current);
      throw user.error!;
    }

    ref.read(authStateProvider.notifier).setUser(user.value);
    return user.value!;
  }

  // Sign Up with Email & Password
  Future<AppUser> signUpWithEmailAndPassword(String email, String password, String name, String phone) async {
    state = const AsyncValue.loading();
    final user = await AsyncValue.guard(() async {
      return await _authService.signUpWithEmailAndPassword(email, password, name, phone);
    });

    if (user.hasError) {
      state = AsyncValue.error(user.error!, StackTrace.current);
      throw user.error!;
    }

    ref.read(authStateProvider.notifier).setUser(user.value);
    return user.value!;
  }

  // Sign out
  Future<void> signOut() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      await _authService.signOut();
    });

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

    final updatedUser = await _authService.getCurrentUser();
    if (updatedUser != null) {
      ref.read(authStateProvider.notifier).setUser(updatedUser);
    }
  }
}
