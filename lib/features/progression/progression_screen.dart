import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/round_stats.dart';
import '../../data/models/tactical_themes.dart';
import '../../data/repositories/round_repository.dart';
import '../../data/repositories/set_repository.dart';
import '../../data/repositories/stats_repository.dart';
import 'widgets/bar_chart.dart';
import 'widgets/theme_heatmap.dart';
import 'widgets/trend_chart.dart';

class ProgressionScreen extends ConsumerWidget {
  const ProgressionScreen({super.key, required this.setId});

  final String setId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setAsync = ref.watch(setByIdProvider(setId));
    final statsAsync = ref.watch(setRoundsStatsProvider(setId));
    final themesAsync = ref.watch(themeStatsProvider(setId));
    final problemsAsync = ref.watch(problemPuzzlesProvider(setId));

    return Scaffold(
      appBar: AppBar(
        title: setAsync.maybeWhen(
          data: (s) => Text(s?.name ?? 'Progression'),
          orElse: () => const Text('Progression'),
        ),
      ),
      body: statsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (stats) {
          if (stats.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Complete a round to see progression.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _Header(stats: stats),
              const SizedBox(height: 16),
              TrendChart(
                title: 'Accuracy',
                series: [
                  TrendSeries(
                    label: 'Accuracy',
                    color: const Color(0xFF2E7D32),
                    values:
                        stats.map((s) => s.accuracy * 100).toList(),
                  ),
                ],
                yMin: 0,
                yMax: 100,
              ),
              const SizedBox(height: 16),
              TrendChart(
                title: 'Time per puzzle (seconds)',
                series: [
                  TrendSeries(
                    label: 'Avg',
                    color: const Color(0xFF1565C0),
                    values: stats
                        .map((s) =>
                            s.averageTime.inMilliseconds / 1000.0)
                        .toList(),
                  ),
                  TrendSeries(
                    label: 'Median',
                    color: const Color(0xFF6A1B9A),
                    values: stats
                        .map((s) =>
                            s.medianTime.inMilliseconds / 1000.0)
                        .toList(),
                  ),
                ],
                yMin: 0,
              ),
              const SizedBox(height: 16),
              BarChart(
                title: 'Yield (correct per minute)',
                values: stats.map((s) => s.yieldPerMinute).toList(),
                color: const Color(0xFF6A1B9A),
              ),
              const SizedBox(height: 24),
              Text(
                'Tactical heatmap',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              themesAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Text('Error: $e'),
                data: (themes) => ThemeHeatmap(stats: themes),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Problem puzzles',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  problemsAsync.maybeWhen(
                    data: (problems) => problems.isEmpty
                        ? const SizedBox.shrink()
                        : FilledButton.tonalIcon(
                            onPressed: () =>
                                context.push('/sets/$setId/drill'),
                            icon: const Icon(Icons.fitness_center, size: 18),
                            label: const Text('Drill'),
                          ),
                    orElse: () => const SizedBox.shrink(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              problemsAsync.when(
                loading: () => const SizedBox(
                  height: 24,
                  child: Center(
                    child: SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (e, _) => Text('Error: $e'),
                data: (problems) {
                  if (problems.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child:
                          Text('No repeat-mistake puzzles yet — keep going!'),
                    );
                  }
                  return Column(
                    children: [
                      for (final p in problems)
                        Builder(builder: (context) {
                          final tactical = filterTactical(p.themes);
                          final themesSuffix = tactical.isEmpty
                              ? ''
                              : ' · ${tactical.take(3).join(', ')}';
                          return Card(
                            child: ListTile(
                              leading: const Icon(Icons.replay),
                              title: Text(
                                  'Failed in ${p.failedRounds} rounds · ${p.rating}'),
                              subtitle: Text('#${p.puzzleId}$themesSuffix'),
                              trailing: const Icon(Icons.chevron_right),
                              onTap: () =>
                                  context.push('/puzzles/${p.puzzleId}'),
                            ),
                          );
                        }),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              Text(
                'Round history',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final s in stats.reversed) _RoundRow(stats: s),
            ],
          );
        },
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.stats});
  final List<RoundStats> stats;

  @override
  Widget build(BuildContext context) {
    final firstMs = stats.first.medianTime.inMilliseconds;
    final lastMs = stats.last.medianTime.inMilliseconds;
    final last = stats.last;
    final firstAcc = stats.first.accuracy;
    final lastAcc = last.accuracy;

    final speedupPct = (stats.length >= 2 && firstMs > 0)
        ? (firstMs - lastMs) / firstMs * 100.0
        : null;
    final accDeltaPct = (stats.length >= 2)
        ? (lastAcc - firstAcc) * 100.0
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (speedupPct != null)
          Builder(
            builder: (context) {
              final scheme = Theme.of(context).colorScheme;
              final bg = speedupPct >= 0
                  ? scheme.tertiaryContainer
                  : scheme.errorContainer;
              final fg = speedupPct >= 0
                  ? scheme.onTertiaryContainer
                  : scheme.onErrorContainer;
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      speedupPct >= 0
                          ? Icons.trending_up
                          : Icons.trending_down,
                      color: fg,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        speedupPct >= 0
                            ? '${speedupPct.toStringAsFixed(1)}% faster median '
                                'since round 1'
                            : '${(-speedupPct).toStringAsFixed(1)}% slower median '
                                'than round 1',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: fg),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _MiniCard(
              label: 'Rounds',
              value: '${stats.length}',
            ),
            _MiniCard(
              label: 'Latest accuracy',
              value: '${(lastAcc * 100).round()}%',
            ),
            _MiniCard(
              label: 'Latest median',
              value:
                  '${(last.medianTime.inMilliseconds / 1000).toStringAsFixed(1)}s',
            ),
            if (accDeltaPct != null)
              _MiniCard(
                label: 'Accuracy Δ',
                value:
                    '${accDeltaPct >= 0 ? '+' : ''}${accDeltaPct.toStringAsFixed(1)}%',
              ),
          ],
        ),
      ],
    );
  }
}

class _MiniCard extends StatelessWidget {
  const _MiniCard({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 100,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 2),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _RoundRow extends StatelessWidget {
  const _RoundRow({required this.stats});
  final RoundStats stats;

  @override
  Widget build(BuildContext context) {
    final pct = (stats.accuracy * 100).round();
    final median =
        (stats.medianTime.inMilliseconds / 1000).toStringAsFixed(1);
    final avg =
        (stats.averageTime.inMilliseconds / 1000).toStringAsFixed(1);
    final total = _fmtTotal(stats.totalTime);
    final hints = stats.hintsUsed > 0 ? ' · ${stats.hintsUsed} hint' : '';
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Round ${stats.roundNumber}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 4),
            Text(
              '${stats.correct}/${stats.total} ($pct%) · '
              'median ${median}s · avg ${avg}s · $total total$hints',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  String _fmtTotal(Duration d) {
    final s = d.inSeconds;
    if (s < 60) return '${s}s';
    return '${s ~/ 60}m ${s % 60}s';
  }
}
