import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cyber.dart';
import '../../data/models/cyber_room_profile.dart';
import '../../data/repositories/cyber_repository.dart';
import 'auth_provider.dart';
import 'owner_dashboard_provider.dart';

final cyberProfileRoomsProvider = FutureProvider.autoDispose
    .family<List<CyberRoomProfile>, String>((ref, cyberId) async {
  return ref.read(ownerRepositoryProvider).getCyberRoomsWithStations(cyberId);
});

/// Cybers available on the profile screen (owner's centers or all for admin).
final cyberProfileCyberListProvider =
    FutureProvider.autoDispose<List<Cyber>>((ref) async {
  final user = ref.watch(authStateProvider);
  if (user == null) return [];
  if (user.isAdmin) {
    return CyberRepository().getAllCybers();
  }
  return ref.read(ownerRepositoryProvider).getOwnerCybers(user.id);
});

final selectedCyberProfileIdProvider = StateProvider<String?>((ref) {
  final cybers = ref.watch(cyberProfileCyberListProvider).valueOrNull;
  if (cybers == null || cybers.isEmpty) return null;
  final primary = ref.watch(ownerPrimaryCyberProvider);
  return primary?.id ?? cybers.first.id;
});
