import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/bot_game_repository.dart';
import '../../services/app_preferences.dart';
import '../../services/board_appearance.dart';
import '../../services/sound_service.dart';
import '../../services/stockfish_service.dart';
import '../../widgets/captured_row.dart';
import '../solve/solve_board_widget.dart' show LastMoveSquareBorder;
import 'bot_config.dart';
import 'bot_controller.dart';

class BotGameScreen extends ConsumerStatefulWidget {
  const BotGameScreen({
    super.key,
    required this.config,
    this.resumeFrom,
  });

  final BotConfig config;
  final BotGameSnapshot? resumeFrom;

  @override
  ConsumerState<BotGameScreen> createState() => _BotGameScreenState();
}

class _BotGameScreenState extends ConsumerState<BotGameScreen> {
  late BotGameController _controller;
  String? _validMovesFen;
  IMap<Square, ISet<Square>>? _validMovesCache;

  @override
  void initState() {
    super.initState();
    _controller = BotGameController(
      config: widget.config,
      stockfish: ref.read(stockfishServiceProvider),
      repo: ref.read(botGameRepositoryProvider),
      sound: ref.read(soundServiceProvider),
      animDuration: () => ref.read(animationSpeedProvider).duration,
      resumeFrom: widget.resumeFrom,
    )..addListener(_onChange);
  }

