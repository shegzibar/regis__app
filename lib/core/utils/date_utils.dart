import 'package:intl/intl.dart';

class DateUtils {
  static const String _dateFormat = 'MMM dd, yyyy';
  static const String _timeFormat = 'hh:mm a';
  static const String _dateTimeFormat = 'MMM dd, yyyy hh:mm a';
  static const String _apiFormat = 'yyyy-MM-dd HH:mm:ss';

  // Format date for display
  static String formatDate(DateTime date) {
    return DateFormat(_dateFormat).format(date);
  }

  // Format time for display
  static String formatTime(DateTime time) {
    return DateFormat(_timeFormat).format(time);
  }

  // Format date and time for display
  static String formatDateTime(DateTime dateTime) {
    return DateFormat(_dateTimeFormat).format(dateTime);
  }

  // Format for API
  static String formatForApi(DateTime dateTime) {
    return DateFormat(_apiFormat).format(dateTime);
  }

  // Parse from API
  static DateTime parseFromApi(String dateString) {
    return DateFormat(_apiFormat).parse(dateString);
  }

  // Get relative time (e.g., "2 hours ago")
  static String getRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} ago';
    } else {
      return 'Just now';
    }
  }

  // Get time remaining (e.g., "15 minutes left")
  static String getTimeRemaining(DateTime dateTime) {
    final now = DateTime.now();
    final difference = dateTime.difference(now);

    if (difference.isNegative) {
      return 'Expired';
    }

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays == 1 ? '' : 's'} left';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours == 1 ? '' : 's'} left';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes == 1 ? '' : 's'} left';
    } else {
      return 'Less than a minute left';
    }
  }

  // Check if date is today
  static bool isToday(DateTime date) {
    final now = DateTime.now();
    return date.year == now.year && date.month == now.month && date.day == now.day;
  }

  // Check if date is tomorrow
  static bool isTomorrow(DateTime date) {
    final tomorrow = DateTime.now().add(const Duration(days: 1));
    return date.year == tomorrow.year && date.month == tomorrow.month && date.day == tomorrow.day;
  }

  // Check if date is yesterday
  static bool isYesterday(DateTime date) {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return date.year == yesterday.year && date.month == yesterday.month && date.day == yesterday.day;
  }

  // Get date range for next 7 days
  static List<DateTime> getNext7Days() {
    final now = DateTime.now();
    return List.generate(7, (index) => now.add(Duration(days: index)));
  }

  // Get time slots for a day (2-hour intervals)
  static List<DateTime> getTimeSlotsForDay(DateTime date) {
    final slots = <DateTime>[];
    final startTime = DateTime(date.year, date.month, date.day, 10, 0); // 10:00 AM
    final endTime = DateTime(date.year, date.month, date.day, 2, 0); // 2:00 AM next day
    
    var current = startTime;
    while (current.isBefore(endTime)) {
      slots.add(current);
      current = current.add(const Duration(hours: 2));
    }
    
    return slots;
  }

  // Get end time based on start time and duration
  static DateTime getEndTime(DateTime startTime, double durationHours) {
    return startTime.add(Duration(minutes: (durationHours * 60).round()));
  }

  // Check if time slots overlap
  static bool doTimeSlotsOverlap(
    DateTime start1, DateTime end1,
    DateTime start2, DateTime end2,
  ) {
    return start1.isBefore(end2) && end1.isAfter(start2);
  }

  // Format duration in hours
  static String formatDuration(double hours) {
    if (hours == hours.roundToDouble()) {
      return '${hours.round()} hour${hours.round() == 1 ? '' : 's'}';
    } else {
      final minutes = ((hours - hours.floor()) * 60).round();
      return '${hours.floor()}h ${minutes}m';
    }
  }

  // Get date string for tabs (Today, Tomorrow, Mon, etc.)
  static String getDateTab(DateTime date) {
    if (isToday(date)) return 'Today';
    if (isTomorrow(date)) return 'Tomorrow';
    return DateFormat('EEE').format(date);
  }
}
