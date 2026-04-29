import 'package:dartchess/dartchess.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:woodpecker_chess/features/solve/move_validator.dart';

void main() {
  group('checkUserMove', () {
    const moves = ['e8d7', 'a2e6', 'd7d8', 'f7f8'];

    test('correct user move returns correct', () {
      final result = checkUserMove(
        uciMoves: moves,
        expectedIndex: 1,
        userMove: Move.parse('a2e6')!,
      );
      expect(result, MoveCheck.correct);
    });

    test('correct final user move returns correctAndDone', () {
      final result = checkUserMove(
        uciMoves: moves,
        expectedIndex: 3,
        userMove: Move.parse('f7f8')!,
      );
      expect(result, MoveCheck.correctAndDone);
    });

    test('wrong user move returns wrong', () {
      final result = checkUserMove(
        uciMoves: moves,
        expectedIndex: 1,
        userMove: Move.parse('a2b3')!,
      );
      expect(result, MoveCheck.wrong);
    });

    test('out-of-bounds index returns wrong', () {
      final result = checkUserMove(
        uciMoves: moves,
        expectedIndex: 99,
        userMove: Move.parse('a2e6')!,
      );
      expect(result, MoveCheck.wrong);
    });
  });
}
