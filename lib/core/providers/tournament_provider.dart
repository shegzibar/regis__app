import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/tournament.dart';
import '../../data/repositories/tournament_repository.dart';

final tournamentRepositoryProvider = Provider<TournamentRepository>((ref) {
  return TournamentRepository();
});

// Local tournaments for current cyber owner
final localTournamentsProvider =
    FutureProvider.family<List<Tournament>, String>((ref, cyberId) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.getLocalTournaments(cyberId);
});

// International tournaments (all users)
final internationalTournamentsProvider =
    FutureProvider<List<Tournament>>((ref) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.getInternationalTournaments();
});

// Tournament leaderboard (realtime)
final tournamentLeaderboardProvider =
    StreamProvider.family<List<TournamentLeaderboard>, String>((ref, tournamentId) {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.getTournamentLeaderboardStream(tournamentId);
});

// Participants list (cached/one-time fetch or stream depending on needs)
final tournamentParticipantsProvider =
    FutureProvider.family<List<TournamentParticipant>, String>(
        (ref, tournamentId) async {
  return ref.watch(tournamentRepositoryProvider).getTournamentParticipants(tournamentId);
});

// User's joined tournaments
final userJoinedTournamentsProvider =
    FutureProvider.family<List<Tournament>, String>((ref, userId) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  return repo.getUserJoinedTournaments(userId);
});

// Discover active tournaments (Local + International)
// For a user, we can fetch International + Local for their favourite cybers or near location
final discoverTournamentsProvider = FutureProvider<List<Tournament>>((ref) async {
  final repo = ref.watch(tournamentRepositoryProvider);
  final international = await repo.getInternationalTournaments();
  // Here you can add logic to fetch local tournaments from nearby/favorite cybers
  // For now, we return international tournaments
  return international.where((t) => t.isJoinable).toList();
});
