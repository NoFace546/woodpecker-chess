import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:woodpecker_chess/features/solve/solve_screen.dart';

void main() {
  testWidgets('SolveScreen shows loading state when puzzle is not yet ready',
      (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SolveScreen()),
      ),
    );
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
