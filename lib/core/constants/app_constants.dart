class AppConstants {
  // Supabase Configuration
  static const String supabaseUrl = 'https://anajhyletxfzvhugdszy.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImFuYWpoeWxldHhmenZodWdkc3p5Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzk2Njc3MzMsImV4cCI6MjA5NTI0MzczM30.AeZbuqF1HIGDiVXxCxlQLuyyQY0YlRB8BzAy4ZC4dUQ';

  // App Configuration
  static const String appName = 'GamingHub';
  static const String appVersion = '1.0.0';

  /// When true, any logged-in email account can open user / admin / cyber apps.
  /// Set to false before production release.
  static const bool bypassRoleChecksForTesting = true;

  /// When true, sign-up shows a role picker (user, owner, manager, admin).
  static const bool allowTestRoleSelection = false;

  // Booking Configuration
  static const double bookingFee = 5.0; // 5 EGP
  static const Duration bookingTimeout = Duration(minutes: 15);
  static const Duration bookingReminderTime = Duration(minutes: 15);

  // Pagination
  static const int defaultPageSize = 20;

  // Image Upload
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const List<String> supportedImageFormats = ['jpg', 'jpeg', 'png'];

  // Map Configuration
  static const double defaultLatitude = 30.0444; // Cairo
  static const double defaultLongitude = 31.2357;
  static const double defaultZoom = 12.0;

  // Time Slots
  static const List<int> availableDurations = [1, 2, 3, 4]; // hours
  static const int timeSlotInterval = 2; // hours

  // Working Hours
  static const String defaultOpeningTime = '10:00';
  static const String defaultClosingTime = '02:00';

  // Rating
  static const int maxRating = 5;

  // Payment Methods
  static const List<String> paymentMethods = [
    'instapay',
    'vodafone_cash',
    'fawry'
  ];

  // User Roles
  static const List<String> userRoles = ['user', 'owner', 'manager', 'admin'];

  // Room Types
  static const List<String> roomTypes = ['ps5', 'pc', 'vip'];

  // Booking Statuses
  static const List<String> bookingStatuses = [
    'pending_payment',
    'fee_under_review',
    'confirmed',
    'rejected',
    'completed',
    'cancelled'
  ];

  // Payment Statuses
  static const List<String> paymentStatuses = [
    'pending',
    'approved',
    'rejected'
  ];

  // Station Statuses
  static const List<String> stationStatuses = [
    'active',
    'maintenance',
    'blocked'
  ];
}
