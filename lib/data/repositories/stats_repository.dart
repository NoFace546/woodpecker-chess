import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../models/enriched_theme_stats.dart';
import '../models/global_stats.dart';
import '../models/phase_stats.dart';
import '../models/problem_puzzle.dart';
import '../models/tactical_themes.dart';
import '../models/theme_stats.dart';
import '../models/weakness_entry.dart';
import 'puzzle_repository.dart';
import 'user_state_repository.dart';

class StatsRepository {
  StatsRepository(this._db);

  final AppDatabase _db;

  String get _excludedPlaceholders =>
      kNonTacticalThemes.map((_) => '?').join(',');
  List<Variable<Object>> get _excludedVariables =>
      kNonTacticalThemes.map(Variable<String>.new).toList();

  Future<List<ThemeStats>> globalThemes() async {
    final rows = await _db.customSelect(
      '''
      SELECT pt.theme,
             COUNT(*) AS total,
             SUM(CASE WHEN a.is_correct = 1 AND a.hints_used = 0 THEN 1 ELSE 0 END) AS correct,
             AVG(a.time_ms) AS avg_time_ms
      FROM attempts a
      JOIN puzzle_themes pt ON pt.puzzle_id = a.puzzle_id
      WHERE pt.theme NOT IN ($_excludedPlaceholders)
      GROUP BY pt.theme
      HAVING total >= 3
      ORDER BY (CAST(correct AS REAL) / total) ASC, avg_time_ms DESC
      ''',
      variables: _excludedVariables,
      readsFrom: {_db.attempts, _db.puzzleThemes},
    ).get();

    return rows.map((row) {
      final avgMs = row.read<double>('avg_time_ms');
      return ThemeStats(
        theme: row.read<String>('theme'),
        total: row.read<int>('total'),
        correct: row.read<int>('correct'),
        averageTime: Duration(milliseconds: avgMs.round()),
      );
    }).toList();
  }

  Future<List<EnrichedThemeStats>> globalThemesEnriched({
    required int userElo,
  }) async {
    final now = DateTime.now();
    final cutoffRecent =
        now.subtract(const Duration(days: 30)).millisecondsSinceEpoch;
    final cutoffOlder =
        now.subtract(const Duration(days: 60)).millisecondsSinceEpoch;

    // Group by (theme, rating-bucket). Bucket size is 200 Elo. Joining
    // through `puzzles` gives us the puzzle's rating at solve time.
    final rows = await _db.customSelect(
      '''
      SELECT pt.theme,
        ((p.rating / $kRatingBucketSize) * $kRatingBucketSize) AS bucket_min,
        COUNT(*) AS total,
        SUM(CASE WHEN a.is_correct = 1 AND a.hints_used = 0 THEN 1 ELSE 0 END) AS correct,
        AVG(a.time_ms) AS avg_time_ms,
        SUM(CASE WHEN a.finished_at >= ? THEN 1 ELSE 0 END) AS recent_total,
        SUM(CASE WHEN a.finished_at >= ? AND a.is_correct = 1 AND a.hints_used = 0 THEN 1 ELSE 0 END) AS recent_correct,
        SUM(CASE WHEN a.finished_at >= ? AND a.finished_at < ? THEN 1 ELSE 0 END) AS prev_total,
        SUM(CASE WHEN a.finished_at >= ? AND a.finished_at < ? AND a.is_correct = 1 AND a.hints_used = 0 THEN 1 ELSE 0 END) AS prev_correct
      FROM attempts a
      JOIN puzzle_themes pt ON pt.puzzle_id = a.puzzle_id
      JOIN puzzles p ON p.id = a.puzzle_id
      WHERE pt.theme NOT IN ($_excludedPlaceholders)
      GROUP BY pt.theme, bucket_min
      ORDER BY pt.theme, bucket_min
      ''',
      variables: [
        Variable.withInt(cutoffRecent),
        Variable.withInt(cutoffRecent),
        Variable.withInt(cutoffOlder),
        Variable.withInt(cutoffRecent),
        Variable.withInt(cutoffOlder),
        Variable.withInt(cutoffRecent),
        ..._excludedVariables,
      ],
      readsFrom: {_db.attempts, _db.puzzleThemes, _db.puzzles},
    ).get();

    final byTheme = <String, List<ThemeRatingBucket>>{};
    for (final r in rows) {
      final theme = r.read<String>('theme');
      final bucket = ThemeRatingBucket(
        bucketMin: r.read<int>('bucket_min'),
        total: r.read<int>('total'),
        correct: r.readNullable<int>('correct') ?? 0,
        recentTotal: r.readNullable<int>('recent_total') ?? 0,
        recentCorrect: r.readNullable<int>('recent_correct') ?? 0,
        prevTotal: r.readNullable<int>('prev_total') ?? 0,
        prevCorrect: r.readNullable<int>('prev_correct') ?? 0,
        avgTimeMs: (r.readNullable<double>('avg_time_ms') ?? 0).round(),
      );
      (byTheme[theme] ??= []).add(bucket);
    }

    final stats = byTheme.entries.map((e) {
      return EnrichedThemeStats.fromBuckets(
        theme: e.key,
        buckets: e.value,
        userElo: userElo,
      );
    }).toList()
      ..sort((a, b) => b.totalAttempts.compareTo(a.totalAttempts));
    return stats;
  }

