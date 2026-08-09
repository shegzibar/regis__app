import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../data/models/tournament.dart';
import '../../../core/providers/tournament_provider.dart';
import '../constants/cd_colors.dart';
import '../providers/cd_providers.dart';

class TournamentsPage extends ConsumerWidget {
  const TournamentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cyberAsync = ref.watch(currentCyberProvider);
    final cyber = cyberAsync.valueOrNull;

    if (cyber == null) {
      return const Center(child: CircularProgressIndicator(color: kPurple));
    }

    final tournamentsAsync = ref.watch(localTournamentsProvider(cyber.id));

    return SingleChildScrollView(
      padding: const EdgeInsets.all(kPadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Tournaments',
                style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: kSidebarText),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Show Create Tournament Sheet
                  _showCreateTournamentSheet(context, ref, cyber.id);
                },
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Create Tournament'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: kPurple,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(kRadiusSm),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Tournaments List
          tournamentsAsync.when(
            data: (tournaments) {
              if (tournaments.isEmpty) {
                return _buildEmptyState();
              }
              
              final upcoming = tournaments.where((t) => t.status == 'registration').toList();
              final active = tournaments.where((t) => t.status == 'active').toList();
              final completed = tournaments.where((t) => t.status == 'completed').toList();

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (active.isNotEmpty) ...[
                    _buildSectionHeader('Active Tournaments', kGreen),
                    ...active.map((t) => _TournamentCard(tournament: t)).toList(),
                    const SizedBox(height: 24),
                  ],
                  if (upcoming.isNotEmpty) ...[
                    _buildSectionHeader('Upcoming Tournaments', kAmber),
                    ...upcoming.map((t) => _TournamentCard(tournament: t)).toList(),
                    const SizedBox(height: 24),
                  ],
                  if (completed.isNotEmpty) ...[
                    _buildSectionHeader('Past Tournaments', kGray),
                    ...completed.map((t) => _TournamentCard(tournament: t)).toList(),
                  ],
                ],
              );
            },
            loading: () => const Center(child: CircularProgressIndicator(color: kPurple)),
            error: (e, st) => Text('Error loading tournaments: $e', style: const TextStyle(color: kRed)),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color dotColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: kSidebarText,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.emoji_events_outlined, size: 48, color: kGray),
          const SizedBox(height: 16),
          const Text(
            'No Tournaments Yet',
            style: TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, color: kSidebarText),
          ),
          const SizedBox(height: 8),
          const Text(
            'Create your first tournament to engage your players!',
            style: TextStyle(color: kGray),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showCreateTournamentSheet(BuildContext context, WidgetRef ref, String cyberId) {
    // This will be a bottom sheet or a modal dialog
    // For now we will show a simple dialog placeholder
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Create Tournament'),
        content: const Text('Form will go here.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}

class _TournamentCard extends ConsumerWidget {
  final Tournament tournament;

  const _TournamentCard({required this.tournament});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dateFormat = DateFormat('MMM d, yyyy');
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kCardBg,
        borderRadius: BorderRadius.circular(kRadius),
        border: Border.all(color: kBorder),
      ),
      child: Row(
        children: [
          // Game Icon/Type
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: kPurpleLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.sports_esports, color: kPurple),
          ),
          const SizedBox(width: 16),
          
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tournament.name,
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: kSidebarText),
                ),
                const SizedBox(height: 4),
                Text(
                  '${tournament.gameType.toUpperCase()} • ${dateFormat.format(tournament.startDate)} - ${dateFormat.format(tournament.endDate)}',
                  style: const TextStyle(fontSize: 12, color: kGray),
                ),
              ],
            ),
          ),
          
          // Prize Pool
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              const Text(
                'Prize Pool',
                style: TextStyle(fontSize: 11, color: kGray),
              ),
              const SizedBox(height: 2),
              Text(
                '${tournament.prizePool.toInt()} EGP',
                style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: kGreen),
              ),
            ],
          ),
          
          const SizedBox(width: 24),
          
          // Action Button
          ElevatedButton(
            onPressed: () {
              // TODO: Navigate to Details
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: kPurpleLight,
              foregroundColor: kPurple,
              elevation: 0,
            ),
            child: const Text('Manage'),
          ),
        ],
      ),
    );
  }
}
