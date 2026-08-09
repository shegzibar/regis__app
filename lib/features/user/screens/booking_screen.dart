import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/room_provider.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../core/providers/cyber_provider.dart';
import '../../../data/repositories/booking_repository.dart';
import '../../../shared/widgets/date_card.dart';
import '../../../shared/widgets/duration_button.dart';
import '../../../shared/widgets/time_slot_card.dart';

class BookingScreen extends ConsumerStatefulWidget {
  final String roomId;

  const BookingScreen({super.key, required this.roomId});

  @override
  ConsumerState<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends ConsumerState<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  int _selectedDuration = 2; // Default 2 hours
  String? _selectedTimeSlot;
  bool _isFavorite = false;
  bool _isBookingLoading = false;
  Set<String> _bookedSlots = {};

  // Realtime subscription
  List<String> _allStationIds = []; // all stations in this room
  List<RealtimeChannel> _realtimeChannels = [];

  late final List<DateTime> _availableDates;

  List<String> _timeSlots = [
    '10:00 AM',
    '10:30 AM',
    '11:00 AM',
    '11:30 AM',
    '12:00 PM',
    '12:30 PM',
    '01:00 PM',
    '01:30 PM',
    '02:00 PM',
    '02:30 PM',
    '03:00 PM',
    '03:30 PM',
    '04:00 PM',
    '04:30 PM',
    '05:00 PM',
    '05:30 PM',
    '06:00 PM',
    '06:30 PM',
    '07:00 PM',
    '07:30 PM',
    '08:00 PM',
    '08:30 PM',
    '09:00 PM',
    '09:30 PM',
    '10:00 PM',
    '10:30 PM',
    '11:00 PM',
    '11:30 PM',
  ];

  final List<int> _durations = [1, 2, 3, 4];

  @override
  void initState() {
    super.initState();
    _availableDates =
        List.generate(7, (index) => DateTime.now().add(Duration(days: index)));
    _selectedDate = _availableDates[0];
    // Load initial data + subscribe to realtime
    WidgetsBinding.instance.addPostFrameCallback((_) => _initRealtime());
  }

  DateTime? _parseSlotToDateTime(DateTime date, String slot) {
    try {
      final parts = slot.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);
      final isPm = parts[1].toLowerCase() == 'pm';
      if (isPm && hour < 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;
      return DateTime(date.year, date.month, date.day, hour, minute);
    } catch (_) {
      return null;
    }
  }

  Future<void> _initRealtime() async {
    try {
      final room = await ref.read(roomByIdProvider(widget.roomId).future);
      if (room != null) {
        final cyber = await ref.read(cyberByIdProvider(room.cyberId).future);
        if (cyber != null) {
          _generateTimeSlots(cyber.workingHoursFrom, cyber.workingHoursTo);
        }
      }

      final stations = await ref.read(roomStationsProvider(widget.roomId).future);
      if (stations.isEmpty || !mounted) return;
      _allStationIds = stations.map((s) => s.id).toList();

      // Initial load for all stations
      await _loadBookedSlotsForRoom();

      // Subscribe to realtime changes for ALL stations in this room
      for (final stationId in _allStationIds) {
        final channel = Supabase.instance.client
            .channel('bookings:station_id=eq.$stationId')
            .onPostgresChanges(
              event: PostgresChangeEvent.all,
              schema: 'public',
              table: 'bookings',
              filter: PostgresChangeFilter(
                type: PostgresChangeFilterType.eq,
                column: 'station_id',
                value: stationId,
              ),
              callback: (_) {
                if (mounted) _loadBookedSlotsForRoom();
              },
            )
            .subscribe();
        _realtimeChannels.add(channel);
      }
    } catch (e) {
      debugPrint('Realtime init failed: $e');
    }
  }

  @override
  void dispose() {
    for (final ch in _realtimeChannels) {
      ch.unsubscribe();
    }
    super.dispose();
  }

