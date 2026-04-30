import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/models/puzzle_set.dart';
import '../../data/models/round.dart';
import '../../data/repositories/puzzle_repository.dart';
import '../../data/repositories/round_repository.dart';
import '../../data/repositories/set_repository.dart';
import '../../data/repositories/stats_repository.dart';
import '../../services/app_preferences.dart';
import '../progression/widgets/round_summary_dialog.dart';
import '../solve/puzzle.dart';
import '../solve/solve_board_controller.dart';
import '../solve/solve_board_widget.dart';
import '../solve/solve_state.dart';

class SessionScreen extends ConsumerStatefulWidget {
  const SessionScreen({
    super.key,
    required this.setId,
    required this.roundId,
  });

  final String setId;
  final String roundId;

  @override
  ConsumerState<SessionScreen> createState() => _SessionScreenState();
}

enum AttemptOutcome { correct, wrong, record }

class _SessionScreenState extends ConsumerState<SessionScreen> {
  PuzzleSet? _set;
  Round? _round;
  List<String> _orderedIds = const [];
  Puzzle? _puzzle;
  int _position = 0;
  bool _loading = true;
  String? _error;
  // ignore: prefer_final_fields
  Map<String, int> _previousBestMs = const {};
  final List<AttemptOutcome> _outcomes = [];

  @override
  void initState() {
    super.initState();
    _loadInitial();
  }

