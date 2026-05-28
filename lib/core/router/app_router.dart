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
import '../../features/owner/screens/owner_home_screen.dart';
import '../../features/owner/screens/owner_schedule_screen.dart';
import '../../features/owner/screens/owner_requests_screen.dart';
import '../../features/owner/screens/owner_stations_screen.dart';
import '../../features/manager/screens/manager_queue_screen.dart';
import '../../features/manager/screens/manager_history_screen.dart';
import '../../features/manager/screens/manager_overview_screen.dart';
import '../../features/admin/screens/admin_home_screen.dart';
import '../providers/auth_provider.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final isInitializing = ref.watch(authInitializingProvider);

  return GoRouter(
    initialLocation: '/splash',
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final user = authState;

      // Show splash screen while restoring session from Supabase on cold start
      if (isInitializing) {
        return state.uri.toString() == '/splash' ? null : '/splash';
      }

      // If not authenticated, redirect to auth
      if (user == null) {
        final isAuthRoute = state.uri.toString().startsWith('/auth') ||
            state.uri.toString().startsWith('/signup') ||
            state.uri.toString().startsWith('/splash');
        if (!isAuthRoute) {
          return '/auth';
        }
        // If on splash but not initializing → not logged in, go to auth
        if (state.uri.toString() == '/splash') {
          return '/auth';
        }
        return null;
      }

      // If authenticated and on auth or splash route, redirect based on role
      final isAuthRoute = state.uri.toString().startsWith('/auth') ||
          state.uri.toString().startsWith('/signup') ||
          state.uri.toString().startsWith('/splash');
      if (isAuthRoute) {
        switch (user.role) {
          case 'owner':
            return '/owner/home';
          case 'manager':
            return '/manager/queue';
          case 'admin':
            return '/admin/home';
          default:
            return '/explore';
        }
      }

      // Role-based route protection
      final location = state.uri.toString();

      // Owner routes
      if (location.startsWith('/owner') && !user.isOwner) {
        return user.isAdmin ? '/admin/home' : '/explore';
      }

      // Manager routes
      if (location.startsWith('/manager') && !user.isManager) {
        return user.isAdmin ? '/admin/home' : '/explore';
      }

      // Admin routes
      if (location.startsWith('/admin') && !user.isAdmin) {
        return '/explore';
      }

      return null;
    },
    routes: [
      // Splash Route
      GoRoute(
        path: '/splash',
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),

      // Authentication Routes
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

      // User Routes
      ShellRoute(
        builder: (context, state, child) {
          return UserShell(child: child);
        },
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
        ],
      ),

      // Owner Routes
      ShellRoute(
        builder: (context, state, child) {
          return OwnerShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/owner/home',
            name: 'owner_home',
            builder: (context, state) => const OwnerHomeScreen(),
          ),
          GoRoute(
            path: '/owner/schedule',
            name: 'owner_schedule',
            builder: (context, state) => const OwnerScheduleScreen(),
          ),
          GoRoute(
            path: '/owner/requests',
            name: 'owner_requests',
            builder: (context, state) => const OwnerRequestsScreen(),
          ),
          GoRoute(
            path: '/owner/stations',
            name: 'owner_stations',
            builder: (context, state) => const OwnerStationsScreen(),
          ),
        ],
      ),

      // Manager Routes
      ShellRoute(
        builder: (context, state, child) {
          return ManagerShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/manager/queue',
            name: 'manager_queue',
            builder: (context, state) => const ManagerQueueScreen(),
          ),
          GoRoute(
            path: '/manager/history',
            name: 'manager_history',
            builder: (context, state) => const ManagerHistoryScreen(),
          ),
          GoRoute(
            path: '/manager/overview',
            name: 'manager_overview',
            builder: (context, state) => const ManagerOverviewScreen(),
          ),
        ],
      ),

      // Admin Routes
      ShellRoute(
        builder: (context, state, child) {
          return AdminShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/admin/home',
            name: 'admin_home',
            builder: (context, state) => const AdminHomeScreen(),
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

// User Bottom Navigation Shell
class UserShell extends ConsumerStatefulWidget {
  final Widget child;

  const UserShell({super.key, required this.child});

  @override
  ConsumerState<UserShell> createState() => _UserShellState();
}

class _UserShellState extends ConsumerState<UserShell> {
  int _currentIndex = 0;

  static const List<NavigationDestination> destinations = [
    NavigationDestination(
      icon: Icon(Icons.explore_outlined),
      selectedIcon: Icon(Icons.explore),
      label: 'Explore',
    ),
    NavigationDestination(
      icon: Icon(Icons.map_outlined),
      selectedIcon: Icon(Icons.map),
      label: 'Map',
    ),
    NavigationDestination(
      icon: Icon(Icons.calendar_today_outlined),
      selectedIcon: Icon(Icons.calendar_today),
      label: 'Bookings',
    ),
    NavigationDestination(
      icon: Icon(Icons.person_outline),
      selectedIcon: Icon(Icons.person),
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });

          switch (index) {
            case 0:
              context.go('/explore');
              break;
            case 1:
              context.go('/map');
              break;
            case 2:
              context.go('/bookings');
              break;
            case 3:
              context.go('/profile');
              break;
          }
        },
        destinations: destinations,
      ),
    );
  }
}

