import 'dart:math' as math;

enum ConfidenceLevel { low, medium, high }

enum TrendDirection { improving, stable, declining }

/// 200-Elo rating buckets. `bucketMin` is inclusive, `bucketMin + 200`
/// exclusive. Bucket center = bucketMin + 100. So a puzzle rated 1437 lives
/// in bucket 1400 (center 1500).
const int kRatingBucketSize = 200;

int ratingBucket(int rating) => (rating ~/ kRatingBucketSize) * kRatingBucketSize;

/// Per-bucket aggregates for one tactical theme. The recommender / analyzer
/// re-weights these against the user's current Elo so historical strength
/// at a lower level does not mask current weakness at a higher level.
class ThemeRatingBucket {
  const ThemeRatingBucket({
    required this.bucketMin,
    required this.total,
    required this.correct,
    required this.recentTotal,
    required this.recentCorrect,
    required this.prevTotal,
    required this.prevCorrect,
    required this.avgTimeMs,
  });

  final int bucketMin;
  final int total;
  final int correct;
  final int recentTotal;
  final int recentCorrect;
  final int prevTotal;
  final int prevCorrect;
  final int avgTimeMs;

  int get bucketCenter => bucketMin + kRatingBucketSize ~/ 2;
}

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
    required this.buckets,
    required this.effectiveSampleSize,
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
  // Bucket-level history kept on the stat so callers can render distribution
  // or recompute against a different anchor Elo.
  final List<ThemeRatingBucket> buckets;
  // Elo-weighted "effective" attempt count used for the confidence rating.
  // 100 attempts at Elo 800 give few effective attempts when the user is
  // 1500 - they tell you little about current skill at the higher level.
  final double effectiveSampleSize;

  double get rawAccuracy =>
      totalAttempts == 0 ? 0 : correctAttempts / totalAttempts;

  double get recentAccuracy =>
      recentAttempts == 0 ? 0 : recentCorrect / recentAttempts;

  /// Builds a stat from the per-bucket rows, weighting buckets by their
  /// distance to the anchor Elo (a Gaussian with σ = [kRatingBucketSize]).
  /// [userElo] is the user's current rating - the question being answered
  /// is "how well does the user *currently* solve this theme at their
  /// current level?"
  factory EnrichedThemeStats.fromBuckets({
    required String theme,
    required List<ThemeRatingBucket> buckets,
    required int userElo,
  }) {
    if (buckets.isEmpty) {
      return EnrichedThemeStats(
        theme: theme,
        totalAttempts: 0,
        correctAttempts: 0,
        averageTime: Duration.zero,
        recentAttempts: 0,
        recentCorrect: 0,
        wilsonLowerLifetime: 0,
        wilsonLowerRecent: 0,
        effectiveAccuracy: 0,
        confidence: ConfidenceLevel.low,
        trend: TrendDirection.stable,
        buckets: const [],
        effectiveSampleSize: 0,
      );
    }

    final totalAttempts = buckets.fold<int>(0, (s, b) => s + b.total);
    final correctAttempts = buckets.fold<int>(0, (s, b) => s + b.correct);
    final recentTotal = buckets.fold<int>(0, (s, b) => s + b.recentTotal);
    final recentCorrect =
        buckets.fold<int>(0, (s, b) => s + b.recentCorrect);
    final prevTotal = buckets.fold<int>(0, (s, b) => s + b.prevTotal);
    final prevCorrect = buckets.fold<int>(0, (s, b) => s + b.prevCorrect);

    // Weighted-average puzzle-time uses raw attempt counts (no Elo bias).
    final timeNumer = buckets.fold<double>(
      0,
      (s, b) => s + b.avgTimeMs.toDouble() * b.total,
    );
    final avgMs = totalAttempts == 0 ? 0 : (timeNumer / totalAttempts).round();

    // Elo-weighted aggregates. weight per bucket = exp(-((distance/σ)²)).
    final double sigma = kRatingBucketSize.toDouble();
    double weightFor(int bucketCenter) {
      final d = (bucketCenter - userElo) / sigma;
      return math.exp(-d * d);
    }

    double wTotal = 0;
    double wCorrect = 0;
    double wRecentTotal = 0;
    double wRecentCorrect = 0;
    for (final b in buckets) {
      final w = weightFor(b.bucketCenter);
      wTotal += w * b.total;
      wCorrect += w * b.correct;
      wRecentTotal += w * b.recentTotal;
      wRecentCorrect += w * b.recentCorrect;
    }

    // Treat the weighted sample as if it were an integer-binomial draw with
    // size = wTotal. Wilson lower-bound is well-defined for any positive n.
    final wilsonLifetime = _wilsonLowerBoundFractional(wCorrect, wTotal);
    final wilsonRecent = wRecentTotal > 0
        ? _wilsonLowerBoundFractional(wRecentCorrect, wRecentTotal)
        : 0.0;

    // Lifetime + recent blend, weighted toward recent (30/70). Recent
    // performance is the better signal once the user starts climbing.
    final double effective;
    if (wRecentTotal == 0) {
      effective = wilsonLifetime;
    } else if (wTotal == 0) {
      effective = wilsonRecent;
    } else {
      effective = 0.3 * wilsonLifetime + 0.7 * wilsonRecent;
    }

    final effectiveSampleSize = wTotal;
    final confidence = _confidenceFor(effectiveSampleSize.round());
    final trend = _trendFor(
      recentTotal: recentTotal,
      recentCorrect: recentCorrect,
      prevTotal: prevTotal,
      prevCorrect: prevCorrect,
    );

    return EnrichedThemeStats(
      theme: theme,
      totalAttempts: totalAttempts,
      correctAttempts: correctAttempts,
      averageTime: Duration(milliseconds: avgMs),
      recentAttempts: recentTotal,
      recentCorrect: recentCorrect,
      wilsonLowerLifetime: wilsonLifetime,
      wilsonLowerRecent: wilsonRecent,
      effectiveAccuracy: effective,
      confidence: confidence,
      trend: trend,
      buckets: buckets,
      effectiveSampleSize: effectiveSampleSize,
    );
  }
}

/// Wilson lower-bound that accepts non-integer correct/total counts (so it
/// can be applied to Elo-weighted samples). Mathematically equivalent to
/// the integer version when inputs are integers.
double _wilsonLowerBoundFractional(double correct, double total,
    {double z = 1.96}) {
  if (total <= 0) return 0;
  final p = correct / total;
  final n = total;
  final denom = 1 + (z * z) / n;
  final center = (p + (z * z) / (2 * n)) / denom;
  final margin =
      z * math.sqrt((p * (1 - p) + (z * z) / (4 * n)) / n) / denom;
  final v = center - margin;
  if (v.isNaN) return 0;
  return v.clamp(0.0, 1.0);
}

/// Kept for callers that still want the integer-only version.
double wilsonLowerBound(int correct, int total, {double z = 1.96}) {
  return _wilsonLowerBoundFractional(
    correct.toDouble(),
    total.toDouble(),
    z: z,
  );
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
