import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/auth_provider.dart';
import '../../../data/models/booking.dart';
import '../../../data/supabase/supabase_client.dart';

final ownerScheduleBookingsProvider =
    FutureProvider.autoDispose.family<List<Booking>, DateTime>((ref, date) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];

  final startOfDay = DateTime(date.year, date.month, date.day);
  final endOfDay = startOfDay.add(const Duration(days: 1));

  try {
    final response = await SupabaseService()
        .from('bookings')
        .select('''
          *,
          stations!inner(
            id, name, room_id,
            rooms!inner(
              id, name, type,
              cybers!inner(id, name, owner_id)
            )
          )
        ''')
        .gte('start_time', startOfDay.toIso8601String())
        .lt('start_time', endOfDay.toIso8601String())
        .inFilter('status', ['confirmed', 'fee_under_review', 'pending_payment'])
        .eq('stations.rooms.cybers.owner_id', user.id)
        .order('start_time');

    return (response as List).map((b) => Booking.fromMap(b)).toList();
  } catch (_) {
    return [];
  }
});

class OwnerScheduleScreen extends ConsumerStatefulWidget {
  const OwnerScheduleScreen({super.key});

  @override
  ConsumerState<OwnerScheduleScreen> createState() =>
      _OwnerScheduleScreenState();
}

class _OwnerScheduleScreenState extends ConsumerState<OwnerScheduleScreen> {
  late DateTime _selectedDate;
  late List<DateTime> _dateRange;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _buildDateRange();
  }

  void _buildDateRange() {
    final today = DateTime.now();
    _dateRange = List.generate(
        14, (i) => today.subtract(const Duration(days: 3)).add(Duration(days: i)));
  }

  @override
  Widget build(BuildContext context) {
    final bookingsAsync =
        ref.watch(ownerScheduleBookingsProvider(_selectedDate));

    return Scaffold(
      backgroundColor: AppColors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Text(
                'Schedule',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Date Picker
            SizedBox(
              height: 76,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: _dateRange.length,
                itemBuilder: (context, index) {
                  final date = _dateRange[index];
                  final isSelected = _isSameDay(date, _selectedDate);
                  final isToday = _isSameDay(date, DateTime.now());

                  return GestureDetector(
                    onTap: () => setState(() => _selectedDate = date),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 52,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: isSelected ? AppColors.teal : AppColors.lightGray,
                        borderRadius: BorderRadius.circular(14),
                        border: isToday && !isSelected
                            ? Border.all(color: AppColors.teal, width: 1.5)
                            : null,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _dayAbbr(date.weekday),
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white.withOpacity(0.8)
                                  : AppColors.textSecondary,
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${date.day}',
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : AppColors.textPrimary,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 8),

            // Selected date label
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                _formatFullDate(_selectedDate),
                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),

            const SizedBox(height: 16),
            const Divider(color: AppColors.lightGray, height: 1),

            // Bookings list
            Expanded(
              child: bookingsAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.teal)),
                error: (e, _) => Center(
                    child: Text('Error loading schedule',
                        style:
                            const TextStyle(color: AppColors.error))),
                data: (bookings) {
                  if (bookings.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.event_available,
                              color: AppColors.gray, size: 56),
                          const SizedBox(height: 16),
                          const Text(
                            'No bookings on this day',
                            style: TextStyle(
                                color: AppColors.textPrimary,
                                fontSize: 16,
                                fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _formatFullDate(_selectedDate),
                            style: const TextStyle(
                                color: AppColors.textSecondary,
                                fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(24),
                    itemCount: bookings.length,
                    itemBuilder: (context, index) {
                      final booking = bookings[index];
                      return _ScheduleBookingCard(booking: booking);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  String _dayAbbr(int weekday) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[weekday - 1];
  }

  String _formatFullDate(DateTime dt) {
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    const days = [
      'Monday', 'Tuesday', 'Wednesday', 'Thursday',
      'Friday', 'Saturday', 'Sunday'
    ];
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]}';
  }
}

class _ScheduleBookingCard extends StatelessWidget {
  final Booking booking;
  const _ScheduleBookingCard({required this.booking});

  @override
  Widget build(BuildContext context) {
    final statusColor = booking.isConfirmed
        ? AppColors.statusConfirmed
        : booking.isPendingPayment || booking.isFeeUnderReview
            ? AppColors.statusPending
            : AppColors.gray;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.lightGray),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          // Time indicator
          Column(
            children: [
              Text(
                _formatTime(booking.startTime),
                style: const TextStyle(
                    color: AppColors.teal,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
              Container(
                  width: 2,
                  height: 28,
                  margin: const EdgeInsets.symmetric(vertical: 4),
                  color: AppColors.teal.withOpacity(0.3)),
              Text(
                _formatTime(booking.endTime),
                style: const TextStyle(
                    color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(width: 16),
          // Details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Station ${booking.stationId.substring(0, 8)}',
                  style: const TextStyle(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${booking.durationHours.toInt()} hour session  •  EGP ${booking.totalAmount.toStringAsFixed(0)}',
                  style: const TextStyle(
                      color: AppColors.textSecondary, fontSize: 12),
                ),
              ],
            ),
          ),
          // Status badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              booking.statusDisplay,
              style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final h = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final m = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }
}
