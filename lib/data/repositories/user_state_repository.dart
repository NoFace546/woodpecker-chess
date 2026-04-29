import 'dart:math' as math;

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../database/app_database.dart';
import '../models/elo_history_entry.dart';
import 'puzzle_repository.dart';

class UserState {
  const UserState({
    required this.elo,
    required this.attemptsTotal,
    required this.calibrationStatus,
  });

  final int elo;
  final int attemptsTotal;
  final String calibrationStatus;

  bool get needsCalibration => calibrationStatus == 'pending';
  bool get isCalibrated => calibrationStatus == 'completed';
}

class EloDelta {
  const EloDelta({
    required this.before,
    required this.after,
    this.wasHinted = false,
  });
  final int before;
  final int after;
  final bool wasHinted;
  int get delta => after - before;
}

class UserStateRepository {
  UserStateRepository(this._db);

  final AppDatabase _db;
  static const _id = 'me';

  Future<UserState> get() async {
    final row = await (_db.select(_db.userStates)
          ..where((u) => u.id.equals(_id)))
        .getSingleOrNull();
    if (row != null) return _toModel(row);
    // Defensive: seed if missing (should be created by migration / onCreate).
    await _db.into(_db.userStates).insertOnConflictUpdate(
          UserStatesCompanion.insert(id: _id, updatedAt: DateTime.now()),
        );
    return const UserState(
      elo: 1500,
      attemptsTotal: 0,
      calibrationStatus: 'pending',
    );
  }

  Stream<UserState> watch() {
    return (_db.select(_db.userStates)..where((u) => u.id.equals(_id)))
        .watchSingleOrNull()
        .map((row) =>
            row == null ? _defaultState() : _toModel(row));
  }

  Future<void> setElo(int elo) async {
    await _db.into(_db.userStates).insertOnConflictUpdate(
          UserStatesCompanion(
            id: const Value(_id),
            elo: Value(elo),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Resets Elo to [elo] and clears attempts/history so the K-factor ramp
  /// restarts and the "Find your rating" nudge reappears.
  Future<void> resetEloAndAttempts({int elo = 1500}) async {
    await _db.transaction(() async {
      await _db.into(_db.userStates).insertOnConflictUpdate(
            UserStatesCompanion(
              id: const Value(_id),
              elo: Value(elo),
              attemptsTotal: const Value(0),
              updatedAt: Value(DateTime.now()),
            ),
          );
      await _db.delete(_db.eloHistory).go();
    });
  }

  Future<List<EloHistoryEntry>> historyOrderedByTime() async {
    final rows = await (_db.select(_db.eloHistory)
          ..orderBy([(h) => OrderingTerm.asc(h.at)]))
        .get();
    return rows
        .map((r) => EloHistoryEntry(
              puzzleId: r.puzzleId,
              puzzleRating: r.puzzleRating,
              eloBefore: r.eloBefore,
              eloAfter: r.eloAfter,
              wasCorrect: r.wasCorrect,
              at: r.at,
            ))
        .toList();
  }

  Future<void> markCalibrated(String status) async {
    await _db.into(_db.userStates).insertOnConflictUpdate(
          UserStatesCompanion(
            id: const Value(_id),
            calibrationStatus: Value(status),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  /// Returns the Elo before/after; logs to history.
  /// If [hintsUsed] > 0 and the attempt was correct, Elo is left unchanged
  /// (a hint-assisted win shouldn't reward you, but doesn't punish either).
  Future<EloDelta> applyAttempt({
    required String puzzleId,
    required int puzzleRating,
    required bool isCorrect,
    int hintsUsed = 0,
  }) async {
    final state = await get();
    final hintAssisted = hintsUsed > 0 && isCorrect;
    final newElo = hintAssisted
        ? state.elo
        : _calcNewElo(
            userElo: state.elo,
            puzzleRating: puzzleRating,
            isCorrect: isCorrect,
            attemptsTotal: state.attemptsTotal,
          );

    await _db.transaction(() async {
      await _db.into(_db.userStates).insertOnConflictUpdate(
            UserStatesCompanion(
              id: const Value(_id),
              elo: Value(newElo),
              attemptsTotal: Value(state.attemptsTotal + 1),
              updatedAt: Value(DateTime.now()),
            ),
          );
      await _db.into(_db.eloHistory).insert(
            EloHistoryCompanion.insert(
              puzzleId: puzzleId,
              puzzleRating: puzzleRating,
              eloBefore: state.elo,
              eloAfter: newElo,
              wasCorrect: isCorrect,
              at: DateTime.now(),
            ),
          );
    });

    return EloDelta(
      before: state.elo,
      after: newElo,
      wasHinted: hintAssisted,
    );
  }

  static int _calcNewElo({
    required int userElo,
    required int puzzleRating,
    required bool isCorrect,
    required int attemptsTotal,
  }) {
    // Aggressive ramp early so a fresh Elo converges fast.
    final double k;
    if (attemptsTotal < 10) {
      k = 48.0;
    } else if (attemptsTotal < 50) {
      k = 32.0;
    } else {
      k = 16.0;
    }
    final expected = 1.0 / (1.0 + math.pow(10, (puzzleRating - userElo) / 400.0));
    final actual = isCorrect ? 1.0 : 0.0;
    final delta = (k * (actual - expected)).round();
    return (userElo + delta).clamp(400, 3200);
  }

  UserState _toModel(UserStateRow row) {
    return UserState(
      elo: row.elo,
      attemptsTotal: row.attemptsTotal,
      calibrationStatus: row.calibrationStatus,
    );
  }

  UserState _defaultState() => const UserState(
        elo: 1500,
        attemptsTotal: 0,
        calibrationStatus: 'pending',
      );
}

final userStateRepositoryProvider = Provider<UserStateRepository>((ref) {
  return UserStateRepository(ref.watch(databaseProvider));
});

final userStateProvider = StreamProvider<UserState>((ref) {
  return ref.watch(userStateRepositoryProvider).watch();
});

final eloHistoryProvider =
    FutureProvider<List<EloHistoryEntry>>((ref) async {
  return ref.watch(userStateRepositoryProvider).historyOrderedByTime();
});
