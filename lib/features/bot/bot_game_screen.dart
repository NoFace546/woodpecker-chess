import 'dart:math';

import 'package:chessground/chessground.dart';
import 'package:dartchess/dartchess.dart';
import 'package:fast_immutable_collections/fast_immutable_collections.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/bot_game_repository.dart';
import '../../services/stockfish_service.dart';
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

  @override
  void initState() {
    super.initState();
    _controller = BotGameController(
      config: widget.config,
      stockfish: ref.read(stockfishServiceProvider),
      repo: ref.read(botGameRepositoryProvider),
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
              if (mounted) context.pop();
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
    return Scaffold(
      appBar: AppBar(
        title: Text('vs ${widget.config.level.label}'),
        actions: [
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
                    );
                  },
                ),
              ),
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
    return makeLegalMoves(state.position);
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
          return ('You won — ${state.outcomeReason}', colors.primaryContainer);
        case BotGameOutcome.botWon:
          return ('You lost — ${state.outcomeReason}', colors.errorContainer);
        case BotGameOutcome.draw:
          return ('Draw — ${state.outcomeReason}', colors.surfaceContainerHigh);
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