  Future<PhaseStats> phaseStats() async {
    final rows = await _db.customSelect(
      '''
      SELECT pt.theme,
             COUNT(*) AS total,
             SUM(CASE WHEN a.is_correct = 1 AND a.hints_used = 0 THEN 1 ELSE 0 END) AS correct,
             AVG(a.time_ms) AS avg_time_ms
      FROM attempts a
      JOIN puzzle_themes pt ON pt.puzzle_id = a.puzzle_id
      WHERE pt.theme IN (?, ?, ?)
      GROUP BY pt.theme
      ''',
      variables: [
        Variable.withString('opening'),
        Variable.withString('middlegame'),
        Variable.withString('endgame'),
      ],
      readsFrom: {_db.attempts, _db.puzzleThemes},
    ).get();

    PhasePoint pointFor(String phase) {
      final row = rows
          .where((r) => r.read<String>('theme') == phase)
          .firstOrNull;
      if (row == null) {
        return PhasePoint(
          phase: phase,
          total: 0,
          correct: 0,
          averageTimeMs: 0,
        );
      }
      return PhasePoint(
        phase: phase,
        total: row.read<int>('total'),
        correct: row.readNullable<int>('correct') ?? 0,
        averageTimeMs:
            (row.readNullable<double>('avg_time_ms') ?? 0).round(),
      );
    }

    return PhaseStats(
      opening: pointFor('opening'),
      middlegame: pointFor('middlegame'),
      endgame: pointFor('endgame'),
    );
  }

  Future<int> globalMedianTimeMs() async {
    final row = await _db.customSelect(
      '''
      SELECT time_ms FROM attempts
      ORDER BY time_ms
      LIMIT 1 OFFSET (
        SELECT COUNT(*) FROM attempts
      ) / 2
      ''',
      readsFrom: {_db.attempts},
    ).getSingleOrNull();
    return row?.read<int>('time_ms') ?? 0;
  }

  Future<List<ThemeStats>> themesForSet(String setId) async {
    final rows = await _db.customSelect(
      '''
      SELECT pt.theme,
             COUNT(*) AS total,
             SUM(CASE WHEN a.is_correct = 1 AND a.hints_used = 0 THEN 1 ELSE 0 END) AS correct,
             AVG(a.time_ms) AS avg_time_ms
      FROM attempts a
      JOIN puzzle_themes pt ON pt.puzzle_id = a.puzzle_id
      WHERE a.round_id IN (SELECT id FROM rounds WHERE set_id = ?)
      GROUP BY pt.theme
      HAVING total >= 3
      ORDER BY (CAST(correct AS REAL) / total) ASC, avg_time_ms DESC
      ''',
      variables: [Variable.withString(setId)],
      readsFrom: {_db.attempts, _db.puzzleThemes, _db.rounds},
    ).get();

    return rows.map((row) {
      final avgMs = row.read<double>('avg_time_ms');
      return ThemeStats(
        theme: row.read<String>('theme'),
        total: row.read<int>('total'),
        correct: row.read<int>('correct'),
        averageTime: Duration(milliseconds: avgMs.round()),
      );
    }).toList();
  }

