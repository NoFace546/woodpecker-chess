class EloHistoryEntry {
  const EloHistoryEntry({
    required this.puzzleId,
    required this.puzzleRating,
    required this.eloBefore,
    required this.eloAfter,
    required this.wasCorrect,
    required this.at,
  });

  final String puzzleId;
  final int puzzleRating;
  final int eloBefore;
  final int eloAfter;
  final bool wasCorrect;
  final DateTime at;

  int get delta => eloAfter - eloBefore;
}
