import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/bot_game_repository.dart';
import '../../services/stockfish_service.dart';
import 'bot_config.dart';

const _botMoveDelay = Duration(milliseconds: 400);

enum BotGameStatus { thinking, awaitingUser, finished }

enum BotGameOutcome { userWon, botWon, draw, resigned }

class BotGameState {
  const BotGameState({
    required this.position,
    required this.status,
    required this.userSide,
    this.lastMove,
    this.promotionMove,
    this.outcome,
    this.outcomeReason,
  });

  final Position position;
  final BotGameStatus status;
  final Side userSide;
  final Move? lastMove;
  final NormalMove? promotionMove;
  final BotGameOutcome? outcome;
  final String? outcomeReason;

  BotGameState copyWith({
    Position? position,
    BotGameStatus? status,
    Move? lastMove,
    NormalMove? promotionMove,
    bool clearPromotion = false,
    BotGameOutcome? outcome,
    String? outcomeReason,
  }) {
    return BotGameState(
      position: position ?? this.position,
      status: status ?? this.status,
      userSide: userSide,
      lastMove: lastMove ?? this.lastMove,
      promotionMove:
          clearPromotion ? null : (promotionMove ?? this.promotionMove),
      outcome: outcome ?? this.outcome,
      outcomeReason: outcomeReason ?? this.outcomeReason,
    );
  }
}

class BotGameController extends ChangeNotifier {
  BotGameController({
    required this.config,
    required this.stockfish,
    required this.repo,
    BotGameSnapshot? resumeFrom,
  })  : _state = _initialState(config, resumeFrom),
        _isResume = resumeFrom != null {
    _bootstrap();
  }

  final BotConfig config;
  final StockfishService stockfish;
  final BotGameRepository repo;

  BotGameState _state;
  bool _disposed = false;
  final bool _isResume;

  BotGameState get state => _state;

  static BotGameState _initialState(
    BotConfig config,
    BotGameSnapshot? snapshot,
  ) {
    if (snapshot != null) {
      final pos = Chess.fromSetup(Setup.parseFen(snapshot.fen));
      final lastMove = snapshot.lastMoveUci != null
          ? Move.parse(snapshot.lastMoveUci!)
          : null;
      final isUserTurn = pos.turn == config.userSide;
      return BotGameState(
        position: pos,
        status: isUserTurn
            ? BotGameStatus.awaitingUser
            : BotGameStatus.thinking,
        userSide: config.userSide,
        lastMove: lastMove,
      );
    }
    return BotGameState(
      position: Chess.initial,
      status: config.userSide == Side.white
          ? BotGameStatus.awaitingUser
          : BotGameStatus.thinking,
      userSide: config.userSide,
    );
  }

  void _set(BotGameState s) {
    if (_disposed) return;
    _state = s;
    notifyListeners();
  }

  Future<void> _persist() async {
    if (_state.status == BotGameStatus.finished) return;
    try {
      await repo.save(BotGameSnapshot(
        id: 'active',
        fen: _state.position.fen,
        lastMoveUci: _state.lastMove?.uci,
        userSide: _state.userSide,
        level: config.level,
      ));
    } catch (_) {
      // Persistence failure shouldn't block gameplay.
    }
  }

  Future<void> _bootstrap() async {
    try {
      final elo = config.level.elo;
      if (elo != null) {
        await stockfish.setElo(elo);
      } else {
        await stockfish.setSkillLevel(config.level.skillLevel ?? 0);
      }
    } catch (_) {
      // Engine setup failed; gameplay can still try below and surface error.
    }
    final isUserTurn = _state.position.turn == _state.userSide;
    if (!isUserTurn) {
      await _playBotMove();
    } else if (!_isResume) {
      // Brand-new game with user as white — nothing to do until first move.
    }
  }

  Future<void> onUserMove(NormalMove move) async {
    if (_state.status != BotGameStatus.awaitingUser) return;
    if (_state.position.turn != _state.userSide) return;

    final isPromotion = _isPromotionPawnMove(_state.position, move);
    if (isPromotion && move.promotion == null) {
      _set(_state.copyWith(promotionMove: move));
      return;
    }
    if (!_state.position.isLegal(move)) return;

    final after = _state.position.playUnchecked(move);
    _set(_state.copyWith(
      position: after,
      lastMove: move,
      status: BotGameStatus.thinking,
      clearPromotion: true,
    ));
    await _persist();

    if (_checkGameOver(after, userJustMoved: true)) return;

    await _playBotMove();
  }

  void onPromotionSelected(Role role) {
    final pending = _state.promotionMove;
    if (pending == null) return;
    onUserMove(pending.withPromotion(role));
  }

  void cancelPromotion() {
    _set(_state.copyWith(clearPromotion: true));
  }

  Future<void> _playBotMove() async {
    await Future.delayed(_botMoveDelay);
    if (_disposed) return;

    final fen = _state.position.fen;
    final String? uci;
    try {
      uci = await stockfish.bestMove(fen: fen, depth: config.level.depth);
    } catch (_) {
      _set(_state.copyWith(
        status: BotGameStatus.finished,
        outcome: BotGameOutcome.draw,
        outcomeReason: 'Engine error',
      ));
      return;
    }
    if (_disposed) return;
    if (uci == null) {
      _checkGameOver(_state.position, userJustMoved: false);
      return;
    }

    final move = Move.parse(uci);
    if (move == null || !_state.position.isLegal(move)) {
      _set(_state.copyWith(
        status: BotGameStatus.finished,
        outcome: BotGameOutcome.draw,
        outcomeReason: 'Engine returned illegal move',
      ));
      return;
    }
    final after = _state.position.playUnchecked(move);
    _set(_state.copyWith(
      position: after,
      lastMove: move,
      status: BotGameStatus.awaitingUser,
    ));
    await _persist();

    _checkGameOver(after, userJustMoved: false);
  }

  bool _checkGameOver(Position position, {required bool userJustMoved}) {
    if (!position.isGameOver) return false;
    BotGameOutcome outcome;
    String reason;
    if (position.isCheckmate) {
      outcome = userJustMoved ? BotGameOutcome.userWon : BotGameOutcome.botWon;
      reason = 'Checkmate';
    } else if (position.isStalemate) {
      outcome = BotGameOutcome.draw;
      reason = 'Stalemate';
    } else if (position.isInsufficientMaterial) {
      outcome = BotGameOutcome.draw;
      reason = 'Insufficient material';
    } else {
      outcome = BotGameOutcome.draw;
      reason = 'Draw';
    }
    _set(_state.copyWith(
      status: BotGameStatus.finished,
      outcome: outcome,
      outcomeReason: reason,
    ));
    repo.clear();
    return true;
  }

  void resign() {
    if (_state.status == BotGameStatus.finished) return;
    repo.clear();
    _set(_state.copyWith(
      status: BotGameStatus.finished,
      outcome: BotGameOutcome.resigned,
      outcomeReason: 'You resigned',
    ));
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}

bool _isPromotionPawnMove(Position position, NormalMove move) {
  final piece = position.board.pieceAt(move.from);
  if (piece == null || piece.role != Role.pawn) return false;
  final toRank = move.to.rank;
  return toRank == Rank.first || toRank == Rank.eighth;
}
