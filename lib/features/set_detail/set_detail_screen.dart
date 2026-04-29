import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/round.dart';
import '../../data/repositories/round_repository.dart';
import '../../data/repositories/set_repository.dart';

class SetDetailScreen extends ConsumerWidget {
  const SetDetailScreen({super.key, required this.setId});

  final String setId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setAsync = ref.watch(setByIdProvider(setId));
    final roundsAsync = ref.watch(roundsForSetProvider(setId));

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/');
            }
          },
        ),
        title: setAsync.maybeWhen(
          data: (s) => Text(s?.name ?? 'Set'),
          orElse: () => const Text('Set'),
        ),
        actions: [
          setAsync.maybeWhen(
            data: (s) {
              if (s == null) return const SizedBox.shrink();
              if (s.isArchived) {
                return IconButton(
                  icon: const Icon(Icons.unarchive_outlined),
                  tooltip: 'Restore set',
                  onPressed: () => _restore(context, ref),
                );
              }
              return IconButton(
                icon: const Icon(Icons.archive_outlined),
                tooltip: 'Archive set',
                onPressed: () => _confirmArchive(context, ref),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Delete set',
            onPressed: () => _confirmDelete(context, ref),
          ),
        ],
      ),
      body: setAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (set) {
          if (set == null) return const Center(child: Text('Set not found'));
          return roundsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
            data: (rounds) {
              final activeRound =
                  rounds.where((r) => !r.isCompleted).firstOrNull;
              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(
                    '${set.size} puzzles • '
                    'rating ${set.filter.ratingMin}–${set.filter.ratingMax}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  if (set.filter.themes.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Themes: ${set.filter.themes.join(', ')}',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  const SizedBox(height: 24),
                  if (activeRound != null)
                    FilledButton.icon(
                      onPressed: () => context.push(
                        '/sets/${set.id}/rounds/${activeRound.id}',
                      ),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        'Continue round ${activeRound.roundNumber} '
                        '(${activeRound.currentPosition}/${set.size})',
                      ),
                    )
                  else
                    FilledButton.icon(
                      onPressed: () => _startRound(context, ref, set.id),
                      icon: const Icon(Icons.play_arrow),
                      label: Text(
                        rounds.isEmpty
                            ? 'Start round 1'
                            : 'Start round ${rounds.length + 1}',
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: Text('History',
                            style: Theme.of(context).textTheme.titleMedium),
                      ),
                      if (rounds.any((r) => r.isCompleted))
                        TextButton.icon(
                          onPressed: () => context
                              .push('/sets/${set.id}/progression'),
                          icon: const Icon(Icons.show_chart, size: 18),
                          label: const Text('Progression'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (rounds.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text('No rounds yet'),
                    ),
                  for (final round in rounds.reversed)
                    _RoundTile(setId: set.id, round: round, total: set.size),
                ],
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _startRound(
      BuildContext context, WidgetRef ref, String setId) async {
    final repo = ref.read(roundRepositoryProvider);
    final round = await repo.startNew(setId);
    ref.invalidate(roundsForSetProvider(setId));
    if (!context.mounted) return;
    context.push('/sets/$setId/rounds/${round.id}');
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete set?'),
        content: const Text(
            'This removes the set and all rounds and attempts within it.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final repo = ref.read(setRepositoryProvider);
    await repo.delete(setId);
    ref.invalidate(allSetsProvider);
    if (!context.mounted) return;
    context.go('/');
  }

  Future<void> _confirmArchive(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Archive set?'),
        content: const Text(
            'The set will be hidden from your home list. You can restore '
            'it any time from the Archived screen, and stats are preserved.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Archive'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    await ref.read(setRepositoryProvider).archive(setId);
    ref.invalidate(allSetsProvider);
    ref.invalidate(archivedSetsProvider);
    ref.invalidate(setByIdProvider(setId));
    if (!context.mounted) return;
    context.go('/');
  }

  Future<void> _restore(BuildContext context, WidgetRef ref) async {
    await ref.read(setRepositoryProvider).unarchive(setId);
    ref.invalidate(allSetsProvider);
    ref.invalidate(archivedSetsProvider);
    ref.invalidate(setByIdProvider(setId));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Set restored')),
    );
  }
}

class _RoundTile extends ConsumerWidget {
  const _RoundTile({
    required this.setId,
    required this.round,
    required this.total,
  });

  final String setId;
  final Round round;
  final int total;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!round.isCompleted) {
      return Card(
        child: ListTile(
          title: Text('Round ${round.roundNumber}'),
          subtitle:
              Text('In progress (${round.currentPosition}/$total)'),
          trailing: const Icon(Icons.pause_circle_outline),
          onTap: () => context.push('/sets/$setId/rounds/${round.id}'),
        ),
      );
    }
    final statsAsync = ref.watch(roundStatsProvider(round.id));
    return Card(
      child: ListTile(
        title: Text('Round ${round.roundNumber}'),
        subtitle: statsAsync.when(
          loading: () => const Text('Loading…'),
          error: (_, _) => const Text('Completed'),
          data: (stats) {
            if (stats == null || stats.total == 0) {
              return const Text('Completed');
            }
            final pct = (stats.accuracy * 100).round();
            final median =
                (stats.medianTime.inMilliseconds / 1000).toStringAsFixed(1);
            final hints = stats.hintsUsed;
            final streak = stats.longestFlowStreak;
            final parts = <String>[
              '${stats.correct}/${stats.total} ($pct%)',
              'median ${median}s',
            ];
            if (hints > 0) parts.add('$hints hint${hints == 1 ? '' : 's'}');
            if (streak >= 3) parts.add('$streak-streak');
            return Text(parts.join(' · '));
          },
        ),
        trailing: const Icon(Icons.show_chart),
        onTap: () => context.push('/sets/$setId/progression'),
      ),
    );
  }
}
