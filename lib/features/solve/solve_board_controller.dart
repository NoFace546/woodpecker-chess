import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';

import '../../services/haptic.dart';
import '../../services/sound_service.dart';
import '../../services/stockfish_service.dart';
import 'move_validator.dart';
import 'puzzle.dart';
import 'solve_state.dart';

const _setupMoveDelay = Duration(milliseconds: 150);
const _opponentMoveDelay = Duration(milliseconds: 600);
// Keep timer updates coarse so board animations stay smooth on mid devices.
const _tickInterval = Duration(milliseconds: 500);

class SolveResult {
  const SolveResult({
    required this.puzzleId,
    required this.puzzleRating,
    required this.isCorrect,
    required this.time,
    required this.hintsUsed,
    required this.userMoveUci,
  });

  final String puzzleId;
  final int puzzleRating;
  final bool isCorrect;
  final Duration time;
  final int hintsUsed;
  final String? userMoveUci;
}

class SolveBoardController extends ChangeNotifier {
  SolveBoardController(
    this._puzzle, {
    this.onResult,
    this.stockfish,
    this.sound,
    Duration Function()? animDuration,
  })  : animDuration = animDuration ?? (() => Duration.zero),
        _state = _initial(_puzzle) {
    Future.delayed(_setupMoveDelay, _playSetupMove);
  }

  final Puzzle _puzzle;
  final void Function(SolveResult result)? onResult;
  final StockfishService? stockfish;
  final SoundService? sound;
  final Duration Function() animDuration;

  /// Plays [snd] timed to the move's visual completion. User moves are
  /// instant (animation = 0) so sound fires immediately. Opponent moves
  /// and replay moves are animated, so sound is delayed to land when the
  /// piece visually stops.
  void _playMoveSnd(SoundEffect snd, {required bool fromUser}) {
    final isReplay = _state.status == SolveStatus.revealed;
    final delay =
        (fromUser && !isReplay) ? Duration.zero : animDuration();
    sound?.playAfter(snd, delay);
  }

  SolveState _state;
  Stopwatch? _stopwatch;
  Timer? _ticker;
  bool _resultReported = false;
  bool _disposed = false;
  String? _firstUserMoveUci;

  SolveState get state => _state;

  void _set(SolveState s) {
    if (_disposed) return;
    _state = s;
    notifyListeners();
  }

  static SolveState _initial(Puzzle puzzle) {
    return SolveState(
      puzzle: puzzle,
      position: puzzle.initialPosition,
      status: SolveStatus.loadingSetup,
    );
  }

  void _playSetupMove() {
    if (_state.status != SolveStatus.loadingSetup) return;
    final setupMove = Move.parse(_state.puzzle.uciMoves[0]);
    if (setupMove == null || !_state.position.isLegal(setupMove)) return;
    final before = _state.position;
    final after = before.playUnchecked(setupMove);
    _playMoveSnd(_moveSound(before, setupMove, after), fromUser: false);
    _set(_state.copyWith(
      position: after,
      lastMove: setupMove,
      status: SolveStatus.playing,
      expectedMoveIndex: 1,
    ));
    _startTimer();
  }

  void _startTimer() {
    _stopwatch = Stopwatch()..start();
    var lastSecond = -1;
    _ticker = Timer.periodic(_tickInterval, (_) {
      if (_state.status != SolveStatus.playing) return;
      final elapsed = _stopwatch!.elapsedMilliseconds;
      final second = elapsed ~/ 1000;
      if (second == lastSecond) return;
      lastSecond = second;
      _set(_state.copyWith(elapsedMs: elapsed));
    });
  }

  void _stopTimer() {
    _ticker?.cancel();
    _ticker = null;
    _stopwatch?.stop();
  }

  void requestHint() {
    if (_state.status != SolveStatus.playing) return;
    if (_state.expectedMoveIndex >= _state.puzzle.uciMoves.length) return;
    final expected = _state.puzzle.uciMoves[_state.expectedMoveIndex];
    final move = Move.parse(expected);
    if (move is! NormalMove) return;
    _set(_state.copyWith(
      hintFromSquare: move.from,
      hintsUsed: _state.hintsUsed + 1,
    ));
    AppHaptics.medium();
  }