  Future<void> _loadInitial() async {
    try {
      final setRepo = ref.read(setRepositoryProvider);
      final roundRepo = ref.read(roundRepositoryProvider);
      final puzzleRepo = ref.read(puzzleRepositoryProvider);
      final set = await setRepo.getById(widget.setId);
      final rounds = await roundRepo.listForSet(widget.setId);
      final round = rounds.firstWhere(
        (r) => r.id == widget.roundId,
        orElse: () => throw 'Round not found',
      );
      if (set == null) throw 'Set not found';
      final orderedIds = round.orderedPuzzleIds(set.puzzleIds);
      final statsRepo = ref.read(statsRepositoryProvider);
      final bestTimes = await statsRepo.bestTimesForSetExcludingRound(
        widget.setId,
        widget.roundId,
      );
      final priorAttempts = await roundRepo.attemptsForRound(widget.roundId);
      // Authoritative position = number of attempts already made. This heals
      // older rounds where currentPosition fell behind because the previous
      // build only advanced it on the Next button.
      final position = priorAttempts.length
          .clamp(0, orderedIds.length);
      if (position != round.currentPosition) {
        await roundRepo.advancePosition(round.id, position);
        ref.invalidate(roundsForSetProvider(widget.setId));
      }
      Puzzle? puzzle;
      if (position < orderedIds.length) {
        puzzle = await puzzleRepo.getById(orderedIds[position]);
      }
      final outcomes = <AttemptOutcome>[];
      for (final a in priorAttempts) {
        if (!a.isCorrect || a.hintsUsed > 0) {
          outcomes.add(AttemptOutcome.wrong);
        } else {
          final prev = bestTimes[a.puzzleId];
          if (prev != null && a.time.inMilliseconds < prev) {
            outcomes.add(AttemptOutcome.record);
          } else {
            outcomes.add(AttemptOutcome.correct);
          }
        }
      }
      if (!mounted) return;
      setState(() {
        _set = set;
        _round = round;
        _orderedIds = orderedIds;
        _position = position;
        _puzzle = puzzle;
        _previousBestMs = bestTimes;
        _outcomes
          ..clear()
          ..addAll(outcomes);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _onResult(SolveResult result) async {
    if (_round == null) return;
    final roundRepo = ref.read(roundRepositoryProvider);
    await roundRepo.recordAttempt(
      roundId: _round!.id,
      puzzleId: result.puzzleId,
      position: _position,
      isCorrect: result.isCorrect,
      time: result.time,
      hintsUsed: result.hintsUsed,
      userMoveUci: result.userMoveUci,
    );
    // Advance currentPosition immediately so resuming a paused round picks
    // up the *next* puzzle, not the one we just finished.
    final newPosition = _position + 1;
    await roundRepo.advancePosition(_round!.id, newPosition);
    ref.invalidate(roundsForSetProvider(_set!.id));
    // Refresh global stats so Strengths / phase radar / Elo history pick
    // up the attempt without an app restart.
    ref.invalidate(globalStatsProvider);
    ref.invalidate(globalThemeStatsProvider);
    ref.invalidate(enrichedThemeStatsProvider);
    ref.invalidate(weaknessAnalysisProvider);
    ref.invalidate(phaseStatsProvider);
    ref.invalidate(globalMedianTimeProvider);

    final outcome = _classifyOutcome(result);
    if (!mounted) return;
    setState(() {
      while (_outcomes.length <= _position) {
        _outcomes.add(AttemptOutcome.wrong);
      }
      _outcomes[_position] = outcome;
    });

    // Auto-advance only on a clean solve - hints break the flow.
    if (result.isCorrect &&
        result.hintsUsed == 0 &&
        ref.read(autoAdvanceProvider)) {
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (!mounted) return;
        _advance();
      });
    }
  }

  AttemptOutcome _classifyOutcome(SolveResult result) {
    if (!result.isCorrect || result.hintsUsed > 0) return AttemptOutcome.wrong;
    final prev = _previousBestMs[result.puzzleId];
    if (prev != null && result.time.inMilliseconds < prev) {
      return AttemptOutcome.record;
    }
    return AttemptOutcome.correct;
  }

  Future<void> _advance() async {
    if (_set == null || _round == null) return;
    final roundRepo = ref.read(roundRepositoryProvider);
    final puzzleRepo = ref.read(puzzleRepositoryProvider);
    // currentPosition was already advanced in _onResult - just navigate.
    final newPosition = _position + 1;

    if (newPosition >= _orderedIds.length) {
      await roundRepo.complete(_round!.id);
      ref.invalidate(setRoundsStatsProvider(_set!.id));
      ref.invalidate(themeStatsProvider(_set!.id));
      ref.invalidate(problemPuzzlesProvider(_set!.id));
      if (!mounted) return;
      _showRoundComplete();
      return;
    }

    final next = await puzzleRepo.getById(_orderedIds[newPosition]);
    if (!mounted) return;
    setState(() {
      _position = newPosition;
      _puzzle = next;
    });
  }

  void _showRoundComplete() {
    if (!mounted || _round == null) return;
    final roundId = _round!.id;
    final setId = widget.setId;
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => RoundSummaryDialog(
        roundId: roundId,
        setId: setId,
        onBackToSet: () {
          Navigator.pop(ctx);
          if (mounted) context.go('/sets/$setId');
        },
        onViewProgression: () {
          Navigator.pop(ctx);
          if (mounted) context.go('/sets/$setId/progression');
        },
        onArchive: () async {
          Navigator.pop(ctx);
          await ref.read(setRepositoryProvider).archive(setId);
          ref.invalidate(allSetsProvider);
          if (mounted) context.go('/');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_round == null
            ? 'Round'
            : 'Round ${_round!.roundNumber} • '
                '${_position + 1}/${_set?.size ?? '?'}'),
        leading: IconButton(
          icon: const Icon(Icons.pause),
          tooltip: 'Pause',
          onPressed: () => context.go('/sets/${widget.setId}'),
        ),
      ),
      body: SafeArea(child: _buildBody(context)),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return Center(child: Text(_error!));
    }
    if (_puzzle == null) {
      return const Center(child: Text('No puzzle at this position'));
    }
    return SolveBoardWidget(
      key: ValueKey('${_round?.id}-$_position'),
      puzzle: _puzzle!,
      onResult: _onResult,
      statusBarBuilder: (context, state, controller) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _AttemptStrip(
            outcomes: _outcomes,
            currentPosition: _position,
            total: _set?.size ?? 0,
          ),
          _SessionStatusBar(
            state: state,
            controller: controller,
            position: _position,
            total: _set?.size ?? 0,
            onContinue: _advance,
          ),
        ],
      ),
    );
  }
}

class _AttemptStrip extends StatefulWidget {
  const _AttemptStrip({
    required this.outcomes,
    required this.currentPosition,
    required this.total,
  });