  /// Marks a slot as booked only if ALL stations in the room are occupied at
  /// that time. If even one station is free, the slot stays available.
  Future<void> _loadBookedSlotsForRoom() async {
    try {
      if (_allStationIds.isEmpty) return;
      final startOfDay = DateTime(
          _selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));

      // For each time slot, track which stations are occupied
      final stationOccupied = <String, Set<String>>{}; // slot -> set of occupied station IDs
      for (final stationId in _allStationIds) {
        final existing = await BookingRepository().getStationBookings(
            stationId,
            startDate: startOfDay,
            endDate: endOfDay);
        for (final b in existing) {
          for (final slot in _timeSlots) {
            final slotTime = _parseSlotToDateTime(_selectedDate, slot);
            // A slot is occupied if any part of its 30-min window falls
            // within an existing booking's time range.
            if (slotTime != null &&
                slotTime.isBefore(b.endTime.toLocal()) &&
                slotTime
                    .add(const Duration(minutes: 30))
                    .isAfter(b.startTime.toLocal())) {
              stationOccupied.putIfAbsent(slot, () => <String>{}).add(stationId);
            }
          }
        }
      }

      // A slot is considered booked if ANY station in the room is occupied
      final booked = <String>{};
      for (final slot in _timeSlots) {
        final occupiedCount = stationOccupied[slot]?.length ?? 0;
        if (occupiedCount > 0) {
          booked.add(slot);
        }
      }

      if (mounted) setState(() => _bookedSlots = booked);
    } catch (e) {
      debugPrint('Failed to load booked slots: $e');
    }
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _selectedTimeSlot = null;
      _bookedSlots = {}; // Clear immediately so stale slots don't show
    });
    // Re-fetch for new date using all stations in the room
    _loadBookedSlotsForRoom();
  }

  void _selectDuration(int duration) {
    setState(() {
      _selectedDuration = duration;
    });
  }

  void _generateTimeSlots(String? from, String? to) {
    if (from == null || to == null) return;
    try {
      final fromParts = from.split(':');
      final toParts = to.split(':');
      int fromHour = int.parse(fromParts[0]);
      int fromMin = int.parse(fromParts[1]);
      int toHour = int.parse(toParts[0]);
      int toMin = int.parse(toParts[1]);

      final now = DateTime.now();
      DateTime start = DateTime(now.year, now.month, now.day, fromHour, fromMin);
      DateTime end = DateTime(now.year, now.month, now.day, toHour, toMin);

      if (end.isBefore(start) || end.isAtSameMomentAs(start)) {
        end = end.add(const Duration(days: 1));
      }

      final List<String> newSlots = [];
      DateTime current = start;
      while (current.isBefore(end)) {
        newSlots.add(DateFormat('hh:mm a').format(current));
        current = current.add(const Duration(minutes: 30));
      }

      if (mounted) {
        setState(() {
          _timeSlots = newSlots;
        });
      }
    } catch (e) {
      debugPrint('Failed to generate time slots: $e');
    }
  }

  void _selectTimeSlot(String timeSlot) {
    if (_isSlotInPast(timeSlot)) return;
    setState(() {
      _selectedTimeSlot = timeSlot;
    });
  }

  bool _isSlotInPast(String slot) {
    if (!_isSameDay(_selectedDate, DateTime.now())) return false;
    final slotTime = _parseSlotToDateTime(_selectedDate, slot);
    if (slotTime == null) return false;
    return slotTime.isBefore(DateTime.now());
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  Future<void> _confirmBooking() async {
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('booking.please_select_time'.tr())),
      );
      return;
    }

    // Prevent booking a past time slot
    if (_isSlotInPast(_selectedTimeSlot!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('booking.time_slot_passed'.tr())),
      );
      setState(() => _selectedTimeSlot = null);
      return;
    }

    setState(() => _isBookingLoading = true);

    try {
      // Get stations
      final stations =
          await ref.read(roomStationsProvider(widget.roomId).future);
      if (stations.isEmpty) {
        throw Exception('booking.no_active_stations'.tr());
      }

      // ── Conflict-check (race-condition guard) ───────────────────────────────
      // Re-query the DB right before inserting to make sure the slot is still
      // free even if another user booked it in the last few seconds.
      final startOfDay = DateTime(
          _selectedDate.year, _selectedDate.month, _selectedDate.day);
      final endOfDay = startOfDay.add(const Duration(days: 1));
      
      final slotTime = _parseSlotToDateTime(_selectedDate, _selectedTimeSlot!);
      if (slotTime == null) throw Exception('Invalid time slot');

      // Find an available station
      var targetStation = stations.first;
      bool foundAvailable = false;

      for (final station in stations) {
        final latestBookings = await BookingRepository().getStationBookings(
            station.id,
            startDate: startOfDay,
            endDate: endOfDay);

        bool hasConflict = false;
        for (final b in latestBookings) {
          if (slotTime.isBefore(b.endTime) &&
              slotTime
                  .add(Duration(hours: _selectedDuration))
                  .isAfter(b.startTime)) {
            hasConflict = true;
            break;
          }
        }

        if (!hasConflict) {
          targetStation = station;
          foundAvailable = true;
          break;
        }
      }

      if (!foundAvailable) {
        // Slot was taken while the user was looking at the screen
        if (mounted) {
          setState(() {
            _bookedSlots.add(_selectedTimeSlot!);
            _selectedTimeSlot = null;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('⚡ This slot was just booked by someone else. Please choose another time.'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 4),
            ),
          );
        }
        setState(() => _isBookingLoading = false);
        return;
      }
      // ────────────────────────────────────────────────────────────────────────

      // Parse slot time (e.g. "10:00 AM")
      final parts = _selectedTimeSlot!.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);
      final isPm = parts[1].toLowerCase() == 'pm';

      if (isPm && hour < 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;

      // Store as UTC so the Cyber Dashboard (which compares UTC) shows the correct day
      final startTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        hour,
        minute,
      ).toUtc();
      final endTime = startTime.add(Duration(hours: _selectedDuration));

      final room = await ref.read(roomByIdProvider(widget.roomId).future);
      if (room == null) throw Exception('Room details not found');

      final basePrice = room.pricePerHour;
      final totalAmount = basePrice * _selectedDuration;
      final bookingFee = room.effectiveBookingFee;

      // Create booking
      final booking =
          await ref.read(bookingNotifierProvider.notifier).createBooking(
                stationId: targetStation.id,
                startTime: startTime,
                endTime: endTime,
                durationHours: _selectedDuration.toDouble(),
                totalAmount: totalAmount,
                bookingFee: bookingFee,
                notes: 'booking.booked_via_app'.tr(),
              );

      if (mounted) {
        setState(() => _isBookingLoading = false);
        // Refresh bookings lists
        ref.invalidate(userBookingsProvider);
        // Route to payment screen
        // Route to payment screen, paying only the registration fee
        context.push('/payment/${booking.id}?amount=$bookingFee');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isBookingLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    }
  }

  String _getDayOfWeek(DateTime date) {
    return DateFormat('E').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final roomAsync = ref.watch(roomByIdProvider(widget.roomId));

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'home.book_station'.tr(),
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _toggleFavorite,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: AppColors.darkCard,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.darkBorder),
                      ),
                      child: Icon(
                        _isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: _isFavorite ? Colors.red : Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Content
            Expanded(
              child: roomAsync.when(
                loading: () => const Center(
                    child: CircularProgressIndicator(color: AppColors.green)),
                error: (err, _) => Center(
                    child: Text('Error: $err',
                        style: const TextStyle(color: Colors.red))),
                data: (room) {
                  if (room == null) {
                    return Center(
                        child: Text('booking.room_not_found'.tr(),
                            style: const TextStyle(color: Colors.white)));
                  }

                  return SingleChildScrollView(
                    padding: EdgeInsets.zero,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Room image banner — carousel when multiple photos, single when one, icon fallback
                        _RoomImageBanner(room: room),

                        const SizedBox(height: 24),

                        // Rest of content padded
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [

                        // Date Selection
                        Text(
                          'booking.select_date'.tr(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Date Cards
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: _availableDates.length,
                            itemBuilder: (context, index) {
                              final date = _availableDates[index];
                              final isSelected =
                                  _isSameDay(date, _selectedDate);

                              return Padding(
                                padding: const EdgeInsets.only(right: 12.0),
                                child: DateCard(
                                  dayName: _getDayOfWeek(date),
                                  dayNumber: date.day.toString(),
                                  isSelected: isSelected,
                                  onTap: () => _selectDate(date),
                                ),
                              );
                            },
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Duration Selection
                        Text(
                          'booking.duration'.tr(),
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 16),

                        // Duration Buttons
                        Row(
                          children: _durations.map((duration) {
                            return Padding(
                              padding: const EdgeInsets.only(right: 12.0),
                              child: DurationButton(
                                duration: duration,
                                isSelected: duration == _selectedDuration,
                                onTap: () => _selectDuration(duration),
                              ),
                            );
                          }).toList(),
                        ),

                        const SizedBox(height: 32),

                        // Available Slots
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'booking.available_slots'.tr(),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              'booking.hour_intervals'.tr(),
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Time Slots Grid (Responsive Wrap)
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          alignment: WrapAlignment.start,
                          children: _timeSlots.map((timeSlot) {
                            final isSelected = timeSlot == _selectedTimeSlot;
                            final isBooked = _bookedSlots.contains(timeSlot);
                            final isPast = _isSlotInPast(timeSlot);

                            return TimeSlotCard(
                               time: timeSlot,
                               isAvailable: !isBooked,
                               isSelected: isSelected,
                               isPast: isPast,
                               onTap: () => _selectTimeSlot(timeSlot),
                             );
                          }).toList(),
                        ),

                        const SizedBox(height: 32),

                        // Booking Summary
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppColors.darkCard,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.darkBorder),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'booking.registration_fee_pay_now'.tr(),
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    '${room.effectiveBookingFee.toInt()} EGP',
                                    style: const TextStyle(
                                      color: AppColors.green,
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              const Divider(color: AppColors.darkBorder),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'booking.total_session_price'.tr(),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                  Text(
                                    '${(room.pricePerHour * _selectedDuration).toInt()} EGP',
                                    style: const TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 32),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // Bottom Confirm Button
            Container(
              padding: const EdgeInsets.all(24.0),
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                border: Border(
                  top: BorderSide(color: AppColors.darkBorder),
                ),
              ),
              child: ElevatedButton(
                onPressed: _isBookingLoading ? null : _confirmBooking,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.green,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isBookingLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'booking.confirm_and_book'.tr(),
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }
}

/// Shows a full-width image banner on the booking screen.
/// • Multiple images → horizontal PageView carousel with dot indicators
/// • Single image   → simple Stack with gradient overlay
/// • No images      → compact icon + text row
class _RoomImageBanner extends StatefulWidget {
  final dynamic room; // Room
  const _RoomImageBanner({required this.room});

  @override
  State<_RoomImageBanner> createState() => _RoomImageBannerState();
}

class _RoomImageBannerState extends State<_RoomImageBanner> {
  int _currentPage = 0;
  final PageController _pageController = PageController();

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Widget _gradient({required Widget child}) {
    return Stack(
      children: [
        child,
        // Gradient fade at bottom
        Container(
          height: 260,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                AppColors.darkBg.withOpacity(0.6),
                AppColors.darkBg,
              ],
              stops: const [0.3, 0.7, 1.0],
            ),
          ),
        ),
        // Room name overlay
        Positioned(
          bottom: 16,
          left: 24,
          right: 24,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.room.name,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.green,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'booking.open_badge'.tr(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              if (widget.room.description != null &&
                  widget.room.description!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  widget.room.description!,
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 13,
                    height: 1.4,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = widget.room.images as List<String>;
    final imageUrl = widget.room.imageUrl as String?;

    // Build effective list: prefer images[], fall back to imageUrl
    final allImages = images.isNotEmpty
        ? images
        : (imageUrl != null && imageUrl.isNotEmpty ? [imageUrl] : <String>[]);

    if (allImages.isEmpty) {
      // No image — compact title row
      return Padding(
        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                color: AppColors.darkCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                child: Text(widget.room.typeIcon,
                    style: const TextStyle(fontSize: 28)),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.room.name,
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    widget.room.description != null &&
                            widget.room.description!.isNotEmpty
                        ? widget.room.description!
                        : '${'booking.category_label'.tr()}: ${widget.room.displayName}',
                    style: const TextStyle(
                        color: AppColors.textMuted, fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    if (allImages.length == 1) {
      // Single image — simple banner
      return SizedBox(
        height: 260,
        child: _gradient(
          child: Image.network(
            allImages.first,
            width: double.infinity,
            height: 260,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // Multiple images — PageView carousel
    return SizedBox(
      height: 260,
      child: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: allImages.length,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (context, index) => Image.network(
              allImages[index],
              width: double.infinity,
              height: 260,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: AppColors.darkCard,
                child: const Icon(Icons.broken_image, color: Colors.white38),
              ),
            ),
          ),
          // Gradient + text overlay
          _gradient(child: const SizedBox(width: double.infinity, height: 260)),
          // Dot indicators
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                allImages.length,
                (i) => AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  width: _currentPage == i ? 16 : 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: _currentPage == i
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
