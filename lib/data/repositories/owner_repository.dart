import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/utils/supabase_error_message.dart';
import '../models/booking.dart';
import '../models/cyber.dart';
import '../models/cyber_profile_input.dart';
import '../models/cyber_room_profile.dart';
import '../models/inventory_item.dart';
import '../models/owner_booking_item.dart';
import '../models/room.dart';
import '../models/station.dart';
import '../supabase/supabase_client.dart';

class OwnerRepository {
  final SupabaseService _supabase = SupabaseService();

  static const _bookingSelect = '''
    *,
    stations!inner(
      id, name, room_id,
      rooms!inner(
        id, name, type, cyber_id,
        cybers!inner(id, name, owner_id)
      )
    )
  ''';

  Future<List<Cyber>> getOwnerCybers(String ownerId) async {
    final response =
        await _supabase.from('cybers').select().eq('owner_id', ownerId);
    return (response as List).map((c) => Cyber.fromMap(c)).toList();
  }

  Future<List<OwnerBookingItem>> getOwnerBookingsForDay(
    String ownerId,
    DateTime day,
  ) async {
    final start = DateTime(day.year, day.month, day.day);
    final end = start.add(const Duration(days: 1));

    final response = await _supabase
        .from('bookings')
        .select(_bookingSelect)
        .gte('start_time', start.toUtc().toIso8601String())
        .lt('start_time', end.toUtc().toIso8601String())
        .eq('stations.rooms.cybers.owner_id', ownerId)
        .order('start_time');

    return (response as List)
        .map((b) => OwnerBookingItem.fromMap(b as Map<String, dynamic>))
        .toList();
  }

  Future<List<OwnerBookingItem>> getOwnerTodayTimeline(String ownerId) async {
    return getOwnerBookingsForDay(ownerId, DateTime.now());
  }

  Future<OwnerDashboardStats> getDashboardStats(String ownerId) async {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final yesterdayStart = todayStart.subtract(const Duration(days: 1));

    final todayBookings = await getOwnerBookingsForDay(ownerId, today);
    final yesterdayBookings =
        await getOwnerBookingsForDay(ownerId, yesterdayStart);

    double sumRevenue(List<OwnerBookingItem> list) {
      return list
          .where((b) => b.status == 'confirmed' || b.status == 'completed')
          .fold(0.0, (s, b) => s + b.totalAmount);
    }

    final todayRevenue = sumRevenue(todayBookings);
    final yesterdayRevenue = sumRevenue(yesterdayBookings);
    final revenueChange = yesterdayRevenue == 0
        ? (todayRevenue > 0 ? 100.0 : 0.0)
        : ((todayRevenue - yesterdayRevenue) / yesterdayRevenue) * 100;

    final now = DateTime.now();
    var active = 0;
    for (final b in todayBookings) {
      if (b.status == 'confirmed' &&
          !now.isBefore(b.startTime) &&
          now.isBefore(b.endTime)) {
        active++;
      }
    }

    final stations = await getOwnerStations(ownerId);
    final pendingPayments = todayBookings
        .where((b) =>
            b.status == 'pending_payment' || b.status == 'fee_under_review')
        .length;

    return OwnerDashboardStats(
      todayRevenue: todayRevenue,
      revenueChangePercent: revenueChange,
      todayBookings: todayBookings.length,
      confirmedToday:
          todayBookings.where((b) => b.status == 'confirmed').length,
      pendingToday: todayBookings
          .where((b) =>
              b.status == 'pending_payment' || b.status == 'fee_under_review')
          .length,
      activeStations: active,
      totalStations: stations.length,
      manualBookingsToday: todayBookings.where((b) => b.isManual).length,
      pendingReceipts: pendingPayments,
    );
  }

  Future<List<OwnerStationItem>> getOwnerStations(String ownerId) async {
    final response = await _supabase.from('stations').select('''
          id, name, status, room_id,
          rooms!inner(id, name, cyber_id, cybers!inner(owner_id))
        ''').eq('rooms.cybers.owner_id', ownerId);

    return (response as List)
        .map((s) => OwnerStationItem.fromMap(s as Map<String, dynamic>))
        .toList();
  }

  Future<List<Room>> getOwnerRooms(String ownerId) async {
    final cybers = await getOwnerCybers(ownerId);
    if (cybers.isEmpty) return [];

    final ids = cybers.map((c) => c.id).toList();
    final response = await _supabase
        .from('rooms')
        .select()
        .inFilter('cyber_id', ids)
        .eq('is_active', true);

    return (response as List).map((r) => Room.fromMap(r)).toList();
  }

