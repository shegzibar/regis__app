import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../core/providers/owner_dashboard_provider.dart';
import '../../../data/models/room.dart';
import '../../../data/models/station.dart';

class OwnerManualBookingScreen extends ConsumerStatefulWidget {
  const OwnerManualBookingScreen({super.key});

  @override
  ConsumerState<OwnerManualBookingScreen> createState() =>
      _OwnerManualBookingScreenState();
}

class _OwnerManualBookingScreenState
    extends ConsumerState<OwnerManualBookingScreen> {
  int _step = 0;
  Room? _room;
  Station? _station;
  int _hours = 2;
  bool _saving = false;
  final TextEditingController _guestNameController = TextEditingController();

  @override
  void dispose() {
    _guestNameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final user = ref.read(authStateProvider);
    if (user == null || _station == null || _room == null) return;

    setState(() => _saving = true);
    try {
      final repo = ref.read(ownerRepositoryProvider);
      final total = _room!.pricePerHour * _hours;
      await repo.createManualBooking(
        ownerUserId: user.id,
        stationId: _station!.id,
        startTime: DateTime.now(),
        durationHours: _hours.toDouble(),
        totalAmount: total,
        guestName: _guestNameController.text.trim(),
      );
      ref.invalidate(ownerDashboardStatsProvider);
      ref.invalidate(ownerTimelineStreamProvider);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('owner_dashboard.start_session'.tr()),
            backgroundColor: AppColors.green,
          ),
        );
        context.go('/owner/home');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString())),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final roomsAsync = ref.watch(ownerRoomsProvider);

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'owner_dashboard.manual_booking'.tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(3, (i) {
              return Expanded(
                child: Container(
                  height: 4,
                  margin: EdgeInsetsDirectional.only(end: i < 2 ? 6 : 0),
                  decoration: BoxDecoration(
                    color: i <= _step ? AppColors.primary : const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: _step == 0
                  ? roomsAsync.when(
                      loading: () => const Center(
                          child: CircularProgressIndicator(color: AppColors.primary)),
                      error: (e, _) => Center(child: Text('$e')),
                      data: (rooms) {
                        if (rooms.isEmpty) {
                          return Center(
                              child: Text('errors.no_data_available'.tr()));
                        }
                        return ListView.separated(
                          itemCount: rooms.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 6),
                          itemBuilder: (_, i) {
                            final room = rooms[i] as Room;
                            return ListTile(
                              dense: true,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: const BorderSide(color: Color(0xFFE2E8F0)),
                              ),
                              title: Text(room.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                  '${room.type.toUpperCase()} • ${room.pricePerHour} ${'common.egp'.tr()}/${'common.per_hour'.tr()}'),
                              onTap: () async {
                                setState(() {
                                  _room = room;
                                  _station = null;
                                  _step = 1;
                                });
                              },
                            );
                          },
                        );
                      },
                    )
                  : _step == 1
                      ? _StationStep(
                          roomId: _room!.id,
                          onSelected: (s) => setState(() {
                            _station = s;
                            _step = 2;
                          }),
                        )
                      : _DurationStep(
                          hours: _hours,
                          pricePerHour: _room!.pricePerHour,
                          onChanged: (h) => setState(() => _hours = h),
                          onConfirm: _saving ? null : _submit,
                          saving: _saving,
                          nameController: _guestNameController,
                        ),
            ),
          ),
          if (_step > 0)
            TextButton(
              onPressed: () => setState(() => _step--),
              child: Text('common.back'.tr()),
            ),
        ],
      ),
    );
  }
}

class _StationStep extends ConsumerWidget {
  final String roomId;
  final ValueChanged<Station> onSelected;

  const _StationStep({required this.roomId, required this.onSelected});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List<Station>>(
      future: ref.read(ownerRepositoryProvider).getRoomStationsAll(roomId),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(
              child: CircularProgressIndicator(color: AppColors.primary));
        }
        final stations = snap.data!
            .where((s) => s.status == 'active')
            .toList();
        if (stations.isEmpty) {
          return Center(child: Text('errors.no_data_available'.tr()));
        }
        return ListView.separated(
          itemCount: stations.length,
          separatorBuilder: (_, __) => const SizedBox(height: 6),
          itemBuilder: (_, i) => ListTile(
            dense: true,
            title: Text(stations[i].name),
            trailing: const Icon(Icons.check_circle_outline),
            onTap: () => onSelected(stations[i]),
          ),
        );
      },
    );
  }
}

class _DurationStep extends StatelessWidget {
  final int hours;
  final double pricePerHour;
  final ValueChanged<int> onChanged;
  final VoidCallback? onConfirm;
  final bool saving;
  final TextEditingController nameController;

  const _DurationStep({
    required this.hours,
    required this.pricePerHour,
    required this.onChanged,
    required this.onConfirm,
    required this.saving,
    required this.nameController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('owner_dashboard.select_duration'.tr(),
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [1, 2, 3, 4].map((h) {
            final selected = hours == h;
            return ChoiceChip(
              label: Text('$h ${'common.per_hour'.tr()}'),
              selected: selected,
              onSelected: (_) => onChanged(h),
              selectedColor: AppColors.primary.withValues(alpha: 0.2),
            );
          }).toList(),
        ),
        const SizedBox(height: 24),
        Text('Guest Name (Optional)',
            style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextField(
          controller: nameController,
          decoration: InputDecoration(
            hintText: 'Enter walk-in guest name',
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        ),
        const Spacer(),
        Text(
          '${(pricePerHour * hours).round()} ${'common.egp'.tr()}',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: saving
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text('owner_dashboard.start_session'.tr()),
          ),
        ),
      ],
    );
  }
}
