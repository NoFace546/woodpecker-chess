import 'dart:async';

import 'package:dartchess/dartchess.dart';
import 'package:flutter/foundation.dart';

import '../../services/haptic.dart';
import '../../services/sound_service.dart';
import '../../services/stockfish_service.dart';
import 'move_validator.dart';
import 'puzzle.dart';
import 'solve_state.dart';

const _setupMoveDelay = Duration(milliseconds: 600);
const _opponentMoveDelay = Duration(milliseconds: 600);
const _tickInterval = Duration(milliseconds: 100);
const _evalDepth = 16;
const _almostBestThreshold = 30;
const _inaccuracyThreshold = 100;

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
  }) : _state = _initial(_puzzle) {
    Future.delayed(_setupMoveDelay, _playSetupMove);
  }

  final Puzzle _puzzle;
  final void Function(SolveResult result)? onResult;
  final StockfishService? stockfish;
  final SoundService? sound;

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
    final after = _state.position.playUnchecked(setupMove);
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
    _ticker = Timer.periodic(_tickInterval, (_) {
      if (_state.status != SolveStatus.playing) return;
      _set(_state.copyWith(elapsedMs: _stopwatch!.elapsedMilliseconds));
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
      final fenBefore = _state.position.fen;

      _set(_state.copyWith(
        status: SolveStatus.evaluating,
        userMistakeMove: move,
        expectedUci: expectedUci,
        elapsedMs: _stopwatch?.elapsedMilliseconds ?? _state.elapsedMs,
        clearPromotion: true,
        clearHint: true,
      ));

      final quality = await _classifyMistake(
        fen: fenBefore,
        userMove: move.uci,
        expectedMove: expectedUci,
      );
      if (_disposed) return;

      _set(_state.copyWith(
        status: quality.status,
        cpLoss: quality.cpLoss,
      ));
      AppHaptics.heavy();
      sound?.play(SoundEffect.wrong);
      _reportResult(false, userMoveUci: _firstUserMoveUci);

      if (quality.status == SolveStatus.inaccuracy ||
          quality.status == SolveStatus.wrong) {
        await _playMistakeContinuation(move);
      }
      return;
    }

    if (!_state.position.isLegal(move)) return;
    final afterUser = _state.position.playUnchecked(move);
    final nextIndex = _state.expectedMoveIndex + 1;

    if (result == MoveCheck.correctAndDone) {
      _stopTimer();
      // If the user already locked in a result on this puzzle (i.e. they
      // failed first, then hit Try again and played it through), don't
      // award "Solved" — show the line as reviewed and skip re-reporting.
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
      AppHaptics.heavy();
      if (!alreadyReported) {
        sound?.play(SoundEffect.correct);
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
    sound?.play(SoundEffect.move);

    await Future.delayed(_opponentMoveDelay);
    _playOpponentReply();
  }

  Future<void> _playMistakeContinuation(NormalMove userMove) async {
    final sf = stockfish;
    if (sf == null) return;
    if (!_state.position.isLegal(userMove)) return;
    final afterUser = _state.position.playUnchecked(userMove);

    await Future.delayed(_opponentMoveDelay);
    if (_disposed) return;
    _set(_state.copyWith(position: afterUser, lastMove: userMove));

    if (afterUser.isGameOver) return;

    final String? replyUci;
    try {
      replyUci = await sf.bestMove(fen: afterUser.fen, depth: 12);
    } catch (_) {
      return;
    }
    if (_disposed || replyUci == null) return;

    final reply = Move.parse(replyUci);
    if (reply == null || !afterUser.isLegal(reply)) return;
    final afterReply = afterUser.playUnchecked(reply);

    await Future.delayed(_opponentMoveDelay);
    if (_disposed) return;
    _set(_state.copyWith(position: afterReply, lastMove: reply));
  }

  Future<_MistakeQuality> _classifyMistake({
    required String fen,
    required String userMove,
    required String expectedMove,
  }) async {
    final sf = stockfish;
    if (sf == null) {
      return const _MistakeQuality(SolveStatus.wrong, null);
    }
    try {
      final results = await Future.wait([
        sf.evaluateAfterMove(fen: fen, moveUci: userMove, depth: _evalDepth),
        sf.evaluateAfterMove(fen: fen, moveUci: expectedMove, depth: _evalDepth),
      ]);
      final cpUser = results[0];
      final cpExpected = results[1];
      final loss = cpExpected - cpUser;
      if (loss < _almostBestThreshold) {
        return _MistakeQuality(SolveStatus.almostBest, loss < 0 ? 0 : loss);
      }
      if (loss < _inaccuracyThreshold) {
        return _MistakeQuality(SolveStatus.inaccuracy, loss);
      }
      return _MistakeQuality(SolveStatus.wrong, loss);
    } catch (_) {
      return const _MistakeQuality(SolveStatus.wrong, null);
    }
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
    final after = _state.position.playUnchecked(move);
    _set(_state.copyWith(
      position: after,
      lastMove: move,
      expectedMoveIndex: _state.expectedMoveIndex + 1,
    ));
  }

  void resetForRetry() {
    _stopTimer();
    // Keep _resultReported = true so the retry doesn't record a second
    // attempt — the failed first try is the one that counts in stats.
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
      pos = pos.playUnchecked(move);
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

class _MistakeQuality {
  const _MistakeQuality(this.status, this.cpLoss);
  final SolveStatus status;
  final int? cpLoss;
}