  Future<List<Station>> getRoomStationsAll(String roomId) async {
    final response =
        await _supabase.from('stations').select().eq('room_id', roomId);
    return (response as List).map((s) => Station.fromMap(s)).toList();
  }

  Future<Booking> createManualBooking({
    required String ownerUserId,
    required String stationId,
    required DateTime startTime,
    required double durationHours,
    required double totalAmount,
    String? guestName,
  }) async {
    final endTime = startTime.add(Duration(hours: durationHours.round()));

    final data = {
      'user_id': ownerUserId,
      'station_id': stationId,
      'start_time': startTime.toUtc().toIso8601String(),
      'end_time': endTime.toUtc().toIso8601String(),
      'duration_hours': durationHours,
      'total_amount': totalAmount,
      'booking_fee': 0,
      'status': 'confirmed',
      'source': 'manual',
      'notes': 'manual_walk_in',
      if (guestName != null && guestName.trim().isNotEmpty)
        'guest_name': guestName.trim(),
      'confirmed_at': DateTime.now().toIso8601String(),
    };

    final response =
        await _supabase.from('bookings').insert(data).select().single();
    return Booking.fromMap(response);
  }

  /// Polls today's bookings for near-real-time dashboard updates.
  Stream<List<OwnerBookingItem>> watchOwnerTodayBookings(String ownerId) async* {
    yield await getOwnerTodayTimeline(ownerId);
    yield* Stream.periodic(const Duration(seconds: 6), (_) => ownerId)
        .asyncMap(getOwnerTodayTimeline);
  }

  /// Progressive onboarding: auth user + cyber + rooms + stations.
  Future<Cyber> completeOwnerOnboarding(OnboardingSubmitPayload payload) async {
    final auth = _supabase.auth;
    final signUp = await auth.signUp(
      email: payload.email.trim(),
      password: payload.password,
      data: {'name': payload.cyberName, 'role': 'owner'},
    );
    if (signUp.user == null) {
      throw Exception('Failed to create account');
    }
    final userId = signUp.user!.id;

    await _supabase.from('profiles').upsert({
      'id': userId,
      'name': payload.cyberName,
      'role': 'owner',
    });

    final cyberPayload = OnboardingCyberPayload(
      name: payload.cyberName,
      description: payload.description,
      address: payload.address,
      city: payload.city,
      coverImage: payload.coverImage,
      workingHoursFrom: payload.workingHoursFrom,
      workingHoursTo: payload.workingHoursTo,
    );

    final cyberRow = await _supabase
        .from('cybers')
        .insert(cyberPayload.toInsertMap(ownerId: userId))
        .select()
        .single();

    final cyber = Cyber.fromMap(cyberRow);
    await _createRoomsForCyber(cyber.id, payload.rooms);
    return cyber;
  }

  /// Logged-in owner with no cyber yet (profile "Complete setup").
  Future<Cyber> completeCyberSetupForExistingOwner({
    required String ownerUserId,
    required OnboardingCyberPayload cyber,
    required List<OnboardingRoomSelection> rooms,
  }) async {
    final existing = await getOwnerCybers(ownerUserId);
    if (existing.isNotEmpty) {
      throw Exception('You already have a gaming center registered');
    }

    final cyberRow = await _supabase
        .from('cybers')
        .insert(cyber.toInsertMap(ownerId: ownerUserId))
        .select()
        .single();

    final created = Cyber.fromMap(cyberRow);
    await _createRoomsForCyber(created.id, rooms);
    return created;
  }

  Future<void> _createRoomsForCyber(
    String cyberId,
    List<OnboardingRoomSelection> rooms,
  ) async {
    for (final room in rooms) {
      final roomRow = await _supabase
          .from('rooms')
          .insert({
            'cyber_id': cyberId,
            'name': room.displayName,
            'type': room.dbType,
            'price_per_hour': room.pricePerHour,
            // Use defaults here or pass from UI if onboarding supports it. For now, leave null so DB can use defaults if any, or null to fall back to Room getter.
            'is_active': true,
          })
          .select()
          .single();

      final roomId = roomRow['id'] as String;
      for (var i = 1; i <= room.stationCount; i++) {
        await _supabase.from('stations').insert({
          'room_id': roomId,
          'name': 'محطة $i',
          'status': 'active',
        });
      }
    }
  }

