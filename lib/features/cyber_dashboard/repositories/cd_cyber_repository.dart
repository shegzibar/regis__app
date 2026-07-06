import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/cyber.dart';
import '../../../data/models/room.dart';
import '../../../data/models/station.dart';
import '../../../data/models/user.dart';

final _db = Supabase.instance.client;

class CdCyberRepository {
  /// Get the cyber owned by [ownerId]. Returns null if none found.
  Future<Cyber?> getCyberByOwner(String ownerId) async {
    final data = await _db
        .from('cybers')
        .select()
        .eq('owner_id', ownerId)
        .maybeSingle();
    return data != null ? Cyber.fromMap(data) : null;
  }

  /// All active rooms for a cyber, ordered by creation date.
  Future<List<Room>> getRooms(String cyberId) async {
    final data = await _db
        .from('rooms')
        .select()
        .eq('cyber_id', cyberId)
        .eq('is_active', true)
        .order('created_at');
    return (data as List).map((r) => Room.fromMap(r)).toList();
  }

  /// All stations for a room, ordered by name.
  Future<List<Station>> getStations(String roomId) async {
    final data = await _db
        .from('stations')
        .select()
        .eq('room_id', roomId)
        .order('name');
    return (data as List).map((s) => Station.fromMap(s)).toList();
  }

  /// Update any fields on a cyber row.
  Future<void> updateCyber(String cyberId, Map<String, dynamic> updates) async {
    await _db.from('cybers').update(updates).eq('id', cyberId);
  }

  /// Update the price of a single room.
  Future<void> updateRoomPrice(String roomId, double price) async {
    await _db
        .from('rooms')
        .update({'price_per_hour': price})
        .eq('id', roomId);
  }

  /// Update the image of a room.
  Future<void> updateRoomImage(String roomId, String imageUrl) async {
    await _db
        .from('rooms')
        .update({'image_url': imageUrl})
        .eq('id', roomId);
  }

  /// Add a new room to a cyber, and automatically create its single station.
  Future<void> addRoom({
    required String cyberId,
    required String name,
    required String type,
    required double pricePerHour,
    String? description,
  }) async {
    final room = await _db.from('rooms').insert({
      'cyber_id': cyberId,
      'name': name,
      'type': type,
      'price_per_hour': pricePerHour,
      'description': description,
      'is_active': true,
    }).select('id').single();

    await _db.from('stations').insert({
      'room_id': room['id'],
      'name': name,
      'status': 'active',
    });
  }

  /// Soft-delete a room by marking it inactive.
  Future<void> deleteRoom(String roomId) async {
    await _db.from('rooms').update({'is_active': false}).eq('id', roomId);
  }

  /// Add a new station to a room.
  Future<void> addStation({
    required String roomId,
    required String name,
  }) async {
    await _db.from('stations').insert({
      'room_id': roomId,
      'name': name,
      'status': 'active',
    });
  }

  /// Update the status of a station: 'active' | 'maintenance' | 'blocked'.
  Future<void> updateStationStatus(String stationId, String status) async {
    await _db
        .from('stations')
        .update({'status': status})
        .eq('id', stationId);
  }

  /// Get the owner profile for a cyber.
  /// Note: The current schema has no workers/staff table and profiles has no
  /// cyber_id column. This returns the cyber owner's profile.
  /// To support multiple workers per cyber, add a cyber_workers join table.
  Future<List<AppUser>> getWorkers(String cyberId) async {
    try {
      // Get the owner_id for this cyber
      final cyberData = await _db
          .from('cybers')
          .select('owner_id')
          .eq('id', cyberId)
          .maybeSingle();

      if (cyberData == null) return [];

      final ownerId = cyberData['owner_id'] as String?;
      if (ownerId == null) return [];

      // Fetch the owner's profile
      final data = await _db
          .from('profiles')
          .select()
          .eq('id', ownerId)
          .maybeSingle();

      if (data == null) return [];
      return [AppUser.fromMap(data)];
    } catch (e) {
      debugPrint('getWorkers failed: $e');
      return [];
    }
  }
}
