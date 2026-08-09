import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../data/models/cyber.dart';
import '../../../data/models/user.dart';
import '../../../data/repositories/cyber_repository.dart';
import '../../../data/repositories/user_repository.dart';

final allCybersProvider = FutureProvider.autoDispose<List<Cyber>>((ref) async {
  return await CyberRepository().getAllCybersAdmin();
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

/// Provider that fetches the wallet for a specific user ID.
final adminUserWalletProvider = FutureProvider.autoDispose
    .family<Map<String, dynamic>?, String>((ref, userId) async {
  final response = await Supabase.instance.client
      .from('wallets')
      .select()
      .eq('user_id', userId)
      .maybeSingle();
  return response;
});

/// Provider that fetches the short_id for a specific user ID (from profiles table).
final adminUserShortIdProvider = FutureProvider.autoDispose
    .family<String?, String>((ref, userId) async {
  final response = await Supabase.instance.client
      .from('profiles')
      .select('short_id')
      .eq('id', userId)
      .maybeSingle();
  return response?['short_id'] as String?;
});
