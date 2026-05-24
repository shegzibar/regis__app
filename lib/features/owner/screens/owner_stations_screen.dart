import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/models/station.dart';
import '../../../data/repositories/station_repository.dart';
import '../../../data/supabase/supabase_client.dart';

// Fetch all stations across the owner's cybers with room info
final ownerStationsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];

  try {
    final response = await SupabaseService()
        .from('stations')
        .select('''
          *,
          rooms!inner(
            id, name, type,
            cybers!inner(id, name, owner_id)
          )
        ''')
        .eq('rooms.cybers.owner_id', user.id)
        .order('name');

    return List<Map<String, dynamic>>.from(response as List);
  } catch (_) {
    return [];
  }
});

class OwnerStationsScreen extends ConsumerWidget {
  const OwnerStationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stationsAsync = ref.watch(ownerStationsProvider);

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
              child: Row(
                children: [
                  const Text(
                    'Stations',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.refresh, color: AppColors.teal),
                    onPressed: () => ref.invalidate(ownerStationsProvider),
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                'Tap a station to toggle its status',
                style:
                    TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
            ),

            const SizedBox(height: 16),

            // Legend
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  _LegendDot(color: AppColors.statusConfirmed, label: 'Active'),
                  const SizedBox(width: 16),
                  _LegendDot(
                      color: AppColors.statusPending, label: 'Maintenance'),
                  const SizedBox(width: 16),
                  _LegendDot(
                      color: AppColors.statusRejected, label: 'Blocked'),
                ],
              ),
            ),

            const SizedBox(height: 20),
            const Divider(color: AppColors.lightGray, height: 1),

            // Grid
            Expanded(
              child: stationsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.teal)),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      const Text('Failed to load stations',
                          style: TextStyle(color: AppColors.textPrimary)),
                      const SizedBox(height: 8),
                      TextButton(
                          onPressed: () =>
                              ref.invalidate(ownerStationsProvider),
                          child: const Text('Retry',
                              style: TextStyle(color: AppColors.teal))),
                    ],
                  ),
                ),
                data: (rawStations) {
                  if (rawStations.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.computer_outlined,
                              color: AppColors.gray, size: 56),
                          const SizedBox(height: 16),
                          const Text('No stations found',
                              style: TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 6),
                          const Text(
                              'Add stations from the admin panel',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13)),
                        ],
                      ),
                    );
                  }

                  // Group by room type
                  final grouped = <String, List<Map<String, dynamic>>>{};
                  for (final raw in rawStations) {
                    final roomType =
                        (raw['rooms']?['type'] as String?) ?? 'unknown';
                    grouped.putIfAbsent(roomType, () => []).add(raw);
                  }

                  return RefreshIndicator(
                    onRefresh: () async =>
                        ref.invalidate(ownerStationsProvider),
                    child: ListView(
                      padding: const EdgeInsets.all(24),
                      children: grouped.entries.map((entry) {
                        return _StationGroup(
                          roomType: entry.key,
                          stations: entry.value
                              .map((raw) => Station.fromMap(raw))
                              .toList(),
                          rawData: entry.value,
                          onToggle: () =>
                              ref.invalidate(ownerStationsProvider),
                        );
                      }).toList(),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StationGroup extends StatelessWidget {
  final String roomType;
  final List<Station> stations;
  final List<Map<String, dynamic>> rawData;
  final VoidCallback onToggle;

  const _StationGroup({
    required this.roomType,
    required this.stations,
    required this.rawData,
    required this.onToggle,
  });

  String get _roomLabel {
    switch (roomType.toLowerCase()) {
      case 'ps5':
        return '🎮  PlayStation 5';
      case 'pc':
        return '💻  Gaming PC';
      case 'vip':
        return '⭐  VIP Room';
      default:
        return '🕹️  $roomType';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _roomLabel,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.0,
          ),
          itemCount: stations.length,
          itemBuilder: (context, i) {
            return _StationTile(
                station: stations[i], onToggle: onToggle);
          },
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}

class _StationTile extends StatefulWidget {
  final Station station;
  final VoidCallback onToggle;

  const _StationTile({required this.station, required this.onToggle});

  @override
  State<_StationTile> createState() => _StationTileState();
}

class _StationTileState extends State<_StationTile> {
  bool _loading = false;

  Color get _statusColor {
    switch (widget.station.status) {
      case 'active':
        return AppColors.statusConfirmed;
      case 'maintenance':
        return AppColors.statusPending;
      case 'blocked':
        return AppColors.statusRejected;
      default:
        return AppColors.gray;
    }
  }

  Future<void> _toggle() async {
    final nextStatus =
        widget.station.isActive ? 'maintenance' : 'active';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Set "${widget.station.name}" to ${nextStatus == 'active' ? 'Active' : 'Maintenance'}?',
          style: const TextStyle(
              color: AppColors.textPrimary, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.teal,
                foregroundColor: Colors.white),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      await StationRepository().updateStationStatus(
        stationId: widget.station.id,
        newStatus: nextStatus,
      );
      widget.onToggle();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _loading ? null : _toggle,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _statusColor.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _statusColor.withOpacity(0.35)),
        ),
        child: _loading
            ? Center(
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: _statusColor))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    widget.station.isActive
                        ? Icons.computer
                        : widget.station.isMaintenance
                            ? Icons.build_circle_outlined
                            : Icons.block,
                    color: _statusColor,
                    size: 28,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    widget.station.name,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.station.statusDisplay,
                    style: TextStyle(
                      color: _statusColor.withOpacity(0.7),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label,
            style: const TextStyle(
                color: AppColors.textSecondary, fontSize: 12)),
      ],
    );
  }
}