  Future<void> onUserMove(NormalMove move) async {
    if (_state.status == SolveStatus.exploring) {
      await _playExploringMove(move);
      return;
    }
    if (_state.status != SolveStatus.playing) return;

    final needsPromotion =
        isPromotionPawnMove(_state.position, move) && move.promotion == null;
    if (needsPromotion) {
      _set(_state.copyWith(promotionMove: move));
      return;
    }

    // Capture the user's very first move (regardless of correctness) for
    // later analysis on the puzzle preview screen.
    _firstUserMoveUci ??= move.uci;

    final result = checkUserMove(
      uciMoves: _state.puzzle.uciMoves,
      expectedIndex: _state.expectedMoveIndex,
      userMove: move,
    );

    if (result == MoveCheck.wrong) {
      _stopTimer();
      final expectedUci = _state.puzzle.uciMoves[_state.expectedMoveIndex];
      if (!_state.position.isLegal(move)) return;
      final beforeUser = _state.position;
      final afterUser = beforeUser.playUnchecked(move);
      final userMoveSnd = _moveSound(beforeUser, move, afterUser);

      // Show the move immediately - no "evaluating" pause.
      _set(_state.copyWith(
        position: afterUser,
        lastMove: move,
        status: SolveStatus.wrong,
        userMistakeMove: move,
        expectedUci: expectedUci,
        elapsedMs: _stopwatch?.elapsedMilliseconds ?? _state.elapsedMs,
        clearPromotion: true,
        clearHint: true,
      ));
      _playMoveSnd(userMoveSnd, fromUser: true);
      // Subtle wrong cue, after the move sound so they don't stack.
      sound?.playAfter(
        SoundEffect.wrong,
        const Duration(milliseconds: 220),
      );
      AppHaptics.heavy();
      _reportResult(false, userMoveUci: _firstUserMoveUci);

      // Stockfish reply, then enter exploring mode so the user can keep
      // playing the position to see what happens.
      await _replyAndEnterExploring(afterUser);
      return;
    }

    if (!_state.position.isLegal(move)) return;
    final beforeUser = _state.position;
    final afterUser = beforeUser.playUnchecked(move);
    final userMoveSound = _moveSound(beforeUser, move, afterUser);
    final nextIndex = _state.expectedMoveIndex + 1;

    if (result == MoveCheck.correctAndDone) {
      _stopTimer();
      // If the user already locked in a result on this puzzle (i.e. they
      // failed first, then hit Try again and played it through), don't
      // award "Solved" - show the line as reviewed and skip re-reporting.
      final alreadyReported = _resultReported;
      _set(_state.copyWith(
        position: afterUser,
        lastMove: move,
        expectedMoveIndex: nextIndex,
        status: alreadyReported ? SolveStatus.revealed : SolveStatus.solved,
        elapsedMs: _stopwatch?.elapsedMilliseconds ?? _state.elapsedMs,
        clearPromotion: true,
        clearHint: true,
      ));
      _playMoveSnd(userMoveSound, fromUser: true);
      if (!alreadyReported) {
        // Subtle correct chime, just after the final move sound.
        sound?.playAfter(
          SoundEffect.correct,
          const Duration(milliseconds: 220),
        );
      }
      AppHaptics.heavy();
      if (!alreadyReported) {
        _reportResult(true, userMoveUci: _firstUserMoveUci);
      }
      return;
    }

    _set(_state.copyWith(
      position: afterUser,
      lastMove: move,
      expectedMoveIndex: nextIndex,
      clearPromotion: true,
      clearHint: true,
    ));
    AppHaptics.light();
    _playMoveSnd(userMoveSound, fromUser: true);

    await Future.delayed(_opponentMoveDelay);
    _playOpponentReply();
  }

  Future<void> _replyAndEnterExploring(Position afterUser) async {
    if (afterUser.isGameOver) {
      _set(_state.copyWith(status: SolveStatus.exploring));
      return;
    }
    await Future.delayed(_opponentMoveDelay);
    if (_disposed) return;
    final sf = stockfish;
    String? replyUci;
    if (sf != null) {
      try {
        replyUci = await sf.bestMove(fen: afterUser.fen, depth: 8);
      } catch (e) {
        debugPrint('[wrong-reply] stockfish bestMove threw: $e');
      }
    }
    if (_disposed) return;
    // Whatever happens below, we MUST end in exploring so onUserMove keeps
    // funnelling the user's free moves into _playExploringMove.
    if (replyUci == null) {
      debugPrint('[wrong-reply] no reply UCI; entering exploring without bot move');
      _set(_state.copyWith(status: SolveStatus.exploring));
      return;
    }
    final reply = Move.parse(replyUci);
    if (reply == null || !afterUser.isLegal(reply)) {
      debugPrint('[wrong-reply] reply unparseable or illegal: $replyUci');
      _set(_state.copyWith(status: SolveStatus.exploring));
      return;
    }
    final afterReply = afterUser.playUnchecked(reply);
    _playMoveSnd(_moveSound(afterUser, reply, afterReply), fromUser: false);
    _set(_state.copyWith(
      position: afterReply,
      lastMove: reply,
      status: SolveStatus.exploring,
    ));
  }

