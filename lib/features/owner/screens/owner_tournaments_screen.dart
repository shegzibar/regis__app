import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/providers/owner_dashboard_provider.dart';
import '../../../core/providers/tournament_provider.dart';
import '../../../data/models/tournament.dart';
import '../../../data/repositories/tournament_repository.dart';
import 'owner_create_tournament_sheet.dart';
import 'owner_tournament_details_screen.dart';

class OwnerTournamentsScreen extends ConsumerWidget {
  const OwnerTournamentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cyber = ref.watch(ownerPrimaryCyberProvider);

    if (cyber == null) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    final tournamentsAsync = ref.watch(localTournamentsProvider(cyber.id));

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header bar
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            color: Colors.white,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0E6FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.emoji_events,
                      color: Color(0xFF7C3AED), size: 22),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tournaments',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1D21),
                      ),
                    ),
                    Text(
                      cyber.name,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('New Tournament'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF7C3AED),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                  ),
                  onPressed: () async {
                    final created = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) =>
                          OwnerCreateTournamentSheet(cyberId: cyber.id),
                    );
                    if (created == true) {
                      ref.invalidate(localTournamentsProvider(cyber.id));
                    }
                  },
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: tournamentsAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator(color: AppColors.primary)),
              error: (err, _) => Center(
                child: Text('Error: $err',
                    style: const TextStyle(color: Colors.red)),
              ),
              data: (tournaments) {
                if (tournaments.isEmpty) {
                  return _EmptyTournamentsView(
                    cyberId: cyber.id,
                    onCreated: () =>
                        ref.invalidate(localTournamentsProvider(cyber.id)),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async =>
                      ref.invalidate(localTournamentsProvider(cyber.id)),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: tournaments.length,
                    itemBuilder: (context, index) {
                      final t = tournaments[index];
                      return _TournamentOwnerCard(
                        tournament: t,
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  OwnerTournamentDetailsScreen(tournament: t),
                            ),
                          );
                          ref.invalidate(localTournamentsProvider(cyber.id));
                        },
                        onDelete: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (_) => AlertDialog(
                              title: const Text('Delete Tournament'),
                              content: Text(
                                  'Are you sure you want to delete "${t.title}"?'),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, true),
                                  child: const Text('Delete',
                                      style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            try {
                              await TournamentRepository()
                                  .deleteTournament(t.id);
                              ref.invalidate(
                                  localTournamentsProvider(cyber.id));
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(e
                                          .toString()
                                          .replaceAll('Exception: ', ''))),
                                );
                              }
                            }
                          }
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTournamentsView extends StatelessWidget {
  final String cyberId;
  final VoidCallback onCreated;
  const _EmptyTournamentsView(
      {required this.cyberId, required this.onCreated});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFFF0E6FF),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events_outlined,
                size: 56, color: Color(0xFF7C3AED)),
          ),
          const SizedBox(height: 20),
          const Text(
            'No Tournaments Yet',
            style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1A1D21)),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first tournament and\nlet users compete for prizes!',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textMuted, fontSize: 14),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.add),
            label: const Text('Create Tournament'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF7C3AED),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              padding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            ),
            onPressed: () async {
              final created = await showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => OwnerCreateTournamentSheet(cyberId: cyberId),
              );
              if (created == true) onCreated();
            },
          ),
        ],
      ),
    );
  }
}

class _TournamentOwnerCard extends StatelessWidget {
  final Tournament tournament;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _TournamentOwnerCard({
    required this.tournament,
    required this.onTap,
    required this.onDelete,
  });

  Color get _statusColor {
    switch (tournament.status) {
      case 'upcoming':
        return const Color(0xFF2563EB);
      case 'ongoing':
        return const Color(0xFF16A34A);
      case 'completed':
        return AppColors.textMuted;
      default:
        return AppColors.textMuted;
    }
  }

  Color get _statusBg {
    switch (tournament.status) {
      case 'upcoming':
        return const Color(0xFFDBEAFE);
      case 'ongoing':
        return const Color(0xFFDCFCE7);
      case 'completed':
        return const Color(0xFFF1F5F9);
      default:
        return const Color(0xFFF1F5F9);
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('MMM d, yyyy • hh:mm a').format(tournament.startDate.toLocal());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF7C3AED), Color(0xFF9333EA)],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.emoji_events,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tournament.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF1A1D21),
                            ),
                          ),
                          Text(
                            tournament.gameType,
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _statusBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        tournament.status.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: _statusColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline,
                          color: Colors.red, size: 18),
                      onPressed: onDelete,
                      tooltip: 'Delete',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _InfoChip(Icons.calendar_today, dateStr),
                    const SizedBox(width: 8),
                    _InfoChip(Icons.people_outline,
                        '${tournament.maxParticipants} max'),
                    const SizedBox(width: 8),
                    _InfoChip(
                        Icons.monetization_on_outlined, '${tournament.entryFee} pts'),
                  ],
                ),
                if (tournament.prizePool > 0) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.emoji_events_outlined,
                          size: 14, color: Color(0xFFD97706)),
                      const SizedBox(width: 4),
                      Text(
                        'Prize: ${tournament.prizePool}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFD97706),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      'View Participants & Manage →',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF7C3AED),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoChip(this.icon, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
