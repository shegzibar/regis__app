import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final _allBookingsProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) async {
  final data = await Supabase.instance.client.from('bookings').select('''
        id, status, start_time, end_time, total_amount, booking_fee,
        created_at, notes, user_id,
        stations(
          id, name,
          rooms(
            id, name, type,
            cybers(id, name, city)
          )
        )
      ''').order('created_at', ascending: false);

  final bookingList = (data as List)
      .map((b) => Map<String, dynamic>.from(b as Map<String, dynamic>))
      .toList();
      
  final userIds = bookingList
      .map((b) => b['user_id'] as String?)
      .where((id) => id != null)
      .cast<String>()
      .toSet()
      .toList();

  Map<String, Map<String, dynamic>> userProfiles = {};
  if (userIds.isNotEmpty) {
    try {
      final profiles = await Supabase.instance.client
          .from('profiles')
          .select('id, name, phone')
          .inFilter('id', userIds);

      for (var profile in profiles) {
        userProfiles[profile['id']] = profile;
      }
    } catch (e) {
      // Ignore
    }
  }

  for (var booking in bookingList) {
    final userId = booking['user_id'] as String?;
    final profile = userId != null && userProfiles.containsKey(userId)
        ? userProfiles[userId]
        : null;

    String name = 'Unknown User';
    String phone = '—';
    
    if (profile != null) {
      final pName = profile['name'] as String?;
      final pPhone = profile['phone'] as String?;
      
      if (pName != null && pName.trim().isNotEmpty) {
        name = pName;
      } else if (pPhone != null && pPhone.trim().isNotEmpty) {
        name = pPhone;
      }
      
      if (pPhone != null && pPhone.trim().isNotEmpty) {
        phone = pPhone;
      }
    }

    booking['profiles'] = {'name': name, 'phone': phone};
  }

  return bookingList;
});

// ─── Status helpers ───────────────────────────────────────────────────────────

Color _statusColor(String status) {
  switch (status) {
    case 'confirmed':
      return AppColors.statusConfirmed;
    case 'completed':
      return AppColors.statusCompleted;
    case 'cancelled':
      return AppColors.statusCancelled;
    case 'pending_payment':
    case 'fee_under_review':
      return AppColors.statusPending;
    default:
      return AppColors.gray;
  }
}

