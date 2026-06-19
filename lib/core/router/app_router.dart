import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../features/auth/screens/auth_screen.dart';
import '../../features/auth/screens/signup_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/user/screens/explore_screen.dart';
import '../../features/user/screens/cyber_details_screen.dart';
import '../../features/user/screens/booking_screen.dart';
import '../../features/user/screens/payment_screen.dart';
import '../../features/user/screens/my_bookings_screen.dart';
import '../../features/user/screens/map_screen.dart';
import '../../features/user/screens/profile_screen.dart';
import '../../features/wallet/screens/wallet_screen.dart';

import '../providers/auth_provider.dart';
import 'app_shells.dart';

/// Consumer (user) app router.
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final isInitializing = ref.watch(authInitializingProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final user = authState;
      final location = state.uri.toString();

      if (isInitializing) {
        return location == '/splash' ? null : '/splash';
      }

      if (user == null) {
        final isAuthRoute = location.startsWith('/auth') ||
            location.startsWith('/signup') ||
            location == '/splash';
        if (!isAuthRoute) return '/auth';
        if (location == '/splash') return '/auth';
        return null;
      }

      final isAuthRoute = location.startsWith('/auth') ||
          location.startsWith('/signup') ||
          location == '/splash';
      if (isAuthRoute) return '/explore';

      return null;
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
      ShellRoute(
        builder: (context, state, child) => UserShell(child: child),
        routes: [
          GoRoute(
            path: '/explore',
            name: 'explore',
            builder: (context, state) => const ExploreScreen(),
          ),
          GoRoute(
            path: '/cyber/:id',
            name: 'cyber_details',
            builder: (context, state) {
              final cyberId = state.pathParameters['id']!;
              return CyberDetailsScreen(cyberId: cyberId);
            },
          ),
          GoRoute(
            path: '/booking/:roomId',
            name: 'booking',
            builder: (context, state) {
              final roomId = state.pathParameters['roomId']!;
              return BookingScreen(roomId: roomId);
            },
          ),
          GoRoute(
            path: '/payment/:bookingId',
            name: 'payment',
            builder: (context, state) {
              final bookingId = state.pathParameters['bookingId']!;
              final amountStr = state.uri.queryParameters['amount'];
              final amount = double.tryParse(amountStr ?? '') ?? 0.0;
              return PaymentScreen(bookingId: bookingId, amount: amount);
            },
          ),
          GoRoute(
            path: '/bookings',
            name: 'my_bookings',
            builder: (context, state) => const MyBookingsScreen(),
          ),
          GoRoute(
            path: '/map',
            name: 'map',
            builder: (context, state) => const MapScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/wallet',
            name: 'wallet',
            builder: (context, state) => const WalletScreen(),
          ),

        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64),
            const SizedBox(height: 16),
            Text(
              'Page not found',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              state.uri.toString(),
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => context.go('/explore'),
              child: const Text('Go Home'),
            ),
          ],
        ),
      ),
    ),
  );
});