  Future<void> _playExploringMove(NormalMove move) async {
    final needsPromotion = isPromotionPawnMove(_state.position, move) &&
        move.promotion == null;
    if (needsPromotion) {
      _set(_state.copyWith(promotionMove: move));
      return;
    }
    if (!_state.position.isLegal(move)) {
      debugPrint('[explore] user move illegal: $move');
      return;
    }
    final before = _state.position;
    final after = before.playUnchecked(move);
    _playMoveSnd(_moveSound(before, move, after), fromUser: true);
    AppHaptics.light();
    // Always force status back to exploring on every user move so a stray
    // state change can't leave us stuck.
    _set(_state.copyWith(
      position: after,
      lastMove: move,
      status: SolveStatus.exploring,
      clearPromotion: true,
    ));
    if (after.isGameOver) {
      debugPrint('[explore] game over after user move');
      return;
    }

    final sf = stockfish;
    if (sf == null) {
      debugPrint('[explore] stockfish unavailable; no reply');
      return;
    }
    await Future.delayed(_opponentMoveDelay);
    if (_disposed) return;
    String? replyUci;
    try {
      replyUci = await sf.bestMove(fen: after.fen, depth: 10);
    } catch (e) {
      debugPrint('[explore] stockfish bestMove threw: $e');
      return;
    }
    if (_disposed) return;
    if (replyUci == null) {
      debugPrint('[explore] stockfish returned null bestMove');
      return;
    }
    final reply = Move.parse(replyUci);
    if (reply == null) {
      debugPrint('[explore] could not parse reply UCI: $replyUci');
      return;
    }
    if (!after.isLegal(reply)) {
      debugPrint('[explore] reply illegal in current position: $replyUci');
      return;
    }
    final afterReply = after.playUnchecked(reply);
    _playMoveSnd(_moveSound(after, reply, afterReply), fromUser: false);
    _set(_state.copyWith(
      position: afterReply,
      lastMove: reply,
      status: SolveStatus.exploring,
    ));
  }

  void onPromotionSelected(Role role) {
    final pending = _state.promotionMove;
    if (pending == null) return;
    onUserMove(pending.withPromotion(role));
  }

  void cancelPromotion() {
    _set(_state.copyWith(clearPromotion: true));
  }

  void _playOpponentReply() {
    if (_state.status != SolveStatus.playing) return;
    if (_state.expectedMoveIndex >= _state.puzzle.uciMoves.length) return;
    final move = Move.parse(_state.puzzle.uciMoves[_state.expectedMoveIndex]);
    if (move == null || !_state.position.isLegal(move)) return;
    final before = _state.position;
    final after = before.playUnchecked(move);
    _playMoveSnd(_moveSound(before, move, after), fromUser: false);
    _set(_state.copyWith(
      position: after,
      lastMove: move,
      expectedMoveIndex: _state.expectedMoveIndex + 1,
    ));
  }

  void resetForRetry() {
    _stopTimer();
    // Keep _resultReported = true so the retry doesn't record a second
    // attempt - the failed first try is the one that counts in stats.
    _firstUserMoveUci = null;
    _set(_initial(_puzzle));
    Future.delayed(_setupMoveDelay, _playSetupMove);
  }

  Future<void> revealSolution() async {
    if (_state.status == SolveStatus.revealed) return;
    if (_state.status == SolveStatus.solved) return;
    _stopTimer();
    if (!_resultReported && _state.status == SolveStatus.playing) {
      _reportResult(false, userMoveUci: _firstUserMoveUci);
    }
    // Reset board to puzzle initial position, then play every move with a
    // delay so the user can follow the line.
    var pos = _puzzle.initialPosition;
    _set(SolveState(
      puzzle: _puzzle,
      position: pos,
      status: SolveStatus.revealed,
      hintsUsed: _state.hintsUsed,
      elapsedMs: _state.elapsedMs,
    ));
    for (var i = 0; i < _puzzle.uciMoves.length; i++) {
      await Future.delayed(_opponentMoveDelay);
      if (_disposed) return;
      final uci = _puzzle.uciMoves[i];
      final move = Move.parse(uci);
      if (move == null || !pos.isLegal(move)) break;
      final before = pos;
      pos = pos.playUnchecked(move);
      _playMoveSnd(_moveSound(before, move, pos), fromUser: false);
      _set(_state.copyWith(
        position: pos,
        lastMove: move,
        expectedMoveIndex: i + 1,
        status: SolveStatus.revealed,
      ));
    }
  }

  void _reportResult(bool isCorrect, {String? userMoveUci}) {
    if (_resultReported) return;
    _resultReported = true;
    onResult?.call(SolveResult(
      puzzleId: _puzzle.id,
      puzzleRating: _puzzle.rating,
      isCorrect: isCorrect,
      time: Duration(milliseconds: _state.elapsedMs),
      hintsUsed: _state.hintsUsed,
      userMoveUci: userMoveUci,
    ));
  }

  @override
  void dispose() {
    _disposed = true;
    _stopTimer();
    super.dispose();
  }
}

SoundEffect _moveSound(Position before, Move move, Position after) {
  // Check is signalled visually; no separate dramatic sound.
  if (move is NormalMove && before.board.pieceAt(move.to) != null) {
    return SoundEffect.capture;
  }
  return SoundEffect.move;
}
