import 'dart:math';

import 'package:confetti/confetti.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../data/models/outlier_attempt.dart';
import '../../../data/models/round_comparison.dart';
import '../../../data/models/round_stats.dart';
import '../../../data/models/tactical_themes.dart';
import '../../../data/repositories/round_repository.dart';

class RoundSummaryDialog extends ConsumerStatefulWidget {
  const RoundSummaryDialog({
    super.key,
    required this.roundId,
    required this.setId,
    required this.onBackToSet,
    required this.onViewProgression,
    required this.onArchive,
  });

  final String roundId;
  final String setId;
  final VoidCallback onBackToSet;
  final VoidCallback onViewProgression;
  final VoidCallback onArchive;

  @override
  ConsumerState<RoundSummaryDialog> createState() =>
      _RoundSummaryDialogState();
}

class _Mastery {
  const _Mastery({required this.mastered, required this.speedupPct});
  final bool mastered;
  final int speedupPct;
}

class _RoundSummaryDialogState extends ConsumerState<RoundSummaryDialog> {
  final _confettiController =
      ConfettiController(duration: const Duration(seconds: 2));
  bool _confettiTriggered = false;

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  void _maybeFireConfetti(double accuracy) {
    if (_confettiTriggered) return;
    if (accuracy >= 0.85) {
      _confettiTriggered = true;
      _confettiController.play();
    }
  }

  _Mastery _checkMastery(
      RoundComparison comparison, List<RoundStats> allRounds) {
    final cur = comparison.current;
    final prev = comparison.previous;
    if (allRounds.length < 2 || cur.roundNumber < 3 || prev == null) {
      return const _Mastery(mastered: false, speedupPct: 0);
    }
    final first = allRounds.first;
    final firstMs = first.medianTime.inMilliseconds;
    if (firstMs == 0) return const _Mastery(mastered: false, speedupPct: 0);
    final speedupRatio = 1 - (cur.medianTime.inMilliseconds / firstMs);
    final pct = (speedupRatio * 100).round();
    final accuracyOk = cur.accuracy >= 0.9 && prev.accuracy >= 0.85;
    final speedOk = speedupRatio >= 0.35;
    return _Mastery(mastered: accuracyOk && speedOk, speedupPct: pct);
  }

