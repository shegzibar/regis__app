import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../data/models/cyber.dart';
import '../constants/app_colors.dart';
import '../../data/repositories/booking_repository.dart';
import '../../data/repositories/review_repository.dart';
import 'auth_provider.dart';
import 'location_provider.dart';

/// Aggregated profile data loaded from Supabase.
class ProfileData {
  final ProfileStats stats;
  final List<ProfileFavoriteCenter> favoriteCenters;
  final List<ProfileActivity> recentActivities;

  const ProfileData({
    required this.stats,
    required this.favoriteCenters,
    required this.recentActivities,
  });
}

class ProfileStats {
  final int totalHoursPlayed;
  final int totalBookings;
  final int favoriteCentersCount;
  final int achievements;

  const ProfileStats({
    required this.totalHoursPlayed,
    required this.totalBookings,
    required this.favoriteCentersCount,
    required this.achievements,
  });

  static const empty = ProfileStats(
    totalHoursPlayed: 0,
    totalBookings: 0,
    favoriteCentersCount: 0,
    achievements: 0,
  );
}

class ProfileFavoriteCenter {
  final String id;
  final String name;
  final double rating;
  final double? distanceKm;
  final bool isOpen;

  const ProfileFavoriteCenter({
    required this.id,
    required this.name,
    required this.rating,
    this.distanceKm,
    required this.isOpen,
  });
}

class ProfileActivity {
  final String id;
  final String type;
  final String title;
  final String subtitle;
  final DateTime createdAt;
  final String? routeCyberId;

  const ProfileActivity({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.createdAt,
    this.routeCyberId,
  });

  IconData get icon {
    switch (type) {
      case 'review':
        return Icons.star;
      case 'achievement':
        return Icons.emoji_events;
      default:
        return Icons.videogame_asset;
    }
  }

  Color get color {
    switch (type) {
      case 'review':
        return Colors.amber;
      case 'achievement':
        return Colors.purple;
      default:
        return AppColors.green;
    }
  }
}

final profileDataProvider = FutureProvider.autoDispose<ProfileData>((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) {
    return const ProfileData(
      stats: ProfileStats.empty,
      favoriteCenters: [],
      recentActivities: [],
    );
  }

  final position = ref.watch(locationProvider).valueOrNull;

  final bookings = await BookingRepository().getUserBookingsEnriched(user.id);
  final reviews = await ReviewRepository().getUserReviewsEnriched(user.id);

  return _buildProfileData(
    bookings: bookings,
    reviews: reviews,
    userPosition: position,
  );
});

