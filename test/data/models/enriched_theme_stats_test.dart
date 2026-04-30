import 'package:flutter_test/flutter_test.dart';
import 'package:woodpecker_chess/data/models/enriched_theme_stats.dart';

void main() {
  group('EnrichedThemeStats.fromBuckets', () {
    test('weights nearby Elo bucket much more than far buckets', () {
      final stats = EnrichedThemeStats.fromBuckets(
        theme: 'fork',
        userElo: 1500,
        buckets: const [
          ThemeRatingBucket(
            bucketMin: 1400, // center 1500 (near)
            total: 10,
            correct: 2,
            recentTotal: 10,
            recentCorrect: 2,
            prevTotal: 10,
            prevCorrect: 2,
            avgTimeMs: 5000,
          ),
          ThemeRatingBucket(
            bucketMin: 600, // center 700 (far)
            total: 100,
            correct: 100,
            recentTotal: 100,
            recentCorrect: 100,
            prevTotal: 100,
            prevCorrect: 100,
            avgTimeMs: 1000,
          ),
        ],
      );

      // Raw looks great (102/110), but effective should follow the nearby
      // poor bucket because far history is heavily down-weighted.
      expect(stats.rawAccuracy, greaterThan(0.9));
      expect(stats.effectiveAccuracy, lessThan(0.3));
    });

    test('uses weighted sample size for confidence threshold', () {
      final stats = EnrichedThemeStats.fromBuckets(
        theme: 'pin',
        userElo: 1500,
        buckets: const [
          ThemeRatingBucket(
            bucketMin: 1400, // weight ~1.0
            total: 5,
            correct: 3,
            recentTotal: 5,
            recentCorrect: 3,
            prevTotal: 5,
            prevCorrect: 3,
            avgTimeMs: 2200,
          ),
        ],
      );

      expect(stats.effectiveSampleSize, inInclusiveRange(4.9, 5.1));
      expect(stats.confidence, ConfidenceLevel.medium);
    });

    test('detects improving trend when recent beats previous by >10%', () {
      final stats = EnrichedThemeStats.fromBuckets(
        theme: 'skewer',
        userElo: 1500,
        buckets: const [
          ThemeRatingBucket(
            bucketMin: 1400,
            total: 20,
            correct: 10,
            recentTotal: 10,
            recentCorrect: 8, // 80%
            prevTotal: 10,
            prevCorrect: 4, // 40%
            avgTimeMs: 3000,
          ),
        ],
      );

      expect(stats.trend, TrendDirection.improving);
    });
  });
}
