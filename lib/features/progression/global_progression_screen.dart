import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/global_stats.dart';
import '../../data/repositories/stats_repository.dart';
import '../../widgets/empty_state.dart';
import '../../widgets/error_view.dart';
import 'widgets/bar_chart.dart';
import 'widgets/trend_chart.dart';

class GlobalProgressionScreen extends ConsumerWidget {
  const GlobalProgressionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final globalAsync = ref.watch(globalStatsProvider);
    final setsAsync = ref.watch(setActivitiesProvider);
    final dailyAsync = ref.watch(dailyActivityProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Overall progression')),
      body: globalAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const ErrorView(),
        data: (stats) {
          if (stats.totalAttempts == 0) {
            return const Center(
              child: EmptyState(
                icon: Icons.insights_outlined,
                title: 'No attempts yet',
                body: 'Solve some puzzles to see your progression.',
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _SummaryCards(stats: stats),
              const SizedBox(height: 24),
              Text('Daily accuracy',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              dailyAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => const ErrorView(compact: true),
                data: (daily) => _DailySection(daily: daily),
              ),
              const SizedBox(height: 24),
              Text('By set',
                  style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              setsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => const ErrorView(compact: true),
                data: (activities) => _SetsSection(
                  activities:
                      activities.where((a) => a.totalAttempts > 0).toList(),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _SummaryCards extends StatelessWidget {
  const _SummaryCards({required this.stats});
  final GlobalStats stats;

  @override
  Widget build(BuildContext context) {
    final pct = (stats.accuracy * 100).round();
    final hours = stats.totalTime.inMinutes / 60.0;
    final timeStr = hours >= 1
        ? '${hours.toStringAsFixed(1)} h'
        : '${stats.totalTime.inMinutes} min';
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _StatCard(label: 'Rounds done', value: '${stats.totalRoundsCompleted}'),
        _StatCard(label: 'Puzzles solved', value: '${stats.correctAttempts}'),
        _StatCard(label: 'Accuracy', value: '$pct%'),
        _StatCard(label: 'Trained', value: timeStr),
        if (stats.totalHints > 0)
          _StatCard(label: 'Hints used', value: '${stats.totalHints}'),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 110,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.surfaceContainerHighest,
            Theme.of(context).colorScheme.surfaceContainer,
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context)
              .colorScheme
              .outlineVariant
              .withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _DailySection extends StatelessWidget {
  const _DailySection({required this.daily});
  final List<DailyActivity> daily;

  @override
  Widget build(BuildContext context) {
    if (daily.isEmpty) {
      return const EmptyState(
        icon: Icons.event_busy_outlined,
        title: 'No activity yet',
        body: 'Solve puzzles to fill in your last 30 days.',
        compact: true,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TrendChart(
          title: 'Accuracy %',
          series: [
            TrendSeries(
              label: 'Daily',
              color: const Color(0xFF2E7D32),
              values: daily.map((d) => d.accuracy * 100).toList(),
            ),
          ],
          yMin: 0,
          yMax: 100,
        ),
        const SizedBox(height: 12),
        BarChart(
          title: 'Puzzles attempted per day',
          values: daily.map((d) => d.totalAttempts.toDouble()).toList(),
          color: const Color(0xFF1565C0),
        ),
      ],
    );
  }
}

class _SetsSection extends StatelessWidget {
  const _SetsSection({required this.activities});
  final List<SetActivity> activities;

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return const EmptyState(
        icon: Icons.collections_bookmark_outlined,
        title: 'No sets played yet',
        body: 'Build a set and run a round to populate this section.',
        compact: true,
      );
    }
    return Column(
      children: [
        BarChart(
          title: 'Rounds per set',
          values: activities
              .map((a) => a.roundsCompleted.toDouble())
              .toList(),
          color: const Color(0xFF6A1B9A),
        ),
        const SizedBox(height: 8),
        for (final a in activities)
          Card(
            child: ListTile(
              dense: true,
              title: Text(a.setName),
              subtitle: Text(
                '${a.roundsCompleted} round${a.roundsCompleted == 1 ? '' : 's'} · '
                '${a.correctAttempts}/${a.totalAttempts} '
                '(${(a.accuracy * 100).round()}%)',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => context.push('/sets/${a.setId}/progression'),
            ),
          ),
      ],
    );
  }
}
