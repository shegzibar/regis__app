import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:intl/intl.dart';
import '../../../data/models/booking.dart';
import '../models/station_live.dart';

final _db = Supabase.instance.client;

class CdBookingRepository {
  // Removed _getStationIdsForCyber as we now use foolproof local filtering

  /// All bookings for today that belong to this cyber's stations.
  /// Includes all statuses (pending_payment, fee_under_review, confirmed, etc.)
  /// so that new user reservations appear immediately.
  Future<List<Booking>> getTodayBookings(String cyberId) async {
    try {
      final now = DateTime.now();
      final windowStart = now.subtract(const Duration(days: 1));
      final windowEnd = now.add(const Duration(days: 2));

      final data = await _db.from('bookings').select('''
        *,
        stations ( id, name, rooms ( id, name, type, cyber_id ) )
      ''')
          .gte('start_time', windowStart.toIso8601String())
          .lt('start_time', windowEnd.toIso8601String())
          .order('start_time');

      final allBookings = (data as List).map((b) => Booking.fromMap(b)).toList();

      final filteredBookings = allBookings.where((b) {
        if (b.cyberId != cyberId) return false;
        
        final localStart = b.startTime.toLocal();
        return localStart.year == now.year &&
               localStart.month == now.month &&
               localStart.day == now.day;
      }).toList();

      // Foolproof manual fetch for user profiles to bypass missing foreign key constraint
      if (filteredBookings.isNotEmpty) {
        final userIds = filteredBookings.map((b) => b.userId).toSet().toList();
        try {
          final profileMap = <String, String>{};

          try {
            final profiles = await _db.from('profiles').select('id, name, phone').inFilter('id', userIds);
            for (final p in profiles as List) {
              final name = p['name'] as String?;
              final phone = p['phone'] as String?;
              final id = p['id'] as String;
              if (name != null && name.trim().isNotEmpty) {
                profileMap[id] = name.trim();
              } else if (phone != null && phone.trim().isNotEmpty) {
                profileMap[id] = phone.trim();
              }
            }
          } catch (e) {
            debugPrint('Profiles table fetch failed: $e');
          }

          try {
            final legacyUsers = await _db.from('users').select('id, name, phone').inFilter('id', userIds);
            for (final p in legacyUsers as List) {
              final id = p['id'] as String;
              if (profileMap.containsKey(id)) continue; // already found in profiles
              
              final name = p['name'] as String?;
              final phone = p['phone'] as String?;
              if (name != null && name.trim().isNotEmpty) {
                profileMap[id] = name.trim();
              } else if (phone != null && phone.trim().isNotEmpty) {
                profileMap[id] = phone.trim();
              }
            }
          } catch (e) {
            debugPrint('Legacy users table fetch failed: $e');
          }

          for (final id in userIds) {
            if (!profileMap.containsKey(id)) {
              // Show partial UUID so the owner can still identify the user
              profileMap[id] = 'User #${id.substring(0, 8).toUpperCase()}';
            }
          }

          for (var i = 0; i < filteredBookings.length; i++) {
            final b = filteredBookings[i];
            if (b.source == 'app') {
              final resolved = profileMap[b.userId];
              if (resolved != null) {
                filteredBookings[i] = b.copyWith(userName: resolved);
              }
            }
          }
        } catch (e) {
          debugPrint('Profile fetch failed: $e');
        }
      }

      return filteredBookings;
    } catch (e) {
      debugPrint('getTodayBookings failed: $e');
      return [];
    }
  }

  /// All bookings for this cyber, regardless of date, used for Weekly/Monthly views.
  Future<List<Booking>> getAllBookings(String cyberId) async {
    try {
      final now = DateTime.now();
      // Fetch from 1 month ago up to 3 months in the future to cover all tabs
      final windowStart = now.subtract(const Duration(days: 30));
      final windowEnd = now.add(const Duration(days: 90));

      final data = await _db.from('bookings').select('''
        *,
        stations ( id, name, rooms ( id, name, type, cyber_id ) )
      ''')
          .gte('start_time', windowStart.toIso8601String())
          .lt('start_time', windowEnd.toIso8601String())
          .order('start_time');

      final allBookings = (data as List).map((b) => Booking.fromMap(b)).toList();

      final filteredBookings = allBookings.where((b) => b.cyberId == cyberId).toList();

      if (filteredBookings.isNotEmpty) {
        final userIds = filteredBookings.map((b) => b.userId).toSet().toList();
        try {
          final profileMap = <String, String>{};

          try {
            final profiles = await _db.from('profiles').select('id, name, phone').inFilter('id', userIds);
            for (final p in profiles as List) {
              final name = p['name'] as String?;
              final phone = p['phone'] as String?;
              final id = p['id'] as String;
              if (name != null && name.trim().isNotEmpty) {
                profileMap[id] = name.trim();
              } else if (phone != null && phone.trim().isNotEmpty) {
                profileMap[id] = phone.trim();
              }
            }
          } catch (e) {
            debugPrint('Profiles table fetch failed: $e');
          }

          for (final id in userIds) {
            if (!profileMap.containsKey(id)) {
              profileMap[id] = 'User #${id.substring(0, 8).toUpperCase()}';
            }
          }

          for (var i = 0; i < filteredBookings.length; i++) {
            final b = filteredBookings[i];
            if (b.source == 'app') {
              final resolved = profileMap[b.userId];
              if (resolved != null) {
                filteredBookings[i] = b.copyWith(userName: resolved);
              }
            }
          }
        } catch (e) {
          debugPrint('Profile fetch failed: $e');
        }
      }

      return filteredBookings;
    } catch (e) {
      debugPrint('getAllBookings failed: $e');
      return [];
    }
  }

