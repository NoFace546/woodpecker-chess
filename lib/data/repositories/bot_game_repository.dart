import 'package:dartchess/dartchess.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/bot/bot_config.dart';
import '../database/app_database.dart';
import 'puzzle_repository.dart';

class BotGameSnapshot {
  const BotGameSnapshot({
    required this.id,
    required this.fen,
    required this.lastMoveUci,
    required this.userSide,
    required this.level,
  });

  final String id;
  final String fen;
  final String? lastMoveUci;
  final Side userSide;
  final BotLevel level;
}

class BotGameRepository {
  BotGameRepository(this._db);

  final AppDatabase _db;
  static const _activeId = 'active';

  Future<BotGameSnapshot?> active() async {
    final row = await (_db.select(_db.botGames)
          ..where((g) => g.id.equals(_activeId)))
        .getSingleOrNull();
    return row == null ? null : _toSnapshot(row);
  }

  Stream<BotGameSnapshot?> watchActive() {
    return (_db.select(_db.botGames)
          ..where((g) => g.id.equals(_activeId)))
        .watchSingleOrNull()
        .map((row) => row == null ? null : _toSnapshot(row));
  }

  BotGameSnapshot _toSnapshot(BotGameRow row) {
    return BotGameSnapshot(
      id: row.id,
      fen: row.fen,
      lastMoveUci: row.lastMoveUci,
      userSide: row.userSide == 'white' ? Side.white : Side.black,
      level: BotLevel.values[row.level.clamp(0, BotLevel.values.length - 1)],
    );
  }

  Future<void> save(BotGameSnapshot s) async {
    final now = DateTime.now();
    await _db.into(_db.botGames).insertOnConflictUpdate(
          BotGamesCompanion.insert(
            id: _activeId,
            fen: s.fen,
            lastMoveUci: Value(s.lastMoveUci),
            userSide: s.userSide == Side.white ? 'white' : 'black',
            level: s.level.index,
            createdAt: now,
            updatedAt: now,
          ),
        );
  }

  Future<void> clear() async {
    await (_db.delete(_db.botGames)..where((g) => g.id.equals(_activeId)))
        .go();
  }
}

final botGameRepositoryProvider = Provider<BotGameRepository>((ref) {
  return BotGameRepository(ref.watch(databaseProvider));
});

final activeBotGameProvider = StreamProvider<BotGameSnapshot?>((ref) {
  return ref.watch(botGameRepositoryProvider).watchActive();
});
