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
  const RecommendedSetResult({required this.set, required this.mode});
  final PuzzleSet set;
  final RecommendationMode mode;
}

/// Curated baseline themes used when the user has no attempt history yet
/// (Calibration mode). Spans tactical motifs, mate patterns, and phases
/// so the first round establishes broad coverage.
const _calibrationBaselineThemes = [
  // Tactical motifs
  'fork', 'pin', 'skewer', 'discoveredAttack',
  'sacrifice', 'deflection', 'attraction', 'hangingPiece',
  // Mate patterns
  'mate', 'mateIn2',
  // Phases
  'opening', 'middlegame', 'endgame',
];

/// Extended baseline used by later modes to keep widening coverage. Themes
/// from this list that the user has not yet attempted get seeded into the
/// explore pool of Discovery and Refinement so the theme universe fills out
/// monotonically.
const _extendedBaselineThemes = [
  ..._calibrationBaselineThemes,
  // Deeper tactical motifs
  'intermezzo', 'interference', 'clearance', 'xRayAttack',
  'quietMove', 'defensiveMove', 'capturingDefender', 'trappedPiece',
  // Longer mates and named mates
  'mateIn3', 'backRankMate', 'smotheredMate',
  // Endgame depth
  'pawnEndgame', 'rookEndgame', 'bishopEndgame', 'knightEndgame',
];

/// Dynamic exploit/explore split based on how much data we have. Less data
/// → more exploration. More data → more drilling of confirmed weaknesses.
enum RecommendationMode {
  calibration(
    label: 'Calibration',
    minAttempts: 0,
    exploitRatio: 0.30,
    exploitPoolSize: 3,
    unattemptedSeedCount: 13,
  ),
  discovery(
    label: 'Discovery',
    minAttempts: 50,
    exploitRatio: 0.50,
    exploitPoolSize: 3,
    unattemptedSeedCount: 2,
  ),
  refinement(
    label: 'Refinement',
    minAttempts: 150,
    exploitRatio: 0.70,
    exploitPoolSize: 4,
    unattemptedSeedCount: 1,
  ),
  mastery(
    label: 'Mastery',
    minAttempts: 400,
    exploitRatio: 0.85,
    exploitPoolSize: 6,
    unattemptedSeedCount: 0,
  );

  const RecommendationMode({
    required this.label,
    required this.minAttempts,
    required this.exploitRatio,
    required this.exploitPoolSize,
    required this.unattemptedSeedCount,
  });

  final String label;
  final int minAttempts;
  final double exploitRatio;
  // How many top weaknesses to drill in this mode.
  final int exploitPoolSize;
  // How many never-attempted themes from the extended baseline to seed into
  // the explore pool so coverage keeps widening between modes.
  final int unattemptedSeedCount;

  static RecommendationMode forAttempts(int attempts) {
    RecommendationMode current = RecommendationMode.calibration;
    for (final m in RecommendationMode.values) {
      if (attempts >= m.minAttempts) current = m;
    }
    return current;
  }
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
  /// - exploitation - top high-confidence weaknesses
  /// - exploration - low-confidence themes we don't know enough about
  /// The split between them shifts as the user accumulates more attempts;
  /// see [RecommendationMode]. When the user has little data, exploration
  /// dominates; with a rich history the recommender drills.
  Future<RecommendedSetResult> buildRecommended({int targetSize = 150}) async {
    final user = await userStateRepo.get();
    final themes =
        await statsRepo.globalThemesEnriched(userElo: user.elo);
    final median = await statsRepo.globalMedianTimeMs();
    final analysis = const WeaknessAnalyzer()
        .analyze(themes: themes, globalMedianMs: median);

    final mode = RecommendationMode.forAttempts(user.attemptsTotal);

    final exploitThemes = analysis
        .where((e) => e.confidence != ConfidenceLevel.low)
        .take(mode.exploitPoolSize)
        .map((e) => e.theme)
        .toList();

    // Themes the user has attempted but not enough times for confidence.
    final attemptedLowConf = analysis
        .where((e) => e.confidence == ConfidenceLevel.low)
        .map((e) => e.theme)
        .toList();
    // Never-attempted themes pulled from the extended baseline. Calibration
    // pulls from the smaller core list; later modes draw from the wider one
    // so coverage keeps growing.
    final attemptedSet = analysis.map((e) => e.theme).toSet();
    final unattemptedSource = mode == RecommendationMode.calibration
        ? _calibrationBaselineThemes
        : _extendedBaselineThemes;
    final unattempted = unattemptedSource
        .where((t) => !attemptedSet.contains(t))
        .toList();
    // Calibration: pure breadth sweep across the core 13.
    // Discovery / Refinement: a small handful of low-confidence themes plus
    // a few unattempted seeds so the theme universe keeps filling out.
    // Mastery: pure drilling of attempted-but-still-shaky themes.
    final List<String> exploreThemes;
    if (mode == RecommendationMode.calibration) {
      exploreThemes =
          <String>[...unattempted, ...attemptedLowConf].take(13).toList();
    } else {
      final seeds = unattempted.take(mode.unattemptedSeedCount).toList();
      final remaining = 5 - seeds.length;
      exploreThemes = <String>[
        ...attemptedLowConf.take(remaining),
        ...seeds,
      ];
    }

    final ratingMin = (user.elo - 200).clamp(600, 2900);
    final ratingMax = (user.elo + 100).clamp(700, 3000);

    final exploitTarget = (targetSize * mode.exploitRatio).round();
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
    // Calibration shows broad coverage; later modes stay tight on the named
    // exploit + explore themes.
    final topThemesLimit =
        mode == RecommendationMode.calibration ? 15 : 6;
    final derivedThemes =
        await _topThemesForPuzzles(ids, limit: topThemesLimit);
    // Restrict the displayed metadata to themes a club player would
    // recognise as training categories. Phases stay (they show up via the
    // phase radar elsewhere).
    bool isDisplayable(String t) =>
        isCuratedTrainingTheme(t) || kPhaseThemes.contains(t);
    final allThemes = <String>{
      ...exploitThemes.where(isDisplayable),
      ...exploreThemes.where(isDisplayable),
      ...derivedThemes.where(isDisplayable),
    }.toList();

    return RecommendedSetResult(
      set: await _createSetWithIds(
        ids: ids,
        ratingMin: ratingMin,
        ratingMax: ratingMax,
        themes: allThemes,
        mode: mode,
      ),
      mode: mode,
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
    final curated = kCuratedTrainingThemes.map((_) => '?').join(',');
    // Count only themes that the user would recognise as training
    // categories - skip evaluation buckets, length tags, source tags, and
    // niche Lichess-only labels like `attackingF2F7` / `zugzwang`.
    final sql = '''
      SELECT theme, COUNT(*) AS c
      FROM puzzle_themes
      WHERE puzzle_id IN ($placeholders)
        AND theme IN ($curated)
      GROUP BY theme
      ORDER BY c DESC
      LIMIT ?
    ''';
    final vars = <Variable<Object>>[
      ...puzzleIds.map(Variable.withString),
      ...kCuratedTrainingThemes.map(Variable<String>.new),
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
    const disabledClause =
        ' AND NOT EXISTS (SELECT 1 FROM disabled_puzzles dp WHERE dp.puzzle_id = puzzles.id)';
    final sql =
        'SELECT id FROM puzzles WHERE rating BETWEEN ? AND ?$themeClause$excludeClause$disabledClause '
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
    RecommendationMode mode = RecommendationMode.calibration,
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
    final name = 'Recommended · ${mode.label} · $dateLabel';
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
