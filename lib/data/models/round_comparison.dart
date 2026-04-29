import 'round_stats.dart';

class RoundComparison {
  const RoundComparison({required this.current, this.previous});

  final RoundStats current;
  final RoundStats? previous;

  // Positive = saved time. Negative = took longer.
  Duration get timeSavings {
    if (previous == null) return Duration.zero;
    return previous!.totalTime - current.totalTime;
  }

  // Positive = faster. Based on median (typical pace).
  double get speedupPercent {
    final p = previous;
    if (p == null) return 0;
    final prev = p.medianTime.inMilliseconds;
    if (prev == 0) return 0;
    return (prev - current.medianTime.inMilliseconds) / prev * 100.0;
  }

  // Positive = improved.
  double get accuracyDelta {
    if (previous == null) return 0;
    return current.accuracy - previous!.accuracy;
  }

  Duration get medianDelta {
    if (previous == null) return Duration.zero;
    return previous!.medianTime - current.medianTime;
  }
}
