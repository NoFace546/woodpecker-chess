import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/models/enriched_theme_stats.dart';
import '../data/models/puzzle_set.dart';
import '../data/models/set_filter.dart';
import '../data/models/tactical_themes.dart';
import '../data/models/weakness_entry.dart';
import '../data/repositories/puzzle_repository.dart';
import '../data/repositories/set_repository.dart';
import '../data/repositories/stats_repository.dart';
import '../data/repositories/user_state_repository.dart';

class RecommendedSetResult {
  const RecommendedSetResult({required this.set});
  final PuzzleSet set;
}

class TrainingRecommender {
  TrainingRecommender({
    required this.userStateRepo,
    required this.statsRepo,
    required this.setRepo,
    required this.db,
  });

  final UserStateRepository userStateRepo;
  final StatsRepository statsRepo;
  final SetRepository setRepo;
  final AppDatabase db;

  /// Builds one set blending two pools:
  /// - exploitation (~70%) — top high-confidence weaknesses
  /// - exploration (~30%) — low-confidence themes we don't know enough about
  /// When the user has little data, exploitation pool is empty so exploration
  /// fills the whole set; when data is rich the inverse happens.
  Future<RecommendedSetResult> buildRecommended({int targetSize = 150}) async {
    final user = await userStateRepo.get();
    final themes = await statsRepo.globalThemesEnriched();
    final median = await statsRepo.globalMedianTimeMs();
    final analysis = const WeaknessAnalyzer()
        .analyze(themes: themes, globalMedianMs: median);

    final exploitThemes = analysis
        .where((e) => e.confidence != ConfidenceLevel.low)
        .take(3)
        .map((e) => e.theme)
        .toList();

    final exploreThemes = analysis
        .where((e) => e.confidence == ConfidenceLevel.low)
        .take(5)
        .map((e) => e.theme)
        .toList();

    final ratingMin = (user.elo - 200).clamp(600, 2900);
    final ratingMax = (user.elo + 100).clamp(700, 3000);

    final exploitTarget = (targetSize * 0.7).round();
    final exploreTarget = targetSize - exploitTarget;

    final exploitIds = exploitThemes.isEmpty
        ? <String>[]
        : await _pickPuzzles(
            ratingMin: ratingMin,
            ratingMax: ratingMax,
            themes: exploitThemes,
            limit: exploitTarget,
          );
    final exploreIds = exploreThemes.isEmpty
        ? <String>[]
        : await _pickPuzzles(
            ratingMin: ratingMin,
            ratingMax: ratingMax,
            themes: exploreThemes,
            limit: exploreTarget,
          );

    // Fill remaining slots from the unfiltered comfort zone if either pool
    // came up short.
    final combined = <String>{...exploitIds, ...exploreIds};
    final remaining = targetSize - combined.length;
    if (remaining > 0) {
      final filler = await _pickPuzzles(
        ratingMin: ratingMin,
        ratingMax: ratingMax,
        themes: const [],
        limit: remaining,
        exclude: combined,
      );
      combined.addAll(filler);
    }

    final ids = combined.toList()..shuffle();
    final derivedThemes = await _topThemesForPuzzles(ids, limit: 6);
    final allThemes = <String>{
      ...exploitThemes,
      ...exploreThemes,
      ...derivedThemes,
    }.toList();

    return RecommendedSetResult(
      set: await _createSetWithIds(
        ids: ids,
        ratingMin: ratingMin,
        ratingMax: ratingMax,
        themes: allThemes,
      ),
    );
  }

  /// Returns the most-frequent tactical themes across the given puzzle IDs,
  /// so the set's theme list reflects what's actually in the set rather than
  /// just the recommender's pool inputs.
  Future<List<String>> _topThemesForPuzzles(
    List<String> puzzleIds, {
    required int limit,
  }) async {
    if (puzzleIds.isEmpty) return const [];
    final placeholders = puzzleIds.map((_) => '?').join(',');
    final excluded = kNonTacticalThemes.map((_) => '?').join(',');
    final sql = '''
      SELECT theme, COUNT(*) AS c
      FROM puzzle_themes
      WHERE puzzle_id IN ($placeholders)
        AND theme NOT IN ($excluded)
      GROUP BY theme
      ORDER BY c DESC
      LIMIT ?
    ''';
    final vars = <Variable<Object>>[
      ...puzzleIds.map(Variable.withString),
      ...kNonTacticalThemes.map(Variable<String>.new),
      Variable.withInt(limit),
    ];
    final rows = await db
        .customSelect(sql, variables: vars, readsFrom: {db.puzzleThemes})
        .get();
    return rows.map((r) => r.read<String>('theme')).toList();
  }

  Future<List<String>> _pickPuzzles({
    required int ratingMin,
    required int ratingMax,
    required List<String> themes,
    required int limit,
    Set<String> exclude = const {},
  }) async {
    if (limit <= 0) return const [];
    final hasThemes = themes.isNotEmpty;
    final hasExclude = exclude.isNotEmpty;
    final themeClause = hasThemes
        ? ' AND id IN (SELECT puzzle_id FROM puzzle_themes '
            'WHERE theme IN (${themes.map((_) => '?').join(',')}))'
        : '';
    final excludeClause = hasExclude
        ? ' AND id NOT IN (${exclude.map((_) => '?').join(',')})'
        : '';
    final sql =
        'SELECT id FROM puzzles WHERE rating BETWEEN ? AND ?$themeClause$excludeClause '
        'ORDER BY RANDOM() LIMIT ?';
    final vars = <Variable<Object>>[
      Variable.withInt(ratingMin),
      Variable.withInt(ratingMax),
      ...themes.map(Variable.withString),
      ...exclude.map(Variable.withString),
      Variable.withInt(limit),
    ];
    final rows = await db
        .customSelect(sql, variables: vars, readsFrom: {db.puzzles})
        .get();
    return rows.map((r) => r.read<String>('id')).toList();
  }

  Future<PuzzleSet> _createSetWithIds({
    required List<String> ids,
    required int ratingMin,
    required int ratingMax,
    required List<String> themes,
  }) async {
    final filter = SetFilter(
      ratingMin: ratingMin,
      ratingMax: ratingMax,
      themes: themes,
      size: ids.length,
    );
    final now = DateTime.now();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final dateLabel = '${months[now.month - 1]} ${now.day}';
    final name = 'Recommended · $dateLabel';
    return setRepo.createWithIds(filter: filter, ids: ids, name: name);
  }
}

final trainingRecommenderProvider = Provider<TrainingRecommender>((ref) {
  return TrainingRecommender(
    userStateRepo: ref.watch(userStateRepositoryProvider),
    statsRepo: ref.watch(statsRepositoryProvider),
    setRepo: ref.watch(setRepositoryProvider),
    db: ref.watch(databaseProvider),
  );
});
