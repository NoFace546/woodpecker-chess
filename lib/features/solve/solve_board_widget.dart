import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/sound_service.dart';
import '../../services/stockfish_service.dart';
import 'puzzle.dart';
import 'solve_board_controller.dart';
import 'solve_state.dart';

class SolveBoardWidget extends ConsumerStatefulWidget {
  const SolveBoardWidget({
    super.key,
    required this.puzzle,
    this.onResult,
    this.statusBarBuilder,
  });

  final Puzzle puzzle;
  final void Function(SolveResult result)? onResult;
  final Widget Function(
    BuildContext context,
    SolveState state,
    SolveBoardController controller,
  )? statusBarBuilder;

  @override
  ConsumerState<SolveBoardWidget> createState() => _SolveBoardWidgetState();
}

class _SolveBoardWidgetState extends ConsumerState<SolveBoardWidget> {
  late SolveBoardController _controller;

  @override
  void initState() {
    super.initState();
    _controller = _build();
    _controller.addListener(_onStateChange);
  }

  SolveBoardController _build() {
    return SolveBoardController(
      widget.puzzle,
      onResult: widget.onResult,
      stockfish: ref.read(stockfishServiceProvider),
      sound: ref.read(soundServiceProvider),
    );
  }

  @override
  void didUpdateWidget(covariant SolveBoardWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.puzzle.id != oldWidget.puzzle.id) {
      _controller
        ..removeListener(_onStateChange)
        ..dispose();
      _controller = _build();
      _controller.addListener(_onStateChange);
    }
  }

  void _onStateChange() => setState(() {});

  @override
  void dispose() {
    _controller
      ..removeListener(_onStateChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final shapes = _hintShapes(state);
    return Column(
      children: [
        _Hud(state: state),
        Expanded(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = min(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                return Chessboard(
                  size: size,
                  orientation: state.userSide,
                  fen: state.position.fen,
                  lastMove: state.lastMove,
                  shapes: shapes,
                  settings: const ChessboardSettings(
                    enableCoordinates: true,
                    animationDuration: Duration(milliseconds: 200),
                  ),
                  game: GameData(
                    playerSide: _playerSide(state),
                    validMoves: _validMoves(state),
                    sideToMove: state.position.turn,
                    isCheck: state.position.isCheck,
                    promotionMove: state.promotionMove,
                    onMove: (move, {viaDragAndDrop}) {
                      if (move is NormalMove) _controller.onUserMove(move);
                    },
                    onPromotionSelection: (role) {
                      if (role == null) {
                        _controller.cancelPromotion();
                      } else {
                        _controller.onPromotionSelected(role);
                      }
                    },
                  ),
                );
              },
            ),
          ),
        ),
        widget.statusBarBuilder?.call(context, state, _controller) ??
            _DefaultStatusBar(state: state, controller: _controller),
      ],
    );
  }

  PlayerSide _playerSide(SolveState state) {
    if (state.status != SolveStatus.playing) return PlayerSide.none;
    return state.userSide == Side.white ? PlayerSide.white : PlayerSide.black;
  }

  IMap<Square, ISet<Square>> _validMoves(SolveState state) {
    if (state.status != SolveStatus.playing) {
      return const IMap<Square, ISet<Square>>.empty();
    }
    return makeLegalMoves(state.position);
  }

  ISet<Shape>? _hintShapes(SolveState state) {
    final from = state.hintFromSquare;
    if (from == null) return null;
    return ISet<Shape>({
      Circle(color: const Color(0xAAEEAA00), orig: from, scale: 0.95),
    });
  }
}

class _Hud extends StatelessWidget {
  const _Hud({required this.state});

  final SolveState state;

  @override
  Widget build(BuildContext context) {
    final seconds = (state.elapsedMs / 1000).toStringAsFixed(1);
    final movesPlayed = (state.expectedMoveIndex / 2).floor();
    final totalUserMoves = (state.puzzle.uciMoves.length / 2).ceil();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, size: 20),
              const SizedBox(width: 4),
              Text('${seconds}s'),
            ],
          ),
          Text('Move $movesPlayed / $totalUserMoves'),
          Text(
            state.userSide == Side.white ? 'White to play' : 'Black to play',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _DefaultStatusBar extends StatelessWidget {
  const _DefaultStatusBar({required this.state, required this.controller});

  final SolveState state;
  final SolveBoardController controller;

  @override
  Widget build(BuildContext context) {
    final feedback = solveStatusFeedback(context, state);
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
          if (state.status == SolveStatus.evaluating)
            const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
        ],
      ),
    );
  }
}

bool canShowSolution(SolveStatus status) {
  return status == SolveStatus.playing ||
      status == SolveStatus.wrong ||
      status == SolveStatus.inaccuracy ||
      status == SolveStatus.almostBest;
}

class StatusFeedback {
  const StatusFeedback({required this.label, required this.color});
  final String label;
  final Color color;
}

StatusFeedback solveStatusFeedback(BuildContext context, SolveState state) {
  final colors = Theme.of(context).colorScheme;
  switch (state.status) {
    case SolveStatus.loadingSetup:
      return StatusFeedback(
        label: 'Setting up the position…',
        color: colors.surfaceContainerHigh,
      );
    case SolveStatus.playing:
      return StatusFeedback(
        label: 'Find the best move',
        color: colors.surfaceContainerHigh,
      );
    case SolveStatus.evaluating:
      return StatusFeedback(
        label: 'Evaluating your move…',
        color: colors.surfaceContainerHigh,
      );
    case SolveStatus.solved:
      return StatusFeedback(
        label: 'Solved in ${(state.elapsedMs / 1000).toStringAsFixed(1)}s',
        color: colors.primaryContainer,
      );
    case SolveStatus.almostBest:
      return StatusFeedback(
        label: 'Good move — but not the puzzle line. Try again.',
        color: colors.tertiaryContainer,
      );
    case SolveStatus.inaccuracy:
      return StatusFeedback(
        label: 'Inaccuracy. Try again.',
        color: colors.secondaryContainer,
      );
    case SolveStatus.wrong:
      return StatusFeedback(
        label: 'Wrong. Try again.',
        color: colors.errorContainer,
      );
    case SolveStatus.revealed:
      return StatusFeedback(
        label: 'Solution played out',
        color: colors.surfaceContainerHigh,
      );
  }
}