  Future<Map<String, int>> bestTimesForSetExcludingRound(
    String setId,
    String excludeRoundId,
  ) async {
    final rows = await _db.customSelect(
      '''
      SELECT puzzle_id, MIN(time_ms) AS best_ms
      FROM attempts
      WHERE is_correct = 1
        AND hints_used = 0
        AND round_id != ?
        AND round_id IN (SELECT id FROM rounds WHERE set_id = ?)
      GROUP BY puzzle_id
      ''',
      variables: [
        Variable.withString(excludeRoundId),
        Variable.withString(setId),
      ],
      readsFrom: {_db.attempts, _db.rounds},
    ).get();
    return {
      for (final r in rows)
        r.read<String>('puzzle_id'): r.read<int>('best_ms'),
    };
  }

  Future<List<ProblemPuzzle>> problemPuzzlesForSet(
    String setId, {
    int minFailedRounds = 2,
    int limit = 20,
  }) async {
    final rows = await _db.customSelect(
      '''
      SELECT a.puzzle_id, COUNT(*) AS failed_rounds, p.fen, p.rating
      FROM attempts a
      JOIN puzzles p ON p.id = a.puzzle_id
      WHERE (a.is_correct = 0 OR a.hints_used > 0)
        AND a.round_id IN (SELECT id FROM rounds WHERE set_id = ?)
      GROUP BY a.puzzle_id
      HAVING failed_rounds >= ?
      ORDER BY failed_rounds DESC, p.rating DESC
      LIMIT ?
      ''',
      variables: [
        Variable.withString(setId),
        Variable.withInt(minFailedRounds),
        Variable.withInt(limit),
      ],
      readsFrom: {_db.attempts, _db.puzzles, _db.rounds},
    ).get();

    final out = <ProblemPuzzle>[];
    for (final row in rows) {
      final puzzleId = row.read<String>('puzzle_id');
      final themesRows = await (_db.select(_db.puzzleThemes)
            ..where((t) => t.puzzleId.equals(puzzleId)))
          .get();
      out.add(ProblemPuzzle(
        puzzleId: puzzleId,
        failedRounds: row.read<int>('failed_rounds'),
        themes: themesRows.map((t) => t.theme).toList(),
        rating: row.read<int>('rating'),
        fen: row.read<String>('fen'),
      ));
    }
    return out;
  }

  Future<GlobalStats> globalStats() async {
    final row = await _db.customSelect(
      '''
      SELECT
        (SELECT COUNT(*) FROM rounds WHERE completed_at IS NOT NULL) AS rounds,
        COUNT(*) AS attempts,
        SUM(CASE WHEN is_correct = 1 AND hints_used = 0 THEN 1 ELSE 0 END) AS correct,
        COALESCE(SUM(time_ms), 0) AS time_ms,
        COALESCE(SUM(hints_used), 0) AS hints
      FROM attempts
      ''',
      readsFrom: {_db.attempts, _db.rounds},
    ).getSingle();
    return GlobalStats(
      totalRoundsCompleted: row.read<int>('rounds'),
      totalAttempts: row.read<int>('attempts'),
      correctAttempts: (row.readNullable<int>('correct')) ?? 0,
      totalTime: Duration(milliseconds: row.read<int>('time_ms')),
      totalHints: row.read<int>('hints'),
    );
  }

  Future<List<SetActivity>> setActivities() async {
    final rows = await _db.customSelect(
      '''
      SELECT
        s.id AS set_id,
        s.name AS set_name,
        (SELECT COUNT(*) FROM rounds r
           WHERE r.set_id = s.id AND r.completed_at IS NOT NULL) AS rounds_completed,
        (SELECT COUNT(*) FROM attempts a
           WHERE a.round_id IN (SELECT id FROM rounds WHERE set_id = s.id)) AS total_attempts,
        (SELECT SUM(CASE WHEN a.is_correct = 1 AND a.hints_used = 0 THEN 1 ELSE 0 END) FROM attempts a
           WHERE a.round_id IN (SELECT id FROM rounds WHERE set_id = s.id)) AS correct_attempts
      FROM puzzle_sets s
      ORDER BY s.created_at DESC
      ''',
      readsFrom: {_db.puzzleSets, _db.rounds, _db.attempts},
    ).get();
    return rows.map((row) {
      return SetActivity(
        setId: row.read<String>('set_id'),
        setName: row.read<String>('set_name'),
        roundsCompleted: row.read<int>('rounds_completed'),
        totalAttempts: row.read<int>('total_attempts'),
        correctAttempts: row.readNullable<int>('correct_attempts') ?? 0,
      );
    }).toList();
  }