  final List<AttemptOutcome> outcomes;
  final int currentPosition;
  final int total;

  @override
  State<_AttemptStrip> createState() => _AttemptStripState();
}

class _AttemptStripState extends State<_AttemptStrip> {
  final ScrollController _scrollController = ScrollController();

  @override
  void didUpdateWidget(_AttemptStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currentPosition != oldWidget.currentPosition) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        const dotWidth = 28.0;
        final target =
            (widget.currentPosition * dotWidth - 80).clamp(0.0, double.infinity);
        _scrollController.animateTo(
          target.toDouble(),
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.total == 0) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Container(
      height: 36,
      width: double.infinity,
      color: colors.surfaceContainer,
      child: ListView.builder(
        controller: _scrollController,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        itemCount: widget.total,
        itemBuilder: (context, i) {
          final outcome =
              i < widget.outcomes.length ? widget.outcomes[i] : null;
          final isCurrent = i == widget.currentPosition;
          return _AttemptDot(
            index: i,
            outcome: outcome,
            isCurrent: isCurrent,
          );
        },
      ),
    );
  }
}

class _AttemptDot extends StatelessWidget {
  const _AttemptDot({
    required this.index,
    required this.outcome,
    required this.isCurrent,
  });

  final int index;
  final AttemptOutcome? outcome;
  final bool isCurrent;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    Color bg;
    Widget child;
    switch (outcome) {
      case AttemptOutcome.correct:
        bg = const Color(0xFF2E7D32);
        child = const Icon(Icons.check, size: 16, color: Colors.white);
      case AttemptOutcome.wrong:
        bg = const Color(0xFFC62828);
        child = const Icon(Icons.close, size: 16, color: Colors.white);
      case AttemptOutcome.record:
        bg = const Color(0xFFF9A825);
        child = const Icon(Icons.star, size: 16, color: Colors.white);
      case null:
        bg = colors.surfaceContainerHigh;
        child = Text(
          '${index + 1}',
          style: TextStyle(
            fontSize: 11,
            color: colors.onSurfaceVariant,
          ),
        );
    }
    return Container(
      width: 24,
      height: 24,
      margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: isCurrent
            ? Border.all(color: colors.primary, width: 2)
            : null,
      ),
      child: Center(child: child),
    );
  }
}

class _SessionStatusBar extends ConsumerWidget {
  const _SessionStatusBar({
    required this.state,
    required this.controller,
    required this.position,
    required this.total,
    required this.onContinue,
  });

  final SolveState state;
  final SolveBoardController controller;
  final int position;
  final int total;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedback = solveStatusFeedback(context, state);
    final hintsEnabled = ref.watch(hintsEnabledProvider);
    final canContinue = state.status == SolveStatus.solved ||
        state.status == SolveStatus.wrong ||
        state.status == SolveStatus.inaccuracy ||
        state.status == SolveStatus.almostBest ||
        state.status == SolveStatus.revealed ||
        state.status == SolveStatus.exploring;
    final isLast = position + 1 >= total;
    final canRetry = state.status == SolveStatus.wrong ||
        state.status == SolveStatus.inaccuracy ||
        state.status == SolveStatus.almostBest ||
        state.status == SolveStatus.revealed ||
        state.status == SolveStatus.exploring;
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
                IconButton(
                  onPressed: controller.requestHint,
                  icon: const Icon(Icons.lightbulb_outline),
                  tooltip: 'Hint',
                ),
              if (canShowSolution(state.status))
                IconButton(
                  onPressed: controller.revealSolution,
                  icon: const Icon(Icons.visibility_outlined),
                  tooltip: 'Show solution',
                ),
              if (canRetry)
                OutlinedButton.icon(
                  onPressed: controller.resetForRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              if (canContinue)
                FilledButton.icon(
                  onPressed: onContinue,
                  icon: Icon(isLast ? Icons.flag : Icons.skip_next),
                  label: Text(isLast ? 'Finish round' : 'Next'),
                ),
            ],
          ),
          ),
        ],
      ),
    );
  }
}
