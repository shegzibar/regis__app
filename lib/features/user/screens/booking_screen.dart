import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/room_provider.dart';
import '../../../core/providers/booking_provider.dart';
import '../../../core/providers/cyber_provider.dart';
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
  
  late final List<DateTime> _availableDates;
  
  final List<String> _timeSlots = [
    '10:00 AM',
    '12:00 PM',
    '02:00 PM',
    '04:00 PM',
    '06:00 PM',
    '08:00 PM',
    '10:00 PM',
  ];
  
  final List<int> _durations = [1, 2, 3, 4];
  
  @override
  void initState() {
    super.initState();
    // Dynamic dates starting from today
    _availableDates = List.generate(7, (index) => DateTime.now().add(Duration(days: index)));
    _selectedDate = _availableDates[0];
  }

  void _selectDate(DateTime date) {
    setState(() {
      _selectedDate = date;
    });
  }

  void _selectDuration(int duration) {
    setState(() {
      _selectedDuration = duration;
    });
  }

  void _selectTimeSlot(String timeSlot) {
    setState(() {
      _selectedTimeSlot = timeSlot;
    });
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
  }

  Future<void> _confirmBooking() async {
    if (_selectedTimeSlot == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
      return;
    }

    setState(() => _isBookingLoading = true);

    try {
      // Get stations
      final stations = await ref.read(roomStationsProvider(widget.roomId).future);
      if (stations.isEmpty) {
        throw Exception('No active stations found in this room. Please choose another room.');
      }

      // Pick first active/available station
      final targetStation = stations.first;

      // Parse slot time (e.g. "10:00 AM")
      final parts = _selectedTimeSlot!.split(' ');
      final timeParts = parts[0].split(':');
      int hour = int.parse(timeParts[0]);
      final int minute = int.parse(timeParts[1]);
      final isPm = parts[1].toLowerCase() == 'pm';
      
      if (isPm && hour < 12) hour += 12;
      if (!isPm && hour == 12) hour = 0;

      final startTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        hour,
        minute,
      );
      final endTime = startTime.add(Duration(hours: _selectedDuration));

      final room = await ref.read(roomByIdProvider(widget.roomId).future);
      if (room == null) throw Exception('Room details not found');

      final basePrice = room.pricePerHour;
      final totalAmount = basePrice * _selectedDuration;

      // Create booking
      final booking = await ref.read(bookingNotifierProvider.notifier).createBooking(
            stationId: targetStation.id,
            startTime: startTime,
            endTime: endTime,
            durationHours: _selectedDuration.toDouble(),
            totalAmount: totalAmount,
            notes: 'Booked via GamingHub mobile app',
          );

      if (mounted) {
        setState(() => _isBookingLoading = false);
        // Refresh bookings lists
        ref.invalidate(userBookingsProvider);
        // Route to payment screen
        context.push('/payment/${booking.id}?amount=${booking.totalAmount}');
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
                  const Text(
                    'Book Station',
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
                loading: () => const Center(child: CircularProgressIndicator(color: AppColors.green)),
                error: (err, _) => Center(child: Text('Error: $err', style: const TextStyle(color: Colors.red))),
                data: (room) {
                  if (room == null) return const Center(child: Text('Room not found', style: TextStyle(color: Colors.white)));

                  return SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Room name & status
                        Row(
                          children: [
                            Text(
                              room.name,
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppColors.green,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'OPEN',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Category: ${room.displayName}',
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 14,
                          ),
                        ),
                        
                        const SizedBox(height: 24),

                        // Date Selection
                        const Text(
                          'Select Date',
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
                              final isSelected = _isSameDay(date, _selectedDate);
                              
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
                        const Text(
                          'Duration',
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
                            const Text(
                              'Available Slots',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                            const Text(
                              '2-hour intervals',
                              style: TextStyle(
                                color: AppColors.textMuted,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 16),
                        
                        // Time Slots Grid
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 2.0,
                          ),
                          itemCount: _timeSlots.length,
                          itemBuilder: (context, index) {
                            final timeSlot = _timeSlots[index];
                            final isSelected = timeSlot == _selectedTimeSlot;
                            
                            return TimeSlotCard(
                              time: timeSlot,
                              isAvailable: true,
                              isSelected: isSelected,
                              onTap: () => _selectTimeSlot(timeSlot),
                            );
                          },
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
                              const Text(
                                'Total Amount',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                '${(room.pricePerHour * _selectedDuration).toInt()} EGP (${room.pricePerHour.toInt()} EGP/hr)',
                                style: const TextStyle(
                                  color: AppColors.green,
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        
                        const SizedBox(height: 32),
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
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  minimumSize: const Size(double.infinity, 56),
                ),
                child: _isBookingLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'Confirm & Book',
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