  /// Sum of confirmed booking amounts for today for this cyber.
  /// Uses start_time (not created_at) so we count sessions happening today.
  Future<double> getTodayRevenue(String cyberId) async {
    try {
      final now = DateTime.now();
      final windowStart = now.subtract(const Duration(days: 1));
      final windowEnd = now.add(const Duration(days: 2));

      final data = await _db
          .from('bookings')
          .select('start_time, total_amount, stations ( rooms ( cyber_id ) )')
          .eq('status', 'confirmed')
          .gte('start_time', windowStart.toIso8601String())
          .lt('start_time', windowEnd.toIso8601String());

      final filtered = (data as List).where((b) {
        final st = b['stations'] as Map<String, dynamic>?;
        final rm = st?['rooms'] as Map<String, dynamic>?;
        if (rm?['cyber_id'] != cyberId) return false;

        final startDt = DateTime.parse(b['start_time'] as String).toLocal();
        return startDt.year == now.year &&
               startDt.month == now.month &&
               startDt.day == now.day;
      });

      return filtered.fold<double>(
          0.0, (sum, b) => sum + (b['total_amount'] as num).toDouble());
    } catch (e) {
      debugPrint('getTodayRevenue failed: $e');
      return 0.0;
    }
  }

  /// Returns true if the station has no confirmed/pending bookings in the range.
  Future<bool> isStationAvailable(
    String stationId,
    DateTime startTime,
    DateTime endTime,
  ) async {
    final conflicts = await _db
        .from('bookings')
        .select('id')
        .eq('station_id', stationId)
        .inFilter(
            'status', ['confirmed', 'fee_under_review', 'pending_payment'])
        .lt('start_time', endTime.toIso8601String())
        .gt('end_time', startTime.toIso8601String());

    return (conflicts as List).isEmpty;
  }

  /// Creates a confirmed manual booking.
  /// For non-cash payments, also creates an approved payment record.
  /// Note: 'cash' payments are tracked in the booking notes only, because the
  /// DB payments.method constraint only allows instapay/vodafone_cash/fawry.
  Future<Booking> addManualBooking({
    required String stationId,
    required DateTime startTime,
    required int durationHours,
    required double pricePerHour,
    required String paymentMethod,
    String? clientName,
  }) async {
    final endTime = startTime.add(Duration(hours: durationHours));
    final totalAmount = pricePerHour * durationHours;
    final workerId = _db.auth.currentUser!.id;

    final clientNote = clientName != null && clientName.isNotEmpty
        ? 'Walk-in: $clientName'
        : 'Walk-in customer';

    final booking = await _db
        .from('bookings')
        .insert({
          'user_id': workerId,
          'station_id': stationId,
          'start_time': startTime.toIso8601String(),
          'end_time': endTime.toIso8601String(),
          'duration_hours': durationHours,
          'total_amount': totalAmount,
          'booking_fee': 0,
          'status': 'confirmed',
          'source': 'manual',
          'notes': '$clientNote | Payment: $paymentMethod',
          if (clientName != null && clientName.trim().isNotEmpty)
            'guest_name': clientName.trim(),
          'confirmed_at': DateTime.now().toIso8601String(),
        })
        .select()
        .single();

    // Only insert into payments table for non-cash electronic payments,
    // as the DB constraint requires method IN ('instapay','vodafone_cash','fawry').
    if (paymentMethod != 'cash') {
      await _db.from('payments').insert({
        'booking_id': booking['id'],
        'user_id': workerId,
        'amount': totalAmount,
        'method': paymentMethod,
        'status': 'approved',
        'reviewed_by': workerId,
        'reviewed_at': DateTime.now().toIso8601String(),
      });
    }

    return Booking.fromMap(booking);
  }

