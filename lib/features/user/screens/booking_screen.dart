import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../shared/widgets/date_card.dart';
import '../../../shared/widgets/duration_button.dart';
import '../../../shared/widgets/time_slot_card.dart';

class BookingScreen extends StatefulWidget {
  final String roomId;
  
  const BookingScreen({super.key, required this.roomId});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  DateTime _selectedDate = DateTime.now();
  int _selectedDuration = 2; // Default 2 hours
  String? _selectedTimeSlot;
  bool _isFavorite = false;
  
  // Mock data
  final List<DateTime> _availableDates = [
    DateTime(2024, 1, 23), // Monday
    DateTime(2024, 1, 24), // Tuesday (selected)
    DateTime(2024, 1, 25), // Wednesday
    DateTime(2024, 1, 26), // Thursday
    DateTime(2024, 1, 27), // Friday
    DateTime(2024, 1, 28), // Saturday
    DateTime(2024, 1, 29), // Sunday
  ];
  
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
  
  int get _basePrice => 50;
  int get _fee => 5;
  int get _totalAmount => (_basePrice * _selectedDuration) + _fee;

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

  void _confirmBooking() {
    if (_selectedTimeSlot != null) {
      // TODO: Navigate to payment screen
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Proceeding to payment...')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a time slot')),
      );
    }
  }

  String _getDayOfWeek(DateTime date) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return days[date.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
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
            
            // Cyber Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Cyber Zone Maadi',
                        style: TextStyle(
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
                  const Text(
                    'Street 9, Maadi, Cairo',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                            '$_totalAmount EGP ($_basePrice/hr + $_fee fee)',
                            style: const TextStyle(
                              color: AppColors.green,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'PC Room - VIP',
                            style: TextStyle(
                              color: AppColors.textMuted,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
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
                onPressed: _confirmBooking,
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
                child: const Text(
                  'Confirm & Pay Fee',
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
