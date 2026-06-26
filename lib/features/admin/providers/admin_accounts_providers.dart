import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/cyber.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/cyber_repository.dart';
import '../../../data/repositories/user_repository.dart';

final allCybersProvider = FutureProvider.autoDispose<List<Cyber>>((ref) async {
  return await CyberRepository().getAllCybers();
});

final allUsersProvider =
    FutureProvider.autoDispose<List<AppUser>>((ref) async {
  return await UserRepository().getAllUsers();
});

/// Provider that fetches enriched bookings for a given userId.
final userBookingsProvider = FutureProvider.autoDispose
    .family<List<Map<String, dynamic>>, String>((ref, userId) async {
  final data = await Supabase.instance.client.from('bookings').select('''
    id, status, start_time, end_time, total_amount, booking_fee,
    created_at, notes, confirmed_at,
    stations(
      name,
      rooms(
        name, type,
        cybers(name, city)
      )
    )
  ''').eq('user_id', userId).order('created_at', ascending: false);
  return (data as List).cast<Map<String, dynamic>>();
});
