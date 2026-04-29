import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/puzzle_set.dart';
import '../models/set_filter.dart';
import 'puzzle_repository.dart';

class SetRepository {
  SetRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Future<List<PuzzleSet>> listAll() async {
    final rows = await (_db.select(_db.puzzleSets)
          ..where((s) => s.isSystem.equals(false) & s.archivedAt.isNull())
          ..orderBy([(s) => OrderingTerm.desc(s.createdAt)]))
        .get();
    final result = <PuzzleSet>[];
    for (final row in rows) {
      result.add(await _hydrate(row));
    }
    return result;
  }

  Future<List<PuzzleSet>> listArchived() async {
    final rows = await (_db.select(_db.puzzleSets)
          ..where((s) => s.isSystem.equals(false) & s.archivedAt.isNotNull())
          ..orderBy([(s) => OrderingTerm.desc(s.archivedAt)]))
        .get();
    final result = <PuzzleSet>[];
    for (final row in rows) {
      result.add(await _hydrate(row));
    }
    return result;
  }

  Future<void> archive(String setId) async {
    await (_db.update(_db.puzzleSets)..where((s) => s.id.equals(setId)))
        .write(PuzzleSetsCompanion(archivedAt: Value(DateTime.now())));
  }

  Future<void> unarchive(String setId) async {
    await (_db.update(_db.puzzleSets)..where((s) => s.id.equals(setId)))
        .write(const PuzzleSetsCompanion(archivedAt: Value(null)));
  }

  Future<PuzzleSet?> getById(String id) async {
    final row =
        await (_db.select(_db.puzzleSets)..where((s) => s.id.equals(id)))
            .getSingleOrNull();
    if (row == null) return null;
    return _hydrate(row);
  }

  Future<int> previewSize(SetFilter filter) async {
    final (sql, vars) = _filterSql(
      'SELECT COUNT(*) AS c FROM puzzles',
      filter,
      withLimit: false,
    );
    final row = await _db
        .customSelect(sql, variables: vars, readsFrom: {_db.puzzles})
        .getSingle();
    return row.read<int>('c');
  }

  Future<PuzzleSet> create(SetFilter filter, {String? name}) async {
    final (sql, vars) = _filterSql(
      'SELECT id FROM puzzles',
      filter,
      withLimit: true,
    );
    final pickRows = await _db
        .customSelect(sql, variables: vars, readsFrom: {_db.puzzles}).get();
    final ids = pickRows.map((r) => r.read<String>('id')).toList();

    final id = _uuid.v4();
    final now = DateTime.now();
    final setName = name ?? _autoName(filter, now);

    await _db.transaction(() async {
      await _db.into(_db.puzzleSets).insert(
            PuzzleSetsCompanion.insert(
              id: id,
              name: setName,
              createdAt: now,
              ratingMin: Value(filter.ratingMin),
              ratingMax: Value(filter.ratingMax),
              themesJson: Value(filter.themesJson),
              size: ids.length,
            ),
          );
      await _db.batch((b) {
        for (var i = 0; i < ids.length; i++) {
          b.insert(
            _db.puzzleSetItems,
            PuzzleSetItemsCompanion.insert(
              setId: id,
              position: i,
              puzzleId: ids[i],
            ),
          );
        }
      });
    });

    return PuzzleSet(
      id: id,
      name: setName,
      createdAt: now,
      filter: filter,
      puzzleIds: ids,
    );
  }

