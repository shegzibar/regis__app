import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../data/models/tournament.dart';
import '../../../data/repositories/tournament_repository.dart';

class OwnerTournamentDetailsScreen extends ConsumerWidget {
  final Tournament tournament;
  const OwnerTournamentDetailsScreen({super.key, required this.tournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final participantsAsync =
        ref.watch(tournamentParticipantsProvider(tournament.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A1D21)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tournament.name,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1A1D21),
              ),
            ),
            Text(
              tournament.gameType,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textMuted,
              ),
            ),
          ],
        ),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) async {
              try {
                await TournamentRepository()
                    .updateTournamentStatus(tournament.id, val);
                if (context.mounted) Navigator.pop(context);
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                        content: Text(
                            e.toString().replaceAll('Exception: ', ''))),
                  );
                }
              }
            },
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'upcoming', child: Text('Mark as Upcoming')),
              PopupMenuItem(value: 'ongoing', child: Text('Mark as Ongoing')),
              PopupMenuItem(value: 'completed', child: Text('Mark as Completed')),
            ],
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFF0E6FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tournament.status.toUpperCase(),
                    style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF7C3AED)),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down,
                      color: Color(0xFF7C3AED), size: 18),
                ],
              ),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1, color: const Color(0xFFE2E8F0)),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Tournament info card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.emoji_events,
                        color: Colors.white, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tournament.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _StatChip(Icons.sports_esports, tournament.gameType),
                    const SizedBox(width: 8),
                    _StatChip(Icons.calendar_today,
                        DateFormat('MMM d • hh:mm a')
                            .format(tournament.startDate.toLocal())),
                  ],
                ),
                const SizedBox(height: 8),
                if (tournament.prizePool > 0) ...[
                  Row(
                    children: [
                      _StatChip(
                          Icons.workspace_premium,
                          'Prize: ${tournament.prizePool.toStringAsFixed(0)} EGP'),
                    ],
                  ),
                ],
                if (tournament.description != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    tournament.description!,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13),
                  ),
                ],
              ],
            ),
          ),

          // Participants header
          participantsAsync.when(
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
            data: (participants) => Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Participants (${participants.length}/${tournament.maxPlayers})',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF1A1D21),
                    ),
                  ),
                  const Spacer(),
                  if (participants.isNotEmpty) ...[
                    _ProgressBar(
                        current: participants.length,
                        max: tournament.maxPlayers),
                  ],
                ],
              ),
            ),
          ),

          // Participants list
          Expanded(
            child: participantsAsync.when(
              loading: () => const Center(
                  child: CircularProgressIndicator(
                      color: AppColors.primary)),
              error: (err, _) => Center(
                child: Text('Error: $err',
                    style: const TextStyle(color: Colors.red)),
              ),
              data: (participants) {
                if (participants.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: const [
                        Icon(Icons.people_outline,
                            size: 48, color: AppColors.textMuted),
                        SizedBox(height: 12),
                        Text(
                          'No participants yet',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 15),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Share this tournament with users!',
                          style: TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: participants.length,
                  itemBuilder: (context, i) =>
                      _ParticipantTile(participant: participants[i], rank: i + 1),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _StatChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 12),
          const SizedBox(width: 4),
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 11)),
        ],
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  final int current;
  final int max;
  const _ProgressBar({required this.current, required this.max});

  @override
  Widget build(BuildContext context) {
    final ratio = (current / max).clamp(0.0, 1.0);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 80,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: const Color(0xFFE2E8F0),
              color: ratio >= 0.9
                  ? Colors.red
                  : const Color(0xFF7C3AED),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          '$current/$max',
          style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
              fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  final TournamentParticipant participant;
  final int rank;
  const _ParticipantTile(
      {required this.participant, required this.rank});

  @override
  Widget build(BuildContext context) {
    final name = participant.userName ?? 'User #${participant.userId.substring(0, 6)}';
    final joinDate = DateFormat('MMM d, hh:mm a')
        .format(participant.joinedAt.toLocal());

    Color statusColor;
    Color statusBg;
    IconData statusIcon;
    switch (participant.status) {
      case 'winner':
        statusColor = const Color(0xFFD97706);
        statusBg = const Color(0xFFFEF3C7);
        statusIcon = Icons.emoji_events;
        break;
      case 'eliminated':
        statusColor = Colors.red;
        statusBg = const Color(0xFFFEE2E2);
        statusIcon = Icons.cancel_outlined;
        break;
      default:
        statusColor = const Color(0xFF16A34A);
        statusBg = const Color(0xFFDCFCE7);
        statusIcon = Icons.check_circle_outline;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: rank <= 3
                  ? const Color(0xFFF0E6FF)
                  : const Color(0xFFF8FAFC),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: rank <= 3
                      ? const Color(0xFF7C3AED)
                      : AppColors.textMuted,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Color(0xFF1A1D21),
                  ),
                ),
                Text(
                  'Joined $joinDate',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: statusBg,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(statusIcon, size: 12, color: statusColor),
                const SizedBox(width: 4),
                Text(
                  participant.status.toUpperCase(),
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
