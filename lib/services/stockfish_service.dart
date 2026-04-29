import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:multistockfish/multistockfish.dart';

class EvalResult {
  const EvalResult({required this.bestMoveUci, required this.cp});
  final String? bestMoveUci;
  final int cp; // from side-to-move perspective; mate scores mapped to ±100000
}

class StockfishService {
  StockfishService();

  final Stockfish _engine = Stockfish.instance;
  bool _started = false;
  Future<dynamic> _serial = Future.value();
  bool _strengthLimited = false;

  Future<void> start() async {
    if (_started) return;
    if (_engine.state.value == StockfishState.ready) {
      _started = true;
      return;
    }
    await _engine.start();
    _started = true;
  }

  Future<void> setElo(int elo) async {
    await start();
    _engine.stdin = 'setoption name Skill Level value 20';
    if (!_strengthLimited) {
      _engine.stdin = 'setoption name UCI_LimitStrength value true';
      _strengthLimited = true;
    }
    _engine.stdin = 'setoption name UCI_Elo value $elo';
  }

  Future<void> setSkillLevel(int skill) async {
    await start();
    if (_strengthLimited) {
      _engine.stdin = 'setoption name UCI_LimitStrength value false';
      _strengthLimited = false;
    }
    _engine.stdin = 'setoption name Skill Level value $skill';
  }

  Future<void> resetStrength() async {
    await start();
    if (_strengthLimited) {
      _engine.stdin = 'setoption name UCI_LimitStrength value false';
      _strengthLimited = false;
    }
    _engine.stdin = 'setoption name Skill Level value 20';
  }

  Future<EvalResult> evaluate({
    required String fen,
    int depth = 18,
  }) {
    return _serialize(() => _runGo(fen: fen, depth: depth));
  }

  Future<int> evaluateAfterMove({
    required String fen,
    required String moveUci,
    int depth = 18,
  }) {
    return _serialize(() async {
      final r = await _runGo(fen: fen, moves: [moveUci], depth: depth);
      return -r.cp;
    });
  }

  Future<String?> bestMove({
    required String fen,
    int depth = 12,
  }) {
    return _serialize(() async {
      final r = await _runGo(fen: fen, depth: depth);
      return r.bestMoveUci;
    });
  }

  Future<EvalResult> _runGo({
    required String fen,
    List<String>? moves,
    required int depth,
  }) async {
    await start();

    final movesPart =
        (moves != null && moves.isNotEmpty) ? ' moves ${moves.join(' ')}' : '';
    final completer = Completer<EvalResult>();
    int? lastCp;
    int? lastMate;

    final cpRegex = RegExp(r'score cp (-?\d+)');
    final mateRegex = RegExp(r'score mate (-?\d+)');
    final bestRegex = RegExp(r'^bestmove\s+(\S+)');

    final sub = _engine.stdout.listen((line) {
      final cpMatch = cpRegex.firstMatch(line);
      if (cpMatch != null) {
        lastCp = int.parse(cpMatch.group(1)!);
        lastMate = null;
      }
      final mateMatch = mateRegex.firstMatch(line);
      if (mateMatch != null) {
        lastMate = int.parse(mateMatch.group(1)!);
        lastCp = null;
      }
      final bestMatch = bestRegex.firstMatch(line);
      if (bestMatch != null && !completer.isCompleted) {
        final move = bestMatch.group(1)!;
        final cp = lastMate != null
            ? (lastMate! > 0 ? 100000 - lastMate! : -100000 - lastMate!)
            : (lastCp ?? 0);
        completer.complete(
          EvalResult(
            bestMoveUci: move == '(none)' ? null : move,
            cp: cp,
          ),
        );
      }
    });

    _engine.stdin = 'position fen $fen$movesPart';
    _engine.stdin = 'go depth $depth';

    try {
      return await completer.future.timeout(const Duration(seconds: 30));
    } finally {
      await sub.cancel();
    }
  }

  Future<T> _serialize<T>(Future<T> Function() task) {
    final completer = Completer<T>();
    _serial = _serial.then((_) async {
      try {
        completer.complete(await task());
      } catch (e, st) {
        completer.completeError(e, st);
      }
    });
    return completer.future;
  }

  Future<void> dispose() async {
    if (_started) {
      await _engine.quit();
      _started = false;
      _strengthLimited = false;
    }
  }
}

final stockfishServiceProvider = Provider<StockfishService>((ref) {
  final service = StockfishService();
  ref.onDispose(service.dispose);
  return service;
});
