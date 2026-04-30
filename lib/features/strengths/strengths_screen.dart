import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/enriched_theme_stats.dart';
import '../../data/models/weakness_entry.dart';
import '../../data/repositories/stats_repository.dart';
import '../../data/repositories/user_state_repository.dart';
import '../../services/training_recommender.dart';
import '../../services/pro_status.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import '../../widgets/pro_lock.dart';
import '../paywall/paywall_screen.dart';
import 'widgets/phase_radar.dart';
import 'widgets/theme_explainer_sheet.dart';

class StrengthsScreen extends ConsumerWidget {
  const StrengthsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analysisAsync = ref.watch(weaknessAnalysisProvider);
    final userAsync = ref.watch(userStateProvider);
    final phaseAsync = ref.watch(phaseStatsProvider);
    final allThemesAsync = ref.watch(allTacticalThemesProvider);
    final globalStatsAsync = ref.watch(globalStatsProvider);
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
      body: !ref.watch(isProProvider)
          ? _StrengthsSneakPeek(
              analysisAsync: analysisAsync,
              phaseAsync: phaseAsync,
              globalStatsAsync: globalStatsAsync,
            )
          : analysisAsync.when(
        loading: () => const _StrengthsLoading(),
        error: (e, _) => ErrorView(
          onRetry: () {
            ref.invalidate(weaknessAnalysisProvider);
            ref.invalidate(phaseStatsProvider);
            ref.invalidate(globalStatsProvider);
          },
        ),
        data: (entries) {
          // True unique-attempt count from the attempts table (not the sum
          // across themes - each puzzle has multiple tactical themes, so
          // summing per-theme totals would over- or undercount depending on
          // how many tactical themes pass the filter).
          final totalAttempts = globalStatsAsync.maybeWhen(
            data: (g) => g.totalAttempts,
            orElse: () => 0,
          );
          if (entries.isEmpty || totalAttempts < 1) {
            return Center(
              child: EmptyState(
                icon: Icons.compare_arrows,
                title: 'No theme data yet',
                body:
                    'Solve a puzzle to start populating per-theme insights. '
                    'Confidence levels grow as you build attempts.',
              ),
            );
          }
          final highConf = entries
              .where((e) => e.confidence != ConfidenceLevel.low)
              .toList();
          // Split the ranked list so weaknesses and strengths never overlap.
          // With <6 high-confidence themes there isn't enough data to call
          // anything a "strength" - show only the weak end and a hint.
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
                  child: _StrengthsLoadingCard(),
                ),
                error: (e, _) => ErrorView(
                  compact: true,
                  onRetry: () => ref.invalidate(phaseStatsProvider),
                ),
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
                "confidence interval, not raw accuracy. With few attempts "
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
                '6 high-confidence themes; otherwise everything would be '
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
      messenger.showSnackBar(
        const SnackBar(
          content: Text(
            'Could not build a recommended set right now. Please try again.',
          ),
        ),
      );
    }
  }
}

class _StrengthsLoading extends StatelessWidget {
  const _StrengthsLoading();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _StrengthsLoadingCard(
          height: 56,
          color: scheme.tertiaryContainer,
        ),
        const SizedBox(height: 16),
        _StrengthsLoadingCard(height: 14, width: 220),
        const SizedBox(height: 20),
        _StrengthsLoadingCard(height: 16, width: 110),
        const SizedBox(height: 8),
        _StrengthsLoadingCard(height: 240),
        const SizedBox(height: 20),
        _StrengthsLoadingCard(height: 16, width: 140),
        const SizedBox(height: 8),
        for (var i = 0; i < 3; i++) ...[
          _StrengthsLoadingCard(height: 90),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}

class _StrengthsLoadingCard extends StatelessWidget {
  const _StrengthsLoadingCard({
    this.height = 88,
    this.width,
    this.color,
  });

