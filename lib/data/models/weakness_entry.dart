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
        insight: _insight(t, relSpeed),
      );
    }).toList()
      ..sort((a, b) => b.weaknessScore.compareTo(a.weaknessScore));
    return out;
  }

  String _insight(EnrichedThemeStats t, double relSpeed) {
    if (t.confidence == ConfidenceLevel.low) {
      return 'Only ${t.totalAttempts} attempt${t.totalAttempts == 1 ? '' : 's'} '
          'on ${t.theme} — keep playing for a reliable read.';
    }
    final pct = (t.rawAccuracy * 100).round();
    final secs = (t.averageTime.inMilliseconds / 1000).toStringAsFixed(1);
    final trendSuffix = _trendSuffix(t.trend);
    String body;
    if (t.rawAccuracy < 0.6) {
      body = 'You struggle with ${t.theme} — only $pct% correct. The pattern '
          'isn\'t recognised yet.';
    } else if (t.rawAccuracy < 0.8) {
      body = 'You know ${t.theme} but waver — $pct% correct.';
    } else if (t.rawAccuracy >= 0.85 && relSpeed < 0.7) {
      body = '${t.theme} is solid ($pct%), but you take ${secs}s — slower '
          'than your baseline. Automate the pattern.';
    } else if (t.rawAccuracy >= 0.85 && relSpeed >= 0.9) {
      body = '${t.theme} is locked in — $pct% correct and fast recognition.';
    } else {
      body = '${t.theme}: $pct% correct, avg ${secs}s.';
    }
    return trendSuffix.isEmpty ? body : '$body $trendSuffix';
  }

  String _trendSuffix(TrendDirection trend) {
    switch (trend) {
      case TrendDirection.improving:
        return '(trending up — keep going)';
      case TrendDirection.declining:
        return '(slipping recently — repetition will help)';
      case TrendDirection.stable:
        return '';
    }
  }
}
