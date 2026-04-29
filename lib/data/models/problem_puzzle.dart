class ProblemPuzzle {
  const ProblemPuzzle({
    required this.puzzleId,
    required this.failedRounds,
    required this.themes,
    required this.rating,
    required this.fen,
  });

  final String puzzleId;
  final int failedRounds;
  final List<String> themes;
  final int rating;
  final String fen;
}
