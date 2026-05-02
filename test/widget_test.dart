import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:woodpecker_chess/data/repositories/puzzle_repository.dart';
import 'package:woodpecker_chess/features/solve/puzzle.dart';
import 'package:woodpecker_chess/features/solve/solve_screen.dart';

void main() {
  testWidgets('SolveScreen shows loading state when puzzle is not yet ready',
      (tester) async {
    final pendingPuzzle = Completer<Puzzle>();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          eloRandomPuzzleProvider.overrideWith((ref) => pendingPuzzle.future),
        ],
        child: const MaterialApp(home: SolveScreen()),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
