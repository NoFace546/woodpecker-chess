import 'package:go_router/go_router.dart';

import 'data/repositories/bot_game_repository.dart';
import 'features/archive/archived_sets_screen.dart';
import 'features/bot/bot_config.dart';
import 'features/bot/bot_game_screen.dart';
import 'features/bot/bot_setup_screen.dart';
import 'features/elo_history/elo_history_screen.dart';
import 'features/home/home_screen.dart';
import 'features/progression/drill_screen.dart';
import 'features/progression/global_progression_screen.dart';
import 'features/progression/progression_screen.dart';
import 'features/progression/puzzle_preview_screen.dart';
import 'features/session/session_screen.dart';
import 'features/set_builder/set_builder_screen.dart';
import 'features/set_detail/set_detail_screen.dart';
import 'features/settings/about_screen.dart';
import 'features/settings/settings_screen.dart';
import 'features/settings/woodpecker_method_screen.dart';
import 'features/solve/solve_screen.dart';
import 'features/strengths/strengths_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (_, _) => const HomeScreen()),
    GoRoute(path: '/random', builder: (_, _) => const SolveScreen()),
    GoRoute(path: '/elo-history',
        builder: (_, _) => const EloHistoryScreen()),
    GoRoute(path: '/progression',
        builder: (_, _) => const GlobalProgressionScreen()),
    GoRoute(path: '/strengths',
        builder: (_, _) => const StrengthsScreen()),
    GoRoute(path: '/settings',
        builder: (_, _) => const SettingsScreen()),
    GoRoute(path: '/about',
        builder: (_, _) => const AboutScreen()),
    GoRoute(path: '/method',
        builder: (_, _) => const WoodpeckerMethodScreen()),
    GoRoute(
      path: '/puzzles/:puzzleId',
      builder: (context, state) =>
          PuzzlePreviewScreen(puzzleId: state.pathParameters['puzzleId']!),
    ),
    GoRoute(path: '/sets/new', builder: (_, _) => const SetBuilderScreen()),
    GoRoute(path: '/archived',
        builder: (_, _) => const ArchivedSetsScreen()),
    GoRoute(
      path: '/play-bot',
      builder: (_, _) => const BotSetupScreen(),
      routes: [
        GoRoute(
          path: 'game',
          builder: (context, state) {
            final extra = state.extra;
            if (extra is BotConfig) {
              return BotGameScreen(config: extra);
            }
            if (extra is ({BotConfig config, BotGameSnapshot? snapshot})) {
              return BotGameScreen(
                config: extra.config,
                resumeFrom: extra.snapshot,
              );
            }
            throw StateError('Unsupported extra for /play-bot/game: $extra');
          },
        ),
      ],
    ),
    GoRoute(
      path: '/sets/:setId',
      builder: (context, state) =>
          SetDetailScreen(setId: state.pathParameters['setId']!),
      routes: [
        GoRoute(
          path: 'rounds/:roundId',
          builder: (context, state) => SessionScreen(
            setId: state.pathParameters['setId']!,
            roundId: state.pathParameters['roundId']!,
          ),
        ),
        GoRoute(
          path: 'progression',
          builder: (context, state) => ProgressionScreen(
            setId: state.pathParameters['setId']!,
          ),
        ),
        GoRoute(
          path: 'drill',
          builder: (context, state) => DrillScreen(
            setId: state.pathParameters['setId']!,
          ),
        ),
      ],
    ),
  ],
);
