import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/auth_provider.dart';
import '../constants/cd_colors.dart';
import '../providers/cd_providers.dart';

class CdTopBar extends ConsumerWidget {
  const CdTopBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isAr = context.locale.languageCode == 'ar';
    final cyberAsync = ref.watch(currentCyberProvider);
    final user = ref.watch(authStateProvider);

    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: kTopBarBg,
        border: Border(
          bottom: BorderSide(color: kBorder, width: 0.5),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          // Logo + Cyber name
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: kPurple,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.sports_esports,
                    color: Colors.white, size: 18),
              ),
              const SizedBox(width: 10),
              cyberAsync.when(
                data: (cyber) => Text(
                  cyber?.name ?? 'Forya Cyber',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: kSidebarText,
                  ),
                ),
                loading: () => const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                error: (_, __) => const Text('Forya Cyber'),
              ),
            ],
          ),

          const Spacer(),

          // Live Clock
          const _LiveClock(),
          
          const SizedBox(width: 16),

          // Language toggle
          GestureDetector(
            onTap: () {
              context.setLocale(Locale(isAr ? 'en' : 'ar'));
            },
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(color: kBorder),
                borderRadius: BorderRadius.circular(kRadiusSm),
              ),
              child: Row(
                children: [
                  const Text('🌐', style: TextStyle(fontSize: 14)),
                  const SizedBox(width: 6),
                  Text(
                    isAr ? 'English' : 'العربية',
                    style: const TextStyle(
                        fontSize: 12,
                        color: kSidebarText,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(width: 12),

          // User menu
          PopupMenuButton<String>(
            offset: const Offset(0, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(kRadius),
              side: BorderSide(color: kBorder),
            ),
            itemBuilder: (_) => [
              PopupMenuItem(
                enabled: false,
                child: Text(
                  user?.name ?? user?.email ?? 'Owner',
                  style: const TextStyle(
                      color: kGray,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
              ),
              const PopupMenuDivider(),
              PopupMenuItem(
                value: 'logout',
                child: Row(
                  children: [
                    const Icon(Icons.logout, size: 16, color: kRed),
                    const SizedBox(width: 8),
                    Text(
                      'common.logout'.tr(),
                      style: const TextStyle(color: kRed, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
            onSelected: (val) {
              if (val == 'logout') {
                ref.read(authControllerProvider.notifier).signOut();
              }
            },
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: kPurpleLight,
                  child: Text(
                    (user?.name?.isNotEmpty == true
                            ? user!.name![0]
                            : user?.email?.substring(0, 1) ?? 'O')
                        .toUpperCase(),
                    style: const TextStyle(
                        color: kPurple,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.keyboard_arrow_down,
                    size: 18, color: kGray),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveClock extends StatefulWidget {
  const _LiveClock();

  @override
  State<_LiveClock> createState() => _LiveClockState();
}

class _LiveClockState extends State<_LiveClock> {
  late Timer _timer;
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) {
        setState(() {
          _now = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final h = _now.hour > 12 ? _now.hour - 12 : (_now.hour == 0 ? 12 : _now.hour);
    final m = _now.minute.toString().padLeft(2, '0');
    final p = _now.hour >= 12 ? 'PM' : 'AM';
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: kPurple.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: kPurple.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.schedule, size: 14, color: kPurple),
          const SizedBox(width: 6),
          Text(
            '$h:$m $p',
            style: const TextStyle(
              color: kSidebarText,
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
