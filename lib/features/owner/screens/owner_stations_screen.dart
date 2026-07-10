import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/models/station.dart';
import '../../../data/models/booking.dart';
import '../../../data/models/inventory_item.dart';
import '../../../data/repositories/station_repository.dart';
import '../../../data/repositories/owner_repository.dart';
import '../../../data/supabase/supabase_client.dart';

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
            id, name, type, cyber_id,
            cybers!inner(id, name, owner_id)
          ),
          bookings(
            id, status, start_time, end_time, total_amount, booking_fee, user_id
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

    return ColoredBox(
      color: const Color(0xFFF4F6F8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 4),
            child: Row(
              children: [
                Text(
                  'owner_stations.stations'.tr(),
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh, color: AppColors.primary),
                  onPressed: () => ref.invalidate(ownerStationsProvider),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'owner_stations.tap_station'.tr(),
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
          ),

          const SizedBox(height: 16),

          // Legend
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                _LegendDot(color: AppColors.statusConfirmed, label: 'owner_stations.active'.tr()),
                const SizedBox(width: 16),
                _LegendDot(color: AppColors.statusPending, label: 'owner_stations.maintenance'.tr()),
                const SizedBox(width: 16),
                _LegendDot(color: AppColors.statusRejected, label: 'owner_stations.blocked'.tr()),
              ],
            ),
          ),

          const SizedBox(height: 20),
          const Divider(color: AppColors.lightGray, height: 1),

          // Grid
          Expanded(
            child: stationsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (e, _) => Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.error_outline, color: AppColors.error, size: 48),
                    const SizedBox(height: 12),
                    Text('owner_stations.failed_load'.tr(),
                        style: const TextStyle(color: AppColors.textPrimary)),
                    const SizedBox(height: 8),
                    TextButton(
                        onPressed: () => ref.invalidate(ownerStationsProvider),
                        child: Text('owner_stations.retry'.tr(),
                            style: const TextStyle(color: AppColors.primary))),
                  ],
                ),
              ),
              data: (rawStations) {
                if (rawStations.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.computer_outlined, color: AppColors.gray, size: 56),
                        const SizedBox(height: 16),
                        Text('owner_stations.no_stations'.tr(),
                            style: const TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text('owner_stations.add_from_admin'.tr(),
                            style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
                      ],
                    ),
                  );
                }

                // Group by room type
                final grouped = <String, List<Map<String, dynamic>>>{};
                for (final raw in rawStations) {
                  final roomType = (raw['rooms']?['type'] as String?) ?? 'unknown';
                  grouped.putIfAbsent(roomType, () => []).add(raw);
                }

                return RefreshIndicator(
                  onRefresh: () async => ref.invalidate(ownerStationsProvider),
                  child: ListView(
                    padding: const EdgeInsets.all(24),
                    children: grouped.entries.map((entry) {
                      return _StationGroup(
                        roomType: entry.key,
                        rawData: entry.value,
                        onToggle: () => ref.invalidate(ownerStationsProvider),
                      );
                    }).toList(),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StationGroup extends StatelessWidget {
  final String roomType;
  final List<Map<String, dynamic>> rawData;
  final VoidCallback onToggle;

  const _StationGroup({
    required this.roomType,
    required this.rawData,
    required this.onToggle,
  });

  String get _roomLabel {
    switch (roomType.toLowerCase()) {
      case 'ps5':
        return 'owner_stations.ps5_room'.tr();
      case 'pc':
        return 'owner_stations.pc_room'.tr();
      case 'vip':
        return 'owner_stations.vip_room'.tr();
      default:
        return 'owner_stations.room_default'.tr(args: [roomType]);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.05),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Text(
                  _roomLabel,
                  style: const TextStyle(
                    color: AppColors.primary,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.85,
              ),
              itemCount: rawData.length,
              itemBuilder: (context, i) {
                final raw = rawData[i];
                final station = Station.fromMap(raw);
                
                // Find active booking if any
                Booking? activeBooking;
                final bookingsRaw = raw['bookings'] as List?;
                if (bookingsRaw != null) {
                  for (final b in bookingsRaw) {
                    final booking = Booking.fromMap(b);
                    if (booking.status == 'confirmed' || booking.status == 'ongoing') {
                      if (booking.endTime.isAfter(DateTime.now())) {
                        activeBooking = booking;
                        break;
                      }
                    }
                  }
                }
                
                final cyberId = raw['rooms']?['cyber_id'] as String?;

                return _StationTile(
                  station: station,
                  activeBooking: activeBooking,
                  cyberId: cyberId,
                  onToggle: onToggle,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StationTile extends StatefulWidget {
  final Station station;
  final Booking? activeBooking;
  final String? cyberId;
  final VoidCallback onToggle;

  const _StationTile({
    required this.station,
    this.activeBooking,
    this.cyberId,
    required this.onToggle,
  });

  @override
  State<_StationTile> createState() => _StationTileState();
}

class _StationTileState extends State<_StationTile> {
  bool _loading = false;
  Timer? _timer;
  Duration _timeLeft = Duration.zero;

  @override
  void initState() {
    super.initState();
    _updateTimeLeft();
    if (widget.activeBooking != null) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimeLeft());
    }
  }

  @override
  void didUpdateWidget(_StationTile oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.activeBooking?.id != widget.activeBooking?.id) {
      _timer?.cancel();
      _updateTimeLeft();
      if (widget.activeBooking != null) {
        _timer = Timer.periodic(const Duration(seconds: 1), (_) => _updateTimeLeft());
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _updateTimeLeft() {
    if (widget.activeBooking == null) return;
    final now = DateTime.now();
    final end = widget.activeBooking!.endTime;
    if (end.isAfter(now)) {
      if (mounted) {
        setState(() {
          _timeLeft = end.difference(now);
        });
      }
    } else {
      if (mounted) {
        setState(() {
          _timeLeft = Duration.zero;
        });
        _timer?.cancel();
      }
    }
  }

  String _formatDuration(Duration d) {
    final hh = d.inHours.toString().padLeft(2, '0');
    final mm = (d.inMinutes % 60).toString().padLeft(2, '0');
    final ss = (d.inSeconds % 60).toString().padLeft(2, '0');
    if (d.inHours > 0) return '$hh:$mm:$ss';
    return '$mm:$ss';
  }

  Color get _statusColor {
    if (widget.activeBooking != null) return AppColors.orange;
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

  Future<void> _handleTap() async {
    // If active booking exists, show details
    if (widget.activeBooking != null && widget.cyberId != null) {
      await showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (ctx) => _StationDetailsBottomSheet(
          booking: widget.activeBooking!,
          cyberId: widget.cyberId!,
          onUpdate: widget.onToggle,
        ),
      );
      return;
    }

    // Else toggle status
    final nextStatus = widget.station.isActive ? 'maintenance' : 'active';
    final targetDisplay = nextStatus == 'active' ? 'owner_stations.active'.tr() : 'owner_stations.maintenance'.tr();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'owner_stations.set_status'.tr(args: [widget.station.name, targetDisplay]),
          style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('owner_stations.cancel'.tr(), style: const TextStyle(color: AppColors.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: Text('owner_stations.confirm'.tr()),
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
      final msg = 'owner_stations.failed'.tr(args: [e.toString()]);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg)),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasActiveSession = widget.activeBooking != null;
    return GestureDetector(
      onTap: _loading ? null : _handleTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: _statusColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: _statusColor.withValues(alpha: 0.35)),
        ),
        child: _loading
            ? Center(child: CircularProgressIndicator(strokeWidth: 2, color: _statusColor))
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    hasActiveSession
                        ? Icons.timer
                        : widget.station.isActive
                            ? Icons.computer
                            : widget.station.isMaintenance
                                ? Icons.build_circle_outlined
                                : Icons.block,
                    color: _statusColor,
                    size: 24,
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
                  const SizedBox(height: 4),
                  if (hasActiveSession)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        _formatDuration(_timeLeft),
                        style: TextStyle(
                          color: _statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else
                    Text(
                      widget.station.statusDisplay,
                      style: TextStyle(
                        color: _statusColor.withValues(alpha: 0.7),
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}

class _StationDetailsBottomSheet extends ConsumerStatefulWidget {
  final Booking booking;
  final String cyberId;
  final VoidCallback onUpdate;

  const _StationDetailsBottomSheet({
    required this.booking,
    required this.cyberId,
    required this.onUpdate,
  });

  @override
  ConsumerState<_StationDetailsBottomSheet> createState() => _StationDetailsBottomSheetState();
}

class _StationDetailsBottomSheetState extends ConsumerState<_StationDetailsBottomSheet> {
  bool _loading = false;
  List<CyberInventoryItem>? _inventory;

  @override
  void initState() {
    super.initState();
    _loadInventory();
  }

  Future<void> _loadInventory() async {
    setState(() => _loading = true);
    try {
      final items = await OwnerRepository().getInventoryItems(widget.cyberId);
      if (mounted) setState(() => _inventory = items.where((i) => i.isActive).toList());
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('owner_stations.error_inventory'.tr())),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addItem(CyberInventoryItem item) async {
    setState(() => _loading = true);
    try {
      await OwnerRepository().addBookingItem(
        bookingId: widget.booking.id,
        item: item,
        quantity: 1,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('owner_stations.added_successfully'.tr()), backgroundColor: AppColors.green),
        );
      }
      widget.onUpdate();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('owner_stations.failed'.tr(args: [e.toString()])), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 24,
        left: 24,
        right: 24,
        bottom: MediaQuery.of(context).padding.bottom + 24,
      ),
      decoration: const BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'owner_stations.session_details'.tr(),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildDetailRow('ID', '#${widget.booking.id.substring(0, 8).toUpperCase()}'),
          const SizedBox(height: 8),
          _buildDetailRow('Start', DateFormat('hh:mm a').format(widget.booking.startTime)),
          const SizedBox(height: 8),
          _buildDetailRow('End', DateFormat('hh:mm a').format(widget.booking.endTime)),
          const SizedBox(height: 24),
          Text(
            'owner_stations.add_items'.tr(),
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          if (_loading && _inventory == null)
            const Center(child: CircularProgressIndicator())
          else if (_inventory != null && _inventory!.isNotEmpty)
            SizedBox(
              height: 50,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _inventory!.length,
                itemBuilder: (context, i) {
                  final item = _inventory![i];
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ActionChip(
                      label: Text('${item.name} (${item.price.toInt()} EGP)'),
                      onPressed: _loading ? null : () => _addItem(item),
                      backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                      labelStyle: const TextStyle(color: AppColors.primary),
                    ),
                  );
                },
              ),
            )
          else
            const Text(
              'No inventory items found. Add them from Profile > Cyber Profile.',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text('$label: ', style: const TextStyle(color: AppColors.textSecondary, fontSize: 14)),
        Text(value, style: const TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w600)),
      ],
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

