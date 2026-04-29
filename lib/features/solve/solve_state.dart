import 'package:dartchess/dartchess.dart';

import 'puzzle.dart';

enum SolveStatus {
  loadingSetup,
  playing,
  evaluating,
  almostBest,
  inaccuracy,
  wrong,
  solved,
  revealed,
}

class SolveState {
  const SolveState({
    required this.puzzle,
    required this.position,
    required this.status,
    this.lastMove,
    this.expectedMoveIndex = 0,
    this.elapsedMs = 0,
    this.promotionMove,
    this.expectedUci,
    this.userMistakeMove,
    this.hintsUsed = 0,
    this.hintFromSquare,
    this.cpLoss,
  });

  final Puzzle puzzle;
  final Position position;
  final SolveStatus status;
  final Move? lastMove;
  final int expectedMoveIndex;
  final int elapsedMs;
  final NormalMove? promotionMove;
  final String? expectedUci;
  final Move? userMistakeMove;
  final int hintsUsed;
  final Square? hintFromSquare;
  final int? cpLoss;

  Side get userSide => puzzle.userSide;

  SolveState copyWith({
    Position? position,
    SolveStatus? status,
    Move? lastMove,
    int? expectedMoveIndex,
    int? elapsedMs,
    NormalMove? promotionMove,
    bool clearPromotion = false,
    String? expectedUci,
    Move? userMistakeMove,
    int? hintsUsed,
    Square? hintFromSquare,
    bool clearHint = false,
    int? cpLoss,
    bool clearCpLoss = false,
  }) {
    return SolveState(
      puzzle: puzzle,
      position: position ?? this.position,
      status: status ?? this.status,
      lastMove: lastMove ?? this.lastMove,
      expectedMoveIndex: expectedMoveIndex ?? this.expectedMoveIndex,
      elapsedMs: elapsedMs ?? this.elapsedMs,
      promotionMove:
          clearPromotion ? null : (promotionMove ?? this.promotionMove),
      expectedUci: expectedUci ?? this.expectedUci,
      userMistakeMove: userMistakeMove ?? this.userMistakeMove,
      hintsUsed: hintsUsed ?? this.hintsUsed,
      hintFromSquare:
          clearHint ? null : (hintFromSquare ?? this.hintFromSquare),
      cpLoss: clearCpLoss ? null : (cpLoss ?? this.cpLoss),
    );
  }
}