  Future<List<CyberRoomProfile>> getCyberRoomsWithStations(String cyberId) async {
    final response = await _supabase.from('rooms').select('''
          *,
          stations(id, name, status, room_id, created_at)
        ''').eq('cyber_id', cyberId).order('created_at');

    return (response as List)
        .map((r) => CyberRoomProfile.fromMap(r as Map<String, dynamic>))
        .toList();
  }

  Future<Cyber> updateCyberProfile({
    required String cyberId,
    required String ownerId,
    required CyberProfileInput input,
  }) async {
    try {
      final updates = input.toUpdateMap();
      if (updates.isEmpty) {
        return await getCyberByIdForOwner(cyberId, ownerId);
      }

      final row = await _supabase
          .from('cybers')
          .update(updates)
          .eq('id', cyberId)
          .eq('owner_id', ownerId)
          .select()
          .single();
      return Cyber.fromMap(row);
    } on PostgrestException catch (e) {
      throw Exception(supabaseErrorMessage(e));
    } catch (e) {
      throw Exception(supabaseErrorMessage(e));
    }
  }

  Future<Cyber> getCyberByIdForOwner(String cyberId, String ownerId) async {
    try {
      final row = await _supabase
          .from('cybers')
          .select()
          .eq('id', cyberId)
          .eq('owner_id', ownerId)
          .single();
      return Cyber.fromMap(row);
    } on PostgrestException catch (e) {
      throw Exception(supabaseErrorMessage(e));
    }
  }

  Future<Room> addRoomWithStations({
    required String cyberId,
    required String name,
    required String type,
    required double pricePerHour,
    double? bookingFee,
    required int stationCount,
  }) async {
    final roomRow = await _supabase
        .from('rooms')
        .insert({
          'cyber_id': cyberId,
          'name': name,
          'type': type,
          'price_per_hour': pricePerHour,
          if (bookingFee != null) 'booking_fee': bookingFee,
          'is_active': true,
        })
        .select()
        .single();

    final roomId = roomRow['id'] as String;
    for (var i = 1; i <= stationCount; i++) {
      await _supabase.from('stations').insert({
        'room_id': roomId,
        'name': 'محطة $i',
        'status': 'active',
      });
    }
    return Room.fromMap(roomRow);
  }

  Future<void> deleteRoomCascade(String roomId) async {
    await _supabase.from('rooms').update({'is_active': false}).eq('id', roomId);
  }

  Future<Station> addStation({
    required String roomId,
    required String name,
  }) async {
    final row = await _supabase
        .from('stations')
        .insert({
          'room_id': roomId,
          'name': name,
          'status': 'active',
        })
        .select()
        .single();
    return Station.fromMap(row);
  }

  Future<void> deleteStation(String stationId) async {
    try {
      await _supabase.from('stations').delete().eq('id', stationId);
    } on PostgrestException catch (e) {
      if (e.code == '23503') {
        throw Exception('Cannot delete station because it has associated bookings.');
      }
      rethrow;
    }
  }

  // --- Inventory Management ---
  
  Future<List<CyberInventoryItem>> getInventoryItems(String cyberId) async {
    final response = await _supabase
        .from('cyber_inventory_items')
        .select()
        .eq('cyber_id', cyberId)
        .order('created_at');
    return (response as List).map((i) => CyberInventoryItem.fromMap(i)).toList();
  }

  Future<CyberInventoryItem> addInventoryItem(CyberInventoryItem item) async {
    final row = await _supabase
        .from('cyber_inventory_items')
        .insert(item.toInsertMap())
        .select()
        .single();
    return CyberInventoryItem.fromMap(row);
  }

  Future<void> toggleInventoryItemStatus(String itemId, bool isActive) async {
    await _supabase
        .from('cyber_inventory_items')
        .update({'is_active': isActive})
        .eq('id', itemId);
  }

  // --- Booking Items Management ---
  
  Future<List<BookingItem>> getBookingItems(String bookingId) async {
    final response = await _supabase
        .from('booking_items')
        .select('*, cyber_inventory_items(*)')
        .eq('booking_id', bookingId);
    return (response as List).map((i) => BookingItem.fromMap(i)).toList();
  }

