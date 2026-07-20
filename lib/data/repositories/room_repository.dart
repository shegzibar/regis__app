import '../models/room.dart';
import '../supabase/supabase_client.dart';

class RoomRepository {
  final SupabaseService _supabase = SupabaseService();

  // Get rooms for a cyber
  Future<List<Room>> getCyberRooms(String cyberId) async {
    try {
      final response = await _supabase
          .from('rooms')
          .select()
          .eq('cyber_id', cyberId)
          .eq('is_active', true);

      return (response as List).map((room) => Room.fromMap(room)).toList();
    } catch (e) {
      throw Exception('Failed to fetch cyber rooms: $e');
    }
  }

  // Get room by ID
  Future<Room?> getRoomById(String roomId) async {
    try {
      final response =
          await _supabase.from('rooms').select().eq('id', roomId).maybeSingle();

      if (response != null) {
        return Room.fromMap(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch room: $e');
    }
  }

  // Get rooms by type
  Future<List<Room>> getRoomsByType(String cyberId, String roomType) async {
    try {
      final response = await _supabase
          .from('rooms')
          .select()
          .eq('cyber_id', cyberId)
          .eq('type', roomType)
          .eq('is_active', true);

      return (response as List).map((room) => Room.fromMap(room)).toList();
    } catch (e) {
      throw Exception('Failed to fetch rooms by type: $e');
    }
  }

  // Create room
  Future<Room> createRoom({
    required String cyberId,
    required String name,
    required String type,
    required double pricePerHour,
    String? description,
  }) async {
    try {
      final roomData = {
        'cyber_id': cyberId,
        'name': name,
        'type': type,
        'price_per_hour': pricePerHour,
        'description': description,
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response =
          await _supabase.from('rooms').insert(roomData).select().single();

      return Room.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create room: $e');
    }
  }

  // Update room
  Future<Room> updateRoom({
    required String roomId,
    String? name,
    double? pricePerHour,
    String? description,
    bool? isActive,
    String? type,
    List<String>? images,
    String? imageUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (pricePerHour != null) updateData['price_per_hour'] = pricePerHour;
      if (description != null) updateData['description'] = description;
      if (isActive != null) updateData['is_active'] = isActive;
      if (type != null) updateData['type'] = type;
      if (images != null) updateData['images'] = images;
      if (imageUrl != null) updateData['image_url'] = imageUrl;

      final response = await _supabase
          .from('rooms')
          .update(updateData)
          .eq('id', roomId)
          .select()
          .single();

      return Room.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update room: $e');
    }
  }

  // Delete room
  Future<void> deleteRoom(String roomId) async {
    try {
      await _supabase.from('rooms').delete().eq('id', roomId);
    } catch (e) {
      throw Exception('Failed to delete room: $e');
    }
  }
}
