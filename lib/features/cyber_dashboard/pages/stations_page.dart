import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/cd_colors.dart';
import '../providers/cd_providers.dart';
import '../models/station_live.dart';
import '../../../data/models/room.dart';
import '../../../core/providers/owner_dashboard_provider.dart';
import '../widgets/session_details_sheet.dart';

class StationsPage extends ConsumerWidget {
  const StationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lang = ref.watch(cdLangProvider);
    final isAr = lang == 'ar';
    final roomsAsync = ref.watch(cyberRoomsProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(kPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Title
          Text(
            isAr ? 'حالة المحطات' : 'Station Status',
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kSidebarText),
          ),
          Text(
            isAr
                ? 'مراقبة حالة الأجهزة في الوقت الفعلي'
                : 'Real-time monitoring of all stations',
            style: const TextStyle(fontSize: 12, color: kGray),
          ),
          const SizedBox(height: 20),

          roomsAsync.when(
            loading: () => const Center(
                child: Padding(
              padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(),
            )),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (rooms) {
              if (rooms.isEmpty) {
                return Center(
                    child: Text(isAr ? 'لا توجد غرف' : 'No rooms added'));
              }
              return Column(
                children: rooms.map((room) => _RoomSection(room: room, isAr: isAr)).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RoomSection extends ConsumerWidget {
  final Room room;
  final bool isAr;

  const _RoomSection({required this.room, required this.isAr});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationsAsync = ref.watch(stationStatusProvider(room.id));

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: kBorder, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(room.typeIcon, style: const TextStyle(fontSize: 20)),
                    const SizedBox(width: 8),
                    Text(
                      room.name,
                      style: const TextStyle(
                          fontSize: 15, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                Text(
                  '${room.pricePerHour.toInt()} EGP/hr',
                  style: const TextStyle(fontSize: 12, color: kGray),
                ),
              ],
            ),
          ),

          // Grid
          Padding(
            padding: const EdgeInsets.all(16),
            child: stationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Text('Error: $e', style: const TextStyle(color: kRed)),
              data: (stations) {
                if (stations.isEmpty) {
                  return Text(isAr ? 'لا توجد أجهزة' : 'No stations');
                }
                return GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.1,
                  ),
                  itemCount: stations.length,
                  itemBuilder: (context, i) {
                    final s = stations[i];
                    return _StationCard(s: s, isAr: isAr, ref: ref);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StationCard extends StatefulWidget {
  final StationLive s;
  final bool isAr;
  final WidgetRef ref;

  const _StationCard({required this.s, required this.isAr, required this.ref});

  @override
  State<_StationCard> createState() => _StationCardState();
}

class _StationCardState extends State<_StationCard> {
  Timer? _timer;
  Duration _remaining = Duration.zero;

  StationLive get s => widget.s;
  bool get isAr => widget.isAr;
  WidgetRef get ref => widget.ref;

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void didUpdateWidget(covariant _StationCard old) {
    super.didUpdateWidget(old);
    if (old.s.busyUntil != widget.s.busyUntil ||
        old.s.isBusy != widget.s.isBusy) {
      _timer?.cancel();
      _startCountdown();
    }
  }

  void _startCountdown() {
    if (!s.isBusy || s.busyUntil == null) {
      _remaining = Duration.zero;
      return;
    }
    _updateRemaining();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      _updateRemaining();
    });
  }

  void _updateRemaining() {
    final now = DateTime.now();
    final end = s.busyUntil!.toLocal();
    final diff = end.difference(now);
    setState(() {
      _remaining = diff.isNegative ? Duration.zero : diff;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final sec = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    if (h > 0) return '$h:$m:$sec';
    return '$m:$sec';
  }

  @override
  Widget build(BuildContext context) {
    Color bgColor = kBg;
    Color borderColor = kBorder;
    IconData icon = Icons.computer;
    Color iconColor = kGray;

    final bool isOvertime = s.isBusy && s.busyUntil != null && _remaining == Duration.zero;

    if (s.isMaintenance) {
      bgColor = const Color(0xFFFDECEE);
      borderColor = kRed.withValues(alpha: 0.5);
      iconColor = kRed;
      icon = Icons.build;
    } else if (s.isBusy) {
      if (isOvertime) {
        bgColor = const Color(0xFFFFF3E0);
        borderColor = const Color(0xFFFF9800);
        iconColor = const Color(0xFFFF9800);
        icon = Icons.timer_off;
      } else {
        bgColor = kPurpleLight;
        borderColor = kPurple;
        iconColor = kPurple;
        icon = Icons.person;
      }
    } else if (s.isActive) {
      bgColor = const Color(0xFFE8F5E8);
      borderColor = kGreen.withValues(alpha: 0.5);
      iconColor = kGreen;
    }

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () async {
        if (s.isBusy && s.currentBookingId != null) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(child: CircularProgressIndicator()),
          );
          try {
            final booking = await ref.read(ownerRepositoryProvider).getBookingById(s.currentBookingId!);
            if (context.mounted) {
              Navigator.pop(context);
              showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (ctx) => SessionDetailsSheet(
                  booking: booking,
                  isAr: isAr,
                  onAdded: () => ref.invalidate(stationStatusProvider(s.roomId)),
                ),
              );
            }
          } catch (e) {
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error loading session')));
            }
          }
        }
      },
      onLongPress: () {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(s.name),
            content: Text(isAr
                ? 'هل تريد تغيير حالة الصيانة؟'
                : 'Toggle maintenance status?'),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text(isAr ? 'إلغاء' : 'Cancel')),
              TextButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final newStatus =
                      s.isMaintenance ? 'active' : 'maintenance';
                  await ref
                      .read(cdCyberRepoProvider)
                      .updateStationStatus(s.id, newStatus);
                  ref.invalidate(stationStatusProvider(s.roomId));
                },
                child: Text(isAr ? 'تأكيد' : 'Confirm',
                    style: const TextStyle(color: kPurple)),
              ),
            ],
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(kRadiusSm),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 6),
            Text(
              s.name,
              style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: s.isBusy ? kPurple : kSidebarText),
            ),
            const SizedBox(height: 2),
            Text(
              s.statusLabel(arabic: isAr),
              style: TextStyle(fontSize: 9, color: iconColor),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            if (s.isBusy && s.busyUntil != null) ...[
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isOvertime
                      ? const Color(0xFFFF9800)
                      : kPurple,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isOvertime ? Icons.warning_amber : Icons.timer,
                      color: Colors.white,
                      size: 12,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isOvertime
                          ? (isAr ? 'انتهى!' : 'Over!')
                          : _formatDuration(_remaining),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        fontFeatures: [FontFeature.tabularFigures()],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

