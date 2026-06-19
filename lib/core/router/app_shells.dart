import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/providers/auth_provider.dart';
import '../../features/admin/widgets/admin_sidebar.dart';
import '../../features/admin/widgets/admin_top_bar.dart';
import '../../features/owner/widgets/owner_dashboard_shell.dart';

/// Consumer app bottom navigation.
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
          setState(() => _currentIndex = index);
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

/// Cyber café owner dashboard shell (RTL sidebar layout).
class OwnerShell extends StatelessWidget {
  final Widget child;

  const OwnerShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return OwnerDashboardShell(child: child);
  }
}

/// Platform admin app shell.
class AdminShell extends ConsumerStatefulWidget {
  final Widget child;

  const AdminShell({super.key, required this.child});

  @override
  ConsumerState<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends ConsumerState<AdminShell> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Column(
        children: [
          const AdminTopBar(),
          Expanded(
            child: Row(
              children: [
                const AdminSidebar(),
                Expanded(
                  child: ClipRect(
                    child: widget.child,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Manager shell (used inside the full consumer app build).
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
          setState(() => _currentIndex = index);
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
