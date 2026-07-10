import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/models/user.dart';
import '../../data/supabase/supabase_client.dart';
import '../constants/app_constants.dart';

// Auth state provider
final authStateProvider =
    StateNotifierProvider<AuthStateNotifier, AppUser?>((ref) {
  return AuthStateNotifier();
});

// Exposes whether the app is still initializing (showing splash screen)
final authInitializingProvider = StateNotifierProvider<AuthInitNotifier, bool>((ref) {
  return AuthInitNotifier(ref);
});

class AuthInitNotifier extends StateNotifier<bool> {
  final Ref ref;
  bool _minDelayPassed = false;

  AuthInitNotifier(this.ref) : super(true) {
    ref.listen<AppUser?>(authStateProvider, (previous, next) {
      _checkState();
    });
    _init();
  }

  Future<void> _init() async {
    // Force minimum 2 second delay to show splash screen animation
    await Future.delayed(const Duration(milliseconds: 2000));
    if (!mounted) return;
    _minDelayPassed = true;
    _checkState();
  }

  void _checkState() {
    if (!_minDelayPassed) return;

    final user = ref.read(authStateProvider);
    final supabaseUser = SupabaseService().currentUser;
    
    if (user == null && supabaseUser != null) {
      state = true; // still hydrating
    } else {
      state = false; // done hydrating and min delay passed
    }
  }
}

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

  /// Fetches the full profile row (including role) from the `profiles` table and
  /// sets state. Falls back to a minimal AppUser built from Auth metadata if
  /// the DB fetch fails (e.g. no network on first launch).
  Future<void> _fetchAndSetUser(String userId) async {
    try {
      final response = await SupabaseService()
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response != null) {
        final mutableResponse = Map<String, dynamic>.from(response);
        final authUser = SupabaseService().currentUser;
        if (authUser != null) {
          mutableResponse['email'] = authUser.email;
          if (mutableResponse['phone'] == null || mutableResponse['phone'] == '') {
            mutableResponse['phone'] = authUser.phone;
          }
        }
        state = AppUser.fromMap(mutableResponse);
        return;
      }

      final authUser = SupabaseService().currentUser;
      if (authUser != null && authUser.id == userId) {
        state = await AuthService().ensureUserProfile(authUser);
      }
    } catch (_) {
      final authUser = SupabaseService().currentUser;
      if (authUser != null) {
        try {
          state = await AuthService().ensureUserProfile(authUser);
        } catch (_) {
          state = AppUser.fromSupabase(authUser);
        }
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

  /// Ensures a `profiles` row exists after Supabase Auth sign-in / sign-up.
  Future<AppUser> ensureUserProfile(
    User authUser, {
    String? email,
    String? name,
    String? phone,
    String role = 'user',
    bool isSignUp = false,
  }) async {
    try {
      final existing = await _supabase
          .from('profiles')
          .select()
          .eq('id', authUser.id)
          .maybeSingle();

      Map<String, dynamic> profileData = {};
      bool needsUpdate = false;

      if (existing != null) {
        profileData = Map<String, dynamic>.from(existing);
        
        if (isSignUp) {
          if (name != null) profileData['name'] = name;
          if (phone != null) profileData['phone'] = phone;
          if (role != 'user') profileData['role'] = role;
          needsUpdate = true;
        } else {
          // Just login: update if missing
          if (name != null && (profileData['name'] == null || profileData['name'] == '')) {
            profileData['name'] = name;
            needsUpdate = true;
          }
          if (phone != null && (profileData['phone'] == null || profileData['phone'] == '')) {
            profileData['phone'] = phone;
            needsUpdate = true;
          }
        }
      } else {
        needsUpdate = true;
        profileData = {
          'id': authUser.id,
          'name': name ??
              authUser.userMetadata?['name'] ??
              (email ?? authUser.email ?? '').split('@').first,
          'role': role,
          'phone': phone ?? authUser.phone ?? '',
        };
        if (role == 'owner') {
          profileData['short_id'] = 'CYB${(10000 + DateTime.now().millisecondsSinceEpoch % 90000)}';
        }
      }

      if (needsUpdate) {
        await _supabase.from('profiles').upsert(profileData);
        if (existing == null) {
          // Log new user registration
          try {
            String? cyberId;
            final cyberCode = authUser.userMetadata?['cyber_code'];
            if (cyberCode != null) {
              final cyber = await _supabase.from('profiles').select('cybers(id)').eq('short_id', cyberCode).maybeSingle();
              if (cyber != null && cyber['cybers'] != null && (cyber['cybers'] as List).isNotEmpty) {
                 cyberId = cyber['cybers'][0]['id'] as String?;
              }
            }
            
            await _supabase.from('system_logs').insert({
              'event_type': 'USER_REGISTERED',
              'user_id': authUser.id,
              'cyber_id': cyberId,
              'details': {
                'role': role,
                'provider': email != null ? 'email' : 'phone',
                if (cyberCode != null) 'cyber_code': cyberCode,
              }
            });
          } catch (e) {
            debugPrint('Failed to log USER_REGISTERED to system_logs: $e');
            // Ignore log errors so it doesn't break sign-up
          }
        }
      }

      // Inject email since it's not stored in the profiles table
      profileData['email'] = email ?? authUser.email;
      
      return AppUser.fromMap(profileData);
    } catch (e) {
      debugPrint('ensureUserProfile failed: $e');
      return AppUser.fromSupabase(authUser);
    }
  }

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

  // Verify OTP — fetches the full profile row so the role is correct
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

      return ensureUserProfile(
        response.user!,
        phone: phone,
        role: 'user',
      );
    } catch (e) {
      throw Exception('Failed to verify OTP: $e');
    }
  }

  // Sign In with Email & Password
  Future<AppUser> signInWithEmailAndPassword(String email, String password) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email.trim(),
        password: password,
      );

      if (response.user == null) {
        throw Exception('Login failed');
      }

      return ensureUserProfile(
        response.user!,
        email: email.trim(),
      );
    } catch (e) {
      throw Exception('Failed to sign in: $e');
    }
  }

  // Sign Up with Email & Password
  Future<AppUser> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
    String phone, {
    String role = 'user',
    String? cyberCode,
  }) async {
    try {
      if (!AppConstants.userRoles.contains(role)) {
        throw Exception('Invalid role: $role');
      }

      final response = await _supabase.auth.signUp(
        email: email.trim(),
        password: password,
        data: {
          'name': name, 
          'role': role, 
          'phone': phone,
          if (cyberCode != null) 'cyber_code': cyberCode,
        },
      );

      if (response.user == null) {
        throw Exception('Sign up failed');
      }

      return ensureUserProfile(
        response.user!,
        email: email.trim(),
        name: name,
        phone: phone,
        role: role,
        isSignUp: true,
      );
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
    String? phone,
  }) async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('User not authenticated');

      final updates = <String, dynamic>{};
      if (name != null) updates['name'] = name;
      if (avatarUrl != null) updates['avatar_url'] = avatarUrl;
      if (phone != null && phone.isNotEmpty) updates['phone'] = phone;

      if (updates.isEmpty) return;

      await _supabase.from('profiles').update(updates).eq('id', userId).select();

      if (name != null) {
        await _supabase.auth.updateUser(
          UserAttributes(data: {'name': name}),
        );
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<void> updatePassword(String newPassword) async {
    try {
      if (newPassword.length < 6) {
        throw Exception('Password must be at least 6 characters');
      }
      await _supabase.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } catch (e) {
      throw Exception('Failed to update password: $e');
    }
  }

  // Get current user from profiles table (with correct role)
  Future<AppUser?> getCurrentUser() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return null;

      final response =
          await _supabase.from('profiles').select().eq('id', userId).single();

      return AppUser.fromMap(response);
    } catch (e) {
      debugPrint('getCurrentUser failed: $e');
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
  Future<AppUser> signUpWithEmailAndPassword(
    String email,
    String password,
    String name,
    String phone, {
    String role = 'user',
    String? cyberCode,
  }) async {
    state = const AsyncValue.loading();
    final user = await AsyncValue.guard(() async {
      return await _authService.signUpWithEmailAndPassword(
        email,
        password,
        name,
        phone,
        role: role,
        cyberCode: cyberCode,
      );
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
    String? phone,
  }) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      await _authService.updateProfile(
        name: name,
        avatarUrl: avatarUrl,
        phone: phone,
      );
    });
    state = result;

    if (result.hasError) {
      throw result.error!;
    }

    final updatedUser = await _authService.getCurrentUser();
    if (updatedUser != null) {
      ref.read(authStateProvider.notifier).setUser(updatedUser);
    }
  }

  Future<void> updatePassword(String newPassword) async {
    state = const AsyncValue.loading();
    final result = await AsyncValue.guard(() async {
      await _authService.updatePassword(newPassword);
    });
    state = result;

    if (result.hasError) {
      throw result.error!;
    }
  }
}
