import 'package:dartchess/dartchess.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/puzzle_attempt.dart';
import '../../data/models/tactical_themes.dart';
import '../../data/repositories/puzzle_repository.dart';
import '../../data/repositories/round_repository.dart';
import '../../services/stockfish_service.dart';
import '../solve/puzzle.dart';
import '../solve/solve_board_controller.dart';
import '../solve/solve_board_widget.dart';
import '../solve/solve_state.dart';

class PuzzlePreviewScreen extends ConsumerStatefulWidget {
  const PuzzlePreviewScreen({super.key, required this.puzzleId});

  final String puzzleId;

  @override
  ConsumerState<PuzzlePreviewScreen> createState() =>
      _PuzzlePreviewScreenState();
}

class _PuzzlePreviewScreenState extends ConsumerState<PuzzlePreviewScreen> {
  bool _analysing = false;
  String? _analysisResult;

  @override
  Widget build(BuildContext context) {
    final puzzleAsync = ref.watch(puzzleByIdProvider(widget.puzzleId));
    final attemptAsync =
        ref.watch(lastAttemptForPuzzleProvider(widget.puzzleId));

    return Scaffold(
      appBar: AppBar(
        title: puzzleAsync.maybeWhen(
          data: (p) => Text(p == null
              ? 'Puzzle'
              : 'Puzzle #${widget.puzzleId} • ${p.rating}'),
          orElse: () => Text('Puzzle #${widget.puzzleId}'),
        ),
      ),
      body: SafeArea(
        child: puzzleAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (puzzle) {
            if (puzzle == null) {
              return const Center(child: Text('Puzzle not found'));
            }
            final tacticalThemes = filterTactical(puzzle.themes);
            return Column(
              children: [
                if (tacticalThemes.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    child: Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final t in tacticalThemes)
                          Chip(
                            label: Text(t),
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                          ),
                      ],
                    ),
                  ),
                attemptAsync.maybeWhen(
                  data: (attempt) {
                    if (attempt == null || attempt.userMoveUci == null) {
                      return const SizedBox.shrink();
                    }
                    return _LastAttemptCard(
                      attempt: attempt,
                      analysing: _analysing,
                      analysisResult: _analysisResult,
                      onAnalyse: () => _analyse(puzzle, attempt),
                    );
                  },
                  orElse: () => const SizedBox.shrink(),
                ),
                Expanded(
                  child: SolveBoardWidget(
                    key: ValueKey(puzzle.id),
                    puzzle: puzzle,
                    statusBarBuilder: (context, state, controller) =>
                        _PreviewStatusBar(
                      state: state,
                      controller: controller,
                      onTryAgain: controller.resetForRetry,
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _analyse(Puzzle puzzle, PuzzleAttempt attempt) async {
    final userUci = attempt.userMoveUci;
    if (userUci == null) return;
    if (puzzle.uciMoves.length < 2) return;

    setState(() {
      _analysing = true;
      _analysisResult = null;
    });

    try {
      // Position right before the user's first move = after the setup move.
      final initial = puzzle.initialPosition;
      final setup = Move.parse(puzzle.uciMoves[0]);
      if (setup == null || !initial.isLegal(setup)) {
        throw StateError('Invalid setup move');
      }
      final afterSetup = initial.playUnchecked(setup);
      final fen = afterSetup.fen;
      final expectedUci = puzzle.uciMoves[1];

      final sf = ref.read(stockfishServiceProvider);
      final cpUser = await sf.evaluateAfterMove(
        fen: fen,
        moveUci: userUci,
        depth: 16,
      );
      final cpExpected = await sf.evaluateAfterMove(
        fen: fen,
        moveUci: expectedUci,
        depth: 16,
      );
      final loss = cpExpected - cpUser;

      String result;
      if (userUci == expectedUci) {
        result = 'Spot on — your move was the puzzle line ($expectedUci).';
      } else if (loss < 30) {
        result = 'Almost as good. Your $userUci lost only $loss cp '
            'compared to $expectedUci.';
      } else if (loss < 100) {
        result =
            'Inaccuracy. $userUci lost $loss cp vs the line $expectedUci.';
      } else {
        result =
            'Big miss. $userUci lost $loss cp — the puzzle line was $expectedUci.';
      }

      if (!mounted) return;
      setState(() {
        _analysing = false;
        _analysisResult = result;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _analysing = false;
        _analysisResult = 'Analysis failed: $e';
      });
    }
  }
}

class _LastAttemptCard extends StatelessWidget {
  const _LastAttemptCard({
    required this.attempt,
    required this.analysing,
    required this.analysisResult,
    required this.onAnalyse,
  });

  final PuzzleAttempt attempt;
  final bool analysing;
  final String? analysisResult;
  final VoidCallback onAnalyse;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final wasCorrect = attempt.isCorrect;
    final bg =
        wasCorrect ? scheme.tertiaryContainer : scheme.errorContainer;
    final fg =
        wasCorrect ? scheme.onTertiaryContainer : scheme.onErrorContainer;
    final label = wasCorrect ? 'correct' : 'wrong';
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                wasCorrect ? Icons.check_circle_outline : Icons.cancel_outlined,
                color: fg,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Your last attempt: ${attempt.userMoveUci} ($label)',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: fg, fontWeight: FontWeight.w600),
                ),
              ),
              if (analysing)
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: fg),
                )
              else if (analysisResult == null)
                TextButton(
                  onPressed: onAnalyse,
                  style: TextButton.styleFrom(foregroundColor: fg),
                  child: const Text('Analyse'),
                ),
            ],
          ),
          if (analysisResult != null) ...[
            const SizedBox(height: 6),
            Text(
              analysisResult!,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(color: fg),
            ),
          ],
        ],
      ),
    );
  }
}

class _PreviewStatusBar extends StatelessWidget {
  const _PreviewStatusBar({
    required this.state,
    required this.controller,
    required this.onTryAgain,
  });

  final SolveState state;
  final SolveBoardController controller;
  final VoidCallback onTryAgain;

  @override
  Widget build(BuildContext context) {
    final feedback = solveStatusFeedback(context, state);
    final canRetry = state.status == SolveStatus.solved ||
        state.status == SolveStatus.wrong ||
        state.status == SolveStatus.inaccuracy ||
        state.status == SolveStatus.almostBest ||
        state.status == SolveStatus.revealed;
    return Container(
      width: double.infinity,
      color: feedback.color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
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
          if (canShowSolution(state.status))
            TextButton.icon(
              onPressed: controller.revealSolution,
              icon: const Icon(Icons.visibility_outlined),
              label: const Text('Show solution'),
            ),
          if (canRetry)
            OutlinedButton.icon(
              onPressed: onTryAgain,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
        ],
      ),
    );
  }
}
