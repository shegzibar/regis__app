import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/cyber.dart';
import '../../data/repositories/cyber_repository.dart';

// Single instance of the repository
final cyberRepositoryProvider = Provider<CyberRepository>((ref) {
  return CyberRepository();
});

// All active cybers (used by Explore + Map)
final cybersProvider = FutureProvider<List<Cyber>>((ref) async {
  return ref.read(cyberRepositoryProvider).getAllCybers();
});

// Featured cybers only
final featuredCybersProvider = FutureProvider<List<Cyber>>((ref) async {
  final all = await ref.watch(cybersProvider.future);
  return all.where((c) => c.isFeatured).toList();
});

// Single cyber by ID (used by Details screen)
final cyberByIdProvider =
    FutureProvider.family<Cyber?, String>((ref, cyberId) async {
  return ref.read(cyberRepositoryProvider).getCyberById(cyberId);
});

// Cybers owned by the current owner
final ownerCybersProvider =
    FutureProvider.family<List<Cyber>, String>((ref, ownerId) async {
  return ref.read(cyberRepositoryProvider).getCybersByOwner(ownerId);
});

// Search cybers
final cyberSearchProvider =
    FutureProvider.family<List<Cyber>, String>((ref, query) async {
  if (query.isEmpty) return ref.watch(cybersProvider.future);
  return ref.read(cyberRepositoryProvider).searchCybers(query);
});
