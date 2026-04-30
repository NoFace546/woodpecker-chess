import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../services/app_preferences.dart';
import '../../services/board_appearance.dart';
import '../../services/sound_service.dart';
import '../../services/stockfish_service.dart';
import '../../widgets/captured_row.dart';
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
  String? _validMovesFen;
  IMap<Square, ISet<Square>>? _validMovesCache;

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
      animDuration: () => ref.read(animationSpeedProvider).duration,
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
    final shapes = _shapes(state);
    final boardTheme = ref.watch(boardThemeProvider);
    final pieceSet = ref.watch(pieceSetProvider);
    final showCoords = ref.watch(showCoordinatesProvider);
    final showMoves = ref.watch(showLegalMovesProvider);
    final animSpeed = ref.watch(animationSpeedProvider);
    final autoFlip = ref.watch(autoFlipBoardProvider);
    final orientation = autoFlip ? state.userSide : Side.white;
    final initial = widget.puzzle.initialPosition;
    // Asymmetric animation: when the user just moved (turn now opponent's),
    // jump instantly. Animate only opponent moves so the user can actually
    // see what the opponent played. The setup move also jumps instantly
    // because the first animation right after the screen mounts tends to
    // be janky (cold widget tree, image cache, etc.). During Show Solution
    // playback the user is watching, so animate everything.
    final movedBySide = state.position.turn.opposite;
    final isUserMove = state.lastMove != null && movedBySide == state.userSide;
    final isReplay = state.status == SolveStatus.revealed;
    final shouldInstant = isUserMove && !isReplay;
    final animDuration =
        shouldInstant ? Duration.zero : animSpeed.duration;
    return Column(
      children: [
        _Hud(state: state),
        CapturedRow(
          captorSide: orientation.opposite,
          initialPosition: initial,
          currentPosition: state.position,
          pieceAssets: pieceSet.assets,
        ),
        Expanded(
          child: Center(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final size = min(
                  constraints.maxWidth,
                  constraints.maxHeight,
                );
                final lastTo = state.lastMove?.to;
                return RepaintBoundary(
                  child: Stack(
                    children: [
                  Chessboard(
                  size: size,
                  orientation: autoFlip ? state.userSide : Side.white,
                  fen: state.position.fen,
                  lastMove: state.lastMove,
                  shapes: shapes,
                  settings: ChessboardSettings(
                    enableCoordinates: showCoords,
                    showValidMoves: showMoves,
                    animationDuration: animDuration,
                    colorScheme: boardTheme.colors,
                    pieceAssets: pieceSet.assets,
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
                  ),
                  if (lastTo != null)
                    LastMoveSquareBorder(
                      to: lastTo,
                      orientation: autoFlip ? state.userSide : Side.white,
                      boardSize: size,
                    ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        CapturedRow(
          captorSide: orientation,
          initialPosition: initial,
          currentPosition: state.position,
          pieceAssets: pieceSet.assets,
        ),
        widget.statusBarBuilder?.call(context, state, _controller) ??
            _DefaultStatusBar(state: state, controller: _controller),
      ],
    );
  }

  PlayerSide _playerSide(SolveState state) {
    final canMove = state.status == SolveStatus.playing ||
        state.status == SolveStatus.exploring;
    if (!canMove) return PlayerSide.none;
    if (state.status == SolveStatus.exploring) {
      // In exploring mode, allow moves for whichever side is to move.
      return state.position.turn == Side.white
          ? PlayerSide.white
          : PlayerSide.black;
    }
    return state.userSide == Side.white ? PlayerSide.white : PlayerSide.black;
  }

  IMap<Square, ISet<Square>> _validMoves(SolveState state) {
    if (state.status != SolveStatus.playing &&
        state.status != SolveStatus.exploring) {
      return const IMap<Square, ISet<Square>>.empty();
    }
    final fen = state.position.fen;
    if (_validMovesFen == fen && _validMovesCache != null) {
      return _validMovesCache!;
    }
    final moves = makeLegalMoves(state.position);
    _validMovesFen = fen;
    _validMovesCache = moves;
    return moves;
  }

  ISet<Shape>? _shapes(SolveState state) {
    final shapes = <Shape>{};
    final hintFrom = state.hintFromSquare;
    if (hintFrom != null) {
      shapes.add(
        Circle(color: const Color(0xAAEEAA00), orig: hintFrom, scale: 0.95),
      );
    }
    if (shapes.isEmpty) return null;
    return ISet(shapes);
  }
}

/// Yellow border around the destination square of the most recent move.
/// Painted as an overlay on top of the Chessboard since chessground's
/// Shape API only supports circles and arrows.
class LastMoveSquareBorder extends StatelessWidget {
  const LastMoveSquareBorder({
    super.key,
    required this.to,
    required this.orientation,
    required this.boardSize,
    this.color = const Color(0xCCFFD600),
    this.thickness = 3,
  });

  final Square to;
  final Side orientation;
  final double boardSize;
  final Color color;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    final sqSize = boardSize / 8;
    final fileIdx = to.value & 7;
    final rankIdx = to.value >> 3;
    final double xIdx, yIdx;
    if (orientation == Side.white) {
      xIdx = fileIdx.toDouble();
      yIdx = (7 - rankIdx).toDouble();
    } else {
      xIdx = (7 - fileIdx).toDouble();
      yIdx = rankIdx.toDouble();
    }
    return Positioned(
      left: xIdx * sqSize,
      top: yIdx * sqSize,
      width: sqSize,
      height: sqSize,
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: color, width: thickness),
          ),
        ),
      ),
    );
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

class _DefaultStatusBar extends ConsumerWidget {
  const _DefaultStatusBar({required this.state, required this.controller});

  final SolveState state;
  final SolveBoardController controller;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final feedback = solveStatusFeedback(context, state);
    final hintsEnabled = ref.watch(hintsEnabledProvider);
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
      status == SolveStatus.almostBest ||
      status == SolveStatus.exploring;
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
        label: '',
        color: colors.surface,
      );
    case SolveStatus.playing:
      return StatusFeedback(
        label: '',
        color: colors.surface,
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
        label: 'Good move, but not the puzzle line. Try again.',
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
    case SolveStatus.exploring:
      return StatusFeedback(
        label: 'Wrong. Keep playing to see what happens.',
        color: colors.errorContainer,
      );
  }
}
