import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/puzzle_repository.dart';
import '../../data/repositories/round_repository.dart';
import '../../data/repositories/user_state_repository.dart';
import 'solve_board_controller.dart';
import 'solve_board_widget.dart';
import 'solve_state.dart';

class SolveScreen extends ConsumerWidget {
  const SolveScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final puzzleAsync = ref.watch(eloRandomPuzzleProvider);
    final userAsync = ref.watch(userStateProvider);
    return Scaffold(
      appBar: AppBar(
        title: puzzleAsync.maybeWhen(
          data: (p) => Text('Puzzle ${p.id} • ${p.rating}'),
          orElse: () => const Text('Random puzzle'),
        ),
        actions: [
          userAsync.maybeWhen(
            data: (u) => Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Center(
                child: Text(
                  'Elo ${u.elo}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
            ),
            orElse: () => const SizedBox.shrink(),
          ),
          IconButton(
            icon: const Icon(Icons.skip_next),
            tooltip: 'Next puzzle',
            onPressed: () => ref.invalidate(eloRandomPuzzleProvider),
          ),
        ],
      ),
      body: SafeArea(
        child: puzzleAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorView(
            error: error,
            onRetry: () => ref.invalidate(eloRandomPuzzleProvider),
          ),
          data: (puzzle) => SolveBoardWidget(
            key: ValueKey(puzzle.id),
            puzzle: puzzle,
            onResult: (result) async {
              // Log to the system "Random Play" round so the attempt shows up
              // in strengths/weaknesses analysis.
              await ref.read(roundRepositoryProvider).recordAttempt(
                    roundId: '__random_round__',
                    puzzleId: result.puzzleId,
                    position: 0,
                    isCorrect: result.isCorrect,
                    time: result.time,
                    hintsUsed: result.hintsUsed,
                    userMoveUci: result.userMoveUci,
                  );
              // Random free-play is the only flow that updates Elo (sets are
              // pre-filtered by rating, so they aren't a fair test).
              final delta =
                  await ref.read(userStateRepositoryProvider).applyAttempt(
                        puzzleId: result.puzzleId,
                        puzzleRating: result.puzzleRating,
                        isCorrect: result.isCorrect,
                        hintsUsed: result.hintsUsed,
                      );
              if (!context.mounted) return;
              _showEloDelta(context, delta);
            },
            statusBarBuilder: (context, state, controller) =>
                _RandomStatusBar(
              state: state,
              controller: controller,
              onTryAgain: controller.resetForRetry,
              onNext: () => ref.invalidate(eloRandomPuzzleProvider),
            ),
          ),
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 12),
            Text(error.toString(), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

void _showEloDelta(BuildContext context, EloDelta delta) {
  final scheme = Theme.of(context).colorScheme;
  final Color bg;
  final Color fg;
  final String text;
  if (delta.wasHinted) {
    // Hint-assisted correct: yellow, no Elo change.
    bg = const Color(0xFFFFF3CD);
    fg = const Color(0xFF7A5C00);
    text = '0 Elo (hint used)';
  } else if (delta.delta > 0) {
    bg = scheme.tertiaryContainer;
    fg = scheme.onTertiaryContainer;
    text = '+${delta.delta} Elo · now ${delta.after}';
  } else if (delta.delta < 0) {
    bg = scheme.errorContainer;
    fg = scheme.onErrorContainer;
    text = '${delta.delta} Elo · now ${delta.after}';
  } else {
    bg = scheme.surfaceContainerHigh;
    fg = scheme.onSurface;
    text = 'No Elo change';
  }
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text, style: TextStyle(color: fg)),
        backgroundColor: bg,
        duration: const Duration(milliseconds: 1800),
        behavior: SnackBarBehavior.floating,
      ),
    );
}

class _RandomStatusBar extends StatelessWidget {
  const _RandomStatusBar({
    required this.state,
    required this.controller,
    required this.onTryAgain,
    required this.onNext,
  });

  final SolveState state;
  final SolveBoardController controller;
  final VoidCallback onTryAgain;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final feedback = solveStatusFeedback(context, state);
    final canAdvance = state.status == SolveStatus.solved ||
        state.status == SolveStatus.wrong ||
        state.status == SolveStatus.inaccuracy ||
        state.status == SolveStatus.almostBest ||
        state.status == SolveStatus.revealed;
    return Container(
      width: double.infinity,
      color: feedback.color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  feedback.label,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              if (state.status == SolveStatus.evaluating)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          if (state.status == SolveStatus.playing ||
              canShowSolution(state.status) ||
              canAdvance)
            const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.end,
            children: [
              if (state.status == SolveStatus.playing &&
                  state.hintFromSquare == null)
                TextButton.icon(
                  onPressed: controller.requestHint,
                  icon: const Icon(Icons.lightbulb_outline),
                  label: const Text('Hint'),
                ),
              if (canShowSolution(state.status))
                TextButton.icon(
                  onPressed: controller.revealSolution,
                  icon: const Icon(Icons.visibility_outlined),
                  label: const Text('Show solution'),
                ),
              if (canAdvance) ...[
                OutlinedButton.icon(
                  onPressed: onTryAgain,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
                FilledButton.icon(
                  onPressed: onNext,
                  icon: const Icon(Icons.skip_next),
                  label: const Text('Next'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
