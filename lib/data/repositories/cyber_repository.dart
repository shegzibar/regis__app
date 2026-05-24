import '../models/cyber.dart';
import '../supabase/supabase_client.dart';

class CyberRepository {
  final SupabaseService _supabase = SupabaseService();

  // Get all gaming centers
  Future<List<Cyber>> getAllCybers() async {
    try {
      final response =
          await _supabase.from('cybers').select().eq('is_active', true);

      return (response as List).map((cyber) => Cyber.fromMap(cyber)).toList();
    } catch (e) {
      throw Exception('Failed to fetch cybers: $e');
    }
  }

  // Get cyber by ID
  Future<Cyber?> getCyberById(String cyberId) async {
    try {
      final response = await _supabase
          .from('cybers')
          .select()
          .eq('id', cyberId)
          .maybeSingle();

      if (response != null) {
        return Cyber.fromMap(response);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to fetch cyber: $e');
    }
  }

  // Search cybers by name or city
  Future<List<Cyber>> searchCybers(String query) async {
    try {
      final response = await _supabase
          .from('cybers')
          .select()
          .or('name.ilike.%$query%,city.ilike.%$query%')
          .eq('is_active', true);

      return (response as List).map((cyber) => Cyber.fromMap(cyber)).toList();
    } catch (e) {
      throw Exception('Failed to search cybers: $e');
    }
  }

  // Get cybers by owner
  Future<List<Cyber>> getCybersByOwner(String ownerId) async {
    try {
      final response =
          await _supabase.from('cybers').select().eq('owner_id', ownerId);

      return (response as List).map((cyber) => Cyber.fromMap(cyber)).toList();
    } catch (e) {
      throw Exception('Failed to fetch owner cybers: $e');
    }
  }

  // Get cybers by city
  Future<List<Cyber>> getCybersByCity(String city) async {
    try {
      final response = await _supabase
          .from('cybers')
          .select()
          .eq('city', city)
          .eq('is_active', true);

      return (response as List).map((cyber) => Cyber.fromMap(cyber)).toList();
    } catch (e) {
      throw Exception('Failed to fetch cybers by city: $e');
    }
  }

  // Create cyber (owner only)
  Future<Cyber> createCyber({
    required String ownerId,
    required String name,
    String? description,
    String? address,
    String? city,
    double? lat,
    double? lng,
    List<String>? images,
  }) async {
    try {
      final cyberData = {
        'owner_id': ownerId,
        'name': name,
        'description': description,
        'address': address,
        'city': city,
        'lat': lat,
        'lng': lng,
        'images': images ?? [],
        'is_active': true,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response =
          await _supabase.from('cybers').insert(cyberData).select().single();

      return Cyber.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create cyber: $e');
    }
  }

  // Update cyber
  Future<Cyber> updateCyber({
    required String cyberId,
    String? name,
    String? description,
    String? address,
    String? city,
    double? lat,
    double? lng,
    List<String>? images,
    String? workingHoursFrom,
    String? workingHoursTo,
    bool? isActive,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (name != null) updateData['name'] = name;
      if (description != null) updateData['description'] = description;
      if (address != null) updateData['address'] = address;
      if (city != null) updateData['city'] = city;
      if (lat != null) updateData['lat'] = lat;
      if (lng != null) updateData['lng'] = lng;
      if (images != null) updateData['images'] = images;
      if (workingHoursFrom != null)
        updateData['working_hours_from'] = workingHoursFrom;
      if (workingHoursTo != null)
        updateData['working_hours_to'] = workingHoursTo;
      if (isActive != null) updateData['is_active'] = isActive;

      final response = await _supabase
          .from('cybers')
          .update(updateData)
          .eq('id', cyberId)
          .select()
          .single();

      return Cyber.fromMap(response);
    } catch (e) {
      throw Exception('Failed to update cyber: $e');
    }
  }

  // Delete cyber
  Future<void> deleteCyber(String cyberId) async {
    try {
      await _supabase.from('cybers').delete().eq('id', cyberId);
    } catch (e) {
      throw Exception('Failed to delete cyber: $e');
    }
  }
}
