import '../models/cyber.dart';
import '../supabase/supabase_client.dart';

class CyberRepository {
  final SupabaseService _supabase = SupabaseService();

  // Get all gaming centers (for public use — active only)
  Future<List<Cyber>> getAllCybers() async {
    try {
      final response =
          await _supabase.from('cybers').select().eq('is_active', true);

      return (response as List).map((cyber) => Cyber.fromMap(cyber)).toList();
    } catch (e) {
      throw Exception('Failed to fetch cybers: $e');
    }
  }

  // Get ALL cybers regardless of status (admin use only)
  Future<List<Cyber>> getAllCybersAdmin() async {
    try {
      final response = await _supabase
          .from('cybers')
          .select()
          .order('created_at', ascending: false);

      return (response as List).map((cyber) => Cyber.fromMap(cyber)).toList();
    } catch (e) {
      throw Exception('Failed to fetch all cybers for admin: $e');
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
    String? workingHoursFrom,
    String? workingHoursTo,
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
        'is_featured': false,
        'is_active': true,
        if (workingHoursFrom != null) 'working_hours_from': workingHoursFrom,
        if (workingHoursTo != null) 'working_hours_to': workingHoursTo,
        'created_at': DateTime.now().toIso8601String(),
      };

      final response =
          await _supabase.from('cybers').insert(cyberData).select().single();

      return Cyber.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create cyber: $e');
    }
  }

  // Update cover image
  Future<void> updateCoverImage(String cyberId, String coverImageUrl) async {
    try {
      await _supabase
          .from('cybers')
          .update({'cover_image': coverImageUrl})
          .eq('id', cyberId);
    } catch (e) {
      throw Exception('Failed to update cover image: $e');
    }
  }

  // Update gallery images
  Future<void> updateGalleryImages(String cyberId, List<String> galleryImages) async {
    try {
      await _supabase
          .from('cybers')
          .update({'images': galleryImages})
          .eq('id', cyberId);
    } catch (e) {
      throw Exception('Failed to update gallery images: $e');
    }
  }

  // Add gallery image
  Future<void> addGalleryImage(String cyberId, String imageUrl) async {
    try {
      final cyber = await getCyberById(cyberId);
      if (cyber == null) throw Exception('Cyber not found');

      final updatedImages = List<String>.from(cyber.images)..add(imageUrl);
      await updateGalleryImages(cyberId, updatedImages);
    } catch (e) {
      throw Exception('Failed to add gallery image: $e');
    }
  }

  // Remove gallery image
  Future<void> removeGalleryImage(String cyberId, String imageUrl) async {
    try {
      final cyber = await getCyberById(cyberId);
      if (cyber == null) throw Exception('Cyber not found');

      final updatedImages = List<String>.from(cyber.images)..remove(imageUrl);
      await updateGalleryImages(cyberId, updatedImages);
    } catch (e) {
      throw Exception('Failed to remove gallery image: $e');
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

  // Update cyber subscription
  Future<void> updateCyberSubscription({
    required String cyberId,
    required String subscriptionPlan,
    required String subscriptionBilling,
    DateTime? subscriptionEndDate,
  }) async {
    try {
      final updateData = {
        'subscription_plan': subscriptionPlan,
        'subscription_billing': subscriptionBilling,
        'subscription_end_date': subscriptionEndDate?.toIso8601String(),
      };

      await _supabase
          .from('cybers')
          .update(updateData)
          .eq('id', cyberId);
    } catch (e) {
      throw Exception('Failed to update cyber subscription: $e');
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

  // Get featured cybers with pagination
  Future<List<Cyber>> getFeaturedCybers(
      {int limit = 10, int offset = 0}) async {
    try {
      final response = await _supabase
          .from('cybers')
          .select()
          .eq('is_featured', true)
          .eq('is_active', true)
          .order('rating', ascending: false)
          .range(offset, offset + limit - 1);

      return (response as List).map((cyber) => Cyber.fromMap(cyber)).toList();
    } catch (e) {
      throw Exception('Failed to fetch featured cybers: $e');
    }
  }

  // Get cybers sorted by rating
  Future<List<Cyber>> getTopRatedCybers({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('cybers')
          .select()
          .eq('is_active', true)
          .order('rating', ascending: false)
          .limit(limit);

      return (response as List).map((cyber) => Cyber.fromMap(cyber)).toList();
    } catch (e) {
      throw Exception('Failed to fetch top rated cybers: $e');
    }
  }

  // Get cybers by type (ps5, pc, vip)
  Future<List<Cyber>> getCybersByType(String type) async {
    try {
      // Get all cybers first, then filter by room type
      final cybers = await _supabase
          .from('cybers')
          .select()
          .eq('is_active', true)
          .order('rating', ascending: false);

      final cyberIds = (cybers as List).map((c) => c['id']).toList();

      if (cyberIds.isEmpty) return [];

      final rooms = await _supabase
          .from('rooms')
          .select('cyber_id')
          .eq('type', type)
          .inFilter('cyber_id', cyberIds);

      final cyberIdsWithType =
          (rooms as List).map((r) => r['cyber_id']).toSet();

      return (cybers as List)
          .where((cyber) => cyberIdsWithType.contains(cyber['id']))
          .map((cyber) => Cyber.fromMap(cyber as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch cybers by type: $e');
    }
  }

  // Get recent cybers
  Future<List<Cyber>> getRecentCybers({int limit = 10}) async {
    try {
      final response = await _supabase
          .from('cybers')
          .select()
          .eq('is_active', true)
          .order('created_at', ascending: false)
          .limit(limit);

      return (response as List).map((cyber) => Cyber.fromMap(cyber)).toList();
    } catch (e) {
      throw Exception('Failed to fetch recent cybers: $e');
    }
  }

  // Update cyber rating (called after review submission)
  Future<void> updateCyberRating(String cyberId, double newRating) async {
    try {
      await _supabase
          .from('cybers')
          .update({'rating': newRating}).eq('id', cyberId);
    } catch (e) {
      throw Exception('Failed to update cyber rating: $e');
    }
  }

  // Increment review count
  Future<void> incrementReviewCount(String cyberId) async {
    try {
      // First get current count
      final cyber = await _supabase
          .from('cybers')
          .select('review_count')
          .eq('id', cyberId)
          .single();

      final currentCount = (cyber['review_count'] as int?) ?? 0;

      // Then update with incremented count
      await _supabase
          .from('cybers')
          .update({'review_count': currentCount + 1}).eq('id', cyberId);
    } catch (e) {
      throw Exception('Failed to increment review count: $e');
    }
  }
}
