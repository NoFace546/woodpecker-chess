import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/database/app_database.dart';
import '../data/repositories/puzzle_repository.dart';

class ResetService {
  ResetService(this._db);
  final AppDatabase _db;

  Future<void> resetUserData() async {
    await _db.transaction(() async {
      // Wipe all attempts (including those under the system Random Play round).
      await _db.delete(_db.attempts).go();
      // Delete user rounds, but keep the system __random_round__ alive.
      await (_db.delete(_db.rounds)
            ..where((r) => r.id.equals('__random_round__').not()))
          .go();
      // Delete user set items, but only those tied to non-system sets.
      await (_db.delete(_db.puzzleSetItems)
            ..where((i) => i.setId.isInQuery(
                  _db.selectOnly(_db.puzzleSets)
                    ..addColumns([_db.puzzleSets.id])
                    ..where(_db.puzzleSets.isSystem.equals(false)),
                )))
          .go();
      // Delete only user sets, leave system sets intact.
      await (_db.delete(_db.puzzleSets)
            ..where((s) => s.isSystem.equals(false)))
          .go();
      await _db.delete(_db.botGames).go();
      await _db.delete(_db.eloHistory).go();
      await (_db.update(_db.userStates)..where((u) => u.id.equals('me')))
          .write(UserStatesCompanion(
        elo: const Value(1500),
        attemptsTotal: const Value(0),
        calibrationStatus: const Value('pending'),
        updatedAt: Value(DateTime.now()),
      ));
    });
  }
}

final resetServiceProvider = Provider<ResetService>((ref) {
  return ResetService(ref.watch(databaseProvider));
});
