import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/global_stats.dart';
import '../../data/repositories/bot_game_repository.dart';
import '../../data/repositories/puzzle_repository.dart';
import '../../data/repositories/round_repository.dart';
import '../../data/repositories/set_repository.dart';
import '../../data/repositories/stats_repository.dart';
import '../../data/repositories/user_state_repository.dart';
import '../../services/app_preferences.dart';
import '../../widgets/error_view.dart';
import '../bot/bot_config.dart';
import '../onboarding/onboarding_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _onboardingShown = false;

  void _maybeShowOnboarding() {
    if (_onboardingShown) return;
    final onboarded = ref.read(onboardedProvider);
    if (onboarded) return;
    _onboardingShown = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => const OnboardingScreen(),
          fullscreenDialog: true,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    _maybeShowOnboarding();
    final puzzleSeed = ref.watch(puzzleSeedProvider);
    if (puzzleSeed is AsyncLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.fitness_center, size: 64),
              SizedBox(height: 16),
              Text('Preparing puzzle library...'),
              SizedBox(height: 16),
              CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }
    final setsAsync = ref.watch(allSetsProvider);
    final activeBotAsync = ref.watch(activeBotGameProvider);
    final userAsync = ref.watch(userStateProvider);
    final globalStatsAsync = ref.watch(globalStatsProvider);
    final archivedAsync = ref.watch(archivedSetsProvider);
    final recentActivityAsync = ref.watch(recentSetActivityProvider);

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 20,
        title: const Text('Woodpecker'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: setsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => const ErrorView(),
        data: (sets) => ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            _HeroStats(
              userAsync: userAsync,
              globalStatsAsync: globalStatsAsync,
            ),
            const SizedBox(height: 24),
            _ResumeBotCard(activeBotAsync: activeBotAsync),
            _ContinueTrainingCard(
              recentActivityAsync: recentActivityAsync,
              setsAsync: setsAsync,
            ),
            const SizedBox(height: 24),
            _SectionLabel('Quick play'),
            const SizedBox(height: 8),
            const _QuickActionsGrid(),
            const SizedBox(height: 28),
            _MySetsHeader(archivedAsync: archivedAsync),
            const SizedBox(height: 8),
            if (sets.isEmpty)
              _EmptySetsHint()
            else
              for (final set in sets) ...[
                _SetTile(set: set),
                const SizedBox(height: 8),
              ],
            const SizedBox(height: 24),
            _SectionLabel('Insights'),
            const SizedBox(height: 8),
            const _InsightsGrid(),
          ],
        ),
      ),
    );
  }
}

class _HeroStats extends StatelessWidget {
  const _HeroStats({
    required this.userAsync,
    required this.globalStatsAsync,
  });

