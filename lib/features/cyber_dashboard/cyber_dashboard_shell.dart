import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'constants/cd_colors.dart';
import 'providers/cd_providers.dart';
import 'pages/home_page.dart';
import 'pages/manual_booking_page.dart';
import 'pages/payments_page.dart';
import 'pages/schedule_page.dart';
import 'pages/stations_page.dart';
import 'pages/cyber_profile_page.dart';
import 'pages/workers_page.dart';
import 'pages/wallet_points_page.dart';
import 'widgets/cd_top_bar.dart';
import 'widgets/cd_sidebar.dart';

class CyberDashboardShell extends ConsumerStatefulWidget {
  const CyberDashboardShell({super.key});

  @override
  ConsumerState<CyberDashboardShell> createState() =>
      _CyberDashboardShellState();
}

class _CyberDashboardShellState
    extends ConsumerState<CyberDashboardShell> {
  RealtimeChannel? _bookingsChannel;
  RealtimeChannel? _paymentsChannel;
  Timer? _endCheckTimer;
  final _notifiedEndIds = <String>{};
  final _db = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _setupRealtime();
      _startBookingEndChecker();
    });
  }

  void _setupRealtime() {
    _bookingsChannel = _db
        .channel('cd-shell-bookings')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          callback: (_) {
            ref.invalidate(todayBookingsProvider);
            ref.invalidate(todayRevenueProvider);
            ref.invalidate(stationStatusProvider);
          },
        )
        .subscribe();

    _paymentsChannel = _db
        .channel('cd-shell-payments')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'payments',
          callback: (_) {
            ref.invalidate(pendingPaymentsProvider);
          },
        )
        .subscribe();
  }

  /// Checks every 60 seconds for bookings whose end time has passed.
  /// Shows a SnackBar notification to alert the cyber owner.
  void _startBookingEndChecker() {
    _endCheckTimer = Timer.periodic(const Duration(seconds: 60), (_) {
      _checkForEndedBookings();
    });
  }

  void _checkForEndedBookings() {
    final bookings = ref.read(todayBookingsProvider).valueOrNull;
    if (bookings == null || bookings.isEmpty) return;

    final now = DateTime.now();
    final lang = ref.read(cdLangProvider);
    final isAr = lang == 'ar';

    for (final b in bookings) {
      // Only notify for confirmed or ongoing bookings that just ended
      if (_notifiedEndIds.contains(b.id)) continue;
      if (b.isCancelled || b.isRejected || b.isCompleted) continue;

      final localEnd = b.endTime.toLocal();
      if (localEnd.isBefore(now)) {
        _notifiedEndIds.add(b.id);
        final name = b.userName ?? (isAr ? 'عميل' : 'Customer');
        final station = b.stationName ?? (isAr ? 'محطة' : 'Station');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.timer_off, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      isAr
                          ? '⏰ انتهى حجز $name على $station'
                          : '⏰ Session ended: $name on $station',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
              backgroundColor: kPurple,
              duration: const Duration(seconds: 8),
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      }
    }
  }

  @override
  void dispose() {
    _endCheckTimer?.cancel();
    if (_bookingsChannel != null) _db.removeChannel(_bookingsChannel!);
    if (_paymentsChannel != null) _db.removeChannel(_paymentsChannel!);
    super.dispose();
  }

  Widget _currentPage(String page) {
    return switch (page) {
      'home' => const HomePage(),
      'manual' => const ManualBookingPage(),
      'payments' => const PaymentsPage(),
      'schedule' => const SchedulePage(),
      'stations' => const StationsPage(),
      'profile' => const CyberProfilePage(),
      'workers' => const WorkersPage(),
      'wallet_points' => const WalletPointsPage(),
      _ => const HomePage(),
    };
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(cdLangProvider);
    final page = ref.watch(cdSelectedPageProvider);
    final isAr = lang == 'ar';

    return Directionality(
      textDirection: isAr ? TextDirection.rtl : TextDirection.ltr,
      child: Scaffold(
        backgroundColor: kBg,
        body: Column(
          children: [
            const CdTopBar(),
            Expanded(
              child: Row(
                children: [
                  const CdSidebar(),
                  Expanded(
                    child: ClipRect(
                      child: _currentPage(page),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
