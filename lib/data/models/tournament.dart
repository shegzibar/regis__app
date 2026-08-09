class Tournament {
  final String id;
  final String name;
  final String? description;
  final String type; // 'local' | 'international'
  final String? cyberId; // NULL for international
  final String adminId; // User who created it
  final String gameType; // ps5, ps4, pc, vip, mixed
  final int maxPlayers;
  final DateTime startDate;
  final DateTime endDate;
  final String status; // registration, active, completed, cancelled
  final double prizePool; // total EGP
  final double prizePerHour; // usually 1.0
  final String? coverImageUrl;
  final String? rules;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Tournament({
    required this.id,
    required this.name,
    this.description,
    required this.type,
    this.cyberId,
    required this.adminId,
    required this.gameType,
    required this.maxPlayers,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.prizePool,
    required this.prizePerHour,
    this.coverImageUrl,
    this.rules,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Tournament.fromMap(Map<String, dynamic> map) {
    return Tournament(
      id: map['id'] as String? ?? '',
      name: map['name'] as String? ?? 'Unnamed Tournament',
      description: map['description'] as String?,
      type: map['type'] as String? ?? 'local',
      cyberId: map['cyber_id'] as String?,
      adminId: map['admin_id'] as String? ?? '',
      gameType: map['game_type'] as String? ?? 'unknown',
      maxPlayers: map['max_players'] as int? ?? 100,
      startDate: map['start_date'] != null
          ? DateTime.parse(map['start_date'] as String)
          : DateTime.now(),
      endDate: map['end_date'] != null
          ? DateTime.parse(map['end_date'] as String)
          : DateTime.now().add(const Duration(hours: 3)),
      status: map['status'] as String? ?? 'registration',
      prizePool: (map['prize_pool'] as num?)?.toDouble() ?? 0.0,
      prizePerHour: (map['prize_per_hour'] as num?)?.toDouble() ?? 1.0,
      coverImageUrl: map['cover_image_url'] as String?,
      rules: map['rules'] as String?,
      createdAt: map['created_at'] != null
          ? DateTime.parse(map['created_at'] as String)
          : DateTime.now(),
      updatedAt: map['updated_at'] != null
          ? DateTime.parse(map['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'type': type,
      'cyber_id': cyberId,
      'admin_id': adminId,
      'game_type': gameType,
      'max_players': maxPlayers,
      'start_date': startDate.toIso8601String(),
      'end_date': endDate.toIso8601String(),
      'status': status,
      'prize_pool': prizePool,
      'prize_per_hour': prizePerHour,
      'cover_image_url': coverImageUrl,
      'rules': rules,
    };
  }

  /// Alias for [name] — used by UI screens that reference `tournament.title`.
  String get title => name;

  /// Alias for [maxPlayers] — used by UI screens that reference `tournament.maxParticipants`.
  int get maxParticipants => maxPlayers;

  /// Entry fee in points (currently 0 — no entry fee field in the DB schema).
  int get entryFee => 0;

  bool get isActive => status == 'active';
  bool get isJoinable => status == 'registration' || status == 'active';
  Duration get timeLeft => endDate.difference(DateTime.now());

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Tournament && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

class TournamentParticipant {
  final String id;
  final String tournamentId;
  final String userId;
  final int score;
  final int? rank;
  final String status; // active, disqualified, winner, runner_up
  final DateTime joinedAt;
  final String? userName; // For UI convenience
  final String? avatarUrl; // For UI convenience

  const TournamentParticipant({
    required this.id,
    required this.tournamentId,
    required this.userId,
    required this.score,
    this.rank,
    required this.status,
    required this.joinedAt,
    this.userName,
    this.avatarUrl,
  });

  factory TournamentParticipant.fromMap(Map<String, dynamic> map) {
    return TournamentParticipant(
      id: map['id'] as String,
      tournamentId: map['tournament_id'] as String,
      userId: map['user_id'] as String,
      score: map['score'] as int? ?? 0,
      rank: map['rank'] as int?,
      status: map['status'] as String? ?? 'active',
      joinedAt: DateTime.parse(map['joined_at'] as String),
      userName: map['profiles'] != null ? map['profiles']['name'] as String? : null,
      avatarUrl: map['profiles'] != null ? map['profiles']['avatar_url'] as String? : null,
    );
  }
}

class TournamentLeaderboard {
  final String id;
  final String tournamentId;
  final String userId;
  final int position;
  final int score;
  final int wins;
  final int losses;
  final DateTime updatedAt;
  final String? userName; // For UI convenience
  final String? avatarUrl; // For UI convenience

  const TournamentLeaderboard({
    required this.id,
    required this.tournamentId,
    required this.userId,
    required this.position,
    required this.score,
    required this.wins,
    required this.losses,
    required this.updatedAt,
    this.userName,
    this.avatarUrl,
  });

  factory TournamentLeaderboard.fromMap(Map<String, dynamic> map) {
    return TournamentLeaderboard(
      id: map['id'] as String,
      tournamentId: map['tournament_id'] as String,
      userId: map['user_id'] as String,
      position: map['position'] as int,
      score: map['score'] as int? ?? 0,
      wins: map['wins'] as int? ?? 0,
      losses: map['losses'] as int? ?? 0,
      updatedAt: DateTime.parse(map['updated_at'] as String),
      userName: map['profiles'] != null ? map['profiles']['name'] as String? : null,
      avatarUrl: map['profiles'] != null ? map['profiles']['avatar_url'] as String? : null,
    );
  }
}