  final AsyncValue<UserState> userAsync;
  final AsyncValue<GlobalStats> globalStatsAsync;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final user = userAsync.value;
    final stats = globalStatsAsync.value;
    return GestureDetector(
      onTap: () => GoRouter.of(context).push('/elo-history'),
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              scheme.surfaceContainerHigh,
              scheme.surfaceContainerLow,
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: scheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.18),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your rating',
                    style: Theme.of(context)
                        .textTheme
                        .labelMedium
                        ?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user == null ? '-' : '${user.elo}',
                    style: Theme.of(context).textTheme.displaySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            _StatPill(
              label: 'Attempts',
              value: stats == null ? '-' : '${stats.totalAttempts}',
            ),
            const SizedBox(width: 8),
            _StatPill(
              label: 'Accuracy',
              value: (stats == null || stats.totalAttempts == 0)
                  ? '-'
                  : '${(stats.accuracy * 100).round()}%',
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  const _StatPill({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: scheme.outlineVariant.withValues(alpha: 0.5),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.10),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
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

class _ResumeBotCard extends StatelessWidget {
  const _ResumeBotCard({required this.activeBotAsync});
  final AsyncValue<BotGameSnapshot?> activeBotAsync;

  @override
  Widget build(BuildContext context) {
    final snapshot = activeBotAsync.value;
    if (snapshot == null) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: scheme.primaryContainer,
        borderRadius: BorderRadius.circular(16),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => GoRouter.of(context).push(
            '/play-bot/game',
            extra: (
              config: BotConfig(
                level: snapshot.level,
                userSide: snapshot.userSide,
              ),
              snapshot: snapshot,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.play_circle_outline,
                    color: scheme.onPrimaryContainer),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Resume game vs ${snapshot.level.label}',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(color: scheme.onPrimaryContainer),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Pick up where you left off',
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: scheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right,
                    color: scheme.onPrimaryContainer),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContinueTrainingCard extends StatelessWidget {
  const _ContinueTrainingCard({
    required this.recentActivityAsync,
    required this.setsAsync,
  });

  final AsyncValue<RecentSetActivity?> recentActivityAsync;
  final AsyncValue<List<dynamic>> setsAsync;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final recent = recentActivityAsync.value;
    final sets = setsAsync.value ?? const [];

    final String title;
    final String subtitle;
    final IconData icon;
    final VoidCallback onTap;

    if (recent != null && !recent.isComplete) {
      // Resume the in-progress round.
      title = 'Resume ${recent.setName}';
      subtitle = 'Round ${recent.roundNumber} · puzzle '
          '${recent.currentPosition + 1}/${recent.totalPuzzles}';
      icon = Icons.play_arrow_rounded;
      onTap = () => GoRouter.of(context).push(
            '/sets/${recent.setId}/rounds/${recent.roundId}',
          );
    } else if (recent != null) {
      // Last round completed - drop into set detail to start the next round.
      title = 'Continue ${recent.setName}';
      subtitle = 'Last round complete · start round '
          '${recent.roundNumber + 1}';
      icon = Icons.replay_rounded;
      onTap = () => GoRouter.of(context).push('/sets/${recent.setId}');
    } else if (sets.isNotEmpty) {
      title = 'Open ${sets.first.name}';
      subtitle = 'Tap to start your first round';
      icon = Icons.play_arrow_rounded;
      onTap =
          () => GoRouter.of(context).push('/sets/${sets.first.id}');
    } else {
      title = 'Start training';
      subtitle = 'Build a recommended set tailored to you';
      icon = Icons.fitness_center;
      onTap = () => GoRouter.of(context).push('/sets/new');
    }

    return Material(
      color: scheme.primary,
      borderRadius: BorderRadius.circular(20),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: scheme.onPrimary.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: scheme.onPrimary, size: 26),
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
                          .titleLarge
                          ?.copyWith(color: scheme.onPrimary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: Theme.of(context)
                          .textTheme
                          .bodyMedium
                          ?.copyWith(
                            color: scheme.onPrimary
                                .withValues(alpha: 0.85),
                          ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward,
                  color: scheme.onPrimary, size: 22),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickActionsGrid extends StatelessWidget {
  const _QuickActionsGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _QuickAction(
            icon: Icons.add_box_outlined,
            title: 'New set',
            subtitle: 'Build training',
            route: '/sets/new',
            accent: _Accent.primary,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _QuickAction(
            icon: Icons.shuffle,
            title: 'Random',
            subtitle: 'Free play',
            route: '/random',
            accent: _Accent.tertiary,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _QuickAction(
            icon: Icons.smart_toy_outlined,
            title: 'Bot',
            subtitle: 'Stockfish',
            route: '/play-bot',
            accent: _Accent.secondary,
          ),
        ),
      ],
    );
  }
}

enum _Accent { primary, secondary, tertiary, neutral }

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.route,
    this.accent = _Accent.neutral,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final String route;
  final _Accent accent;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (Color iconBg, Color iconColor) = switch (accent) {
      _Accent.primary => (scheme.primaryContainer, scheme.onPrimaryContainer),
      _Accent.secondary => (
          scheme.secondaryContainer,
          scheme.onSecondaryContainer
        ),
      _Accent.tertiary => (
          scheme.tertiaryContainer,
          scheme.onTertiaryContainer
        ),
      _Accent.neutral => (scheme.surfaceContainer, scheme.onSurface),
    };
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => GoRouter.of(context).push(route),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(16),
          ),
          padding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: iconColor, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context)
                    .textTheme
                    .labelSmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
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

class _MySetsHeader extends StatelessWidget {
  const _MySetsHeader({required this.archivedAsync});
  final AsyncValue<List<dynamic>> archivedAsync;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _SectionLabel('My sets')),
        archivedAsync.maybeWhen(
          data: (archived) => archived.isEmpty
              ? const SizedBox.shrink()
              : TextButton.icon(
                  onPressed: () => GoRouter.of(context).push('/archived'),
                  icon: const Icon(Icons.archive_outlined, size: 18),
                  label: Text('Archived (${archived.length})'),
                ),
          orElse: () => const SizedBox.shrink(),
        ),
      ],
    );
  }
}