  void _onChange() {
    if (!mounted) return;
    setState(() {});
    final outcome = _controller.state.outcome;
    if (outcome != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _maybeShowOutcomeDialog();
      });
    }
  }

  bool _dialogShown = false;
  void _maybeShowOutcomeDialog() {
    if (_dialogShown) return;
    final state = _controller.state;
    if (state.outcome == null) return;
    _dialogShown = true;
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_outcomeTitle(state.outcome!)),
        content: Text(state.outcomeReason ?? ''),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (mounted) context.pop();
            },
            child: const Text('Back'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (!mounted) return;
              context.go('/play-bot/game', extra: widget.config);
            },
            child: const Text('New game'),
          ),
        ],
      ),
    );
  }

  String _outcomeTitle(BotGameOutcome outcome) {
    switch (outcome) {
      case BotGameOutcome.userWon:
        return 'You won!';
      case BotGameOutcome.botWon:
        return 'You lost';
      case BotGameOutcome.draw:
        return 'Draw';
      case BotGameOutcome.resigned:
        return 'Resigned';
    }
  }

  @override
  void dispose() {
    _controller
      ..removeListener(_onChange)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = _controller.state;
    final boardTheme = ref.watch(boardThemeProvider);
    final pieceSet = ref.watch(pieceSetProvider);
    final showCoords = ref.watch(showCoordinatesProvider);
    final showMoves = ref.watch(showLegalMovesProvider);
    final animSpeed = ref.watch(animationSpeedProvider);
    final autoFlip = ref.watch(autoFlipBoardProvider);
    final movedBySide = state.position.turn.opposite;
    final isUserMove =
        state.lastMove != null && movedBySide == state.userSide;
    final animDuration =
        isUserMove ? Duration.zero : animSpeed.duration;
    final assist = widget.config.assistMode;
    final canHint = assist.hintsAllowed &&
        (assist.hintsUnlimited ||
            state.hintsUsed < assist.hintLimit) &&
        state.status == BotGameStatus.awaitingUser;
    final canTakeback = assist.takebacksAllowed &&
        (assist.takebacksUnlimited ||
            state.takebacksUsed < assist.takebackLimit) &&
        state.status != BotGameStatus.finished;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Flexible(
              child: Text(
                'vs ${widget.config.level.label}',
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            for (int i = 0; i < 3; i++)
              Icon(
                Icons.emoji_events,
                size: 16,
                color: i < assist.crowns
                    ? const Color(0xFFE0A82E)
                    : Theme.of(context).colorScheme.outlineVariant,
              ),
          ],
        ),
        actions: [
          if (assist.takebacksAllowed &&
              state.status != BotGameStatus.finished)
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: assist.takebacksUnlimited
                  ? 'Takeback'
                  : 'Takeback (${assist.takebackLimit - state.takebacksUsed} left)',
              onPressed: () {
                if (canTakeback) {
                  _controller.takeback();
                  return;
                }
                if (state.status == BotGameStatus.finished) return;
                if (state.status == BotGameStatus.thinking) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Wait for the opponent move first.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                if (!assist.takebacksUnlimited &&
                    state.takebacksUsed >= assist.takebackLimit) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No takebacks left in this mode.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          if (assist.hintsAllowed &&
              state.status != BotGameStatus.finished)
            IconButton(
              icon: const Icon(Icons.lightbulb_outline),
              tooltip: assist.hintsUnlimited
                  ? 'Hint'
                  : 'Hint (${assist.hintLimit - state.hintsUsed} left)',
              onPressed: () {
                if (canHint) {
                  _controller.requestHint();
                  return;
                }
                if (state.status == BotGameStatus.finished) return;
                if (state.status == BotGameStatus.thinking) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Hints are available on your turn.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                  return;
                }
                if (!assist.hintsUnlimited &&
                    state.hintsUsed >= assist.hintLimit) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('No hints left in this mode.'),
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                }
              },
            ),
          if (state.status != BotGameStatus.finished)
            IconButton(
              icon: const Icon(Icons.flag_outlined),
              tooltip: 'Resign',
              onPressed: _confirmResign,
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            CapturedRow(
              captorSide: (autoFlip ? state.userSide : Side.white).opposite,
              initialPosition: Chess.initial,
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
                    final boardOrientation =
                        autoFlip ? state.userSide : Side.white;
                    return RepaintBoundary(
                      child: Stack(
                        children: [
                      Chessboard(
                      size: size,
                      orientation: boardOrientation,
                      fen: state.position.fen,
                      lastMove: state.lastMove,
                      shapes: state.hintMove != null
                          ? ISet({
                              Arrow(
                                color: const Color(0xCC2E7D32),
                                orig: state.hintMove!.from,
                                dest: state.hintMove!.to,
                              ),
                            })
                          : null,
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
                          if (move is NormalMove) {
                            _controller.onUserMove(move);
                          }
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
                          orientation: boardOrientation,
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
              captorSide: autoFlip ? state.userSide : Side.white,
              initialPosition: Chess.initial,
              currentPosition: state.position,
              pieceAssets: pieceSet.assets,
            ),
            _StatusBar(state: state),
          ],
        ),
      ),
    );
  }

  PlayerSide _playerSide(BotGameState state) {
    if (state.status != BotGameStatus.awaitingUser) return PlayerSide.none;
    return state.userSide == Side.white ? PlayerSide.white : PlayerSide.black;
  }

  IMap<Square, ISet<Square>> _validMoves(BotGameState state) {
    if (state.status != BotGameStatus.awaitingUser) {
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

  Future<void> _confirmResign() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Resign?'),
        content: const Text('You will lose the game.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Resign'),
          ),
        ],
      ),
    );
    if (confirmed == true) _controller.resign();
  }
}

class _StatusBar extends StatelessWidget {
  const _StatusBar({required this.state});

  final BotGameState state;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final (label, color) = _content(context, colors);
    return Container(
      width: double.infinity,
      color: color,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          if (state.status == BotGameStatus.thinking) ...[
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.titleMedium),
          ),
        ],
      ),
    );
  }

  (String, Color) _content(BuildContext context, ColorScheme colors) {
    if (state.outcome != null) {
      switch (state.outcome!) {
        case BotGameOutcome.userWon:
          return ('You won. ${state.outcomeReason}', colors.primaryContainer);
        case BotGameOutcome.botWon:
          return ('You lost. ${state.outcomeReason}', colors.errorContainer);
        case BotGameOutcome.draw:
          return ('Draw. ${state.outcomeReason}', colors.surfaceContainerHigh);
        case BotGameOutcome.resigned:
          return ('Resigned', colors.errorContainer);
      }
    }
    if (state.position.isCheck) {
      return ('Check!', colors.errorContainer);
    }
    final turn = state.position.turn;
    final isUser = turn == state.userSide;
    return (
      isUser ? 'Your move' : 'Opponent thinking…',
      colors.surfaceContainerHigh,
    );
  }
}