  Future<BookingItem> addBookingItem({
    required String bookingId,
    required CyberInventoryItem item,
    required int quantity,
  }) async {
    final totalPrice = item.price * quantity;
    final row = await _supabase.from('booking_items').insert({
      'booking_id': bookingId,
      'item_id': item.id,
      'quantity': quantity,
      'price_at_time': item.price,
      'total_price': totalPrice,
    }).select('*, cyber_inventory_items(*)').single();

    // Fetch current total and add only once (avoids double-count from RPC + manual update)
    final bookingRaw = await _supabase.from('bookings').select('total_amount').eq('id', bookingId).single();
    final currentTotal = (bookingRaw['total_amount'] as num).toDouble();
    await _supabase.from('bookings').update({'total_amount': currentTotal + totalPrice}).eq('id', bookingId);

    return BookingItem.fromMap(row);
  }

  Future<void> stopBookingEarly(String bookingId) async {
    // 1. Fetch booking and the room's hourly price
    final bookingRaw = await _supabase
        .from('bookings')
        .select('*, stations!inner(rooms!inner(price_per_hour))')
        .eq('id', bookingId)
        .single();
    
    final startTime = DateTime.parse(bookingRaw['start_time']);
    final bookingFee = (bookingRaw['booking_fee'] as num).toDouble();
    
    // Parse the joined data safely
    final stationData = bookingRaw['stations'] as Map<String, dynamic>;
    final roomData = stationData['rooms'] as Map<String, dynamic>;
    final pricePerHour = (roomData['price_per_hour'] as num).toDouble();
    
    // 2. Calculate time stayed in 30-min blocks
    final now = DateTime.now();
    int minutesStayed = now.difference(startTime).inMinutes;
    if (minutesStayed < 0) minutesStayed = 0;
    
    int blocks = (minutesStayed / 30.0).ceil();
    if (blocks == 0) blocks = 1; // Minimum 30 min charge
    
    final newRoomCost = blocks * (pricePerHour / 2);
    final newDurationHours = blocks * 0.5;
    
    // 3. Get any additional items cost
    final itemsRes = await _supabase.from('booking_items').select('total_price').eq('booking_id', bookingId);
    final itemsCost = (itemsRes as List).fold<double>(0.0, (sum, row) => sum + (row['total_price'] as num).toDouble());
    
    // 4. Update the booking
    final newTotalAmount = newRoomCost + bookingFee + itemsCost;
    
    await _supabase.from('bookings').update({
      'end_time': now.toIso8601String(),
      'duration_hours': newDurationHours,
      'total_amount': newTotalAmount,
      'status': 'completed',
    }).eq('id', bookingId);
  }

  Future<Map<String, dynamic>> previewStopBookingEarly(String bookingId) async {
    final bookingRaw = await _supabase
        .from('bookings')
        .select('*, stations!inner(rooms!inner(price_per_hour))')
        .eq('id', bookingId)
        .single();
    
    final startTime = DateTime.parse(bookingRaw['start_time']);
    final bookingFee = (bookingRaw['booking_fee'] as num).toDouble();
    
    final stationData = bookingRaw['stations'] as Map<String, dynamic>;
    final roomData = stationData['rooms'] as Map<String, dynamic>;
    final pricePerHour = (roomData['price_per_hour'] as num).toDouble();
    
    final now = DateTime.now();
    int minutesStayed = now.difference(startTime).inMinutes;
    if (minutesStayed < 0) minutesStayed = 0;
    
    int blocks = (minutesStayed / 30.0).ceil();
    if (blocks == 0) blocks = 1;
    
    final newRoomCost = blocks * (pricePerHour / 2);
    
    final itemsRes = await _supabase.from('booking_items').select('total_price').eq('booking_id', bookingId);
    final itemsCost = (itemsRes as List).fold<double>(0.0, (sum, row) => sum + (row['total_price'] as num).toDouble());
    
    final newTotalAmount = newRoomCost + bookingFee + itemsCost;
    
    return {
      'newTotalAmount': newTotalAmount,
      'minutesStayed': minutesStayed,
    };
  }

  Future<void> cancelBooking(String bookingId) async {
    await _supabase
        .from('bookings')
        .update({'status': 'cancelled'})
        .eq('id', bookingId);
  }

  Future<Booking> getBookingById(String bookingId) async {
    final response = await _supabase
        .from('bookings')
        .select(_bookingSelect)
        .eq('id', bookingId)
        .single();
    return Booking.fromMap(response);
  }

  Future<void> completeBooking(String bookingId) async {
    await _supabase
        .from('bookings')
        .update({'status': 'completed'})
        .eq('id', bookingId);
  }
}
