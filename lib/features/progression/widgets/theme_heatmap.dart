import 'package:flutter/material.dart';

import '../../../data/models/theme_stats.dart';
import '../../../widgets/empty_state.dart';

class ThemeHeatmap extends StatelessWidget {
  const ThemeHeatmap({super.key, required this.stats});

  final List<ThemeStats> stats;

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return const EmptyState(
        icon: Icons.donut_small,
        title: 'No theme data yet',
        body: 'Complete a round to see per-tactic breakdowns.',
        compact: true,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final t in stats) _Row(stat: t),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.stat});
  final ThemeStats stat;

  @override
  Widget build(BuildContext context) {
    final pct = (stat.accuracy * 100).round();
    final avgSec =
        (stat.averageTime.inMilliseconds / 1000).toStringAsFixed(1);
    final color = _accuracyColor(stat.accuracy);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          SizedBox(
            width: 110,
            child: Text(
              stat.theme,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: stat.accuracy,
                minHeight: 14,
                backgroundColor:
                    Theme.of(context).colorScheme.surfaceContainerHigh,
                valueColor: AlwaysStoppedAnimation(color),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 100,
            child: Text(
              '$pct% · ${avgSec}s',
              textAlign: TextAlign.right,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ],
      ),
    );
  }
}

Color _accuracyColor(double accuracy) {
  if (accuracy >= 0.8) return const Color(0xFF2E7D32); // green
  if (accuracy >= 0.6) return const Color(0xFFF9A825); // amber
  return const Color(0xFFC62828); // red
}