  Future<List<DailyActivity>> dailyActivity({int days = 30}) async {
    final cutoffMs = DateTime.now()
        .subtract(Duration(days: days))
        .millisecondsSinceEpoch;
    final rows = await _db.customSelect(
      '''
      SELECT
        CAST(finished_at / 86400000 AS INTEGER) AS day_index,
        COUNT(*) AS total,
        SUM(CASE WHEN is_correct = 1 AND hints_used = 0 THEN 1 ELSE 0 END) AS correct,
        SUM(time_ms) AS total_time_ms
      FROM attempts
      WHERE finished_at >= ?
      GROUP BY day_index
      ORDER BY day_index ASC
      ''',
      variables: [Variable.withInt(cutoffMs)],
      readsFrom: {_db.attempts},
    ).get();
    return rows.map((row) {
      final dayIdx = row.read<int>('day_index');
      return DailyActivity(
        day: DateTime.fromMillisecondsSinceEpoch(
          dayIdx * 86400000,
          isUtc: true,
        ),
        totalAttempts: row.read<int>('total'),
        correctAttempts: row.readNullable<int>('correct') ?? 0,
        totalTime: Duration(
          milliseconds: row.readNullable<int>('total_time_ms') ?? 0,
        ),
      );
    }).toList();
  }

  /// All tactical themes present in the puzzle library, alphabetically
  /// sorted. Used to surface themes the user hasn't attempted yet.
  Future<List<String>> allTacticalThemes() async {
    final rows = await _db.customSelect(
      '''
      SELECT DISTINCT theme
      FROM puzzle_themes
      WHERE theme NOT IN ($_excludedPlaceholders)
      ORDER BY theme
      ''',
      variables: _excludedVariables,
      readsFrom: {_db.puzzleThemes},
    ).get();
    return rows.map((r) => r.read<String>('theme')).toList();
  }
}

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(ref.watch(databaseProvider));
});

final globalStatsProvider = FutureProvider<GlobalStats>((ref) async {
  return ref.watch(statsRepositoryProvider).globalStats();
});

final setActivitiesProvider = FutureProvider<List<SetActivity>>((ref) async {
  return ref.watch(statsRepositoryProvider).setActivities();
});

final dailyActivityProvider = FutureProvider<List<DailyActivity>>((ref) async {
  return ref.watch(statsRepositoryProvider).dailyActivity();
});

final globalThemeStatsProvider =
    FutureProvider<List<ThemeStats>>((ref) async {
  return ref.watch(statsRepositoryProvider).globalThemes();
});

final allTacticalThemesProvider =
    FutureProvider<List<String>>((ref) async {
  return ref.watch(statsRepositoryProvider).allTacticalThemes();
});

final phaseStatsProvider = FutureProvider<PhaseStats>((ref) async {
  return ref.watch(statsRepositoryProvider).phaseStats();
});

final enrichedThemeStatsProvider =
    FutureProvider<List<EnrichedThemeStats>>((ref) async {
  final user = await ref.watch(userStateProvider.future);
  return ref
      .watch(statsRepositoryProvider)
      .globalThemesEnriched(userElo: user.elo);
});

final globalMedianTimeProvider = FutureProvider<int>((ref) async {
  return ref.watch(statsRepositoryProvider).globalMedianTimeMs();
});

final weaknessAnalysisProvider =
    FutureProvider<List<WeaknessEntry>>((ref) async {
  final themes = await ref.watch(enrichedThemeStatsProvider.future);
  final median = await ref.watch(globalMedianTimeProvider.future);
  final globalStats = await ref.watch(globalStatsProvider.future);
  return const WeaknessAnalyzer().analyze(
    themes: themes,
    globalMedianMs: median,
    userAccuracy: globalStats.accuracy,
  );
});

final themeStatsProvider =
    FutureProvider.family<List<ThemeStats>, String>((ref, setId) async {
  return ref.watch(statsRepositoryProvider).themesForSet(setId);
});

final problemPuzzlesProvider =
    FutureProvider.family<List<ProblemPuzzle>, String>((ref, setId) async {
  return ref.watch(statsRepositoryProvider).problemPuzzlesForSet(setId);
});
