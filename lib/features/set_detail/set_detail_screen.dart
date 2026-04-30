import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/puzzle_set.dart';
import '../../data/models/round.dart';
import '../../data/repositories/round_repository.dart';
import '../../data/repositories/set_repository.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../strengths/widgets/theme_explainer_sheet.dart';

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
              return IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Rename set',
                onPressed: () => _renameSet(context, ref, s),
              );
            },
            orElse: () => const SizedBox.shrink(),
          ),
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
        error: (e, _) => const ErrorView(),
        data: (set) {
          if (set == null) {
            return const Center(
              child: EmptyState(
                icon: Icons.help_outline,
                title: 'Set not found',
                body: 'It may have been deleted.',
              ),
            );
          }
          return roundsAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => const ErrorView(),
            data: (rounds) {
              final activeRound =
                  rounds.where((r) => !r.isCompleted).firstOrNull;
              final completed = rounds.where((r) => r.isCompleted).length;
              return ListView(
                padding:
                    const EdgeInsets.fromLTRB(20, 8, 20, 32),
                children: [
                  _SetHero(
                    set: set,
                    completedRounds: completed,
                    activeRound: activeRound,
                  ),
                  const SizedBox(height: 16),
                  _PrimaryRoundCta(
                    set: set,
                    rounds: rounds,
                    activeRound: activeRound,
                    onStart: () => _startRound(context, ref, set.id),
                  ),
                  const SizedBox(height: 24),
                  _SectionLabel('History'),
                  if (rounds.any((r) => r.isCompleted))
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: () => context
                            .push('/sets/${set.id}/progression'),
                        icon: const Icon(Icons.show_chart, size: 18),
                        label: const Text('Open progression'),
                      ),
                    ),
                  const SizedBox(height: 8),
                  if (rounds.isEmpty)
                    const EmptyState(
                      icon: Icons.replay,
                      title: 'No rounds yet',
                      body:
                          'Tap "Start round 1" above to begin drilling '
                          'this set Woodpecker-style.',
                    )
                  else
                    for (final round in rounds.reversed) ...[
                      _RoundTile(
                          setId: set.id, round: round, total: set.size),
                      const SizedBox(height: 8),
                    ],
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

  Future<void> _renameSet(
    BuildContext context,
    WidgetRef ref,
    PuzzleSet set,
  ) async {
    final controller = TextEditingController(text: set.name);
    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename set'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Set name'),
          onSubmitted: (v) => Navigator.pop(ctx, v.trim()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == set.name) return;
    await ref.read(setRepositoryProvider).rename(set.id, newName);
    ref.invalidate(setByIdProvider(set.id));
    ref.invalidate(allSetsProvider);
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
      const SnackBar(
        content: Text('Set restored'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

class _SetHero extends StatelessWidget {
  const _SetHero({
    required this.set,
    required this.completedRounds,
    required this.activeRound,
  });

  final PuzzleSet set;
  final int completedRounds;
  final Round? activeRound;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.fitness_center,
                  color: scheme.onPrimaryContainer,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      set.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${set.size} puzzles · '
                      'rating ${set.filter.ratingMin}-${set.filter.ratingMax}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (set.filter.themes.isNotEmpty) ...[
            const SizedBox(height: 12),
            Builder(builder: (_) {
              const maxVisible = 5;
              final themes = set.filter.themes;
              final visible = themes.take(maxVisible).toList();
              final overflow = themes.length - visible.length;
              return Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final theme in visible)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: scheme.surfaceContainer,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        theme,
                        style: Theme.of(context).textTheme.labelSmall,
                      ),
                    ),
                  if (overflow > 0)
                    Material(
                      color: scheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _showAllThemes(context, themes),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          child: Text(
                            '+$overflow',
                            style: Theme.of(context)
                                .textTheme
                                .labelSmall
                                ?.copyWith(
                                  color: scheme.onPrimaryContainer,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ),
                    ),
                ],
              );
            }),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              _Stat(
                label: 'Rounds done',
                value: '$completedRounds',
              ),
              const SizedBox(width: 12),
              _Stat(
                label: 'Active',
                value: activeRound != null
                    ? '${activeRound!.currentPosition}/${set.size}'
                    : '-',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .labelSmall
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}

class _PrimaryRoundCta extends StatelessWidget {
  const _PrimaryRoundCta({
    required this.set,
    required this.rounds,
    required this.activeRound,
    required this.onStart,
  });

  final PuzzleSet set;
  final List<Round> rounds;
  final Round? activeRound;
  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final String title;
    final String subtitle;
    final IconData icon;
    final VoidCallback onTap;

    if (activeRound != null) {
      title = 'Resume round ${activeRound!.roundNumber}';
      subtitle =
          'Puzzle ${activeRound!.currentPosition + 1}/${set.size}';
      icon = Icons.play_arrow_rounded;
      onTap = () => GoRouter.of(context).push(
            '/sets/${set.id}/rounds/${activeRound!.id}',
          );
    } else {
      final next = rounds.length + 1;
      title = next == 1 ? 'Start round 1' : 'Start round $next';
      subtitle = 'Drill the same ${set.size} puzzles in fresh order';
      icon = Icons.replay_rounded;
      onTap = onStart;
    }

    return Material(
      color: scheme.primary,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.onPrimary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: scheme.onPrimary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(color: scheme.onPrimary),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(
                            color: scheme.onPrimary
                                .withValues(alpha: 0.85),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward,
                  color: scheme.onPrimary, size: 20),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      text.toUpperCase(),
      style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: scheme.onSurfaceVariant,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w600,
          ),
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
    final scheme = Theme.of(context).colorScheme;
    if (!round.isCompleted) {
      return Material(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(14),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () =>
              GoRouter.of(context).push('/sets/$setId/rounds/${round.id}'),
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: scheme.outlineVariant),
              borderRadius: BorderRadius.circular(14),
            ),
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.pause_circle_outline,
                    color: scheme.onSurfaceVariant),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Round ${round.roundNumber}',
                          style: Theme.of(context).textTheme.titleSmall),
                      const SizedBox(height: 2),
                      Text(
                        'In progress · '
                        '${round.currentPosition}/$total',
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: scheme.onSurfaceVariant),
              ],
            ),
          ),
        ),
      );
    }
    final statsAsync = ref.watch(roundStatsProvider(round.id));
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () =>
            GoRouter.of(context).push('/sets/$setId/progression'),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(14),
          ),
          padding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'R${round.roundNumber}',
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: scheme.onPrimaryContainer,
                      ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: statsAsync.when(
                  loading: () => Text(
                    'Loading…',
                    style: Theme.of(context)
                        .textTheme
                        .bodySmall
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  error: (_, _) => const Text('Completed'),
                  data: (stats) {
                    if (stats == null || stats.total == 0) {
                      return const Text('Completed');
                    }
                    final pct = (stats.accuracy * 100).round();
                    final median = (stats.medianTime.inMilliseconds /
                            1000)
                        .toStringAsFixed(1);
                    final hints = stats.hintsUsed;
                    final streak = stats.longestFlowStreak;
                    final parts = <String>[
                      '${stats.correct}/${stats.total} ($pct%)',
                      'median ${median}s',
                    ];
                    if (hints > 0) {
                      parts.add(
                          '$hints hint${hints == 1 ? '' : 's'}');
                    }
                    if (streak >= 3) parts.add('$streak-streak');
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Round ${round.roundNumber}',
                          style: Theme.of(context).textTheme.titleSmall,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          parts.join(' · '),
                          style: Theme.of(context)
                              .textTheme
                              .bodySmall
                              ?.copyWith(color: scheme.onSurfaceVariant),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Icon(Icons.show_chart, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

void _showAllThemes(BuildContext context, List<String> themes) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              'Themes in this set',
              style: Theme.of(ctx).textTheme.titleLarge,
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(
              '${themes.length} themes - tap one for its definition.',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in themes)
                Material(
                  color: Theme.of(ctx).colorScheme.surfaceContainerHigh,
                  shape: const StadiumBorder(),
                  clipBehavior: Clip.antiAlias,
                  child: InkWell(
                    onTap: () {
                      Navigator.of(ctx).pop();
                      ThemeExplainerSheet.show(context, t);
                    },
                    customBorder: const StadiumBorder(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      child: Text(t),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    ),
  );
}
