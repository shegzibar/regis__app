import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../constants/cd_colors.dart';
import '../providers/cd_providers.dart';
import '../models/station_live.dart';
import '../../../data/models/room.dart';

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
                    childAspectRatio: 1.5,
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

class _StationCard extends StatelessWidget {
  final StationLive s;
  final bool isAr;
  final WidgetRef ref;

  const _StationCard({required this.s, required this.isAr, required this.ref});

  @override
  Widget build(BuildContext context) {
    Color bgColor = kBg;
    Color borderColor = kBorder;
    IconData icon = Icons.computer;
    Color iconColor = kGray;

    if (s.isMaintenance) {
      bgColor = const Color(0xFFFDECEE);
      borderColor = kRed.withValues(alpha: 0.5);
      iconColor = kRed;
      icon = Icons.build;
    } else if (s.isBusy) {
      bgColor = kPurpleLight;
      borderColor = kPurple;
      iconColor = kPurple;
      icon = Icons.person;
    } else if (s.isActive) {
      bgColor = const Color(0xFFE8F5E8);
      borderColor = kGreen.withValues(alpha: 0.5);
      iconColor = kGreen;
    }

    return GestureDetector(
      onLongPress: () {
        // Toggle maintenance
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(kRadiusSm),
          border: Border.all(color: borderColor, width: 0.5),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 24),
            const SizedBox(height: 8),
            Text(
              s.name,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: s.isBusy ? kPurple : kSidebarText),
            ),
            const SizedBox(height: 2),
            Text(
              s.statusLabel(arabic: isAr),
              style: TextStyle(fontSize: 10, color: iconColor),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
