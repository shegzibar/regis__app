import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class AppLocalization {
  static const List<Locale> supportedLocales = [
    Locale('en', 'US'), // English
    Locale('ar', 'EG'), // Arabic (Egypt)
  ];

  static const Locale fallbackLocale = Locale('en', 'US');

  static Future<void> init() async {
    await EasyLocalization.ensureInitialized();
  }

  static BuildContext? getContext(BuildContext context) => context;

  // Language switching
  static Future<void> changeLanguage(String languageCode, BuildContext context) async {
    final localizationContext = EasyLocalization.of(context);
    if (localizationContext != null) {
      await localizationContext.setLocale(Locale(languageCode));
    }
  }

  static Locale getCurrentLocale(BuildContext context) => 
      EasyLocalization.of(context)?.currentLocale ?? fallbackLocale;

  static bool isRTL(BuildContext context) => getCurrentLocale(context).languageCode == 'ar';

  static String getCurrentLanguage(BuildContext context) => getCurrentLocale(context).languageCode;

  // Translation helpers
  static String tr(String key) => key.tr();

  static String trArgs(String key, List<String> args) => key.tr(args: args);

  // Common translations
  static String get appName => 'app_name'.tr();
  
  // Common
  static String get loading => 'common.loading'.tr();
  static String get error => 'common.error'.tr();
  static String get success => 'common.success'.tr();
  static String get cancel => 'common.cancel'.tr();
  static String get confirm => 'common.confirm'.tr();
  static String get save => 'common.save'.tr();
  static String get delete => 'common.delete'.tr();
  static String get edit => 'common.edit'.tr();
  static String get close => 'common.close'.tr();
  static String get search => 'common.search'.tr();
  static String get filter => 'common.filter'.tr();
  static String get refresh => 'common.refresh'.tr();
  static String get settings => 'common.settings'.tr();
  static String get profile => 'common.profile'.tr();
  static String get logout => 'common.logout'.tr();
  static String get back => 'common.back'.tr();
  static String get next => 'common.next'.tr();
  static String get done => 'common.done'.tr();
  static String get yes => 'common.yes'.tr();
  static String get no => 'common.no'.tr();
  static String get ok => 'common.ok'.tr();
  static String get retry => 'common.retry'.tr();
  static String get viewAll => 'common.view_all'.tr();
  static String get available => 'common.available'.tr();
  static String get occupied => 'common.occupied'.tr();
  static String get openNow => 'common.open_now'.tr();
  static String get closed => 'common.closed'.tr();
  static String get egp => 'common.egp'.tr();
  static String get perHour => 'common.per_hour'.tr();

  // Auth
  static String get login => 'auth.login'.tr();
  static String get phoneNumber => 'auth.phone_number'.tr();
  static String get enterPhone => 'auth.enter_phone'.tr();
  static String get sendVerificationCode => 'auth.send_verification_code'.tr();
  static String get verificationCode => 'auth.verification_code'.tr();
  static String get enterCode => 'auth.enter_code'.tr();
  static String get resendCode => 'auth.resend_code'.tr();
  static String get verify => 'auth.verify'.tr();
  static String get expiresIn => 'auth.expires_in'.tr();
  static String get payNowToLockSlot => 'auth.pay_now_to_lock_slot'.tr();
  static String get completePayment => 'auth.complete_payment'.tr();
  static String get bookingId => 'auth.booking_id'.tr();
  static String get selectPaymentMethod => 'auth.select_payment_method'.tr();
  static String get sessionPrice => 'auth.session_price'.tr();
  static String get platformFee => 'auth.platform_fee'.tr();
  static String get totalToPay => 'auth.total_to_pay'.tr();
  static String get confirmPayment => 'auth.confirm_payment'.tr();

  // Home
  static String get gamingCentersMap => 'home.gaming_centers_map'.tr();
  static String get searchLocation => 'home.search_location'.tr();
  static String get explore => 'home.explore'.tr();
  static String get featuredCenters => 'home.featured_centers'.tr();
  static String get nearbyYou => 'home.nearby_you'.tr();
  static String get selectRoom => 'home.select_room'.tr();
  static String get bookStation => 'home.book_station'.tr();
  static String get startingFrom => 'home.starting_from'.tr();

  // Booking
  static String get selectDate => 'booking.select_date'.tr();
  static String get duration => 'booking.duration'.tr();
  static String get availableSlots => 'booking.available_slots'.tr();
  static String get hourIntervals => 'booking.hour_intervals'.tr();
  static String get confirmPayFee => 'booking.confirm_pay_fee'.tr();
  static String get pleaseSelectRoom => 'booking.please_select_room'.tr();
  static String get pleaseSelectTime => 'booking.please_select_time'.tr();

  // Payment
  static String get instapay => 'payment.instapay'.tr();
  static String get vodafoneCash => 'payment.vodafone_cash'.tr();
  static String get fawryPay => 'payment.fawry_pay'.tr();
  static String get transferTo => 'payment.transfer_to'.tr();
  static String get sendTo => 'payment.send_to'.tr();
  static String get referenceCodeProvided => 'payment.reference_code_provided'.tr();
  static String get processingPayment => 'payment.processing_payment'.tr();

  // Profile
  static String get personalInformation => 'profile.personal_information'.tr();
  static String get paymentMethods => 'profile.payment_methods'.tr();
  static String get bookingHistory => 'profile.booking_history'.tr();
  static String get helpSupport => 'profile.help_support'.tr();
  static String get memberSince => 'profile.member_since'.tr();
  static String get gamingStatistics => 'profile.gaming_statistics'.tr();
  static String get hoursPlayed => 'profile.hours_played'.tr();
  static String get totalBookings => 'profile.total_bookings'.tr();
  static String get favorites => 'profile.favorites'.tr();
  static String get achievements => 'profile.achievements'.tr();
  static String get favoriteCenters => 'profile.favorite_centers'.tr();
  static String get recentActivity => 'profile.recent_activity'.tr();
  static String get bookedVipRoom => 'profile.booked_vip_room'.tr();
  static String get reviewedCenter => 'profile.reviewed_center'.tr();
  static String get achievementUnlocked => 'profile.achievement_unlocked'.tr();
  static String get logoutConfirm => 'profile.logout_confirm'.tr();
  static String get loggingOut => 'profile.logging_out'.tr();

  // Admin
  static String get feeQueue => 'admin.fee_queue'.tr();
  static String get manageFees => 'admin.manage_fees'.tr();
  static String get verifyReceipts => 'admin.verify_receipts'.tr();
  static String get pending => 'admin.pending'.tr();
  static String get confirmed => 'admin.confirmed'.tr();
  static String get rejected => 'admin.rejected'.tr();
  static String get revenue => 'admin.revenue'.tr();
  static String get pendingReview => 'admin.pending_review'.tr();
  static String get newestFirst => 'admin.newest_first'.tr();
  static String get viewReceipt => 'admin.view_receipt'.tr();
  static String get depositApproved => 'admin.deposit_approved'.tr();
  static String get depositRejected => 'admin.deposit_rejected'.tr();
  static String get refreshingData => 'admin.refreshing_data'.tr();

  // Cyber
  static String get dashboard => 'cyber.dashboard'.tr();
  static String get todayBookings => 'cyber.today_bookings'.tr();
  static String get revenueToday => 'cyber.revenue_today'.tr();
  static String get activeStations => 'cyber.active_stations'.tr();
  static String get occupancyRate => 'cyber.occupancy_rate'.tr();
  static String get manageBookings => 'cyber.manage_bookings'.tr();
  static String get manageRooms => 'cyber.manage_rooms'.tr();
  static String get viewAnalytics => 'cyber.view_analytics'.tr();

  // Rooms
  static String get proPcZone => 'rooms.pro_pc_zone'.tr();
  static String get playstationVip => 'rooms.playstation_vip'.tr();
  static String get privateStreaming => 'rooms.private_streaming'.tr();
  static String get stationsAvailable => 'rooms.stations_available'.tr();

  // Map
  static String get nearestGamingCenter => 'map.nearest_gaming_center'.tr();
  static String get kmAway => 'map.km_away'.tr();
  static String get recenteringMap => 'map.recentering_map'.tr();
  static String get filterOptions => 'map.filter_options'.tr();
  static String get interactiveMap => 'map.interactive_map'.tr();
  static String get googleMapsIntegration => 'map.google_maps_integration'.tr();

  // Errors
  static String get networkError => 'errors.network_error'.tr();
  static String get serverError => 'errors.server_error'.tr();
  static String get invalidCredentials => 'errors.invalid_credentials'.tr();
  static String get somethingWentWrong => 'errors.something_went_wrong'.tr();
  static String get noDataAvailable => 'errors.no_data_available'.tr();
}

// Extension for easy localization
extension LocalizationExtension on BuildContext {
  String tr(String key) => key.tr();
}