  final double height;
  final double? width;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(12),
      ),
    );
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
      text = 'Exploring your style. Solve ${30 - totalAttempts} more '
          'puzzles for high-confidence analysis.';
      bg = scheme.tertiaryContainer;
      fg = scheme.onTertiaryContainer;
      icon = Icons.explore_outlined;
    } else if (highConfCount < 3) {
      text = 'Confidence improving. Most themes still need more data. '
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
                      InkWell(
                        onTap: () =>
                            ThemeExplainerSheet.show(context, entry.theme),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              entry.theme,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(color: fg),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.info_outline, size: 14, color: fg),
                          ],
                        ),
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
    return InkWell(
      onTap: () => ThemeExplainerSheet.show(context, theme),
      child: Opacity(
        opacity: 0.55,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        theme,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.info_outline,
                        size: 14, color: scheme.onSurfaceVariant),
                  ],
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
    return InkWell(
      onTap: () => ThemeExplainerSheet.show(context, entry.theme),
      child: Opacity(
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
                      const SizedBox(width: 4),
                      Icon(Icons.info_outline,
                          size: 14, color: scheme.onSurfaceVariant),
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

class _StrengthsSneakPeek extends StatelessWidget {
  const _StrengthsSneakPeek({
    required this.analysisAsync,
    required this.phaseAsync,
    required this.globalStatsAsync,
  });

  final AsyncValue<List<WeaknessEntry>> analysisAsync;
  final AsyncValue<dynamic> phaseAsync;
  final AsyncValue<dynamic> globalStatsAsync;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final entries = analysisAsync.value ?? const <WeaknessEntry>[];
    final highConf = entries
        .where((e) => e.confidence != ConfidenceLevel.low)
        .toList();
    final topWeakness = highConf.isNotEmpty ? highConf.first : null;
    final remainingThemes = (entries.length - 1).clamp(0, 999);
    final phase = phaseAsync.value;
    final hiddenWeaknesses = highConf.length > 1
        ? highConf.skip(1).take(3).toList()
        : const <WeaknessEntry>[];
    final weakIds = highConf.take(1).map((e) => e.theme).toSet();
    final hiddenStrengths = highConf.length >= 6
        ? highConf.reversed
            .where((e) => !weakIds.contains(e.theme))
            .take(3)
            .toList()
            .reversed
            .toList()
        : const <WeaknessEntry>[];

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 220),
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: scheme.primary.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.visibility_outlined,
                      size: 18, color: scheme.onPrimaryContainer),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Preview · Pro unlocks the full per-theme breakdown',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onPrimaryContainer,
                          ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text('Game phases',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (phase != null)
              PhaseRadar(stats: phase)
            else
              const SizedBox(
                height: 240,
                child: Center(child: CircularProgressIndicator()),
              ),
            const SizedBox(height: 24),
            Text('Your top weakness',
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            if (topWeakness != null)
              _Entry(entry: topWeakness, weakness: true)
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: scheme.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  'Solve a few more puzzles to surface your first '
                  'high-confidence weakness here.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                ),
              ),
            const SizedBox(height: 24),
            Stack(
              children: [
                IgnorePointer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Other weaknesses',
                          style:
                              Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (hiddenWeaknesses.isEmpty)
                        for (var i = 0; i < 2; i++)
                          _LockedBar(
                            accuracy: i == 0 ? 0.55 : 0.65,
                            placeholder: true,
                          )
                      else
                        for (final w in hiddenWeaknesses)
                          _LockedBar(
                            accuracy: w.stats.rawAccuracy,
                            placeholder: false,
                          ),
                      const SizedBox(height: 16),
                      Text('Top 3 strengths',
                          style:
                              Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      if (hiddenStrengths.isEmpty)
                        for (var i = 0; i < 2; i++)
                          _LockedBar(
                            accuracy: i == 0 ? 0.85 : 0.92,
                            placeholder: true,
                          )
                      else
                        for (final s in hiddenStrengths)
                          _LockedBar(
                            accuracy: s.stats.rawAccuracy,
                            placeholder: false,
                          ),
                    ],
                  ),
                ),
                Positioned.fill(
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: scheme.surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: scheme.outlineVariant),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.lock_outline, size: 14),
                          const SizedBox(width: 6),
                          Text(
                            '$remainingThemes more themes locked',
                            style:
                                Theme.of(context).textTheme.labelMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            decoration: BoxDecoration(
              color: scheme.surface,
              border:
                  Border(top: BorderSide(color: scheme.outlineVariant)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.10),
                  blurRadius: 12,
                  offset: const Offset(0, -4),
                ),
              ],
            ),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const ProBadge(),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Per-theme breakdown, weakness drill, phase '
                          'radar with insights, trend tracking.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  FilledButton.icon(
                    onPressed: () => PaywallScreen.show(
                      context,
                      headline: 'Strengths analysis',
                      subhead:
                          'Per-theme Wilson-score breakdown, phase radar, '
                          'weakness drill, trend tracking. The actionable '
                          'insight that drives improvement.',
                    ),
                    icon: const Icon(Icons.star),
                    label: const Text('Unlock Pro'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Color-coded horizontal bar that reveals only the accuracy *direction*
/// without naming the theme. Looks like a loading-screen progress indicator.
class _LockedBar extends StatelessWidget {
  const _LockedBar({required this.accuracy, required this.placeholder});

  final double accuracy;
  // True if there is no real data yet - render with subtle stripes.
  final bool placeholder;

  Color _accuracyColor(double a) {
    if (a >= 0.8) return const Color(0xFF2E7D32);
    if (a >= 0.6) return const Color(0xFFF9A825);
    return const Color(0xFFC62828);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = _accuracyColor(accuracy);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          // Redacted theme-name placeholder.
          Container(
            width: 90,
            height: 12,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(7),
              child: LinearProgressIndicator(
                value: accuracy.clamp(0.05, 0.98),
                minHeight: 14,
                backgroundColor: scheme.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation(
                  color.withValues(alpha: placeholder ? 0.55 : 0.9),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          // Redacted percentage placeholder.
          Container(
            width: 36,
            height: 12,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        ],
      ),
    );
  }
}
