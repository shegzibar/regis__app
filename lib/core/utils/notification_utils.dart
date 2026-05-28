import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'currency_utils.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});

class NotificationService {
  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // Initialize notifications
  Future<void> initialize() async {
    // Android initialization
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS initialization
    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );

    await _flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(const AndroidNotificationChannel(
          'gaminghub_bookings',
          'GamingHub Bookings',
          description: 'Booking notifications',
          importance: Importance.high,
        ));
  }

  // Show local notification
  Future<void> showNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'gaminghub_bookings',
      'GamingHub Bookings',
      channelDescription: 'Booking notifications',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iOSPlatformChannelSpecifics =
        DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformChannelSpecifics = NotificationDetails(
      android: androidPlatformChannelSpecifics,
      iOS: iOSPlatformChannelSpecifics,
    );

    await _flutterLocalNotificationsPlugin.show(
      0,
      title,
      body,
      platformChannelSpecifics,
      payload: payload,
    );
  }

  // Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle navigation based on payload
    print('Notification tapped: ${response.payload}');
  }

  // Cancel notification
  Future<void> cancelNotification(int id) async {
    await _flutterLocalNotificationsPlugin.cancel(id);
  }

  // Cancel all notifications
  Future<void> cancelAllNotifications() async {
    await _flutterLocalNotificationsPlugin.cancelAll();
  }

  // Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }

  // Check if notification permission is granted
  Future<bool> isPermissionGranted() async {
    final result = await _flutterLocalNotificationsPlugin
        .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
    return result ?? false;
  }
}

// Predefined notification types
class NotificationTypes {
  static const String bookingConfirmed = 'booking_confirmed';
  static const String bookingRejected = 'booking_rejected';
  static const String bookingReminder = 'booking_reminder';
  static const String paymentReceived = 'payment_received';
  static const String newBooking = 'new_booking';
  static const String slotExpired = 'slot_expired';
  static const String feeUnderReview = 'fee_under_review';
}

// Notification templates
class NotificationTemplates {
  static Map<String, String> bookingConfirmed(String cyberName) {
    return {
      'title': 'Booking Confirmed!',
      'body': 'Your booking at $cyberName is confirmed. See you there!',
      'type': NotificationTypes.bookingConfirmed,
    };
  }

  static Map<String, String> bookingRejected(String cyberName) {
    return {
      'title': 'Booking Rejected',
      'body':
          'Your booking at $cyberName was rejected. The slot has been released.',
      'type': NotificationTypes.bookingRejected,
    };
  }

  static Map<String, String> bookingReminder(String cyberName, String time) {
    return {
      'title': 'Session Starting Soon',
      'body': 'Your session at $cyberName starts in 15 minutes at $time.',
      'type': NotificationTypes.bookingReminder,
    };
  }

  static Map<String, String> paymentReceived(String userName, double amount) {
    return {
      'title': 'Payment Received',
      'body': '$userName paid ${CurrencyUtils.format(amount)} for booking.',
      'type': NotificationTypes.paymentReceived,
    };
  }

  static Map<String, String> newBooking(String userName, String time) {
    return {
      'title': 'New Booking',
      'body': 'New booking from $userName at $time.',
      'type': NotificationTypes.newBooking,
    };
  }

  static Map<String, String> slotExpired() {
    return {
      'title': 'Slot Expired',
      'body': 'Your booking slot has expired. Please try again.',
      'type': NotificationTypes.slotExpired,
    };
  }

  static Map<String, String> feeUnderReview() {
    return {
      'title': 'Payment Under Review',
      'body': 'Your payment receipt is being reviewed by our team.',
      'type': NotificationTypes.feeUnderReview,
    };
  }
}