// Owner Bottom Navigation Shell
class OwnerShell extends ConsumerStatefulWidget {
  final Widget child;

  const OwnerShell({super.key, required this.child});

  @override
  ConsumerState<OwnerShell> createState() => _OwnerShellState();
}

class _OwnerShellState extends ConsumerState<OwnerShell> {
  int _currentIndex = 0;

  static const List<NavigationDestination> destinations = [
    NavigationDestination(
      icon: Icon(Icons.home_outlined),
      selectedIcon: Icon(Icons.home),
      label: 'Home',
    ),
    NavigationDestination(
      icon: Icon(Icons.schedule_outlined),
      selectedIcon: Icon(Icons.schedule),
      label: 'Schedule',
    ),
    NavigationDestination(
      icon: Icon(Icons.pending_actions_outlined),
      selectedIcon: Icon(Icons.pending_actions),
      label: 'Requests',
    ),
    NavigationDestination(
      icon: Icon(Icons.computer_outlined),
      selectedIcon: Icon(Icons.computer),
      label: 'Stations',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });

          switch (index) {
            case 0:
              context.go('/owner/home');
              break;
            case 1:
              context.go('/owner/schedule');
              break;
            case 2:
              context.go('/owner/requests');
              break;
            case 3:
              context.go('/owner/stations');
              break;
          }
        },
        destinations: destinations,
      ),
    );
  }
}

// Manager Bottom Navigation Shell
class ManagerShell extends ConsumerStatefulWidget {
  final Widget child;

  const ManagerShell({super.key, required this.child});

  @override
  ConsumerState<ManagerShell> createState() => _ManagerShellState();
}

class _ManagerShellState extends ConsumerState<ManagerShell> {
  int _currentIndex = 0;

  static const List<NavigationDestination> destinations = [
    NavigationDestination(
      icon: Icon(Icons.pending_outlined),
      selectedIcon: Icon(Icons.pending),
      label: 'Queue',
    ),
    NavigationDestination(
      icon: Icon(Icons.history_outlined),
      selectedIcon: Icon(Icons.history),
      label: 'History',
    ),
    NavigationDestination(
      icon: Icon(Icons.analytics_outlined),
      selectedIcon: Icon(Icons.analytics),
      label: 'Overview',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });

          switch (index) {
            case 0:
              context.go('/manager/queue');
              break;
            case 1:
              context.go('/manager/history');
              break;
            case 2:
              context.go('/manager/overview');
              break;
          }
        },
        destinations: destinations,
      ),
    );
  }
}

// Admin Shell (simple app bar)
class AdminShell extends StatelessWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Panel'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: child,
    );
  }
}
