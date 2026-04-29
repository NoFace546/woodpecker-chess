class PuzzleAttempt {
  const PuzzleAttempt({
    required this.id,
    required this.roundId,
    required this.puzzleId,
    required this.position,
    required this.isCorrect,
    required this.time,
    required this.finishedAt,
    this.hintsUsed = 0,
    this.userMoveUci,
  });

  final String id;
  final String roundId;
  final String puzzleId;
  final int position;
  final bool isCorrect;
  final Duration time;
  final DateTime finishedAt;
  final int hintsUsed;
  final String? userMoveUci;
}