ProfileData _buildProfileData({
  required List<Map<String, dynamic>> bookings,
  required List<Map<String, dynamic>> reviews,
  Position? userPosition,
}) {
  final totalBookings = bookings.length;

  double hoursPlayed = 0;
  for (final b in bookings) {
    final status = b['status'] as String? ?? '';
    if (status == 'completed' || status == 'confirmed') {
      hoursPlayed += (b['duration_hours'] as num?)?.toDouble() ?? 0;
    }
  }

  final cyberBookingCounts = <String, _CyberAggregate>{};
  for (final b in bookings) {
    final cyber = _cyberFromBooking(b);
    if (cyber == null) continue;
    final id = cyber['id'] as String;
    final status = b['status'] as String? ?? '';
    if (!_countsTowardFavorites(status)) continue;

    cyberBookingCounts.putIfAbsent(
      id,
      () => _CyberAggregate(cyber: cyber, bookingCount: 0),
    );
    cyberBookingCounts[id]!.bookingCount++;
  }

  final sortedCybers = cyberBookingCounts.values.toList()
    ..sort((a, b) => b.bookingCount.compareTo(a.bookingCount));

  final favoriteCenters = sortedCybers.take(5).map((agg) {
    final cyber = Cyber.fromMap(agg.cyber);
    return ProfileFavoriteCenter(
      id: cyber.id,
      name: cyber.name,
      rating: cyber.rating,
      distanceKm: _distanceKm(userPosition, cyber.lat, cyber.lng),
      isOpen: cyber.isOpenNow && cyber.isActive,
    );
  }).toList();

  final achievements = _computeAchievements(
    totalBookings: totalBookings,
    hoursPlayed: hoursPlayed,
    reviewCount: reviews.length,
  );

  final activities = <ProfileActivity>[];

  for (final b in bookings.take(10)) {
    final cyber = _cyberFromBooking(b);
    final room = _roomFromBooking(b);
    if (cyber == null) continue;

    final cyberName = cyber['name'] as String? ?? 'Gaming center';
    final roomLabel = _roomTypeLabel(room?['type'] as String?);
    final status = b['status'] as String? ?? '';

    activities.add(ProfileActivity(
      id: 'booking-${b['id']}',
      type: 'booking',
      title: _bookingActivityTitle(status, roomLabel),
      subtitle: cyberName,
      createdAt: DateTime.parse(b['created_at'] as String),
      routeCyberId: cyber['id'] as String?,
    ));
  }

  for (final r in reviews.take(10)) {
    final cyber = r['cybers'] as Map<String, dynamic>?;
    final cyberName = cyber?['name'] as String? ?? 'Gaming center';
    final rating = r['rating'] as int? ?? 5;

    activities.add(ProfileActivity(
      id: 'review-${r['id']}',
      type: 'review',
      title: 'Rated $cyberName',
      subtitle: '$rating star${rating == 1 ? '' : 's'}',
      createdAt: DateTime.parse(r['created_at'] as String),
      routeCyberId: cyber?['id'] as String?,
    ));
  }

  activities.sort((a, b) => b.createdAt.compareTo(a.createdAt));

  return ProfileData(
    stats: ProfileStats(
      totalHoursPlayed: hoursPlayed.round(),
      totalBookings: totalBookings,
      favoriteCentersCount: cyberBookingCounts.length,
      achievements: achievements,
    ),
    favoriteCenters: favoriteCenters,
    recentActivities: activities.take(8).toList(),
  );
}

class _CyberAggregate {
  final Map<String, dynamic> cyber;
  int bookingCount;

  _CyberAggregate({required this.cyber, required this.bookingCount});
}

bool _countsTowardFavorites(String status) {
  return status == 'confirmed' ||
      status == 'completed' ||
      status == 'fee_under_review';
}

Map<String, dynamic>? _cyberFromBooking(Map<String, dynamic> booking) {
  final stations = booking['stations'];
  if (stations is! Map<String, dynamic>) return null;
  final rooms = stations['rooms'];
  if (rooms is! Map<String, dynamic>) return null;
  final cybers = rooms['cybers'];
  if (cybers is! Map<String, dynamic>) return null;
  return cybers;
}

Map<String, dynamic>? _roomFromBooking(Map<String, dynamic> booking) {
  final stations = booking['stations'];
  if (stations is! Map<String, dynamic>) return null;
  final rooms = stations['rooms'];
  if (rooms is! Map<String, dynamic>) return null;
  return rooms;
}

String _roomTypeLabel(String? type) {
  switch (type) {
    case 'ps5':
      return 'PS5';
    case 'pc':
      return 'PC';
    case 'vip':
      return 'VIP';
    default:
      return 'session';
  }
}

String _bookingActivityTitle(String status, String roomLabel) {
  switch (status) {
    case 'pending_payment':
      return 'Started booking — $roomLabel';
    case 'fee_under_review':
      return 'Payment submitted — $roomLabel';
    case 'confirmed':
      return 'Confirmed — $roomLabel';
    case 'completed':
      return 'Played — $roomLabel';
    case 'rejected':
      return 'Booking rejected — $roomLabel';
    case 'cancelled':
      return 'Booking cancelled — $roomLabel';
    default:
      return 'Booked $roomLabel';
  }
}

double? _distanceKm(Position? user, double? lat, double? lng) {
  if (user == null || lat == null || lng == null) return null;
  final meters = Geolocator.distanceBetween(
    user.latitude,
    user.longitude,
    lat,
    lng,
  );
  return double.parse((meters / 1000).toStringAsFixed(1));
}

int _computeAchievements({
  required int totalBookings,
  required double hoursPlayed,
  required int reviewCount,
}) {
  var count = 0;
  if (totalBookings >= 1) count++;
  if (totalBookings >= 10) count++;
  if (totalBookings >= 25) count++;
  if (hoursPlayed >= 50) count++;
  if (hoursPlayed >= 100) count++;
  if (reviewCount >= 1) count++;
  return count;
}
