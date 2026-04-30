import 'enriched_theme_stats.dart';

class WeaknessEntry {
  const WeaknessEntry({
    required this.stats,
    required this.relativeSpeed,
    required this.weaknessScore,
    required this.insight,
  });

  final EnrichedThemeStats stats;
  final double relativeSpeed; // >1 = faster than baseline; <1 = slower
  final double weaknessScore; // 0..1, higher = weaker
  final String insight;

  String get theme => stats.theme;
  ConfidenceLevel get confidence => stats.confidence;
  TrendDirection get trend => stats.trend;
}

class WeaknessAnalyzer {
  const WeaknessAnalyzer();

  List<WeaknessEntry> analyze({
    required List<EnrichedThemeStats> themes,
    required int globalMedianMs,
    double userAccuracy = 0.5,
  }) {
    final out = themes.map((t) {
      final relSpeed = (globalMedianMs == 0 ||
              t.averageTime.inMilliseconds == 0)
          ? 1.0
          : globalMedianMs / t.averageTime.inMilliseconds;
      final relClamped = relSpeed.clamp(0.0, 2.0);
      final speedPenalty = (1.0 - relClamped.clamp(0.0, 1.0)).clamp(0.0, 1.0);
      // Effective accuracy already blends Wilson lifetime + recent.
      final weakness =
          0.7 * (1 - t.effectiveAccuracy) + 0.3 * speedPenalty;
      return WeaknessEntry(
        stats: t,
        relativeSpeed: relSpeed,
        weaknessScore: weakness,
        insight: _insight(t, relSpeed, userAccuracy),
      );
    }).toList()
      ..sort((a, b) => b.weaknessScore.compareTo(a.weaknessScore));
    return out;
  }

  String _insight(
      EnrichedThemeStats t, double relSpeed, double userAccuracy) {
    if (t.confidence == ConfidenceLevel.low) {
      final needed = 5 - t.totalAttempts;
      if (needed > 0) {
        return 'Only ${t.totalAttempts} attempt${t.totalAttempts == 1 ? '' : 's'}. '
            'Need $needed more for a reliable read.';
      }
      final highNeeded = 20 - t.totalAttempts;
      return 'Only ${t.totalAttempts} attempts. Need $highNeeded more for '
          'a high-confidence read.';
    }

    final pct = (t.rawAccuracy * 100).round();
    final userPct = (userAccuracy * 100).round();
    final gap = pct - userPct;
    final secs = (t.averageTime.inMilliseconds / 1000).toStringAsFixed(1);

    // Block 1: accuracy vs baseline.
    final String accuracyBlock;
    if (gap >= 5) {
      accuracyBlock = '$pct%, $gap pts above your $userPct% overall.';
    } else if (gap <= -5) {
      accuracyBlock = '$pct%, ${gap.abs()} pts below your $userPct% overall.';
    } else {
      accuracyBlock = '$pct%, close to your $userPct% overall.';
    }

    // Block 2: speed vs baseline.
    final String speedBlock;
    if (relSpeed >= 1.2) {
      speedBlock =
          'Avg ${secs}s, ${relSpeed.toStringAsFixed(1)}× your baseline.';
    } else if (relSpeed >= 0.8) {
      speedBlock = 'Avg ${secs}s, on pace with your baseline.';
    } else {
      final slow = (1 / relSpeed).toStringAsFixed(1);
      speedBlock = 'Avg ${secs}s, $slow× slower than baseline.';
    }

    // Block 3: trend (only if not stable).
    final String? trendBlock = switch (t.trend) {
      TrendDirection.improving => 'Trending up.',
      TrendDirection.declining => 'Slipping recently.',
      TrendDirection.stable => null,
    };

    // Block 4: action recommendation.
    final String? actionBlock;
    if (t.rawAccuracy < 0.6) {
      actionBlock = 'Pattern not recognised yet. Drill until ≥85%.';
    } else if (t.rawAccuracy < 0.8) {
      actionBlock = 'Wavering. Repetition will solidify it.';
    } else if (relSpeed < 0.7) {
      actionBlock = 'Accurate but slow. Automate via repetition.';
    } else if (t.rawAccuracy >= 0.9 && relSpeed >= 0.9) {
      actionBlock = 'Locked in.';
    } else {
      actionBlock = null;
    }

    return [accuracyBlock, speedBlock, trendBlock, actionBlock]
        .whereType<String>()
        .join(' ');
  }
}