  /// Live status of all stations in a room, merged with active booking info.
  Future<List<StationLive>> getLiveStationStatus(String roomId) async {
    final now = DateTime.now();

    final stations = await _db
        .from('stations')
        .select('id, name, status, room_id')
        .eq('room_id', roomId)
        .order('name');

    if ((stations as List).isEmpty) return [];

    final stationIds = stations.map((s) => s['id']).toList();

    // Fetch active bookings
    final activeBookings = await _db
        .from('bookings')
        .select('id, station_id, end_time, user_id')
        .inFilter('station_id', stationIds)
        .inFilter('status', ['confirmed', 'fee_under_review', 'pending_payment', 'ongoing'])
        .lte('start_time', now.toUtc().toIso8601String())
        .gte('end_time', now.toUtc().toIso8601String());

    if ((activeBookings as List).isEmpty) {
      return stations.map<StationLive>((s) {
        return StationLive(
          id: s['id'] as String,
          roomId: s['room_id'] as String,
          name: s['name'] as String,
          status: s['status'] as String? ?? 'active',
          isBusy: false,
          currentUser: null,
          currentBookingId: null,
          busyUntil: null,
          source: null,
        );
      }).toList();
    }

    // Batch fetch user profiles
    final userIds = (activeBookings as List)
        .map((b) => b['user_id'] as String)
        .toSet()
        .toList();

    final profileMap = <String, String>{};
    
    try {
      final profiles = await _db.from('profiles').select('id, name').inFilter('id', userIds);
      for (final p in profiles as List) {
        final name = p['name'] as String?;
        if (name != null && name.trim().isNotEmpty) {
          profileMap[p['id'] as String] = name.trim();
        }
      }
    } catch (_) {}

    try {
      final legacyUsers = await _db.from('users').select('id, name').inFilter('id', userIds);
      for (final p in legacyUsers as List) {
        final id = p['id'] as String;
        if (!profileMap.containsKey(id)) {
          final name = p['name'] as String?;
          if (name != null && name.trim().isNotEmpty) {
            profileMap[id] = name.trim();
          }
        }
      }
    } catch (_) {}

    for (final id in userIds) {
      if (!profileMap.containsKey(id)) {
        profileMap[id] = 'User #${id.substring(0, 8).toUpperCase()}';
      }
    }

    // Merge booking data with profiles
    final busyMap = <String, Map<String, dynamic>>{};
    for (final b in activeBookings) {
      final booking = Map<String, dynamic>.from(b as Map<String, dynamic>);
      booking['userName'] = profileMap[b['user_id'] as String];
      busyMap[b['station_id'] as String] = booking;
    }

    return stations.map<StationLive>((s) {
      final sid = s['id'] as String;
      final booking = busyMap[sid];
      return StationLive(
        id: sid,
        roomId: s['room_id'] as String,
        name: s['name'] as String,
        status: s['status'] as String? ?? 'active',
        isBusy: booking != null,
        currentUser: booking != null ? (booking['userName'] as String?) : null,
        currentBookingId: booking != null ? (booking['id'] as String?) : null,
        busyUntil: booking != null
            ? DateTime.tryParse(booking['end_time'] as String)
            : null,
        source: null,
      );
    }).toList();
  }

  /// Subscribe to any booking change for real-time refresh.
  RealtimeChannel subscribeToBookings(
    String cyberId,
    void Function() onUpdate,
  ) {
    return _db
        .channel('cd-bookings-$cyberId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'bookings',
          callback: (_) => onUpdate(),
        )
        .subscribe();
  }

  /// Fetch all bookings for this cyber within [start, end) for accounting.
  Future<List<Booking>> getBookingsForPeriod({
    required String cyberId,
    required DateTime start,
    required DateTime end,
  }) async {
    try {
      final data = await _db.from('bookings').select('''
        *,
        stations ( id, name, rooms ( id, name, type, cyber_id ) )
      ''')
          .gte('start_time', start.toUtc().toIso8601String())
          .lt('start_time', end.toUtc().toIso8601String())
          .order('start_time', ascending: false);

      final all = (data as List).map((b) => Booking.fromMap(b)).toList();
      final filtered = all.where((b) => b.cyberId == cyberId).toList();

      // Resolve user names
      if (filtered.isNotEmpty) {
        final userIds = filtered.map((b) => b.userId).toSet().toList();
        final profileMap = <String, String>{};
        try {
          final profiles = await _db
              .from('profiles')
              .select('id, name, phone')
              .inFilter('id', userIds);
          for (final p in profiles as List) {
            final name = p['name'] as String?;
            final phone = p['phone'] as String?;
            final id = p['id'] as String;
            profileMap[id] = (name?.trim().isNotEmpty == true
                    ? name!
                    : phone?.trim().isNotEmpty == true
                        ? phone!
                        : 'User #${id.substring(0, 8).toUpperCase()}');
          }
        } catch (_) {}

        for (var i = 0; i < filtered.length; i++) {
          final b = filtered[i];
          if (b.source == 'app') {
            final name = profileMap[b.userId];
            if (name != null) filtered[i] = b.copyWith(userName: name);
          }
        }
      }

      return filtered;
    } catch (e) {
      debugPrint('getBookingsForPeriod failed: $e');
      return [];
    }
  }
}