String _statusLabel(String status) {
  switch (status) {
    case 'confirmed':
      return 'Confirmed';
    case 'completed':
      return 'Completed';
    case 'cancelled':
      return 'Cancelled';
    case 'pending_payment':
      return 'Pending Payment';
    case 'fee_under_review':
      return 'Under Review';
    default:
      return status;
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────

class AdminOrdersScreen extends ConsumerStatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  ConsumerState<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends ConsumerState<AdminOrdersScreen> {
  String _filterStatus = 'all';
  String _searchQuery = '';
  final _searchController = TextEditingController();

  static const _statusFilters = [
    ('all', 'All'),
    ('pending_payment', 'Pending'),
    ('fee_under_review', 'Review'),
    ('confirmed', 'Confirmed'),
    ('completed', 'Completed'),
    ('cancelled', 'Cancelled'),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<Map<String, dynamic>> _applyFilters(List<Map<String, dynamic>> all) {
    var list = all;
    if (_filterStatus != 'all') {
      list = list.where((b) => b['status'] == _filterStatus).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((b) {
        final user = b['profiles'] as Map<String, dynamic>?;
        final station = b['stations'] as Map<String, dynamic>?;
        final room = station?['rooms'] as Map<String, dynamic>?;
        final cyber = room?['cybers'] as Map<String, dynamic>?;
        return (user?['name'] ?? '').toString().toLowerCase().contains(q) ||
            (user?['phone'] ?? '').toString().toLowerCase().contains(q) ||
            (cyber?['name'] ?? '').toString().toLowerCase().contains(q) ||
            (station?['name'] ?? '').toString().toLowerCase().contains(q);
      }).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(_allBookingsProvider);

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'All Orders',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Every booking across all cybers',
                        style: TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Refresh
                  GestureDetector(
                    onTap: () => ref.invalidate(_allBookingsProvider),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: const Icon(Icons.refresh,
                          color: Colors.white, size: 24),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ── Search ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: TextField(
                controller: _searchController,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search by user, cyber, station…',
                  hintStyle: const TextStyle(color: AppColors.textMuted),
                  prefixIcon:
                      const Icon(Icons.search, color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.darkCard,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.darkBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.darkBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.green),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                onChanged: (v) => setState(() => _searchQuery = v),
              ),
            ),

            const SizedBox(height: 12),

            // ── Status filter chips ──
            SizedBox(
              height: 36,
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                scrollDirection: Axis.horizontal,
                children: _statusFilters.map((f) {
                  final selected = _filterStatus == f.$1;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(f.$2),
                      selected: selected,
                      onSelected: (_) =>
                          setState(() => _filterStatus = f.$1),
                      backgroundColor: AppColors.darkCard,
                      selectedColor: AppColors.green.withOpacity(0.2),
                      checkmarkColor: AppColors.green,
                      labelStyle: TextStyle(
                        color: selected ? AppColors.green : AppColors.textMuted,
                        fontSize: 12,
                        fontWeight: selected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                      side: BorderSide(
                        color: selected
                            ? AppColors.green.withOpacity(0.5)
                            : AppColors.darkBorder,
                      ),
                      showCheckmark: false,
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 12),

            // ── Content ──
            Expanded(
              child: async.when(
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.green),
                ),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error_outline,
                          color: AppColors.error, size: 48),
                      const SizedBox(height: 12),
                      Text(
                        'Failed to load orders',
                        style: const TextStyle(color: Colors.white),
                      ),
                      const SizedBox(height: 8),
                      ElevatedButton(
                        onPressed: () => ref.invalidate(_allBookingsProvider),
                        style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.green),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (all) {
                  final filtered = _applyFilters(all);
                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              color: AppColors.textMuted.withOpacity(0.5),
                              size: 64),
                          const SizedBox(height: 16),
                          const Text(
                            'No orders found',
                            style: TextStyle(
                                color: AppColors.textMuted, fontSize: 16),
                          ),
                        ],
                      ),
                    );
                  }

                  // Stats bar
                  return Column(
                    children: [
                      // Quick stats
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        child: Row(
                          children: [
                            _StatBadge(
                              label: 'Total',
                              value: all.length.toString(),
                              color: Colors.white,
                            ),
                            const SizedBox(width: 8),
                            _StatBadge(
                              label: 'Showing',
                              value: filtered.length.toString(),
                              color: AppColors.green,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      Expanded(
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 4),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final booking = filtered[index];
                            return _OrderCard(
                              booking: booking,
                              onTap: () =>
                                  _showDetail(context, booking),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetail(
      BuildContext context, Map<String, dynamic> booking) {
    final user = booking['profiles'] as Map<String, dynamic>?;
    final station = booking['stations'] as Map<String, dynamic>?;
    final room = station?['rooms'] as Map<String, dynamic>?;
    final cyber = room?['cybers'] as Map<String, dynamic>?;
    final status = booking['status'] as String? ?? '';

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.darkCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text(
                  'Order Details',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 20),
            _DetailRow(
              icon: Icons.person_outline,
              label: 'Customer',
              value: user?['name'] ?? '—',
            ),
            _DetailRow(
              icon: Icons.phone_outlined,
              label: 'Phone',
              value: user?['phone'] ?? '—',
            ),
            _DetailRow(
              icon: Icons.store_outlined,
              label: 'Cyber',
              value: '${cyber?['name'] ?? '—'} (${cyber?['city'] ?? ''})',
            ),
            _DetailRow(
              icon: Icons.room_outlined,
              label: 'Room / Station',
              value:
                  '${room?['name'] ?? '—'} › ${station?['name'] ?? '—'}',
            ),
            _DetailRow(
              icon: Icons.access_time,
              label: 'Start',
              value: _formatDateTime(booking['start_time']),
            ),
            _DetailRow(
              icon: Icons.timer_off_outlined,
              label: 'End',
              value: _formatDateTime(booking['end_time']),
            ),
            _DetailRow(
              icon: Icons.payments_outlined,
              label: 'Amount',
              value:
                  '${booking['total_amount'] ?? 0} EGP  (fee: ${booking['booking_fee'] ?? 0} EGP)',
            ),
            if ((booking['notes'] ?? '').isNotEmpty)
              _DetailRow(
                icon: Icons.note_outlined,
                label: 'Notes',
                value: booking['notes'].toString(),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(dynamic raw) {
    if (raw == null) return '—';
    try {
      final dt = DateTime.parse(raw.toString()).toLocal();
      return '${dt.day}/${dt.month}/${dt.year}  ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return raw.toString();
    }
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _OrderCard extends StatelessWidget {
  final Map<String, dynamic> booking;
  final VoidCallback onTap;

  const _OrderCard({required this.booking, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final user = booking['profiles'] as Map<String, dynamic>?;
    final station = booking['stations'] as Map<String, dynamic>?;
    final room = station?['rooms'] as Map<String, dynamic>?;
    final cyber = room?['cybers'] as Map<String, dynamic>?;
    final status = booking['status'] as String? ?? '';
    final amount = booking['total_amount'];
    final createdAt = booking['created_at'];

    String timeAgo = '';
    if (createdAt != null) {
      try {
        final dt = DateTime.parse(createdAt.toString()).toLocal();
        final diff = DateTime.now().difference(dt);
        if (diff.inMinutes < 60) {
          timeAgo = '${diff.inMinutes}m ago';
        } else if (diff.inHours < 24) {
          timeAgo = '${diff.inHours}h ago';
        } else {
          timeAgo = '${diff.inDays}d ago';
        }
      } catch (_) {}
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.darkCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.darkBorder),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.green.withOpacity(0.15),
                  child: Text(
                    (user?['name'] ?? '?').toString().isNotEmpty
                        ? (user!['name'] as String)[0].toUpperCase()
                        : '?',
                    style: const TextStyle(
                      color: AppColors.green,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?['name'] ?? 'Unknown User',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        cyber?['name'] ?? '—',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusChip(status: status),
              ],
            ),
            const SizedBox(height: 10),
            const Divider(color: AppColors.darkBorder, height: 1),
            const SizedBox(height: 10),
            Row(
              children: [
                const Icon(Icons.computer_outlined,
                    color: AppColors.textMuted, size: 14),
                const SizedBox(width: 4),
                Text(
                  '${room?['name'] ?? '—'} › ${station?['name'] ?? '—'}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                ),
                const Spacer(),
                Text(
                  '$amount EGP',
                  style: const TextStyle(
                    color: AppColors.green,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time,
                    color: AppColors.textMuted, size: 14),
                const SizedBox(width: 4),
                Text(
                  timeAgo,
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                ),
                const Spacer(),
                const Icon(Icons.chevron_right,
                    color: AppColors.textMuted, size: 16),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        _statusLabel(status),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  const _StatBadge(
      {required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.darkCard,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.darkBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$label: ',
            style:
                const TextStyle(color: AppColors.textMuted, fontSize: 12),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _DetailRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.textMuted, size: 16),
          const SizedBox(width: 10),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style:
                  const TextStyle(color: Colors.white, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
