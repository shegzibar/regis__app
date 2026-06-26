import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../models/room_option_def.dart';

class OnboardingStep2Rooms extends StatelessWidget {
  final Map<String, bool> selected;
  final Map<String, int> stationCounts;
  final void Function(String id, bool value) onToggle;
  final void Function(String id, int count) onCountChanged;

  const OnboardingStep2Rooms({
    super.key,
    required this.selected,
    required this.stationCounts,
    required this.onToggle,
    required this.onCountChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        Text(
          'owner_onboarding.rooms_hint'.tr(),
          style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.15,
          children: roomOptions.map((opt) {
            final isOn = selected[opt.id] == true;
            return _RoomCard(
              option: opt,
              selected: isOn,
              count: stationCounts[opt.id] ?? 1,
              onTap: () => onToggle(opt.id, !isOn),
              onCountChanged: (c) => onCountChanged(opt.id, c),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _RoomCard extends StatelessWidget {
  final RoomOptionDef option;
  final bool selected;
  final int count;
  final VoidCallback onTap;
  final ValueChanged<int> onCountChanged;

  const _RoomCard({
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
                  Icon(option.icon,
                      color: selected ? AppColors.purple : AppColors.textMuted),
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
                  children: [
                    InkWell(
                      onTap:
                          count > 1 ? () => onCountChanged(count - 1) : null,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: count > 1
                              ? Colors.white
                              : Colors.white.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.remove, size: 14),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '$count',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.purple,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => onCountChanged(count + 1),
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Icon(Icons.add, size: 14),
                      ),
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
