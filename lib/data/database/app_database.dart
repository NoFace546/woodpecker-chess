import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

@DataClassName('PuzzleRow')
class Puzzles extends Table {
  TextColumn get id => text()();
  TextColumn get fen => text()();
  TextColumn get moves => text()();
  IntColumn get rating => integer()();
  IntColumn get popularity => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('PuzzleThemeRow')
class PuzzleThemes extends Table {
  TextColumn get puzzleId => text().references(Puzzles, #id)();
  TextColumn get theme => text()();

  @override
  Set<Column<Object>> get primaryKey => {puzzleId, theme};
}

@DataClassName('PuzzleSetRow')
class PuzzleSets extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime()();
  IntColumn get ratingMin => integer().nullable()();
  IntColumn get ratingMax => integer().nullable()();
  TextColumn get themesJson => text().withDefault(const Constant('[]'))();
  IntColumn get size => integer()();
  BoolColumn get isSystem => boolean().withDefault(const Constant(false))();
  DateTimeColumn get archivedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('PuzzleSetItemRow')
class PuzzleSetItems extends Table {
  TextColumn get setId => text().references(PuzzleSets, #id)();
  IntColumn get position => integer()();
  TextColumn get puzzleId => text()();

  @override
  Set<Column<Object>> get primaryKey => {setId, position};
}

@DataClassName('RoundRow')
class Rounds extends Table {
  TextColumn get id => text()();
  TextColumn get setId => text().references(PuzzleSets, #id)();
  IntColumn get roundNumber => integer()();
  DateTimeColumn get startedAt => dateTime()();
  DateTimeColumn get completedAt => dateTime().nullable()();
  IntColumn get currentPosition => integer().withDefault(const Constant(0))();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('AttemptRow')
class Attempts extends Table {
  TextColumn get id => text()();
  TextColumn get roundId => text().references(Rounds, #id)();
  TextColumn get puzzleId => text()();
  IntColumn get position => integer()();
  BoolColumn get isCorrect => boolean()();
  IntColumn get timeMs => integer()();
  DateTimeColumn get finishedAt => dateTime()();
  IntColumn get hintsUsed => integer().withDefault(const Constant(0))();
  TextColumn get userMoveUci => text().nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('BotGameRow')
class BotGames extends Table {
  TextColumn get id => text()();
  TextColumn get fen => text()();
  TextColumn get lastMoveUci => text().nullable()();
  TextColumn get userSide => text()(); // 'white' | 'black'
  IntColumn get level => integer()(); // BotLevel.index
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('UserStateRow')
class UserStates extends Table {
  TextColumn get id => text()(); // singleton 'me'
  IntColumn get elo => integer().withDefault(const Constant(1500))();
  IntColumn get attemptsTotal => integer().withDefault(const Constant(0))();
  TextColumn get calibrationStatus =>
      text().withDefault(const Constant('pending'))();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('EloHistoryRow')
class EloHistory extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get puzzleId => text()();
  IntColumn get puzzleRating => integer()();
  IntColumn get eloBefore => integer()();
  IntColumn get eloAfter => integer()();
  BoolColumn get wasCorrect => boolean()();
  DateTimeColumn get at => dateTime()();
}

@DriftDatabase(
  tables: [
    Puzzles,
    PuzzleThemes,
    PuzzleSets,
    PuzzleSetItems,
    Rounds,
    Attempts,
    BotGames,
    UserStates,
    EloHistory,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  factory AppDatabase.openOnDevice() => AppDatabase(_openConnection());

  factory AppDatabase.inMemory() => AppDatabase(NativeDatabase.memory());

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          // The bundled puzzles.sqlite asset ships with empty user-data
          // tables (puzzle_sets, rounds, attempts, …) defined against an
          // older schema. createAll uses CREATE TABLE IF NOT EXISTS, so the
          // stale tables would survive - drop them first so they're
          // re-created with the current columns.
          await customStatement('DROP TABLE IF EXISTS attempts');
          await customStatement('DROP TABLE IF EXISTS rounds');
          await customStatement('DROP TABLE IF EXISTS puzzle_set_items');
          await customStatement('DROP TABLE IF EXISTS puzzle_sets');
          await m.createAll();
          await _seedUserState();
          await _seedRandomPlay();
          await _createPerfIndexes();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            await m.createTable(botGames);
          }
          if (from < 3) {
            await m.createTable(userStates);
            await m.createTable(eloHistory);
            await _seedUserState();
          }
          if (from < 4) {
            await m.addColumn(attempts, attempts.userMoveUci);
          }
          if (from < 5) {
            await m.addColumn(puzzleSets, puzzleSets.isSystem);
            await m.addColumn(puzzleSets, puzzleSets.archivedAt);
            await _seedRandomPlay();
          }
          if (from < 6) {
            // Defensive fixup: an earlier onCreate could leave puzzle_sets
            // without is_system / archived_at when the bundled asset's
            // stale tables survived. Add them idempotently.
            await _ensurePuzzleSetsColumns();
            await _seedRandomPlay();
          }
          if (from < 7) {
            await _createPerfIndexes();
          }
        },
      );

  Future<void> _seedUserState() async {
    await into(userStates).insertOnConflictUpdate(
      UserStatesCompanion.insert(
        id: 'me',
        updatedAt: DateTime.now(),
      ),
    );
  }

  Future<void> _createPerfIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_attempts_finished_at '
      'ON attempts(finished_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_attempts_round_id '
      'ON attempts(round_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_attempts_puzzle_id '
      'ON attempts(puzzle_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_rounds_set_id '
      'ON rounds(set_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_puzzle_sets_archived_at '
      'ON puzzle_sets(archived_at)',
    );
  }

  Future<void> _ensurePuzzleSetsColumns() async {
    final cols = await customSelect('PRAGMA table_info(puzzle_sets)').get();
    final names = cols.map((r) => r.read<String>('name')).toSet();
    if (!names.contains('is_system')) {
      await customStatement(
        "ALTER TABLE puzzle_sets ADD COLUMN is_system INTEGER NOT NULL DEFAULT 0",
      );
    }
    if (!names.contains('archived_at')) {
      await customStatement(
        'ALTER TABLE puzzle_sets ADD COLUMN archived_at INTEGER',
      );
    }
  }

  Future<void> _seedRandomPlay() async {
    final now = DateTime.now();
    await into(puzzleSets).insertOnConflictUpdate(
      PuzzleSetsCompanion.insert(
        id: '__random_play__',
        name: 'Random Play',
        createdAt: now,
        size: 0,
        isSystem: const Value(true),
      ),
    );
    await into(rounds).insertOnConflictUpdate(
      RoundsCompanion.insert(
        id: '__random_round__',
        setId: '__random_play__',
        roundNumber: 1,
        startedAt: now,
      ),
    );
  }
}

QueryExecutor _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationSupportDirectory();
    final file = File(p.join(dbFolder.path, 'puzzles.sqlite'));

    if (!await file.exists()) {
      try {
        final blob = await rootBundle.load('assets/db/puzzles.sqlite');
        final bytes =
            blob.buffer.asUint8List(blob.offsetInBytes, blob.lengthInBytes);
        await file.create(recursive: true);
        await file.writeAsBytes(bytes, flush: true);
      } catch (_) {
        // No bundled asset - drift will create an empty database.
      }
    }

    return NativeDatabase.createInBackground(file);
  });
}
