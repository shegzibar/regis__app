import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/owner_dashboard_provider.dart';
import '../../../data/models/cyber_room_profile.dart';
import 'name_dialog.dart';

class RoomProfileTile extends ConsumerWidget {
  final CyberRoomProfile profile;
  final VoidCallback onRefresh;

  const RoomProfileTile({
    super.key,
    required this.profile,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final room = profile.room;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      room.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      '${room.type.toUpperCase()} • ${room.pricePerHour.round()} ${'common.egp'.tr()}/${'common.per_hour'.tr()}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${profile.stations.length} ${'owner_cyber_profile.stations'.tr()}',
                style:
                    const TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                onPressed: () async {
                  final ok = await showDialog<bool>(
                    context: context,
                    builder: (_) => AlertDialog(
                      title: Text('owner_cyber_profile.delete_room'.tr()),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
                          child: Text('common.cancel'.tr()),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context, true),
                          child: Text('common.delete'.tr()),
                        ),
                      ],
                    ),
                  );
                  if (ok == true) {
                    await ref
                        .read(ownerRepositoryProvider)
                        .deleteRoomCascade(room.id);
                    onRefresh();
                  }
                },
              ),
            ],
          ),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              ...profile.stations.map(
                (s) => Chip(
                  label: Text(s.name),
                  deleteIcon: const Icon(Icons.close, size: 16),
                  onDeleted: () async {
                    await ref.read(ownerRepositoryProvider).deleteStation(s.id);
                    onRefresh();
                  },
                ),
              ),
              ActionChip(
                avatar: const Icon(Icons.add, size: 16),
                label: Text('owner_cyber_profile.add_station'.tr()),
                onPressed: () async {
                  final name = await showDialog<String>(
                    context: context,
                    builder: (_) => NameDialog(
                      title: 'owner_cyber_profile.add_station'.tr(),
                    ),
                  );
                  if (name != null && name.isNotEmpty) {
                    await ref.read(ownerRepositoryProvider).addStation(
                          roomId: room.id,
                          name: name,
                        );
                    onRefresh();
                  }
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