  List<Widget> _buildActions(
      AsyncValue<RoundComparison> compAsync,
      AsyncValue<List<RoundStats>> allRoundsAsync) {
    final mastery = compAsync.maybeWhen(
      data: (comparison) {
        final all = allRoundsAsync.maybeWhen(
            data: (r) => r, orElse: () => const <RoundStats>[]);
        return _checkMastery(comparison, all);
      },
      orElse: () => const _Mastery(mastered: false, speedupPct: 0),
    );
    if (mastery.mastered) {
      return [
        TextButton(
          onPressed: widget.onViewProgression,
          child: const Text('View progression'),
        ),
        OutlinedButton(
          onPressed: widget.onBackToSet,
          child: const Text('Back to set'),
        ),
        FilledButton.icon(
          onPressed: widget.onArchive,
          icon: const Icon(Icons.archive_outlined),
          label: const Text('Archive set'),
        ),
      ];
    }
    return [
      TextButton(
        onPressed: widget.onViewProgression,
        child: const Text('View progression'),
      ),
      FilledButton(
        onPressed: widget.onBackToSet,
        child: const Text('Back to set'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final compAsync =
        ref.watch(roundComparisonProvider(widget.roundId));
    final allRoundsAsync = ref.watch(setRoundsStatsProvider(widget.setId));
    final outliersAsync = ref.watch(
      outliersProvider((roundId: widget.roundId, limit: 3)),
    );
    return Stack(
      alignment: Alignment.topCenter,
      children: [
        AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: SingleChildScrollView(
              child: compAsync.when(
                loading: () => const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (e, _) => Text('Error: $e'),
                data: (comparison) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _maybeFireConfetti(comparison.current.accuracy);
                  });
                  final allRounds =
                      allRoundsAsync.maybeWhen(data: (r) => r, orElse: () => const <RoundStats>[]);
                  return _Body(
                    comparison: comparison,
                    outliersAsync: outliersAsync,
                    mastery: _checkMastery(comparison, allRounds),
                  );
                },
              ),
            ),
          ),
          actions: _buildActions(compAsync, allRoundsAsync),
        ),
        IgnorePointer(
          child: ConfettiWidget(
            confettiController: _confettiController,
            blastDirection: pi / 2,
            blastDirectionality: BlastDirectionality.explosive,
            emissionFrequency: 0.05,
            numberOfParticles: 30,
            gravity: 0.4,
            shouldLoop: false,
            colors: const [
              Color(0xFF4CAF50),
              Color(0xFF8BC34A),
              Color(0xFFFFC107),
              Color(0xFF2196F3),
            ],
          ),
        ),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.comparison,
    required this.outliersAsync,
    required this.mastery,
  });

  final RoundComparison comparison;
  final AsyncValue<List<OutlierAttempt>> outliersAsync;
  final _Mastery mastery;

  @override
  Widget build(BuildContext context) {
    final stats = comparison.current;
    final accuracyPct = (stats.accuracy * 100).round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'Round ${stats.roundNumber} complete',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 12),
        _StatRow(
          icon: Icons.check_circle_outline,
          label: '${stats.correct} / ${stats.total} ($accuracyPct%)',
        ),
        if (stats.hintsUsed > 0)
          _StatRow(
            icon: Icons.lightbulb_outline,
            label: '${stats.hintsUsed} hint${stats.hintsUsed == 1 ? '' : 's'} used',
          ),
        const SizedBox(height: 4),
        _StatRow(
          icon: Icons.timer_outlined,
          label: 'Total: ${_fmt(stats.totalTime)}',
        ),
        _StatRow(
          icon: Icons.access_time,
          label: 'Avg ${_fmt(stats.averageTime)} · '
              'Median ${_fmt(stats.medianTime)}',
        ),
        if (stats.longestFlowStreak >= 3)
          _StatRow(
            icon: Icons.local_fire_department_outlined,
            label: 'Flow streak: ${stats.longestFlowStreak} in a row',
          ),
        if (comparison.previous != null) ...[
          const Divider(height: 24),
          Text(
            'vs Round ${comparison.previous!.roundNumber}',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          _DeltaRow(
            label: 'accuracy',
            delta: comparison.accuracyDelta * 100,
            unit: '%',
            higherIsBetter: true,
            decimals: 1,
          ),
          _DeltaRow(
            label: 'median',
            delta: comparison.medianDelta.inMilliseconds / 1000.0,
            unit: 's',
            higherIsBetter: true, // savings positive ⇒ better
            decimals: 2,
          ),
          if (comparison.timeSavings.inMilliseconds.abs() > 100)
            _StatRow(
              icon: Icons.trending_down,
              label: comparison.timeSavings.isNegative
                  ? '${_fmt(-comparison.timeSavings)} slower overall'
                  : '${_fmt(comparison.timeSavings)} saved overall',
            ),
        ],
        if (mastery.mastered) ...[
          const Divider(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.workspace_premium, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '90%+ accuracy and ${mastery.speedupPct}% faster than '
                    'round 1. This set looks mastered — archive it and '
                    'build the next recommended?',
                  ),
                ),
              ],
            ),
          ),
        ],
        const Divider(height: 24),
        Text(
          'Hardest puzzles',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 4),
        outliersAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ),
          error: (_, _) => const SizedBox.shrink(),
          data: (outliers) {
            if (outliers.isEmpty) {
              return const Text('No data');
            }
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final o in outliers)
                  Builder(
                    builder: (ctx) {
                      final tactical = filterTactical(o.themes);
                      final suffix = tactical.isEmpty
                          ? ''
                          : ' (${tactical.take(2).join(', ')})';
                      return InkWell(
                        onTap: () =>
                            ctx.push('/puzzles/${o.attempt.puzzleId}'),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            '#${o.attempt.puzzleId} — '
                            '${_fmt(o.attempt.time)}$suffix',
                            style: Theme.of(ctx)
                                .textTheme
                                .bodySmall
                                ?.copyWith(decoration: TextDecoration.underline),
                          ),
                        ),
                      );
                    },
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow({required this.icon, required this.label});
  final IconData icon;
  final String label;
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Icon(icon, size: 18),
          const SizedBox(width: 8),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}

class _DeltaRow extends StatelessWidget {
  const _DeltaRow({
    required this.label,
    required this.delta,
    required this.unit,
    required this.higherIsBetter,
    this.decimals = 1,
  });
  final String label;
  final double delta;
  final String unit;
  final bool higherIsBetter;
  final int decimals;

  @override
  Widget build(BuildContext context) {
    final improved = higherIsBetter ? delta > 0 : delta < 0;
    final color = improved
        ? const Color(0xFF2E7D32)
        : (delta == 0
            ? Theme.of(context).colorScheme.onSurfaceVariant
            : const Color(0xFFC62828));
    final arrow = delta == 0 ? '·' : (improved ? '↑' : '↓');
    final formatted = delta.abs().toStringAsFixed(decimals);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Text(arrow, style: TextStyle(color: color, fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            '$formatted$unit $label',
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }
}

String _fmt(Duration d) {
  final ms = d.inMilliseconds.abs();
  if (ms < 60000) {
    return '${(ms / 1000).toStringAsFixed(1)}s';
  }
  final s = (ms / 1000).round();
  return '${s ~/ 60}m ${s % 60}s';
}
