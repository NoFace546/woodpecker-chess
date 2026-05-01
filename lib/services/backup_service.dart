import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqlite3/sqlite3.dart';

import '../data/repositories/puzzle_repository.dart';

class BackupService {
  BackupService(this._ref);
  final Ref _ref;

  Future<File> _dbFile() async {
    final dir = await getApplicationSupportDirectory();
    return File(p.join(dir.path, 'puzzles.sqlite'));
  }

  /// Copies the live DB into the cache dir with a dated filename and
  /// returns the file. Caller hands it to share_plus.
  Future<XFile> stageExport() async {
    final src = await _dbFile();
    final cache = await getTemporaryDirectory();
    final stamp = DateTime.now().toIso8601String().substring(0, 10);
    final dst =
        File(p.join(cache.path, 'woodpecker_backup_$stamp.sqlite'));
    if (await dst.exists()) await dst.delete();
    await src.copy(dst.path);
    return XFile(dst.path, mimeType: 'application/x-sqlite3');
  }

  /// Validates that [candidate] looks like a Woodpecker backup. Throws
  /// FormatException if not.
  Future<void> validate(File candidate) async {
    final db = sqlite3.open(candidate.path, mode: OpenMode.readOnly);
    try {
      final names = db
          .select("SELECT name FROM sqlite_master WHERE type='table'")
          .map((r) => r['name'] as String)
          .toSet();
      const required = {
        'puzzles',
        'puzzle_themes',
        'puzzle_sets',
        'rounds',
        'attempts',
        'user_states',
      };
      final missing = required.difference(names);
      if (missing.isNotEmpty) {
        throw FormatException(
          'Not a Woodpecker backup (missing: ${missing.join(", ")})',
        );
      }
    } finally {
      db.close();
    }
  }

  /// Closes the live DB, overwrites the file with [candidate], invalidates
  /// the database provider so the next read reopens against the new file.
  Future<void> importFrom(File candidate) async {
    await validate(candidate);
    final db = _ref.read(databaseProvider);
    await db.close();
    final dst = await _dbFile();
    await candidate.copy(dst.path);
    _ref.invalidate(databaseProvider);
  }
}

final backupServiceProvider = Provider<BackupService>(BackupService.new);
