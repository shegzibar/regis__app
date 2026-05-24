import '../models/station.dart';
import '../supabase/supabase_client.dart';

class StationRepository {
  final SupabaseService _supabase = SupabaseService();

  // Get stations for a room
  Future<List<Station>> getRoomStations(String roomId) async {
    try {
      final response = await _supabase
          .from('stations')
          .select()
          .eq('room_id', roomId)
          .eq('status', 'active');

      return (response as List)
          .map((station) => Station.fromMap(station))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch room stations: $e');
    }
  }

  // Get station by ID
  Future<Station?> getStationById(String stationId) async {
    try {
      final response = await _supabase
          .from('stations')
          .select()
          .eq('id', stationId)
          .maybeSingle();

      if (response != null) {
        return Station.fromMap(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch station: $e');
    }
  }

  // Create station
  Future<Station> createStation({
    required String roomId,
    required String name,
    String status = 'active',
  }) async {
    try {
      final stationData = {
        'room_id': roomId,
        'name': name,
        'status': status,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response = await _supabase
          .from('stations')
          .insert(stationData)
          .select()
          .single();

      return Station.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create station: $e');
    }
  }

  // Update station status
  Future<Station> updateStationStatus({
    required String stationId,
    required String newStatus,
  }) async {
    try {
      final response = await _supabase
          .from('stations')
          .update({'status': newStatus})
          .eq('id', stationId)
          .select()
          .single();

      return Station.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update station status: $e');
    }
  }

  // Delete station
  Future<void> deleteStation(String stationId) async {
    try {
      await _supabase.from('stations').delete().eq('id', stationId);
    } catch (e) {
      throw Exception('Failed to delete station: $e');
    }
  }
}