  /// Creates a set from a pre-selected list of puzzle IDs (used by the
  /// recommender, which assembles the list across multiple SQL queries).
  Future<PuzzleSet> createWithIds({
    required SetFilter filter,
    required List<String> ids,
    String? name,
  }) async {
    final id = _uuid.v4();
    final now = DateTime.now();
    final setName = name ?? _autoName(filter, now);

    await _db.transaction(() async {
      await _db.into(_db.puzzleSets).insert(
            PuzzleSetsCompanion.insert(
              id: id,
              name: setName,
              createdAt: now,
              ratingMin: Value(filter.ratingMin),
              ratingMax: Value(filter.ratingMax),
              themesJson: Value(filter.themesJson),
              size: ids.length,
            ),
          );
      await _db.batch((b) {
        for (var i = 0; i < ids.length; i++) {
          b.insert(
            _db.puzzleSetItems,
            PuzzleSetItemsCompanion.insert(
              setId: id,
              position: i,
              puzzleId: ids[i],
            ),
          );
        }
      });
    });

    return PuzzleSet(
      id: id,
      name: setName,
      createdAt: now,
      filter: filter,
      puzzleIds: ids,
    );
  }

  Future<void> delete(String setId) async {
    await _db.transaction(() async {
      await (_db.delete(_db.attempts)
            ..where((a) =>
                a.roundId.isInQuery(_db.selectOnly(_db.rounds)
                  ..addColumns([_db.rounds.id])
                  ..where(_db.rounds.setId.equals(setId)))))
          .go();
      await (_db.delete(_db.rounds)..where((r) => r.setId.equals(setId))).go();
      await (_db.delete(_db.puzzleSetItems)
            ..where((i) => i.setId.equals(setId)))
          .go();
      await (_db.delete(_db.puzzleSets)..where((s) => s.id.equals(setId)))
          .go();
    });
  }

  Future<PuzzleSet> _hydrate(PuzzleSetRow row) async {
    final itemRows = await (_db.select(_db.puzzleSetItems)
          ..where((i) => i.setId.equals(row.id))
          ..orderBy([(i) => OrderingTerm.asc(i.position)]))
        .get();
    return PuzzleSet(
      id: row.id,
      name: row.name,
      createdAt: row.createdAt,
      filter: SetFilter(
        ratingMin: row.ratingMin ?? 600,
        ratingMax: row.ratingMax ?? 3000,
        themes: SetFilter.parseThemes(row.themesJson),
        size: row.size,
      ),
      puzzleIds: itemRows.map((i) => i.puzzleId).toList(),
      archivedAt: row.archivedAt,
    );
  }

  static (String, List<Variable<Object>>) _filterSql(
    String selectClause,
    SetFilter filter, {
    required bool withLimit,
  }) {
    final hasThemes = filter.themes.isNotEmpty;
    final themeClause = hasThemes
        ? ' AND id IN (SELECT puzzle_id FROM puzzle_themes WHERE theme IN (${filter.themes.map((_) => '?').join(',')}))'
        : '';
    final limitClause = withLimit ? ' ORDER BY RANDOM() LIMIT ?' : '';
    final sql =
        '$selectClause WHERE rating BETWEEN ? AND ?$themeClause$limitClause';
    final vars = <Variable<Object>>[
      Variable.withInt(filter.ratingMin),
      Variable.withInt(filter.ratingMax),
      ...filter.themes.map(Variable.withString),
      if (withLimit) Variable.withInt(filter.size),
    ];
    return (sql, vars);
  }

  static String _autoName(SetFilter filter, DateTime when) {
    final themesPart = filter.themes.isEmpty
        ? 'mixed'
        : filter.themes.take(2).join('+');
    return '${filter.size} • ${filter.ratingMin}–${filter.ratingMax} • $themesPart';
  }
}

final setRepositoryProvider = Provider<SetRepository>((ref) {
  return SetRepository(ref.watch(databaseProvider));
});

final allSetsProvider = FutureProvider<List<PuzzleSet>>((ref) async {
  return ref.watch(setRepositoryProvider).listAll();
});

final archivedSetsProvider = FutureProvider<List<PuzzleSet>>((ref) async {
  return ref.watch(setRepositoryProvider).listArchived();
});

final setByIdProvider =
    FutureProvider.family<PuzzleSet?, String>((ref, id) async {
  return ref.watch(setRepositoryProvider).getById(id);
});
