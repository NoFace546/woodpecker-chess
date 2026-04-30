import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';

import '../../data/repositories/bot_game_repository.dart';
import '../../services/haptic.dart';
import '../../services/sound_service.dart';
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
    this.hintMove,
    this.hintsUsed = 0,
    this.takebacksUsed = 0,
  });

  final Position position;
  final BotGameStatus status;
  final Side userSide;
  final Move? lastMove;
  final NormalMove? promotionMove;
  final BotGameOutcome? outcome;
  final String? outcomeReason;
  // Best move suggestion arrow currently displayed for the user.
  final NormalMove? hintMove;
  final int hintsUsed;
  final int takebacksUsed;

  BotGameState copyWith({
    Position? position,
    BotGameStatus? status,
    Move? lastMove,
    bool clearLastMove = false,
    NormalMove? promotionMove,
    bool clearPromotion = false,
    BotGameOutcome? outcome,
    String? outcomeReason,
    NormalMove? hintMove,
    bool clearHint = false,
    int? hintsUsed,
    int? takebacksUsed,
  }) {
    return BotGameState(
      position: position ?? this.position,
      status: status ?? this.status,
      userSide: userSide,
      lastMove: clearLastMove ? null : (lastMove ?? this.lastMove),
      promotionMove:
          clearPromotion ? null : (promotionMove ?? this.promotionMove),
      outcome: outcome ?? this.outcome,
      outcomeReason: outcomeReason ?? this.outcomeReason,
      hintMove: clearHint ? null : (hintMove ?? this.hintMove),
      hintsUsed: hintsUsed ?? this.hintsUsed,
      takebacksUsed: takebacksUsed ?? this.takebacksUsed,
    );
  }
}

class _HistoryEntry {
  _HistoryEntry({required this.position, required this.lastMove});
  final Position position;
  final Move? lastMove;
}

class BotGameController extends ChangeNotifier {
  BotGameController({
    required this.config,
    required this.stockfish,
    required this.repo,
    this.sound,
    Duration Function()? animDuration,
    BotGameSnapshot? resumeFrom,
  })  : animDuration = animDuration ?? (() => Duration.zero),
        _state = _initialState(config, resumeFrom),
        _isResume = resumeFrom != null {
    _bootstrap();
  }

  final BotConfig config;
  final StockfishService stockfish;
  final BotGameRepository repo;
  final SoundService? sound;
  final Duration Function() animDuration;

  void _playMoveSnd(SoundEffect snd, {required bool fromUser}) {
    final delay = fromUser ? Duration.zero : animDuration();
    sound?.playAfter(snd, delay);
  }

  BotGameState _state;
  bool _disposed = false;
  final bool _isResume;
  final List<_HistoryEntry> _history = [];

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
      // Brand-new game with user as white - nothing to do until first move.
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

    final before = _state.position;
    final after = before.playUnchecked(move);
    _history.add(_HistoryEntry(position: before, lastMove: _state.lastMove));
    _playMoveSnd(_moveSound(before, move, after), fromUser: true);
    AppHaptics.light();
    _set(_state.copyWith(
      position: after,
      lastMove: move,
      status: BotGameStatus.thinking,
      clearPromotion: true,
      clearHint: true,
    ));
    await _persist();

    if (_checkGameOver(after, userJustMoved: true)) return;

    await _playBotMove();
  }

  /// Returns the best move from the engine and shows it as an arrow on the
  /// board until the user moves. Respects the assist mode's hint limit.
  Future<void> requestHint() async {
    if (_state.status != BotGameStatus.awaitingUser) return;
    if (!config.assistMode.hintsAllowed) return;
    if (!config.assistMode.hintsUnlimited &&
        _state.hintsUsed >= config.assistMode.hintLimit) {
      return;
    }
    final fen = _state.position.fen;
    String? uci;
    try {
      uci = await stockfish.bestMove(fen: fen, depth: config.level.depth);
    } catch (_) {
      return;
    }
    if (_disposed || uci == null) return;
    final move = Move.parse(uci);
    if (move is! NormalMove) return;
    _set(_state.copyWith(
      hintMove: move,
      hintsUsed: _state.hintsUsed + 1,
    ));
  }

  /// Reverts the last user move (and the bot's reply, if any) so the user can
  /// try again. Respects the assist mode's takeback limit.
  void takeback() {
    if (_state.status == BotGameStatus.finished) return;
    if (!config.assistMode.takebacksAllowed) return;
    if (!config.assistMode.takebacksUnlimited &&
        _state.takebacksUsed >= config.assistMode.takebackLimit) {
      return;
    }
    if (_history.isEmpty) return;
    // Pop until it's the user's turn (covers undoing a bot reply + user move).
    _HistoryEntry? target;
    while (_history.isNotEmpty) {
      target = _history.removeLast();
      if (target.position.turn == _state.userSide) break;
    }
    if (target == null) return;
    _set(_state.copyWith(
      position: target.position,
      lastMove: target.lastMove,
      clearLastMove: target.lastMove == null,
      status: BotGameStatus.awaitingUser,
      clearPromotion: true,
      clearHint: true,
      takebacksUsed: _state.takebacksUsed + 1,
    ));
    _persist();
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
    } on StockfishException catch (e) {
      _set(_state.copyWith(
        status: BotGameStatus.finished,
        outcome: BotGameOutcome.draw,
        outcomeReason: e.message,
      ));
      return;
    } catch (_) {
      _set(_state.copyWith(
        status: BotGameStatus.finished,
        outcome: BotGameOutcome.draw,
        outcomeReason: 'Engine error. Start a new game and try again.',
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
    final before = _state.position;
    final after = before.playUnchecked(move);
    _history.add(_HistoryEntry(position: before, lastMove: _state.lastMove));
    _playMoveSnd(_moveSound(before, move, after), fromUser: false);
    AppHaptics.medium();
    _set(_state.copyWith(
      position: after,
      lastMove: move,
      status: BotGameStatus.awaitingUser,
    ));
    await _persist();

    _checkGameOver(after, userJustMoved: false);
  }

  bool _checkGameOver(Position position, {required bool userJustMoved}) {
    if (_state.status == BotGameStatus.finished) return true;
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
    switch (outcome) {
      case BotGameOutcome.userWon:
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!_disposed) sound?.play(SoundEffect.correct);
        });
      case BotGameOutcome.botWon:
        Future.delayed(const Duration(milliseconds: 600), () {
          if (!_disposed) sound?.play(SoundEffect.wrong);
        });
      case BotGameOutcome.draw:
      case BotGameOutcome.resigned:
        break;
    }
    AppHaptics.heavy();
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
    sound?.play(SoundEffect.wrong);
    AppHaptics.heavy();
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

SoundEffect _moveSound(Position before, Move move, Position after) {
  // Check is signalled visually; no separate dramatic sound.
  if (move is NormalMove && before.board.pieceAt(move.to) != null) {
    return SoundEffect.capture;
  }
  return SoundEffect.move;
}
