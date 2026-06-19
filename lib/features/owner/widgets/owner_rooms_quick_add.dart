import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/cyber_profile_provider.dart';
import '../../../core/providers/owner_dashboard_provider.dart';
import '../../cyber_dashboard/providers/cd_providers.dart';
import 'owner_room_options.dart';

/// Grid picker to add PS5 / PS4 / PC / VIP rooms with station counts (like onboarding).
class OwnerRoomsQuickAddPanel extends ConsumerStatefulWidget {
  final String cyberId;
  final VoidCallback? onAdded;

  const OwnerRoomsQuickAddPanel({
    super.key,
    required this.cyberId,
    this.onAdded,
  });

  @override
  ConsumerState<OwnerRoomsQuickAddPanel> createState() =>
      _OwnerRoomsQuickAddPanelState();
}

class _OwnerRoomsQuickAddPanelState
    extends ConsumerState<OwnerRoomsQuickAddPanel> {
  final Map<String, bool> _selected = {};
  final Map<String, int> _stationCounts = {};
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    for (final o in kOwnerRoomOptions) {
      _selected[o.id] = false;
      _stationCounts[o.id] = 2;
    }
  }

  Future<void> _addSelected() async {
    final toAdd =
        kOwnerRoomOptions.where((o) => _selected[o.id] == true).toList();
    if (toAdd.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('owner_onboarding.select_room'.tr())),
      );
      return;
    }

    setState(() => _adding = true);
    try {
      final repo = ref.read(ownerRepositoryProvider);
      for (final opt in toAdd) {
        await repo.addRoomWithStations(
          cyberId: widget.cyberId,
          name: opt.labelKey.tr(),
          type: opt.dbType,
          pricePerHour: opt.defaultPrice,
          stationCount: _stationCounts[opt.id] ?? 2,
        );
      }
      ref.invalidate(cyberProfileRoomsProvider(widget.cyberId));
      ref.invalidate(ownerCybersProvider);
      ref.invalidate(cyberRoomsProvider);
      widget.onAdded?.call();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('owner_profile.rooms_added'.tr()),
            backgroundColor: AppColors.teal,
          ),
        );
        setState(() {
          for (final o in kOwnerRoomOptions) {
            _selected[o.id] = false;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'owner_onboarding.rooms_hint'.tr(),
          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
        ),
        const SizedBox(height: 10),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.15,
          children: kOwnerRoomOptions.map((opt) {
            final isOn = _selected[opt.id] == true;
            return _RoomTypeCard(
              option: opt,
              selected: isOn,
              count: _stationCounts[opt.id] ?? 2,
              onTap: () => setState(() => _selected[opt.id] = !isOn),
              onCountChanged: (c) => setState(() => _stationCounts[opt.id] = c),
            );
          }).toList(),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _adding ? null : _addSelected,
            icon: _adding
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.add, size: 18),
            label: Text('owner_profile.add_selected_rooms'.tr()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.teal,
              foregroundColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }
}

class _RoomTypeCard extends StatelessWidget {
  final OwnerRoomOption option;
  final bool selected;
  final int count;
  final VoidCallback onTap;
  final ValueChanged<int> onCountChanged;

  const _RoomTypeCard({
    required this.option,
    required this.selected,
    required this.count,
    required this.onTap,
    required this.onCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.purpleLight : Colors.white,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? AppColors.purple : const Color(0xFFE2E8F0),
              width: selected ? 2 : 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    option.icon,
                    color: selected ? AppColors.purple : AppColors.textMuted,
                  ),
                  const Spacer(),
                  Icon(
                    selected ? Icons.check_circle : Icons.circle_outlined,
                    color: selected ? AppColors.purple : AppColors.textMuted,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                option.labelKey.tr(),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: selected ? AppColors.purple : AppColors.textPrimary,
                ),
              ),
              if (selected) ...[
                const Spacer(),
                Text(
                  'owner_onboarding.station_count'.tr(),
                  style:
                      const TextStyle(fontSize: 10, color: AppColors.textMuted),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _CountBtn(
                      icon: Icons.remove,
                      onTap: count > 1 ? () => onCountChanged(count - 1) : null,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        '$count',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    _CountBtn(
                      icon: Icons.add,
                      onTap: () => onCountChanged(count + 1),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CountBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;

  const _CountBtn({required this.icon, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFE2E8F0),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: SizedBox(
          width: 28,
          height: 28,
          child: Icon(icon,
              size: 16, color: onTap != null ? null : AppColors.textMuted),
        ),
      ),
    );
  }
}
