import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/solve/puzzle.dart';
import '../database/app_database.dart';
import 'user_state_repository.dart';

class PuzzleRepository {
  PuzzleRepository(this._db);

  final AppDatabase _db;

  Future<int> count() async {
    final row = await _db
        .customSelect('SELECT COUNT(*) AS c FROM puzzles')
        .getSingle();
    return row.read<int>('c');
  }

  Future<Puzzle?> getById(String id) async {
    final row = await (_db.select(_db.puzzles)..where((p) => p.id.equals(id)))
        .getSingleOrNull();
    if (row == null) return null;
    return _hydrate(row);
  }

  Future<Puzzle?> randomPuzzle() async {
    final row = await _db
        .customSelect(
          'SELECT * FROM puzzles ORDER BY RANDOM() LIMIT 1',
          readsFrom: {_db.puzzles},
        )
        .getSingleOrNull();
    if (row == null) return null;
    final id = row.read<String>('id');
    return getById(id);
  }

  Future<Puzzle?> randomPuzzleByRating({
    required int min,
    required int max,
  }) async {
    final row = await _db.customSelect(
      'SELECT id FROM puzzles WHERE rating BETWEEN ? AND ? '
      'ORDER BY RANDOM() LIMIT 1',
      variables: [Variable.withInt(min), Variable.withInt(max)],
      readsFrom: {_db.puzzles},
    ).getSingleOrNull();
    if (row == null) return null;
    return getById(row.read<String>('id'));
  }

  Future<List<String>> distinctThemes() async {
    final rows = await _db
        .customSelect(
          'SELECT DISTINCT theme FROM puzzle_themes ORDER BY theme',
          readsFrom: {_db.puzzleThemes},
        )
        .get();
    return rows.map((r) => r.read<String>('theme')).toList();
  }

  /// Inserts a single verified Lichess puzzle so the app has something to
  /// solve before the user generates the full asset DB. Real variety comes
  /// from running `tool/build_puzzle_db.dart` against the Lichess CSV.
  Future<void> ensureSeeded() async {
    // Earlier dev builds shipped an invalid hand-crafted puzzle. Strip it
    // out of any device that already received it.
    await (_db.delete(_db.puzzleSetItems)
          ..where((i) => i.puzzleId.equals('0Z2D0')))
        .go();
    await (_db.delete(_db.puzzleThemes)
          ..where((t) => t.puzzleId.equals('0Z2D0')))
        .go();
    await (_db.delete(_db.puzzles)..where((p) => p.id.equals('0Z2D0'))).go();

    if (await count() > 0) return;
    await _db.batch((b) {
      b.insert(
        _db.puzzles,
        PuzzlesCompanion.insert(
          id: '00sHx',
          fen: 'q3k1nr/1pp1nQpp/3p4/1P2p3/4P3/B1PP1b2/B5PP/5K2 b k - 0 17',
          moves: 'e8d7 a2e6 d7d8 f7f8',
          rating: 1760,
          popularity: const Value(100),
        ),
      );
      b.insertAll(_db.puzzleThemes, [
        PuzzleThemesCompanion.insert(puzzleId: '00sHx', theme: 'mate'),
        PuzzleThemesCompanion.insert(puzzleId: '00sHx', theme: 'mateIn2'),
        PuzzleThemesCompanion.insert(puzzleId: '00sHx', theme: 'middlegame'),
        PuzzleThemesCompanion.insert(puzzleId: '00sHx', theme: 'short'),
      ]);
    });
  }

  Future<Puzzle?> _hydrate(PuzzleRow row) async {
    final themeRows = await (_db.select(_db.puzzleThemes)
          ..where((t) => t.puzzleId.equals(row.id)))
        .get();
    return Puzzle(
      id: row.id,
      fen: row.fen,
      uciMoves: row.moves.split(' '),
      rating: row.rating,
      themes: themeRows.map((t) => t.theme).toList(),
    );
  }
}

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.openOnDevice();
  ref.onDispose(db.close);
  return db;
});

final puzzleRepositoryProvider = Provider<PuzzleRepository>((ref) {
  return PuzzleRepository(ref.watch(databaseProvider));
});

/// Runs once on app start to ensure the puzzles table has at least the
/// dev seed available before any feature reads from it.
final puzzleSeedProvider = FutureProvider<void>((ref) async {
  await ref.watch(puzzleRepositoryProvider).ensureSeeded();
});

final currentPuzzleProvider = FutureProvider<Puzzle>((ref) async {
  await ref.watch(puzzleSeedProvider.future);
  final puzzle = await ref.watch(puzzleRepositoryProvider).randomPuzzle();
  if (puzzle == null) {
    throw StateError('No puzzles available in the database.');
  }
  return puzzle;
});

final eloRandomPuzzleProvider = FutureProvider<Puzzle>((ref) async {
  await ref.watch(puzzleSeedProvider.future);
  final repo = ref.watch(puzzleRepositoryProvider);
  // Read user state once (don't watch — we don't want auto-replace mid-puzzle).
  final user = await ref.read(userStateProvider.future);
  final min = (user.elo - 100).clamp(600, 2900);
  final max = (user.elo + 100).clamp(700, 3000);
  final puzzle =
      await repo.randomPuzzleByRating(min: min, max: max);
  if (puzzle != null) return puzzle;
  // Fallback to entire DB if the rating window had no puzzles.
  final fallback = await repo.randomPuzzle();
  if (fallback == null) {
    throw StateError('No puzzles available in the database.');
  }
  return fallback;
});

final puzzleByIdProvider =
    FutureProvider.family<Puzzle?, String>((ref, id) async {
  return ref.watch(puzzleRepositoryProvider).getById(id);
});
