import 'package:dartchess/dartchess.dart';

enum MoveCheck { correct, correctAndDone, wrong }

MoveCheck checkUserMove({
  required List<String> uciMoves,
  required int expectedIndex,
  required Move userMove,
}) {
  if (expectedIndex < 0 || expectedIndex >= uciMoves.length) {
    return MoveCheck.wrong;
  }
  if (userMove.uci != uciMoves[expectedIndex]) {
    return MoveCheck.wrong;
  }
  final isLast = expectedIndex == uciMoves.length - 1;
  return isLast ? MoveCheck.correctAndDone : MoveCheck.correct;
}

bool isPromotionPawnMove(Position position, NormalMove move) {
  final piece = position.board.pieceAt(move.from);
  if (piece == null || piece.role != Role.pawn) return false;
  final toRank = move.to.rank;
  return toRank == Rank.first || toRank == Rank.eighth;
}
