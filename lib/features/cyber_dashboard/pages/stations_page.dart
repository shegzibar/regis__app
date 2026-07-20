import 'dart:async';
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
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
    final roomsAsync = ref.watch(cyberRoomsProvider);
    final isAr = context.locale.languageCode == 'ar';

    return SingleChildScrollView(
      padding: const EdgeInsets.all(kPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Page Title
          Text(
            'cyber.station_status'.tr(),
            style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kSidebarText),
          ),
          Text(
            'cyber.realtime_monitoring_of_all'.tr(),
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
                    child: Text('cyber.no_rooms_added'.tr()));
              }
              return Wrap(
                spacing: 24,
                runSpacing: 24,
                children: rooms.map((room) => SizedBox(
                  width: 360,
                  child: _RoomSection(room: room, isAr: isAr),
                )).toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _RoomSection extends ConsumerStatefulWidget {
  final Room room;
  final bool isAr;

  const _RoomSection({required this.room, required this.isAr});

  @override
  ConsumerState<_RoomSection> createState() => _RoomSectionState();
}

class _RoomSectionState extends ConsumerState<_RoomSection> {
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    // Auto-refresh the station status every 30 seconds to catch booking starts/ends
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) {
        ref.invalidate(stationStatusProvider(widget.room.id));
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    final isAr = widget.isAr;
    final stationsAsync = ref.watch(stationStatusProvider(room.id));

    return Container(
      decoration: BoxDecoration(
        color: kWhite,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
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
              loading: () => const Center(child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              )),
              error: (e, _) => Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text('Error: $e', style: const TextStyle(color: kRed)),
              ),
              data: (stations) {
                if (stations.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('cyber.no_stations'.tr()),
                  );
                }
                return Column(
                  children: stations.map((s) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: SizedBox(
                        width: double.infinity,
                        height: 240, // Increased height to prevent overflow when busy
                        child: _StationCard(s: s, isAr: isAr, ref: ref),
                      ),
                    );
                  }).toList(),
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
            content: Text('cyber.toggle_maintenance_status'.tr()),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text('cyber.cancel'.tr())),
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
                child: Text('cyber.confirm'.tr(),
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
            Icon(icon, color: iconColor, size: 36),
            const SizedBox(height: 12),
            Text(
              s.name,
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: s.isBusy ? kPurple : kSidebarText),
            ),
            const SizedBox(height: 4),
            Text(
              s.statusLabel(arabic: isAr),
              style: TextStyle(fontSize: 13, color: iconColor),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
              if (s.isBusy && s.busyUntil != null) ...[
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
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
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isOvertime
                            ? ('cyber.over'.tr())
                            : _formatDuration(_remaining),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16, // Larger clock text
                          fontWeight: FontWeight.bold,
                          fontFeatures: [FontFeature.tabularFigures()],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Stop Button
                    GestureDetector(
                      onTap: () async {
                        if (s.currentBookingId == null) return;
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator()),
                        );
                        try {
                          final preview = await ref.read(ownerRepositoryProvider).previewStopBookingEarly(s.currentBookingId!);
                          if (!context.mounted) return;
                          Navigator.pop(context); // close loading

                          final double newTotal = preview['newTotalAmount'];
                          final int minutesStayed = preview['minutesStayed'];
                          final int h = minutesStayed ~/ 60;
                          final int m = minutesStayed % 60;
                          final timeStr = h > 0 ? '$h hr $m min' : '$m min';
                          final timeStrAr = h > 0 ? '$h ساعة و $m دقيقة' : '$m دقيقة';

                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Row(
                                children: [
                                  const Icon(Icons.warning_amber_rounded, color: Colors.orange),
                                  const SizedBox(width: 8),
                                  Text(isAr ? 'تأكيد إيقاف الجلسة' : 'Confirm Stop Session', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                ],
                              ),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('${isAr ? 'الوقت المنقضي' : 'Time spent'}: ${isAr ? timeStrAr : timeStr}', style: const TextStyle(fontSize: 16)),
                                  const SizedBox(height: 12),
                                  Text('${isAr ? 'التكلفة المحسوبة' : 'Calculated Cost'}: ${newTotal.toStringAsFixed(2)} EGP', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: kGreen)),
                                  const SizedBox(height: 16),
                                  Text(isAr ? 'هل أنت متأكد أنك تريد إيقاف هذه الجلسة الآن؟' : 'Are you sure you want to stop this session now?', style: const TextStyle(fontSize: 14, color: kGray)),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: Text(isAr ? 'إلغاء' : 'Cancel', style: const TextStyle(color: kGray)),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: kRed),
                                  onPressed: () async {
                                    Navigator.pop(ctx);
                                    showDialog(
                                      context: context,
                                      barrierDismissible: false,
                                      builder: (_) => const Center(child: CircularProgressIndicator()),
                                    );
                                    try {
                                      await ref.read(ownerRepositoryProvider).stopBookingEarly(s.currentBookingId!);
                                      if (context.mounted) {
                                        Navigator.pop(context); // close loading
                                        ref.invalidate(stationStatusProvider(s.roomId));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(isAr ? 'تم إيقاف الجلسة بنجاح' : 'Session stopped successfully')),
                                        );
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        Navigator.pop(context); // close loading
                                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                                      }
                                    }
                                  },
                                  child: Text(isAr ? 'تأكيد الإيقاف' : 'Confirm Stop', style: const TextStyle(color: Colors.white)),
                                ),
                              ],
                            ),
                          );
                        } catch (e) {
                          if (context.mounted) {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: kRed, borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.stop, color: Colors.white, size: 22),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Add Item Button
                    GestureDetector(
                      onTap: () async {
                        if (s.currentBookingId == null) return;
                        showDialog(
                          context: context,
                          barrierDismissible: false,
                          builder: (_) => const Center(child: CircularProgressIndicator()),
                        );
                        try {
                          final booking = await ref.read(ownerRepositoryProvider).getBookingById(s.currentBookingId!);
                          if (context.mounted) {
                            Navigator.pop(context); // close loading
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
                            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                          }
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: kTeal, borderRadius: BorderRadius.circular(6)),
                        child: const Icon(Icons.add_shopping_cart, color: Colors.white, size: 22),
                      ),
                    ),
                  ],
                ),
              ],
            ],
        ),
      ),
    );
  }
}

