import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/owner_dashboard_provider.dart';
import '../../../core/utils/role_utils.dart';
import 'cyber_header_lang_toggle.dart';

class OwnerDashboardShell extends ConsumerStatefulWidget {
  final Widget child;

  const OwnerDashboardShell({super.key, required this.child});

  @override
  ConsumerState<OwnerDashboardShell> createState() =>
      _OwnerDashboardShellState();
}

class _OwnerDashboardShellState extends ConsumerState<OwnerDashboardShell> {
  int _selectedIndex = 0;

  static const _profileIndex = 5;

  static const _ownerRoutes = [
    '/owner/home',
    '/owner/manual-booking',
    '/owner/payments',
    '/owner/schedule',
    '/owner/stations',
    '/owner/profile',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncIndexFromRoute();
  }

  void _syncIndexFromRoute() {
    final loc = GoRouterState.of(context).uri.toString();
    if (loc.startsWith('/owner/profile')) {
      if (_selectedIndex != _profileIndex) {
        setState(() => _selectedIndex = _profileIndex);
      }
      return;
    }
    for (var i = 0; i < _ownerRoutes.length - 1; i++) {
      if (loc.startsWith(_ownerRoutes[i])) {
        if (_selectedIndex != i) setState(() => _selectedIndex = i);
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isRtl = context.locale.languageCode == 'ar';
    final user = ref.watch(authStateProvider);
    final cyber = ref.watch(ownerPrimaryCyberProvider);
    final cafeName = cyber?.name ?? 'owner_dashboard.default_cafe_name'.tr();
    final showAdminNav = showOwnerAdminNavItems(user);

    return Directionality(
      textDirection: isRtl ? ui.TextDirection.rtl : ui.TextDirection.ltr,
      child: Scaffold(
        backgroundColor: const Color(0xFFF4F6F8),
        body: Row(
          children: [
            _Sidebar(
              selectedIndex: _selectedIndex,
              showAdminItems: showAdminNav,
              onSelect: (index) {
                setState(() => _selectedIndex = index);
                context.go(_ownerRoutes[index]);
              },
              onAdminTap: (route) {
                if (route != null) {
                  context.go(route);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('common.loading'.tr())),
                  );
                }
              },
            ),
            Expanded(
              child: Column(
                children: [
                  _DashboardHeader(
                    cafeName: cafeName,
                    userName: user?.name ?? '',
                    onProfile: () => context.go('/owner/profile'),
                    onLogout: () =>
                        ref.read(authControllerProvider.notifier).signOut(),
                  ),
                  Expanded(child: widget.child),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  final String cafeName;
  final String userName;
  final VoidCallback onProfile;
  final VoidCallback onLogout;

  const _DashboardHeader({
    required this.cafeName,
    required this.userName,
    required this.onProfile,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: Row(
        children: [
          const CyberHeaderLangToggle(),
          Expanded(
            child: Text(
              cafeName,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1D21),
              ),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              InkWell(
                onTap: onProfile,
                borderRadius: BorderRadius.circular(20),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.logout, size: 20),
                color: AppColors.textMuted,
                onPressed: onLogout,
                tooltip: 'common.logout'.tr(),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final int selectedIndex;
  final bool showAdminItems;
  final ValueChanged<int> onSelect;
  final void Function(String? route) onAdminTap;

  const _Sidebar({
    required this.selectedIndex,
    required this.showAdminItems,
    required this.onSelect,
    required this.onAdminTap,
  });

  static const _adminRoutes = [
    null,
    null,
    null,
  ];

  @override
  Widget build(BuildContext context) {
    final items = [
      _NavItem(Icons.dashboard_outlined, 'owner_dashboard.home'.tr()),
      _NavItem(Icons.add_circle_outline, 'owner_dashboard.manual_booking'.tr()),
      _NavItem(Icons.payments_outlined, 'owner_dashboard.payments'.tr()),
      _NavItem(Icons.calendar_month_outlined, 'owner_dashboard.schedule'.tr()),
      _NavItem(Icons.computer_outlined, 'owner_dashboard.stations'.tr()),
    ];

    final adminItems = [
      _NavItem(Icons.people_outline, 'owner_dashboard.employees'.tr()),
      _NavItem(Icons.star_outline, 'owner_dashboard.reviews'.tr()),
      _NavItem(Icons.bar_chart_outlined, 'owner_dashboard.statistics'.tr()),
    ];

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          left: BorderSide(color: const Color(0xFFE2E8F0)),
        ),
      ),
      child: SafeArea(
        left: false,
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          children: [
            for (var i = 0; i < items.length; i++)
              _SidebarTile(
                item: items[i],
                selected: selectedIndex == i,
                onTap: () => onSelect(i),
              ),
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 4),
              child: Divider(height: 1),
            ),
            _SidebarTile(
              item: _NavItem(
                Icons.person_outline,
                'owner_dashboard.my_profile'.tr(),
              ),
              selected: selectedIndex == 5,
              onTap: () => onSelect(5),
            ),
            if (showAdminItems) ...[
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 16, 12, 8),
                child: Divider(height: 1),
              ),
              for (var i = 0; i < adminItems.length; i++)
                _SidebarTile(
                  item: adminItems[i],
                  selected: false,
                  onTap: () => onAdminTap(_adminRoutes[i]),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  const _NavItem(this.icon, this.label);
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool selected;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: selected
            ? AppColors.primary.withValues(alpha: 0.12)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                Icon(
                  item.icon,
                  size: 20,
                  color: selected ? AppColors.primary : AppColors.textMuted,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          selected ? FontWeight.w700 : FontWeight.w500,
                      color: selected
                          ? AppColors.primary
                          : const Color(0xFF334155),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
