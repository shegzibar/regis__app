import '../models/tournament.dart';
import '../supabase/supabase_client.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TournamentRepository {
  final SupabaseService _supabase = SupabaseService();

  // ---------------------------------------------------------
  // LOCAL TOURNAMENTS
  // ---------------------------------------------------------
  Future<List<Tournament>> getLocalTournaments(String cyberId) async {
    try {
      final response = await _supabase.client
          .from('tournaments')
          .select()
          .eq('type', 'local')
          .eq('cyber_id', cyberId)
          .order('start_date', ascending: true);
      return (response as List).map((t) => Tournament.fromMap(t)).toList();
    } catch (e) {
      throw Exception('Failed to fetch local tournaments: $e');
    }
  }

  Future<Tournament> createLocalTournament(Tournament tournament) async {
    try {
      final data = tournament.toMap();
      data.remove('id'); // let db generate
      final response = await _supabase.client
          .from('tournaments')
          .insert(data)
          .select()
          .single();
      return Tournament.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create local tournament: $e');
    }
  }

  Future<void> updateTournamentStatus(String tournamentId, String status) async {
    try {
      await _supabase.client
          .from('tournaments')
          .update({'status': status, 'updated_at': DateTime.now().toIso8601String()})
          .eq('id', tournamentId);
    } catch (e) {
      throw Exception('Failed to update tournament status: $e');
    }
  }

  Future<void> publishTournament(String tournamentId) async {
    await updateTournamentStatus(tournamentId, 'registration');
  }

  Future<void> endTournament(String tournamentId) async {
    await updateTournamentStatus(tournamentId, 'completed');
  }

  Future<void> deleteTournament(String tournamentId) async {
    try {
      // Remove participants and leaderboard entries first (FK constraints)
      await _supabase.client
          .from('tournament_participants')
          .delete()
          .eq('tournament_id', tournamentId);

      await _supabase.client
          .from('tournament_leaderboard')
          .delete()
          .eq('tournament_id', tournamentId);

      // Delete the tournament itself
      await _supabase.client
          .from('tournaments')
          .delete()
          .eq('id', tournamentId);
    } catch (e) {
      throw Exception('Failed to delete tournament: $e');
    }
  }

  // ---------------------------------------------------------
  // INTERNATIONAL TOURNAMENTS
  // ---------------------------------------------------------
  Future<List<Tournament>> getInternationalTournaments() async {
    try {
      final response = await _supabase.client
          .from('tournaments')
          .select()
          .eq('type', 'international')
          .order('start_date', ascending: true);
      return (response as List).map((t) => Tournament.fromMap(t)).toList();
    } catch (e) {
      throw Exception('Failed to fetch international tournaments: $e');
    }
  }

  Future<Tournament> createInternationalTournament(Tournament tournament) async {
    try {
      final data = tournament.toMap();
      data.remove('id'); // let db generate
      data['type'] = 'international';
      data['cyber_id'] = null; // explicit null for international
      final response = await _supabase.client
          .from('tournaments')
          .insert(data)
          .select()
          .single();
      return Tournament.fromMap(response);
    } catch (e) {
      throw Exception('Failed to create international tournament: $e');
    }
  }

  // ---------------------------------------------------------
  // PARTICIPATION
  // ---------------------------------------------------------
  Future<bool> hasUserJoined(String tournamentId, String userId) async {
    try {
      final response = await _supabase.client
          .from('tournament_participants')
          .select()
          .eq('tournament_id', tournamentId)
          .eq('user_id', userId)
          .maybeSingle();
      return response != null;
    } catch (e) {
      return false;
    }
  }

  Future<void> joinTournament(String tournamentId, String userId) async {
    try {
      await _supabase.client.from('tournament_participants').insert({
        'tournament_id': tournamentId,
        'user_id': userId,
        'status': 'active',
      });
      // Also initialize leaderboard entry
      await _supabase.client.from('tournament_leaderboard').insert({
        'tournament_id': tournamentId,
        'user_id': userId,
        'position': 9999, // default last
        'score': 0,
      });
    } catch (e) {
      final msg = e.toString();
      if (msg.contains('duplicate key') || msg.contains('unique')) {
        throw Exception('You have already joined this tournament.');
      }
      throw Exception('Failed to join tournament: $e');
    }
  }

  Future<void> leaveTournament(String tournamentId, String userId) async {
    try {
      await _supabase.client
          .from('tournament_participants')
          .delete()
          .eq('tournament_id', tournamentId)
          .eq('user_id', userId);
      
      await _supabase.client
          .from('tournament_leaderboard')
          .delete()
          .eq('tournament_id', tournamentId)
          .eq('user_id', userId);
    } catch (e) {
      throw Exception('Failed to leave tournament: $e');
    }
  }

  Future<List<TournamentParticipant>> getTournamentParticipants(String tournamentId) async {
    try {
      final response = await _supabase.client
          .from('tournament_participants')
          .select('*, profiles(name, avatar_url)')
          .eq('tournament_id', tournamentId)
          .order('score', ascending: false);
      return (response as List).map((p) => TournamentParticipant.fromMap(p)).toList();
    } catch (e) {
      throw Exception('Failed to fetch participants: $e');
    }
  }

  // ---------------------------------------------------------
  // LEADERBOARD
  // ---------------------------------------------------------
  Stream<List<TournamentLeaderboard>> getTournamentLeaderboardStream(String tournamentId) {
    return _supabase.client
        .from('tournament_leaderboard')
        .stream(primaryKey: ['id'])
        .eq('tournament_id', tournamentId)
        .order('score', ascending: false)
        .map((list) => list.map((l) => TournamentLeaderboard.fromMap(l)).toList());
  }

  Future<int> getUserRankInTournament(String tournamentId, String userId) async {
    try {
      final response = await _supabase.client
          .from('tournament_leaderboard')
          .select('position')
          .eq('tournament_id', tournamentId)
          .eq('user_id', userId)
          .maybeSingle();
      if (response != null) {
        return response['position'] as int;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  // ---------------------------------------------------------
  // SEARCH / FILTER
  // ---------------------------------------------------------
  Future<List<Tournament>> getUserJoinedTournaments(String userId) async {
    try {
      final response = await _supabase.client
          .from('tournament_participants')
          .select('tournaments(*)')
          .eq('user_id', userId);
      
      List<Tournament> result = [];
      for (var row in response as List) {
        if (row['tournaments'] != null) {
          result.add(Tournament.fromMap(row['tournaments']));
        }
      }
      return result;
    } catch (e) {
      throw Exception('Failed to fetch joined tournaments: $e');
    }
  }

  // ---------------------------------------------------------
  // PRIZES & SCORING
  // ---------------------------------------------------------
  Future<void> distributePrizes(String tournamentId) async {
    // This calls a backend function or handles the logic
    // For now we assume a postgres RPC function 'distribute_tournament_prizes'
    try {
      await _supabase.client.rpc('distribute_tournament_prizes', params: {
        'p_tournament_id': tournamentId,
      });
      await endTournament(tournamentId);
    } catch (e) {
      throw Exception('Failed to distribute prizes: $e');
    }
  }
}
