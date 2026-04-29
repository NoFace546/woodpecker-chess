// Builds the bundled puzzle database from the Lichess open puzzle CSV.
//
// Usage:
//   1. Download lichess_db_puzzle.csv.zst from https://database.lichess.org
//   2. Decompress: `zstd -d lichess_db_puzzle.csv.zst`
//   3. Run: `dart run tool/build_puzzle_db.dart <path-to-csv>`
//
// Output: assets/db/puzzles.sqlite (~50 MB after filtering to ~150k puzzles)
//
// Filter strategy:
//   - Hard filter: Popularity >= 80 (Lichess recommendation)
//   - Bucket-stratify by rating (48 buckets of 50 points each)
//   - Within each bucket, sort by popularity DESC and take up to N
//   - Target ~150 000 total puzzles
//
// CSV format: PuzzleId,FEN,Moves,Rating,RatingDeviation,Popularity,NbPlays,
//             Themes,GameUrl,OpeningTags

import 'dart:convert';
import 'dart:io';

import 'package:sqlite3/sqlite3.dart';

const int _ratingMin = 600;
const int _ratingMax = 3000;
const int _bucketSize = 50;
const int _targetTotal = 150000;
const int _minPopularity = 80;

Future<void> main(List<String> args) async {
  if (args.isEmpty) {
    stderr.writeln('Usage: dart run tool/build_puzzle_db.dart <csv-path>');
    exit(64);
  }
  final csvPath = args.first;
  final outputPath = 'assets/db/puzzles.sqlite';

  final csvFile = File(csvPath);
  if (!csvFile.existsSync()) {
    stderr.writeln('CSV not found at $csvPath');
    exit(66);
  }

  final outDir = Directory('assets/db');
  if (!outDir.existsSync()) outDir.createSync(recursive: true);

  final outFile = File(outputPath);
  if (outFile.existsSync()) outFile.deleteSync();

  stdout.writeln('Reading $csvPath …');

  final bucketCount =
      ((_ratingMax - _ratingMin) / _bucketSize).ceil(); // 48 buckets
  final perBucketCap = (_targetTotal / bucketCount).ceil(); // ~3125 each
  final buckets = List<List<_Row>>.generate(bucketCount, (_) => []);

  final lines = csvFile
      .openRead()
      .transform(utf8.decoder)
      .transform(const LineSplitter());

  int processed = 0;
  int kept = 0;
  bool isFirst = true;

  await for (final line in lines) {
    if (isFirst) {
      isFirst = false;
      continue; // header
    }
    processed++;
    if (processed % 500000 == 0) {
      stdout.writeln('  …processed $processed rows, kept $kept candidates');
    }

    final row = _parseLine(line);
    if (row == null) continue;
    if (row.popularity < _minPopularity) continue;
    if (row.rating < _ratingMin || row.rating >= _ratingMax) continue;

    final bucketIdx = ((row.rating - _ratingMin) / _bucketSize).floor();
    buckets[bucketIdx].add(row);
    kept++;
  }

  stdout.writeln('Read $processed rows, kept $kept candidates above threshold');
  stdout.writeln('Sorting and picking top puzzles per rating bucket …');

  final selected = <_Row>[];
  for (final bucket in buckets) {
    bucket.sort((a, b) => b.popularity.compareTo(a.popularity));
    selected.addAll(bucket.take(perBucketCap));
  }

  stdout.writeln('Selected ${selected.length} puzzles');
  stdout.writeln('Writing $outputPath …');

  final db = sqlite3.open(outputPath);
  db.execute('''
    CREATE TABLE puzzles (
      id TEXT PRIMARY KEY,
      fen TEXT NOT NULL,
      moves TEXT NOT NULL,
      rating INTEGER NOT NULL,
      popularity INTEGER NOT NULL DEFAULT 0
    );
    CREATE INDEX idx_puzzles_rating ON puzzles(rating);

    CREATE TABLE puzzle_themes (
      puzzle_id TEXT NOT NULL,
      theme TEXT NOT NULL,
      PRIMARY KEY (puzzle_id, theme),
      FOREIGN KEY (puzzle_id) REFERENCES puzzles(id)
    );
    CREATE INDEX idx_themes_theme ON puzzle_themes(theme);

    CREATE TABLE puzzle_sets (
      id TEXT PRIMARY KEY,
      name TEXT NOT NULL,
      created_at INTEGER NOT NULL,
      rating_min INTEGER,
      rating_max INTEGER,
      themes_json TEXT NOT NULL DEFAULT '[]',
      size INTEGER NOT NULL
    );
    CREATE TABLE puzzle_set_items (
      set_id TEXT NOT NULL,
      position INTEGER NOT NULL,
      puzzle_id TEXT NOT NULL,
      PRIMARY KEY (set_id, position),
      FOREIGN KEY (set_id) REFERENCES puzzle_sets(id)
    );
    CREATE TABLE rounds (
      id TEXT PRIMARY KEY,
      set_id TEXT NOT NULL,
      round_number INTEGER NOT NULL,
      started_at INTEGER NOT NULL,
      completed_at INTEGER,
      current_position INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (set_id) REFERENCES puzzle_sets(id)
    );
    CREATE TABLE attempts (
      id TEXT PRIMARY KEY,
      round_id TEXT NOT NULL,
      puzzle_id TEXT NOT NULL,
      position INTEGER NOT NULL,
      is_correct INTEGER NOT NULL,
      time_ms INTEGER NOT NULL,
      finished_at INTEGER NOT NULL,
      hints_used INTEGER NOT NULL DEFAULT 0,
      FOREIGN KEY (round_id) REFERENCES rounds(id)
    );
  ''');

  db.execute('BEGIN TRANSACTION');
  final insertPuzzle = db.prepare(
    'INSERT INTO puzzles (id, fen, moves, rating, popularity) VALUES (?, ?, ?, ?, ?)',
  );
  final insertTheme = db.prepare(
    'INSERT INTO puzzle_themes (puzzle_id, theme) VALUES (?, ?)',
  );
  for (final row in selected) {
    insertPuzzle.execute([row.id, row.fen, row.moves, row.rating, row.popularity]);
    for (final theme in row.themes) {
      if (theme.isEmpty) continue;
      insertTheme.execute([row.id, theme]);
    }
  }
  insertPuzzle.close();
  insertTheme.close();
  db.execute('COMMIT');

  db.execute('VACUUM');
  db.close();

  final size = await outFile.length();
  stdout.writeln('Done. Size: ${(size / 1024 / 1024).toStringAsFixed(1)} MB');
}

class _Row {
  _Row(this.id, this.fen, this.moves, this.rating, this.popularity, this.themes);

  final String id;
  final String fen;
  final String moves;
  final int rating;
  final int popularity;
  final List<String> themes;
}

_Row? _parseLine(String line) {
  // Lichess CSV doesn't quote fields and never embeds commas inside fields,
  // so a simple split is safe. Format:
  // PuzzleId,FEN,Moves,Rating,RatingDeviation,Popularity,NbPlays,Themes,GameUrl,OpeningTags
  final fields = line.split(',');
  if (fields.length < 8) return null;
  final rating = int.tryParse(fields[3]);
  final popularity = int.tryParse(fields[5]);
  if (rating == null || popularity == null) return null;
  final themes = fields[7].split(' ').where((t) => t.isNotEmpty).toList();
  return _Row(fields[0], fields[1], fields[2], rating, popularity, themes);
}
