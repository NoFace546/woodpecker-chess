import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../database/app_database.dart';
import '../models/outlier_attempt.dart';
import '../models/puzzle_attempt.dart';
import '../models/round.dart';
import '../models/round_comparison.dart';
import '../models/round_stats.dart';
import 'puzzle_repository.dart';

class RoundRepository {
  RoundRepository(this._db);

  final AppDatabase _db;
  static const _uuid = Uuid();

  Future<List<Round>> listForSet(String setId) async {
    final rows = await (_db.select(_db.rounds)
          ..where((r) => r.setId.equals(setId))
          ..orderBy([(r) => OrderingTerm.asc(r.roundNumber)]))
        .get();
    return rows.map(_toModel).toList();
  }

  Future<Round?> activeRound(String setId) async {
    final row = await (_db.select(_db.rounds)
          ..where((r) => r.setId.equals(setId) & r.completedAt.isNull())
          ..orderBy([(r) => OrderingTerm.desc(r.roundNumber)])
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : _toModel(row);
  }

  Future<Round> startNew(String setId) async {
    final lastNumber = await _maxRoundNumber(setId);
    final id = _uuid.v4();
    final now = DateTime.now();
    final row = RoundsCompanion.insert(
      id: id,
      setId: setId,
      roundNumber: lastNumber + 1,
      startedAt: now,
    );
    await _db.into(_db.rounds).insert(row);
    return Round(
      id: id,
      setId: setId,
      roundNumber: lastNumber + 1,
      startedAt: now,
    );
  }

  Future<void> advancePosition(String roundId, int newPosition) async {
    await (_db.update(_db.rounds)..where((r) => r.id.equals(roundId)))
        .write(RoundsCompanion(currentPosition: Value(newPosition)));
  }

  Future<void> complete(String roundId) async {
    await (_db.update(_db.rounds)..where((r) => r.id.equals(roundId))).write(
      RoundsCompanion(completedAt: Value(DateTime.now())),
    );
  }

  Future<void> recordAttempt({
    required String roundId,
    required String puzzleId,
    required int position,
    required bool isCorrect,
    required Duration time,
    int hintsUsed = 0,
    String? userMoveUci,
  }) async {
    await _db.into(_db.attempts).insert(
          AttemptsCompanion.insert(
            id: _uuid.v4(),
            roundId: roundId,
            puzzleId: puzzleId,
            position: position,
            isCorrect: isCorrect,
            timeMs: time.inMilliseconds,
            finishedAt: DateTime.now(),
            hintsUsed: Value(hintsUsed),
            userMoveUci: Value(userMoveUci),
          ),
        );
    // Elo is intentionally NOT updated for set-based rounds — those puzzles
    // are pre-filtered by rating, so they're not a fair Elo test. Random
    // free-play attempts (lib/features/solve/solve_screen.dart) update Elo
    // via UserStateRepository directly.
  }

  Future<List<PuzzleAttempt>> attemptsForRound(String roundId) async {
    final rows = await (_db.select(_db.attempts)
          ..where((a) => a.roundId.equals(roundId))
          ..orderBy([(a) => OrderingTerm.asc(a.position)]))
        .get();
    return rows.map(_toAttempt).toList();
  }

  Future<PuzzleAttempt?> lastAttemptForPuzzle(String puzzleId) async {
    final row = await (_db.select(_db.attempts)
          ..where((a) => a.puzzleId.equals(puzzleId))
          ..orderBy([(a) => OrderingTerm.desc(a.finishedAt)])
          ..limit(1))
        .getSingleOrNull();
    return row == null ? null : _toAttempt(row);
  }

  PuzzleAttempt _toAttempt(AttemptRow a) => PuzzleAttempt(
        id: a.id,
        roundId: a.roundId,
        puzzleId: a.puzzleId,
        position: a.position,
        isCorrect: a.isCorrect,
        time: Duration(milliseconds: a.timeMs),
        finishedAt: a.finishedAt,
        hintsUsed: a.hintsUsed,
        userMoveUci: a.userMoveUci,
      );

  Future<RoundStats?> statsForRound(String roundId) async {
    final roundRow = await (_db.select(_db.rounds)
          ..where((r) => r.id.equals(roundId)))
        .getSingleOrNull();
    if (roundRow == null) return null;
    final attempts = await attemptsForRound(roundId);
    return RoundStats.fromAttempts(
      round: _toModel(roundRow),
      attempts: attempts,
    );
  }

  Future<List<RoundStats>> statsForSet(String setId) async {
    final rounds = await listForSet(setId);
    final completed = rounds.where((r) => r.isCompleted).toList();
    final out = <RoundStats>[];
    for (final round in completed) {
      final attempts = await attemptsForRound(round.id);
      if (attempts.isEmpty) continue;
      out.add(RoundStats.fromAttempts(round: round, attempts: attempts));
    }
    return out;
  }

  Future<RoundComparison> comparisonForRound(String roundId) async {
    final roundRow = await (_db.select(_db.rounds)
          ..where((r) => r.id.equals(roundId)))
        .getSingleOrNull();
    if (roundRow == null) {
      throw StateError('Round $roundId not found');
    }
    final current = await statsForRound(roundId);
    if (current == null) {
      throw StateError('Round $roundId not found');
    }
    final earlier = await (_db.select(_db.rounds)
          ..where((r) =>
              r.setId.equals(roundRow.setId) &
              r.completedAt.isNotNull() &
              r.roundNumber.isSmallerThanValue(roundRow.roundNumber))
          ..orderBy([(r) => OrderingTerm.desc(r.roundNumber)])
          ..limit(1))
        .getSingleOrNull();
    if (earlier == null) {
      return RoundComparison(current: current);
    }
    final earlierStats = await statsForRound(earlier.id);
    return RoundComparison(current: current, previous: earlierStats);
  }

  Future<List<OutlierAttempt>> outliersForRound(
    String roundId, {
    int limit = 5,
  }) async {
    final rows = await _db.customSelect(
      '''
      SELECT a.id, a.round_id, a.puzzle_id, a.position, a.is_correct,
             a.time_ms, a.finished_at, a.hints_used, a.user_move_uci,
             p.fen, p.rating
      FROM attempts a
      JOIN puzzles p ON p.id = a.puzzle_id
      WHERE a.round_id = ?
      ORDER BY a.time_ms DESC
      LIMIT ?
      ''',
      variables: [
        Variable.withString(roundId),
        Variable.withInt(limit),
      ],
      readsFrom: {_db.attempts, _db.puzzles},
    ).get();

    final out = <OutlierAttempt>[];
    for (final row in rows) {
      final puzzleId = row.read<String>('puzzle_id');
      final themesRows = await (_db.select(_db.puzzleThemes)
            ..where((t) => t.puzzleId.equals(puzzleId)))
          .get();
      out.add(OutlierAttempt(
        attempt: PuzzleAttempt(
          id: row.read<String>('id'),
          roundId: row.read<String>('round_id'),
          puzzleId: puzzleId,
          position: row.read<int>('position'),
          isCorrect: row.read<int>('is_correct') == 1,
          time: Duration(milliseconds: row.read<int>('time_ms')),
          finishedAt: DateTime.fromMillisecondsSinceEpoch(
            row.read<int>('finished_at'),
          ),
          hintsUsed: row.read<int>('hints_used'),
          userMoveUci: row.readNullable<String>('user_move_uci'),
        ),
        themes: themesRows.map((t) => t.theme).toList(),
        rating: row.read<int>('rating'),
        fen: row.read<String>('fen'),
      ));
    }
    return out;
  }

  Future<int> _maxRoundNumber(String setId) async {
    final row = await _db.customSelect(
      'SELECT COALESCE(MAX(round_number), 0) AS m FROM rounds WHERE set_id = ?',
      variables: [Variable.withString(setId)],
      readsFrom: {_db.rounds},
    ).getSingle();
    return row.read<int>('m');
  }

  Round _toModel(RoundRow row) => Round(
        id: row.id,
        setId: row.setId,
        roundNumber: row.roundNumber,
        startedAt: row.startedAt,
        completedAt: row.completedAt,
        currentPosition: row.currentPosition,
      );
}

final roundRepositoryProvider = Provider<RoundRepository>((ref) {
  return RoundRepository(ref.watch(databaseProvider));
});

final roundsForSetProvider =
    FutureProvider.family<List<Round>, String>((ref, setId) async {
  return ref.watch(roundRepositoryProvider).listForSet(setId);
});

final roundStatsProvider =
    FutureProvider.family<RoundStats?, String>((ref, roundId) async {
  return ref.watch(roundRepositoryProvider).statsForRound(roundId);
});

final setRoundsStatsProvider =
    FutureProvider.family<List<RoundStats>, String>((ref, setId) async {
  return ref.watch(roundRepositoryProvider).statsForSet(setId);
});

final roundComparisonProvider =
    FutureProvider.family<RoundComparison, String>((ref, roundId) async {
  return ref.watch(roundRepositoryProvider).comparisonForRound(roundId);
});

final outliersProvider = FutureProvider.family<
    List<OutlierAttempt>, ({String roundId, int limit})>((ref, args) async {
  return ref
      .watch(roundRepositoryProvider)
      .outliersForRound(args.roundId, limit: args.limit);
});

final lastAttemptForPuzzleProvider =
    FutureProvider.family<PuzzleAttempt?, String>((ref, puzzleId) async {
  return ref.watch(roundRepositoryProvider).lastAttemptForPuzzle(puzzleId);
});
