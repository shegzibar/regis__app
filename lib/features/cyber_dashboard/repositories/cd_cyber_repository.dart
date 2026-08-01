import 'package:flutter/foundation.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/constants/app_constants.dart';
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

  /// Get the workers for a cyber (users where cyber_id = cyberId and role = 'manager').
  Future<List<AppUser>> getWorkers(String cyberId) async {
    try {
      final data = await _db
          .from('profiles')
          .select()
          .eq('cyber_id', cyberId)
          .inFilter('role', ['manager', 'worker']);
      return (data as List).map((p) => AppUser.fromMap(p)).toList();
    } catch (e) {
      debugPrint('getWorkers failed: $e');
      return [];
    }
  }

  /// Add a new worker account via raw HTTP request to avoid signing out the current owner.
  Future<void> addWorker({
    required String cyberId,
    required String name,
    required String email,
    required String password,
    String role = 'manager',
  }) async {
    // Use raw HTTP request to /auth/v1/signup
    // This allows creating an account without modifying the active session in Supabase SDK.
    final authUrl = '${AppConstants.supabaseUrl}/auth/v1/signup';
    final anonKey = AppConstants.supabaseAnonKey;

    final response = await http.post(
      Uri.parse(authUrl),
      headers: {
        'apikey': anonKey,
        'Content-Type': 'application/json',
      },
      body: jsonEncode({
        'email': email,
        'password': password,
        'data': {
          'name': name,
          'role': role,
          'cyber_id': cyberId,
        }
      }),
    );

    if (response.statusCode >= 400) {
      final body = jsonDecode(response.body);
      throw Exception(body['msg'] ?? 'Failed to create worker account');
    }

    final resBody = jsonDecode(response.body);
    final userId = resBody['user']['id'];

    // The backend trigger handles creating the profile. We just need to ensure the profile is updated with the correct role and cyber_id.
    await _db.from('profiles').update({
      'role': role,
      'cyber_id': cyberId,
    }).eq('id', userId);
  }

  Future<void> updateWorker({
    required String userId,
    required String name,
    required String role,
  }) async {
    await _db.from('profiles').update({
      'name': name,
      'role': role,
    }).eq('id', userId);
  }

  Future<void> removeWorker({
    required String userId,
  }) async {
    // Revoke access by setting cyber_id to null and role back to user
    await _db.from('profiles').update({
      'cyber_id': null,
      'role': 'user',
    }).eq('id', userId);
  }
}
