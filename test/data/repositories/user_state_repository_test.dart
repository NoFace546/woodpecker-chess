import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:woodpecker_chess/data/database/app_database.dart';
import 'package:woodpecker_chess/data/repositories/user_state_repository.dart';

void main() {
  late AppDatabase db;
  late UserStateRepository repo;

  setUp(() {
    db = AppDatabase.inMemory();
    repo = UserStateRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> seedUserState({
    required int elo,
    required int attemptsTotal,
  }) async {
    await db.into(db.userStates).insertOnConflictUpdate(
          UserStatesCompanion(
            id: const Value('me'),
            elo: Value(elo),
            attemptsTotal: Value(attemptsTotal),
            updatedAt: Value(DateTime.now()),
          ),
        );
  }

  group('applyAttempt', () {
    test('uses hint penalty: no Elo gain on correct hinted attempt', () async {
      await seedUserState(elo: 1500, attemptsTotal: 0);

      final delta = await repo.applyAttempt(
        puzzleId: 'p1',
        puzzleRating: 1500,
        isCorrect: true,
        hintsUsed: 1,
      );

      expect(delta.before, 1500);
      expect(delta.after, 1500);
      expect(delta.delta, 0);
      expect(delta.wasHinted, isTrue);

      final state = await repo.get();
      expect(state.elo, 1500);
      expect(state.attemptsTotal, 1);
    });

    test('applies K-factor tiers by attempts count', () async {
      await seedUserState(elo: 1500, attemptsTotal: 0);
      final early = await repo.applyAttempt(
        puzzleId: 'k-early',
        puzzleRating: 1500,
        isCorrect: true,
      );

      await seedUserState(elo: 1500, attemptsTotal: 10);
      final mid = await repo.applyAttempt(
        puzzleId: 'k-mid',
        puzzleRating: 1500,
        isCorrect: true,
      );

      await seedUserState(elo: 1500, attemptsTotal: 50);
      final late = await repo.applyAttempt(
        puzzleId: 'k-late',
        puzzleRating: 1500,
        isCorrect: true,
      );

      // expected=0.5 so delta should be K*0.5 (rounded): 24, 16, 8
      expect(early.delta, 24);
      expect(mid.delta, 16);
      expect(late.delta, 8);
    });

    test('clamps Elo to [400, 3200]', () async {
      await seedUserState(elo: 3200, attemptsTotal: 100);
      final high = await repo.applyAttempt(
        puzzleId: 'high',
        puzzleRating: 1000,
        isCorrect: true,
      );
      expect(high.after, 3200);

      await seedUserState(elo: 400, attemptsTotal: 100);
      final low = await repo.applyAttempt(
        puzzleId: 'low',
        puzzleRating: 3000,
        isCorrect: false,
      );
      expect(low.after, 400);
    });
  });
}
