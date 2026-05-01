import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/puzzle_repository.dart';
import '../../data/repositories/round_repository.dart';
import '../../data/repositories/stats_repository.dart';
import '../../data/repositories/user_state_repository.dart';
import '../../services/app_preferences.dart';
import '../../services/puzzle_report_service.dart';
import 'analysis_sheet.dart';
import 'solve_board_controller.dart';
import 'solve_board_widget.dart';
import 'solve_state.dart';

const _autoAdvanceDelay = Duration(milliseconds: 1200);
const _eloLogMax = 12;

class SolveScreen extends ConsumerStatefulWidget {
  const SolveScreen({super.key});

  @override
  ConsumerState<SolveScreen> createState() => _SolveScreenState();
}

class _SolveScreenState extends ConsumerState<SolveScreen> {
  final List<EloDelta> _eloLog = [];

  @override
  void initState() {
    super.initState();
    // Always start /random with a fresh puzzle. Without this the provider
    // would replay the previously-shown puzzle when the user reopens.
    Future.microtask(() {
      if (mounted) ref.invalidate(eloRandomPuzzleProvider);
    });
  }

  @override
  Widget build(BuildContext context) {
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
          puzzleAsync.maybeWhen(
            data: (puzzle) => _PuzzleActionsMenu(puzzle: puzzle),
            orElse: () => _PuzzleActionsMenu(),
          ),
        ],
      ),
      body: SafeArea(
        child: puzzleAsync.when(
          loading: () => const Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Loading puzzle…'),
              ],
            ),
          ),
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
              // Refresh stats providers so Strengths / Elo / phase radar
              // pick up this attempt without an app restart.
              ref.invalidate(globalStatsProvider);
              ref.invalidate(globalThemeStatsProvider);
              ref.invalidate(enrichedThemeStatsProvider);
              ref.invalidate(weaknessAnalysisProvider);
              ref.invalidate(phaseStatsProvider);
              ref.invalidate(eloHistoryProvider);
              ref.invalidate(globalMedianTimeProvider);
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
              setState(() {
                _eloLog.add(delta);
                if (_eloLog.length > _eloLogMax) {
                  _eloLog.removeRange(0, _eloLog.length - _eloLogMax);
                }
              });
              // Auto-advance only on a clean solve - hints break the flow.
              if (result.isCorrect &&
                  result.hintsUsed == 0 &&
                  ref.read(autoAdvanceProvider)) {
                Future.delayed(_autoAdvanceDelay, () {
                  if (!context.mounted) return;
                  ref.invalidate(eloRandomPuzzleProvider);
                });
              }
            },
            statusBarBuilder: (context, state, controller) =>
                _RandomStatusBar(
              state: state,
              controller: controller,
              eloLog: _eloLog,
              onTryAgain: controller.resetForRetry,
              onNext: () => ref.invalidate(eloRandomPuzzleProvider),
              onAnalyze: () => AnalysisSheet.show(
                context,
                puzzle: state.puzzle,
                startPosition: state.position,
              ),
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

class _EloLogStrip extends StatelessWidget {
  const _EloLogStrip({required this.deltas});
  final List<EloDelta> deltas;

  @override
  Widget build(BuildContext context) {
    if (deltas.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        reverse: true,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: deltas.length,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          // Newest on the right; reverse:true makes index 0 = newest.
          final d = deltas[deltas.length - 1 - i];
          final Color bg;
          final Color fg;
          final String text;
          if (d.wasHinted || d.delta == 0) {
            bg = scheme.surfaceContainerHigh;
            fg = scheme.onSurfaceVariant;
            text = d.wasHinted ? '0' : '0';
          } else if (d.delta > 0) {
            bg = scheme.tertiaryContainer;
            fg = scheme.onTertiaryContainer;
            text = '+${d.delta}';
          } else {
            bg = scheme.errorContainer;
            fg = scheme.onErrorContainer;
            text = '${d.delta}';
          }
          return Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              text,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: fg,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          );
        },
      ),
    );
  }
}

class _RandomStatusBar extends ConsumerWidget {
  const _RandomStatusBar({
    required this.state,
    required this.controller,
    required this.eloLog,
    required this.onTryAgain,
    required this.onNext,
    required this.onAnalyze,
  });

  final SolveState state;
  final SolveBoardController controller;
  final List<EloDelta> eloLog;
  final VoidCallback onTryAgain;
  final VoidCallback onNext;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedback = solveStatusFeedback(context, state);
    final hintsEnabled = ref.watch(hintsEnabledProvider);
    final canAdvance = state.status == SolveStatus.solved ||
        state.status == SolveStatus.wrong ||
        state.status == SolveStatus.inaccuracy ||
        state.status == SolveStatus.almostBest ||
        state.status == SolveStatus.revealed ||
        state.status == SolveStatus.exploring;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (eloLog.isNotEmpty) ...[
          const SizedBox(height: 6),
          _EloLogStrip(deltas: eloLog),
          const SizedBox(height: 4),
        ],
        Container(
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
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 40),
            child: Wrap(
            spacing: 8,
            runSpacing: 4,
            alignment: WrapAlignment.end,
            children: [
              if (hintsEnabled &&
                  state.status == SolveStatus.playing &&
                  state.hintFromSquare == null)
                _BarIconButton(
                  onPressed: controller.requestHint,
                  icon: Icons.lightbulb_outline,
                  tooltip: 'Hint',
                ),
              if (canShowSolution(state.status))
                _BarIconButton(
                  onPressed: controller.revealSolution,
                  icon: Icons.visibility_outlined,
                  tooltip: 'Show solution',
                ),
              if (canAdvance) ...[
                _BarIconButton(
                  onPressed: onAnalyze,
                  icon: Icons.search,
                  tooltip: 'Analyze',
                  filled: true,
                ),
                _BarIconButton(
                  onPressed: onTryAgain,
                  icon: Icons.refresh,
                  tooltip: 'Try again',
                ),
                _BarIconButton(
                  onPressed: onNext,
                  icon: Icons.skip_next,
                  tooltip: 'Next',
                  filled: true,
                ),
              ],
            ],
          ),
          ),
        ],
      ),
        ),
      ],
    );
  }
}

class _PuzzleActionsMenu extends StatelessWidget {
  const _PuzzleActionsMenu({this.puzzle});

  final dynamic puzzle;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      tooltip: 'More',
      icon: const Icon(Icons.more_horiz),
      onSelected: (value) {
        switch (value) {
          case 'settings':
            context.push('/settings');
            break;
          case 'report':
            final p = puzzle;
            if (p != null) reportPuzzle(context, p);
            break;
        }
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: 'settings',
          child: ListTile(
            leading: Icon(Icons.settings_outlined),
            title: Text('Settings'),
          ),
        ),
        if (puzzle != null)
          const PopupMenuItem(
            value: 'report',
            child: ListTile(
              leading: Icon(Icons.flag_outlined),
              title: Text('Report puzzle'),
            ),
          ),
      ],
    );
  }
}

class _BarIconButton extends StatelessWidget {
  const _BarIconButton({
    required this.onPressed,
    required this.icon,
    required this.tooltip,
    this.filled = false,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String tooltip;
  final bool filled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 30,
      tooltip: tooltip,
      style: IconButton.styleFrom(
        backgroundColor: filled ? scheme.primary : scheme.surfaceContainerHigh,
        foregroundColor: filled ? scheme.onPrimary : scheme.onSurface,
        minimumSize: const Size.square(48),
      ),
    );
  }
}
