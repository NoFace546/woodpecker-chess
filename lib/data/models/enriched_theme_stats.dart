import 'dart:math' as math;

enum ConfidenceLevel { low, medium, high }

enum TrendDirection { improving, stable, declining }

class EnrichedThemeStats {
  const EnrichedThemeStats({
    required this.theme,
    required this.totalAttempts,
    required this.correctAttempts,
    required this.averageTime,
    required this.recentAttempts,
    required this.recentCorrect,
    required this.wilsonLowerLifetime,
    required this.wilsonLowerRecent,
    required this.effectiveAccuracy,
    required this.confidence,
    required this.trend,
  });

  final String theme;
  final int totalAttempts;
  final int correctAttempts;
  final Duration averageTime;
  final int recentAttempts;
  final int recentCorrect;
  final double wilsonLowerLifetime;
  final double wilsonLowerRecent;
  final double effectiveAccuracy;
  final ConfidenceLevel confidence;
  final TrendDirection trend;

  double get rawAccuracy =>
      totalAttempts == 0 ? 0 : correctAttempts / totalAttempts;

  double get recentAccuracy =>
      recentAttempts == 0 ? 0 : recentCorrect / recentAttempts;

  factory EnrichedThemeStats.compute({
    required String theme,
    required int total,
    required int correct,
    required int avgMs,
    required int recentTotal,
    required int recentCorrect,
    required int prevTotal,
    required int prevCorrect,
  }) {
    final wilsonLifetime = wilsonLowerBound(correct, total);
    final wilsonRecent =
        recentTotal > 0 ? wilsonLowerBound(recentCorrect, recentTotal) : 0.0;

    // Effective accuracy: blend lifetime and recent. If recent has data,
    // weight it equally so newer signal is amplified per-attempt.
    final double effective;
    if (recentTotal == 0) {
      effective = wilsonLifetime;
    } else if (total == 0) {
      effective = wilsonRecent;
    } else {
      effective = 0.5 * wilsonLifetime + 0.5 * wilsonRecent;
    }

    final confidence = _confidenceFor(total);
    final trend = _trendFor(
      recentTotal: recentTotal,
      recentCorrect: recentCorrect,
      prevTotal: prevTotal,
      prevCorrect: prevCorrect,
    );

    return EnrichedThemeStats(
      theme: theme,
      totalAttempts: total,
      correctAttempts: correct,
      averageTime: Duration(milliseconds: avgMs),
      recentAttempts: recentTotal,
      recentCorrect: recentCorrect,
      wilsonLowerLifetime: wilsonLifetime,
      wilsonLowerRecent: wilsonRecent,
      effectiveAccuracy: effective,
      confidence: confidence,
      trend: trend,
    );
  }
}

double wilsonLowerBound(int correct, int total, {double z = 1.96}) {
  if (total == 0) return 0;
  final p = correct / total;
  final n = total;
  final denom = 1 + (z * z) / n;
  final center = (p + (z * z) / (2 * n)) / denom;
  final margin =
      z * math.sqrt((p * (1 - p) + (z * z) / (4 * n)) / n) / denom;
  return (center - margin).clamp(0, 1);
}

ConfidenceLevel _confidenceFor(int total) {
  if (total < 5) return ConfidenceLevel.low;
  if (total < 20) return ConfidenceLevel.medium;
  return ConfidenceLevel.high;
}

TrendDirection _trendFor({
  required int recentTotal,
  required int recentCorrect,
  required int prevTotal,
  required int prevCorrect,
}) {
  if (recentTotal < 3 || prevTotal < 3) return TrendDirection.stable;
  final recentAcc = recentCorrect / recentTotal;
  final prevAcc = prevCorrect / prevTotal;
  final diff = recentAcc - prevAcc;
  if (diff > 0.10) return TrendDirection.improving;
  if (diff < -0.10) return TrendDirection.declining;
  return TrendDirection.stable;
}
