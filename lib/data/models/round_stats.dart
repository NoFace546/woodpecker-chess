import 'puzzle_attempt.dart';
import 'round.dart';

class RoundStats {
  const RoundStats({
    required this.roundId,
    required this.roundNumber,
    required this.total,
    required this.correct,
    required this.hintsUsed,
    required this.totalTime,
    required this.averageTime,
    required this.medianTime,
    required this.longestFlowStreak,
    required this.startedAt,
    this.completedAt,
  });

  final String roundId;
  final int roundNumber;
  final int total;
  final int correct;
  final int hintsUsed;
  final Duration totalTime;
  final Duration averageTime;
  final Duration medianTime;
  final int longestFlowStreak;
  final DateTime startedAt;
  final DateTime? completedAt;

  double get accuracy => total == 0 ? 0 : correct / total;

  double get yieldPerMinute {
    final minutes = totalTime.inMilliseconds / 60000.0;
    if (minutes <= 0) return 0;
    return correct / minutes;
  }

  factory RoundStats.fromAttempts({
    required Round round,
    required List<PuzzleAttempt> attempts,
    Duration flowThreshold = const Duration(seconds: 15),
  }) {
    if (attempts.isEmpty) {
      return RoundStats(
        roundId: round.id,
        roundNumber: round.roundNumber,
        total: 0,
        correct: 0,
        hintsUsed: 0,
        totalTime: Duration.zero,
        averageTime: Duration.zero,
        medianTime: Duration.zero,
        longestFlowStreak: 0,
        startedAt: round.startedAt,
        completedAt: round.completedAt,
      );
    }

    final sorted = attempts.toList()
      ..sort((a, b) => a.position.compareTo(b.position));

    // Hint-assisted solves don't count as correct - pattern wasn't recognised.
    final correct =
        sorted.where((a) => a.isCorrect && a.hintsUsed == 0).length;
    final hintsUsed = sorted.fold<int>(0, (s, a) => s + a.hintsUsed);
    final totalMs = sorted.fold<int>(0, (s, a) => s + a.time.inMilliseconds);
    final times = sorted.map((a) => a.time.inMilliseconds).toList()..sort();
    final medianMs = times.length.isOdd
        ? times[times.length ~/ 2]
        : ((times[times.length ~/ 2 - 1] + times[times.length ~/ 2]) / 2)
            .round();

    int currentStreak = 0;
    int longestStreak = 0;
    for (final a in sorted) {
      // Hint-assisted solves break the flow streak.
      if (a.isCorrect && a.hintsUsed == 0 && a.time <= flowThreshold) {
        currentStreak++;
        if (currentStreak > longestStreak) longestStreak = currentStreak;
      } else {
        currentStreak = 0;
      }
    }

    return RoundStats(
      roundId: round.id,
      roundNumber: round.roundNumber,
      total: sorted.length,
      correct: correct,
      hintsUsed: hintsUsed,
      totalTime: Duration(milliseconds: totalMs),
      averageTime: Duration(milliseconds: totalMs ~/ sorted.length),
      medianTime: Duration(milliseconds: medianMs),
      longestFlowStreak: longestStreak,
      startedAt: round.startedAt,
      completedAt: round.completedAt,
    );
  }
}
