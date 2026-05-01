import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite;
import 'package:woodpecker_chess/data/database/app_database.dart';

void main() {
  test('v7 to v8 migration preserves user data and adds disabled_puzzles',
      () async {
    final dir = await Directory.systemTemp.createTemp('woodpecker_migration_');
    final file = File('${dir.path}${Platform.pathSeparator}puzzles.sqlite');

    final raw = sqlite.sqlite3.open(file.path);
    try {
      _createV7Schema(raw);
      _seedUserData(raw);
      raw.execute('PRAGMA user_version = 7');
    } finally {
      raw.dispose();
    }

    final db = AppDatabase(NativeDatabase(file));
    try {
      await db.customSelect('SELECT 1').getSingle();

      final disabledTable = await db.customSelect(
        "SELECT name FROM sqlite_master "
        "WHERE type = 'table' AND name = 'disabled_puzzles'",
      ).getSingleOrNull();
      expect(disabledTable, isNotNull);

      final setCount =
          await db.customSelect('SELECT COUNT(*) AS c FROM puzzle_sets')
              .getSingle();
      final roundCount =
          await db.customSelect('SELECT COUNT(*) AS c FROM rounds').getSingle();
      final attemptCount =
          await db.customSelect('SELECT COUNT(*) AS c FROM attempts')
              .getSingle();

      expect(setCount.read<int>('c'), 1);
      expect(roundCount.read<int>('c'), 1);
      expect(attemptCount.read<int>('c'), 1);
    } finally {
      await db.close();
      await dir.delete(recursive: true);
    }
  });
}

void _createV7Schema(sqlite.Database db) {
  db.execute('''
    CREATE TABLE puzzles (
      id TEXT PRIMARY KEY NOT NULL,
      fen TEXT NOT NULL,
      moves TEXT NOT NULL,
      rating INTEGER NOT NULL,
      popularity INTEGER NOT NULL DEFAULT 0
    );
  ''');
  db.execute('''
    CREATE TABLE puzzle_themes (
      puzzle_id TEXT NOT NULL,
      theme TEXT NOT NULL,
      PRIMARY KEY (puzzle_id, theme)
    );
  ''');
  db.execute('''
    CREATE TABLE puzzle_sets (
      id TEXT PRIMARY KEY NOT NULL,
      name TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      rating_min INTEGER,
      rating_max INTEGER,
      themes_json TEXT NOT NULL DEFAULT '[]',
      size INTEGER NOT NULL,
      is_system INTEGER NOT NULL DEFAULT 0,
      archived_at INTEGER
    );
  ''');
  db.execute('''
    CREATE TABLE puzzle_set_items (
      set_id TEXT NOT NULL,
      position INTEGER NOT NULL,
      puzzle_id TEXT NOT NULL,
      PRIMARY KEY (set_id, position)
    );
  ''');
  db.execute('''
    CREATE TABLE rounds (
      id TEXT PRIMARY KEY NOT NULL,
      set_id TEXT NOT NULL,
      round_number INTEGER NOT NULL,
      started_at INTEGER NOT NULL,
      completed_at INTEGER,
      current_position INTEGER NOT NULL DEFAULT 0
    );
  ''');
  db.execute('''
    CREATE TABLE attempts (
      id TEXT PRIMARY KEY NOT NULL,
      round_id TEXT NOT NULL,
      puzzle_id TEXT NOT NULL,
      position INTEGER NOT NULL,
      is_correct INTEGER NOT NULL,
      time_ms INTEGER NOT NULL,
      finished_at INTEGER NOT NULL,
      hints_used INTEGER NOT NULL DEFAULT 0,
      user_move_uci TEXT
    );
  ''');
  db.execute('''
    CREATE TABLE user_states (
      id TEXT PRIMARY KEY NOT NULL,
      elo INTEGER NOT NULL DEFAULT 1500,
      attempts_total INTEGER NOT NULL DEFAULT 0,
      calibration_status TEXT NOT NULL DEFAULT 'pending',
      updated_at INTEGER NOT NULL
    );
  ''');
  db.execute('''
    CREATE TABLE elo_history (
      id INTEGER PRIMARY KEY AUTOINCREMENT NOT NULL,
      puzzle_id TEXT NOT NULL,
      puzzle_rating INTEGER NOT NULL,
      elo_before INTEGER NOT NULL,
      elo_after INTEGER NOT NULL,
      was_correct INTEGER NOT NULL,
      at INTEGER NOT NULL
    );
  ''');
  db.execute('''
    CREATE TABLE bot_games (
      id TEXT PRIMARY KEY NOT NULL,
      fen TEXT NOT NULL,
      last_move_uci TEXT,
      user_side TEXT NOT NULL,
      level INTEGER NOT NULL,
      created_at INTEGER NOT NULL,
      updated_at INTEGER NOT NULL
    );
  ''');
}

void _seedUserData(sqlite.Database db) {
  const now = 1714435200000;
  db.execute(
    "INSERT INTO puzzles (id, fen, moves, rating, popularity) "
    "VALUES ('p1', '8/8/8/8/8/8/8/8 w - - 0 1', 'a2a3', 1200, 0)",
  );
  db.execute(
    "INSERT INTO puzzle_sets "
    "(id, name, created_at, rating_min, rating_max, themes_json, size, is_system) "
    "VALUES ('s1', 'My set', $now, 1000, 1400, '[]', 1, 0)",
  );
  db.execute(
    "INSERT INTO puzzle_set_items (set_id, position, puzzle_id) "
    "VALUES ('s1', 0, 'p1')",
  );
  db.execute(
    "INSERT INTO rounds "
    "(id, set_id, round_number, started_at, current_position) "
    "VALUES ('r1', 's1', 1, $now, 1)",
  );
  db.execute(
    "INSERT INTO attempts "
    "(id, round_id, puzzle_id, position, is_correct, time_ms, finished_at, hints_used) "
    "VALUES ('a1', 'r1', 'p1', 0, 1, 3000, $now, 0)",
  );
  db.execute(
    "INSERT INTO user_states "
    "(id, elo, attempts_total, calibration_status, updated_at) "
    "VALUES ('me', 1500, 1, 'pending', $now)",
  );
}