class _EmptySetsHint extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Column(
        children: [
          Icon(Icons.add_box_outlined,
              color: scheme.onSurfaceVariant, size: 28),
          const SizedBox(height: 10),
          Text(
            'No sets yet',
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 4),
          Text(
            'Tap "Start training" above to build your first set.',
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: scheme.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _SetTile extends ConsumerWidget {
  const _SetTile({required this.set});
  final dynamic set;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final roundsAsync = ref.watch(setRoundsStatsProvider(set.id));
    final completedRounds = roundsAsync.maybeWhen(
      data: (rounds) =>
          rounds.where((r) => r.completedAt != null).length,
      orElse: () => 0,
    );
    final lastAccuracy = roundsAsync.maybeWhen(
      data: (rounds) {
        final completed =
            rounds.where((r) => r.completedAt != null).toList();
        if (completed.isEmpty) return null;
        return completed.last.accuracy;
      },
      orElse: () => null,
    );
    return Material(
      color: scheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => GoRouter.of(context).push('/sets/${set.id}'),
        onLongPress: () => _showSetActions(context, ref, set),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: scheme.outlineVariant),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      set.name,
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${set.size} puzzles · '
                      '${set.filter.ratingMin}-${set.filter.ratingMax}',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (completedRounds > 0)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'R$completedRounds',
                      style: Theme.of(context)
                          .textTheme
                          .labelMedium
                          ?.copyWith(color: scheme.onSurfaceVariant),
                    ),
                    if (lastAccuracy != null)
                      Text(
                        '${(lastAccuracy * 100).round()}%',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                  ],
                ),
              const SizedBox(width: 4),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightsGrid extends StatelessWidget {
  const _InsightsGrid();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: const [
        Expanded(
          child: _QuickAction(
            icon: Icons.compare_arrows,
            title: 'Themes',
            subtitle: 'Strengths',
            route: '/strengths',
            accent: _Accent.primary,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _QuickAction(
            icon: Icons.insights_outlined,
            title: 'Progress',
            subtitle: 'All sets',
            route: '/progression',
            accent: _Accent.tertiary,
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: _QuickAction(
            icon: Icons.timeline,
            title: 'Elo',
            subtitle: 'History',
            route: '/elo-history',
            accent: _Accent.secondary,
          ),
        ),
      ],
    );
  }
}

Future<void> _showSetActions(
  BuildContext context,
  WidgetRef ref,
  dynamic set,
) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    showDragHandle: true,
    builder: (ctx) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                set.name,
                style: Theme.of(ctx).textTheme.titleMedium,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.open_in_new),
            title: const Text('Open'),
            onTap: () => Navigator.pop(ctx, 'open'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_outlined),
            title: const Text('Rename'),
            onTap: () => Navigator.pop(ctx, 'rename'),
          ),
          ListTile(
            leading: const Icon(Icons.archive_outlined),
            title: const Text('Archive'),
            onTap: () => Navigator.pop(ctx, 'archive'),
          ),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: Colors.red),
            title: const Text('Delete'),
            onTap: () => Navigator.pop(ctx, 'delete'),
          ),
          const SizedBox(height: 8),
        ],
      ),
    ),
  );
  if (action == null || !context.mounted) return;
  final repo = ref.read(setRepositoryProvider);
  final messenger = ScaffoldMessenger.of(context);
  switch (action) {
    case 'open':
      GoRouter.of(context).push('/sets/${set.id}');
    case 'rename':
      final controller = TextEditingController(text: set.name);
      final newName = await showDialog<String>(
        context: context,
        builder: (dctx) => AlertDialog(
          title: const Text('Rename set'),
          content: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Set name'),
            onSubmitted: (v) => Navigator.pop(dctx, v.trim()),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dctx, controller.text.trim()),
              child: const Text('Save'),
            ),
          ],
        ),
      );
      if (newName == null || newName.isEmpty || newName == set.name) return;
      await repo.rename(set.id, newName);
      ref.invalidate(setByIdProvider(set.id));
      ref.invalidate(allSetsProvider);
    case 'archive':
      await repo.archive(set.id);
      ref.invalidate(allSetsProvider);
      ref.invalidate(archivedSetsProvider);
      messenger.showSnackBar(SnackBar(
        content: Text('Archived "${set.name}"'),
        behavior: SnackBarBehavior.floating,
      ));
    case 'delete':
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dctx) => AlertDialog(
          title: const Text('Delete set?'),
          content: Text(
              'Permanently delete "${set.name}" and all its rounds and attempts.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dctx, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
      await repo.delete(set.id);
      ref.invalidate(allSetsProvider);
      messenger.showSnackBar(SnackBar(
        content: Text('Deleted "${set.name}"'),
        behavior: SnackBarBehavior.floating,
      ));
  }
}
