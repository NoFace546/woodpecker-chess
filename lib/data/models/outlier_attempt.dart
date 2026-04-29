import 'puzzle_attempt.dart';

class OutlierAttempt {
  const OutlierAttempt({
    required this.attempt,
    required this.themes,
    required this.rating,
    required this.fen,
  });

  final PuzzleAttempt attempt;
  final List<String> themes;
  final int rating;
  final String fen;
}
