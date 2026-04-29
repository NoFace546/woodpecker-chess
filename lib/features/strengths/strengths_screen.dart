import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/enriched_theme_stats.dart';
import '../../data/models/weakness_entry.dart';
import '../../data/repositories/stats_repository.dart';
import '../../data/repositories/user_state_repository.dart';
import '../../services/training_recommender.dart';
import 'widgets/phase_radar.dart';

class StrengthsScreen extends ConsumerWidget {
  const StrengthsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisAsync = ref.watch(weaknessAnalysisProvider);
    final userAsync = ref.watch(userStateProvider);
    final phaseAsync = ref.watch(phaseStatsProvider);
    final allThemesAsync = ref.watch(allTacticalThemesProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Strengths & weaknesses'),
        actions: [
          IconButton(
            icon: const Icon(Icons.info_outline),
            tooltip: 'How this works',
            onPressed: () => _showMethodology(context),
          ),
          userAsync.maybeWhen(
            data: (u) => Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  'Elo ${u.elo}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: analysisAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (entries) {
          final totalAttempts =
              entries.fold<int>(0, (s, e) => s + e.stats.totalAttempts);
          if (entries.isEmpty || totalAttempts < 10) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Solve more puzzles to unlock your strengths analysis.\n\n'
                  'You need at least 10 attempts across a few themes.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          final highConf = entries
              .where((e) => e.confidence != ConfidenceLevel.low)
              .toList();
          // Split the ranked list so weaknesses and strengths never overlap.
          // With <6 high-confidence themes there isn't enough data to call
          // anything a "strength" — show only the weak end and a hint.
          final weakest = highConf.take(3).toList();
          final weakIds = weakest.map((e) => e.theme).toSet();
          final strongest = highConf.length < 6
              ? const <WeaknessEntry>[]
              : highConf.reversed
                  .where((e) => !weakIds.contains(e.theme))
                  .take(3)
                  .toList()
                  .reversed
                  .toList();
          final notEnoughForStrengths =
              highConf.length < 6 && weakest.isNotEmpty;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SufficiencyBanner(
                totalAttempts: totalAttempts,
                highConfCount: highConf.length,
              ),
              const SizedBox(height: 12),
              Text(
                'Based on $totalAttempts attempts across '
                '${entries.length} themes',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              Text(
                'Game phases',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              phaseAsync.when(
                loading: () => const SizedBox(
                  height: 240,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Error: $e'),
                data: (phases) => PhaseRadar(stats: phases),
              ),
              const SizedBox(height: 24),
              Text(
                'Top 3 weaknesses',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (weakest.isEmpty)
                _NoHighConfNote()
              else
                for (final w in weakest) _Entry(entry: w, weakness: true),
              const SizedBox(height: 24),
              Text(
                'Top 3 strengths',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              if (notEnoughForStrengths)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    'Need at least 6 themes with reliable data before calling '
                    'anything a strength. Keep playing to surface them.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                )
              else if (strongest.isEmpty)
                _NoHighConfNote()
              else
                for (final s in strongest) _Entry(entry: s, weakness: false),
              const SizedBox(height: 24),
              Text(
                'All themes',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final e in entries) _CompactRow(entry: e),
              ...allThemesAsync.maybeWhen(
                data: (allThemes) {
                  final attemptedNames =
                      entries.map((e) => e.theme).toSet();
                  final missing = allThemes
                      .where((t) => !attemptedNames.contains(t))
                      .toList();
                  if (missing.isEmpty) return const <Widget>[];
                  return [
                    const SizedBox(height: 8),
                    Text(
                      'Not attempted yet',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    for (final t in missing) _UnattemptedRow(theme: t),
                  ];
                },
                orElse: () => const <Widget>[],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => _startRecommended(context, ref),
                icon: const Icon(Icons.fitness_center),
                label: const Text('Start recommended training'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showMethodology(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('How strengths & weaknesses work'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Themes are ranked by the Wilson lower bound of an 80% '
                "confidence interval — not raw accuracy. With few attempts "
                'we trust the score less, so a theme with 3/3 (100%) ranks '
                'below one with 18/20 (90%).',
              ),
              SizedBox(height: 12),
              Text('Confidence levels',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                "High confidence: enough attempts that the score won't "
                'swing much with one more puzzle. Low confidence (n=…): '
                'still volatile. Low-confidence themes are excluded from '
                'top-3 strengths/weaknesses and shown faded in "All themes".',
              ),
              SizedBox(height: 12),
              Text('Weakness vs strength',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                'Both come from the same ranked list. The 3 worst '
                'high-confidence themes are weaknesses; the 3 best are '
                'strengths. Strengths only appear once you have at least '
                '6 high-confidence themes — otherwise everything would be '
                'both top-3 and bottom-3.',
              ),
              SizedBox(height: 12),
              Text('Trend arrows',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                'Compares your last ~10 attempts on the theme to the '
                'previous batch. Up = improving, down = declining.',
              ),
              SizedBox(height: 12),
              Text('Speed multiplier',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              Text(
                'On weakness/strength cards: how much faster or slower '
                "you are on this theme vs your global median solve time.",
              ),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }

  Future<void> _startRecommended(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      const SnackBar(content: Text('Building recommended set…')),
    );
    try {
      final result =
          await ref.read(trainingRecommenderProvider).buildRecommended();
      if (!context.mounted) return;
      messenger.hideCurrentSnackBar();
      context.go('/sets/${result.set.id}');
    } catch (e) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }
}

class _SufficiencyBanner extends StatelessWidget {
  const _SufficiencyBanner({
    required this.totalAttempts,
    required this.highConfCount,
  });
  final int totalAttempts;
  final int highConfCount;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    String? text;
    Color bg;
    Color fg;
    IconData icon;
    if (totalAttempts < 30) {
      text = 'Exploring your style — solve ${30 - totalAttempts} more '
          'puzzles for high-confidence analysis.';
      bg = scheme.tertiaryContainer;
      fg = scheme.onTertiaryContainer;
      icon = Icons.explore_outlined;
    } else if (highConfCount < 3) {
      text = 'Confidence improving — most themes still need more data. '
          'Themes with low data are excluded from top-3 ranking.';
      bg = scheme.surfaceContainerHigh;
      fg = scheme.onSurface;
      icon = Icons.info_outline;
    } else {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

class _NoHighConfNote extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        'Not enough data per theme yet. Keep playing to surface reliable '
        'strengths and weaknesses.',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _Entry extends StatelessWidget {
  const _Entry({required this.entry, required this.weakness});
  final WeaknessEntry entry;
  final bool weakness;

  @override
  Widget build(BuildContext context) {
    final pct = (entry.stats.rawAccuracy * 100).round();
    final speedX = entry.relativeSpeed.toStringAsFixed(1);
    final speedLabel = entry.relativeSpeed >= 1
        ? '$speedX× faster'
        : '${(1 / entry.relativeSpeed).toStringAsFixed(1)}× slower';
    final scheme = Theme.of(context).colorScheme;
    final bg = weakness ? scheme.errorContainer : scheme.tertiaryContainer;
    final fg = weakness ? scheme.onErrorContainer : scheme.onTertiaryContainer;
    return Card(
      color: bg,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Wrap(
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 6,
                    runSpacing: 4,
                    children: [
                      Text(
                        entry.theme,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(color: fg),
                      ),
                      _TrendIcon(trend: entry.trend, color: fg),
                      _ConfidenceBadge(
                        confidence: entry.confidence,
                        sampleSize: entry.stats.totalAttempts,
                        color: fg,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$pct% · $speedLabel',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: fg),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              entry.insight,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: fg),
            ),
          ],
        ),
      ),
    );
  }
}

class _UnattemptedRow extends StatelessWidget {
  const _UnattemptedRow({required this.theme});
  final String theme;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: 0.55,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Expanded(
              child: Text(
                theme,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Text(
              'not attempted',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactRow extends StatelessWidget {
  const _CompactRow({required this.entry});
  final WeaknessEntry entry;

  @override
  Widget build(BuildContext context) {
    final pct = (entry.stats.rawAccuracy * 100).round();
    final secs =
        (entry.stats.averageTime.inMilliseconds / 1000).toStringAsFixed(1);
    final isLow = entry.confidence == ConfidenceLevel.low;
    final scheme = Theme.of(context).colorScheme;
    return Opacity(
      opacity: isLow ? 0.55 : 1,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      Flexible(
                        child: Text(
                          entry.theme,
                          softWrap: true,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 6),
                      _TrendIcon(trend: entry.trend, color: scheme.onSurface),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '$pct% · n=${entry.stats.totalAttempts} · ${secs}s',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: entry.stats.rawAccuracy,
                minHeight: 10,
                backgroundColor: scheme.surfaceContainerHigh,
                valueColor:
                    AlwaysStoppedAnimation(_color(entry.stats.rawAccuracy)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _color(double accuracy) {
    if (accuracy >= 0.8) return const Color(0xFF2E7D32);
    if (accuracy >= 0.6) return const Color(0xFFF9A825);
    return const Color(0xFFC62828);
  }
}

class _TrendIcon extends StatelessWidget {
  const _TrendIcon({required this.trend, required this.color});
  final TrendDirection trend;
  final Color color;

  @override
  Widget build(BuildContext context) {
    switch (trend) {
      case TrendDirection.improving:
        return Icon(Icons.arrow_upward,
            size: 14, color: color.withValues(alpha: 0.85));
      case TrendDirection.declining:
        return Icon(Icons.arrow_downward,
            size: 14, color: color.withValues(alpha: 0.85));
      case TrendDirection.stable:
        return const SizedBox(width: 14);
    }
  }
}

class _ConfidenceBadge extends StatelessWidget {
  const _ConfidenceBadge({
    required this.confidence,
    required this.sampleSize,
    required this.color,
  });
  final ConfidenceLevel confidence;
  final int sampleSize;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (confidence == ConfidenceLevel.high) return const SizedBox.shrink();
    final label = 'n=$sampleSize';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, color: color),
      ),
    );
  }
}
