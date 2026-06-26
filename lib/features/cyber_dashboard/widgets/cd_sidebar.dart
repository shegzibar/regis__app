import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/cd_colors.dart';
import '../providers/cd_providers.dart';

class _NavItem {
  final String key;
  final IconData icon;
  final String labelAr;
  final String labelEn;

  const _NavItem({
    required this.key,
    required this.icon,
    required this.labelAr,
    required this.labelEn,
  });
}

const _navItems = [
  _NavItem(
    key: 'home',
    icon: Icons.dashboard_outlined,
    labelAr: 'الرئيسية',
    labelEn: 'Home',
  ),


  _NavItem(
    key: 'schedule',
    icon: Icons.calendar_month_outlined,
    labelAr: 'الجدول',
    labelEn: 'Schedule',
  ),
  _NavItem(
    key: 'inventory',
    icon: Icons.inventory_2_outlined,
    labelAr: 'المخزون والمنتجات',
    labelEn: 'Inventory & Snacks',
  ),
  _NavItem(
    key: 'stations',
    icon: Icons.computer_outlined,
    labelAr: 'المحطات',
    labelEn: 'Stations',
  ),
  _NavItem(
    key: 'profile',
    icon: Icons.store_outlined,
    labelAr: 'ملف الكافيه',
    labelEn: 'Cyber Profile',
  ),
  _NavItem(
    key: 'workers',
    icon: Icons.people_outline,
    labelAr: 'الموظفون',
    labelEn: 'Workers',
  ),
  _NavItem(
    key: 'wallet_points',
    icon: Icons.stars,
    labelAr: 'نقاط المحفظة',
    labelEn: 'Wallet Points',
  ),
];

class CdSidebar extends ConsumerWidget {
  const CdSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(cdLangProvider);
    final currentPage = ref.watch(cdSelectedPageProvider);
    final isAr = lang == 'ar';

    return Container(
      width: 200,
      decoration: BoxDecoration(
        color: kSidebarBg,
        border: Border(
          right: isAr
              ? BorderSide.none
              : BorderSide(color: kBorder, width: 0.5),
          left: isAr
              ? BorderSide(color: kBorder, width: 0.5)
              : BorderSide.none,
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Expanded(
            child: ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              itemCount: _navItems.length,
              itemBuilder: (_, i) {
                final item = _navItems[i];
                final isSelected = currentPage == item.key;
                final hasBadge = false;

                return _SidebarTile(
                  item: item,
                  isSelected: isSelected,
                  isAr: isAr,
                  badge: null,
                  onTap: () {
                    ref
                        .read(cdSelectedPageProvider.notifier)
                        .state = item.key;
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SidebarTile extends StatelessWidget {
  final _NavItem item;
  final bool isSelected;
  final bool isAr;
  final int? badge;
  final VoidCallback onTap;

  const _SidebarTile({
    required this.item,
    required this.isSelected,
    required this.isAr,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.only(bottom: 2),
        padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? kSidebarSelected : Colors.transparent,
          borderRadius: BorderRadius.circular(kRadiusSm),
        ),
        child: Row(
          children: [
            Icon(
              item.icon,
              size: 18,
              color: isSelected ? kPurple : kGray,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                isAr ? item.labelAr : item.labelEn,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.normal,
                  color: isSelected ? kPurple : kSidebarText,
                ),
              ),
            ),
            if (badge != null)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: kRed,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
