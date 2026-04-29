class PhasePoint {
  const PhasePoint({
    required this.phase,
    required this.total,
    required this.correct,
    required this.averageTimeMs,
  });

  final String phase; // 'opening' | 'middlegame' | 'endgame'
  final int total;
  final int correct;
  final int averageTimeMs;

  double get accuracy => total == 0 ? 0 : correct / total;
}

class PhaseStats {
  const PhaseStats({
    required this.opening,
    required this.middlegame,
    required this.endgame,
  });

  final PhasePoint opening;
  final PhasePoint middlegame;
  final PhasePoint endgame;

  int get totalAttempts =>
      opening.total + middlegame.total + endgame.total;

  bool get hasAnyData => totalAttempts > 0;
}
