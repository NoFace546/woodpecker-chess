import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/bot_game_repository.dart';
import '../../data/repositories/puzzle_repository.dart';
import '../../data/repositories/set_repository.dart';
import '../../data/repositories/user_state_repository.dart';
import '../../services/app_preferences.dart';
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
    ref.watch(puzzleSeedProvider);
    final setsAsync = ref.watch(allSetsProvider);
    final activeBotAsync = ref.watch(activeBotGameProvider);
    final userAsync = ref.watch(userStateProvider);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Woodpecker'),
        actions: [
          userAsync.maybeWhen(
            data: (u) => InkWell(
              onTap: () => context.push('/elo-history'),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 8),
                child: Text(
                  'Elo ${u.elo}',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: setsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sets) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            userAsync.maybeWhen(
              data: (u) {
                if (u.attemptsTotal >= 10) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    color: Theme.of(context).colorScheme.tertiaryContainer,
                    child: ListTile(
                      leading: const Icon(Icons.auto_graph),
                      title: const Text('Find your rating'),
                      subtitle: Text(
                        'Solve random puzzles. Your Elo adjusts per puzzle '
                        '— recommended training is more accurate after a few '
                        'attempts (${u.attemptsTotal}/10 so far).',
                      ),
                      onTap: () => context.push('/random'),
                    ),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            activeBotAsync.maybeWhen(
              data: (snapshot) {
                if (snapshot == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Card(
                    color: Theme.of(context).colorScheme.primaryContainer,
                    child: ListTile(
                      leading: const Icon(Icons.play_circle_outline),
                      title: Text('Resume game vs ${snapshot.level.label}'),
                      subtitle: const Text('Pick up where you left off'),
                      onTap: () => context.push(
                        '/play-bot/game',
                        extra: (
                          config: BotConfig(
                            level: snapshot.level,
                            userSide: snapshot.userSide,
                          ),
                          snapshot: snapshot,
                        ),
                      ),
                    ),
                  ),
                );
              },
              orElse: () => const SizedBox.shrink(),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.add),
                title: const Text('New puzzle set'),
                subtitle: const Text('Pick rating, themes, and size'),
                onTap: () => context.push('/sets/new'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.shuffle),
                title: const Text('Random puzzle (free play)'),
                subtitle: const Text('Quick puzzles around your Elo'),
                onTap: () => context.push('/random'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.smart_toy_outlined),
                title: const Text('Play vs Computer'),
                subtitle: const Text('Stockfish, 7 difficulty levels'),
                onTap: () => context.push('/play-bot'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.insights_outlined),
                title: const Text('Overall progression'),
                subtitle: const Text('Stats across all sets'),
                onTap: () => context.push('/progression'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.compare_arrows),
                title: const Text('Strengths & weaknesses'),
                subtitle: const Text('Per-theme analysis with insights'),
                onTap: () => context.push('/strengths'),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.menu_book_outlined),
                title: const Text('What is the Woodpecker Method?'),
                subtitle: const Text(
                    'The training system this app is built around'),
                onTap: () => context.push('/method'),
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'My sets',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                ref.watch(archivedSetsProvider).maybeWhen(
                      data: (archived) => archived.isEmpty
                          ? const SizedBox.shrink()
                          : TextButton.icon(
                              onPressed: () => context.push('/archived'),
                              icon: const Icon(Icons.archive_outlined,
                                  size: 18),
                              label:
                                  Text('Archived (${archived.length})'),
                            ),
                      orElse: () => const SizedBox.shrink(),
                    ),
              ],
            ),
            const SizedBox(height: 8),
            if (sets.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(
                  child: Text(
                    'No sets yet. Tap "New puzzle set" to create one.',
                  ),
                ),
              ),
            for (final set in sets)
              Card(
                child: ListTile(
                  title: Text(set.name),
                  subtitle: Text(
                    '${set.size} puzzles • '
                    '${set.filter.ratingMin}–${set.filter.ratingMax}'
                    '${set.filter.themes.isEmpty ? '' : ' • ${set.filter.themes.join(', ')}'}',
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.push('/sets/${set.id}'),
                ),
              ),
          ],
        ),
      ),
    );
  }

}
