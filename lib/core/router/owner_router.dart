import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/cyber_dashboard/cyber_dashboard_shell.dart';
import '../../shared/screens/access_denied_screen.dart';
import '../providers/auth_provider.dart';
import '../providers/owner_dashboard_provider.dart';
import 'router_helpers.dart';

final ownerRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final isInitializing = ref.watch(authInitializingProvider);
  final hasCyber = ref.watch(ownerHasCyberProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final location = state.uri.toString();

      if (location.startsWith('/owner/onboarding')) {
        return null; // Allows unauthenticated users to use this page for signup, without interrupting them the moment they log in.
      }

      if (location.startsWith('/owner/setup')) {
        if (authState == null) return '/auth';
        if (hasCyber == true) return '/cyber';
        return null;
      }

      // Removed forced setup redirect loop to allow users to reach the dashboard directly

      // If they try to access old routes, redirect them
      if (location.startsWith('/owner/home') || 
          location.startsWith('/owner/profile') ||
          location.startsWith('/owner/')) {
        return '/cyber';
      }

      return standaloneAuthRedirect(
        user: authState,
        isInitializing: isInitializing,
        location: location,
        homeRoute: '/cyber',
        canAccess: (user) => user.isStaff,
      );
    },
    routes: [
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/auth',
        name: 'auth',
        builder: (context, state) => const AuthScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        // Sign-up is disabled for the cyber app — accounts are created by admin.
        redirect: (_, __) => '/auth',
      ),
      GoRoute(
        path: '/owner/onboarding',
        name: 'owner_onboarding',
        // Onboarding disabled — admins create cyber accounts directly.
        redirect: (_, __) => '/auth',
      ),
      GoRoute(
        path: '/owner/setup',
        name: 'owner_setup',
        // Only reachable by already-authenticated owners.
        redirect: (context, state) {
          if (authState == null) return '/auth';
          if (hasCyber == true) return '/cyber';
          return null; // allow through
        },
        builder: (context, state) => const SizedBox.shrink(),
      ),
      GoRoute(
        path: '/access-denied',
        name: 'access_denied',
        builder: (context, state) => const AccessDeniedScreen(
          requiredRoleLabel: 'cyber café staff',
        ),
      ),
      GoRoute(
        path: '/cyber',
        name: 'cyber_dashboard',
        builder: (context, state) => const CyberDashboardShell(),
      ),
    ],
    errorBuilder: (context, state) =>
        _routerError(context, state, '/cyber'),
  );
});

Widget _routerError(BuildContext context, GoRouterState state, String home) {
  return Scaffold(
    body: Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64),
          const SizedBox(height: 16),
          Text('Page not found',
              style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 8),
          Text(state.uri.toString()),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => context.go(home),
            child: const Text('Go Home'),
          ),
        ],
      ),
    ),
  );
}
