import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/admin/screens/admin_accounts_screen.dart';
import '../../features/admin/screens/admin_create_cyber_screen.dart';
import '../../features/admin/screens/admin_home_screen.dart';
import '../../features/admin/screens/admin_orders_screen.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/manager/screens/manager_history_screen.dart';
import '../../features/manager/screens/manager_overview_screen.dart';
import '../../features/manager/screens/manager_queue_screen.dart';
import '../../shared/screens/access_denied_screen.dart';
import '../providers/auth_provider.dart';
import 'app_shells.dart';
import 'router_helpers.dart';

final adminRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final isInitializing = ref.watch(authInitializingProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      return standaloneAuthRedirect(
        user: authState,
        isInitializing: isInitializing,
        location: state.uri.toString(),
        homeRoute: '/admin/home',
        canAccess: (user) => user.isAdmin || user.isManager,
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
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: '/access-denied',
        name: 'access_denied',
        builder: (context, state) => const AccessDeniedScreen(
          requiredRoleLabel: 'admin or manager',
        ),
      ),
      ShellRoute(
        builder: (context, state, child) => AdminShell(child: child),
        routes: [
          GoRoute(
            path: '/admin/home',
            name: 'admin_home',
            builder: (context, state) => const AdminHomeScreen(),
          ),
          GoRoute(
            path: '/admin/orders',
            name: 'admin_orders',
            builder: (context, state) => const AdminOrdersScreen(),
          ),
          GoRoute(
            path: '/admin/create-cyber',
            name: 'admin_create_cyber',
            builder: (context, state) => const AdminCreateCyberScreen(),
          ),
          GoRoute(
            path: '/admin/accounts',
            name: 'admin_accounts',
            builder: (context, state) => const AdminAccountsScreen(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => _routerError(context, state, '/admin/home'),
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
          Text('Page not found', style: Theme.of(context).textTheme.headlineMedium),
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
