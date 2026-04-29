import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/elo_history_entry.dart';
import '../../data/repositories/user_state_repository.dart';
import '../progression/widgets/trend_chart.dart';

class EloHistoryScreen extends ConsumerWidget {
  const EloHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(eloHistoryProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Elo over time')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (history) {
          if (history.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No Elo history yet — solve some random puzzles to start '
                  'tracking your rating.',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          // Down-sample very long histories so the chart stays legible and
          // rendering stays cheap. Always include the very last point so the
          // current Elo is accurate.
          const maxPoints = 200;
          List<double> values;
          if (history.length <= maxPoints) {
            values = history.map((e) => e.eloAfter.toDouble()).toList();
          } else {
            final step = history.length / maxPoints;
            values = [
              for (var i = 0; i < maxPoints; i++)
                history[(i * step).floor()].eloAfter.toDouble(),
              history.last.eloAfter.toDouble(),
            ];
          }
          final start = history.first.eloBefore;
          final current = history.last.eloAfter;
          final peak = history
              .map((e) => e.eloAfter)
              .reduce((a, b) => a > b ? a : b);
          final low = history
              .map((e) => e.eloAfter)
              .reduce((a, b) => a < b ? a : b);
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TrendChart(
                title: 'Elo across ${history.length} attempts',
                series: [
                  TrendSeries(
                    label: 'Elo',
                    color: Theme.of(context).colorScheme.primary,
                    values: values,
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _MiniCard(label: 'Started', value: '$start'),
                  _MiniCard(label: 'Current', value: '$current'),
                  _MiniCard(label: 'Peak', value: '$peak'),
                  _MiniCard(label: 'Low', value: '$low'),
                  _MiniCard(label: 'Attempts', value: '${history.length}'),
                ],
              ),
              const SizedBox(height: 24),
              Text(
                'Recent activity',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              for (final entry in history.reversed.take(20))
                _ActivityTile(entry: entry),
            ],
          );
        },
      ),
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

class _ActivityTile extends StatelessWidget {
  const _ActivityTile({required this.entry});
  final EloHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final delta = entry.delta;
    final isUp = delta > 0;
    final isFlat = delta == 0;
    final color = isFlat
        ? scheme.onSurfaceVariant
        : (isUp ? const Color(0xFF2E7D32) : const Color(0xFFC62828));
    final icon = isFlat
        ? Icons.remove
        : (isUp ? Icons.arrow_upward : Icons.arrow_downward);
    final sign = isUp ? '+' : (isFlat ? '' : '');
    return InkWell(
      onTap: () => context.push('/puzzles/${entry.puzzleId}'),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                '#${entry.puzzleId} · rating ${entry.puzzleRating}',
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ),
            Text(
              '$sign$delta',
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: color, fontWeight: FontWeight.w600),
            ),
            const SizedBox(width: 8),
            Text(
              '→ ${entry.eloAfter}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
