# AI_HANDOVER.md

> **Project:** Woodpecker Chess — a Flutter chess training app implementing the Woodpecker Method (Smith & Tikkanen). The user solves the same set of tactical puzzles in repeated rounds and tracks improvement.
>
> **Status:** Pre-launch. Pro/Freemium gating wired but IAP product not yet listed in Play Console. Beta build is `kDevForceLocked = false`, debug builds always grant Pro via `kDebugMode`. Single platform target: Android (Play Store) at launch.
>
> **Audience:** A new advanced AI assistant taking over development with no prior conversational context.

---

## 1. TEKNISK STACK OG ARKITEKTUR

### Framework
- **Flutter** with Dart SDK `^3.11.5`
- Single Activity Android target (Android 5.0+, `min_sdk_android: 21`)

### Key packages (`pubspec.yaml`)

| Package | Version | Role |
|---|---|---|
| `flutter_riverpod` | ^3.3.1 | State management. Use `Notifier`/`AsyncNotifier`/`StreamProvider`. **Note: Riverpod 3.x removed `StateProvider` — use `NotifierProvider` instead.** |
| `go_router` | ^17.2.2 | Navigation. Routes defined in [lib/router.dart](lib/router.dart). |
| `drift` | ^2.32.1 | SQLite ORM. Code generation via `drift_dev` + `build_runner`. Generated file: `lib/data/database/app_database.g.dart`. |
| `sqlite3_flutter_libs` | ^0.6.0+eol | Bundled SQLite binary. |
| `sqlite3` | ^3.3.1 | Used by `BackupService` for raw DB ops outside the Drift connection. |
| `path_provider` | ^2.1.5 | App-support directory paths for the runtime DB. |
| `dartchess` | ^0.12.3 | Chess rules — `Position`, `Move`, `NormalMove`, `Side`, `Role`, `Square`, `Setup.parseFen`, `Chess.fromSetup`. GPL-3.0. |
| `chessground` | ^9.0.0 | Lichess board UI widget. `Chessboard`, `ChessboardSettings`, `GameData`, `PlayerSide`, `Shape`, `Arrow`, `Circle`. **GPL-3.0** — propagates to the whole app. |
| `multistockfish` | ^0.5.0 | Stockfish engine wrapper. |
| `audioplayers` | ^6.6.0 | Sound effects with per-effect volume + preloading. |
| `confetti` | ^0.8.0 | Round-summary celebration effect. |
| `shared_preferences` | ^2.5.5 | Lightweight prefs (Pro grandfathering, mute, theme, etc.). |
| `in_app_purchase` | ^3.2.0 | Direct Google Play Billing wrapper (no RevenueCat). |
| `share_plus` | ^11.0.0 | Database-export share sheet. |
| `file_picker` | ^8.1.6 | Database-import file selection. |
| `device_info_plus` / `package_info_plus` | — | Bug-report mailto with version + device info. |
| `url_launcher` | ^6.3.1 | mailto: + external links. |
| `google_fonts` | ^6.2.1 | Inter typography. |
| `fast_immutable_collections` | ^11.2.0 | `IMap`/`ISet` (used for chessground shapes/validMoves). |

### Folder layout

```
lib/
├── main.dart               # App entry, theme, off-screen Chessboard warmup
├── router.dart             # GoRouter route table
├── data/
│   ├── database/
│   │   ├── app_database.dart        # Drift schema + migrations + LazyDatabase
│   │   └── app_database.g.dart      # Generated — DO NOT EDIT
│   ├── models/                      # Plain Dart DTOs and value objects
│   │   ├── puzzle.dart
│   │   ├── round.dart
│   │   ├── round_stats.dart
│   │   ├── round_comparison.dart
│   │   ├── puzzle_set.dart
│   │   ├── set_filter.dart
│   │   ├── enriched_theme_stats.dart  # Bucketed Wilson stats core
│   │   ├── weakness_entry.dart        # WeaknessAnalyzer
│   │   ├── theme_stats.dart
│   │   ├── theme_definitions.dart     # 54 theme blurbs from Lichess
│   │   ├── tactical_themes.dart       # Curated theme allow-lists
│   │   ├── phase_stats.dart
│   │   ├── global_stats.dart
│   │   ├── elo_history_entry.dart
│   │   ├── puzzle_attempt.dart
│   │   ├── outlier_attempt.dart
│   │   └── problem_puzzle.dart
│   └── repositories/                # Drift queries + Riverpod providers
│       ├── puzzle_repository.dart
│       ├── set_repository.dart
│       ├── round_repository.dart
│       ├── stats_repository.dart    # Big SQL — bucketed theme analytics
│       ├── user_state_repository.dart # Elo update lives here
│       └── bot_game_repository.dart
├── services/                         # Singletons + cross-cutting
│   ├── stockfish_service.dart       # Engine wrapper, serialized I/O
│   ├── sound_service.dart           # AudioPlayer pool + per-effect volume
│   ├── app_preferences.dart         # SharedPreferences-backed providers
│   ├── pro_status.dart              # Pro entitlement + IAP listener
│   ├── board_appearance.dart        # 23 board themes + piece sets
│   ├── haptic.dart                  # Static AppHaptics.{light,medium,heavy}
│   ├── backup_service.dart          # Export / import live DB
│   ├── reset_service.dart           # Wipe user data, keep system rows
│   └── training_recommender.dart    # The Recommended-set algorithm
├── features/                         # One subdirectory per route/screen
│   ├── archive/                     # /archived
│   ├── bot/                         # /play-bot, /play-bot/game
│   ├── elo_history/                 # /elo-history
│   ├── home/                        # /
│   ├── onboarding/                  # 3-slide welcome flow
│   ├── paywall/                     # PaywallScreen.show(context)
│   ├── progression/                 # /progression, /sets/:id/progression, /sets/:id/drill
│   ├── session/                     # /sets/:id/rounds/:id (active solving)
│   ├── set_builder/                 # /sets/new
│   ├── set_detail/                  # /sets/:id
│   ├── settings/                    # /settings, /about, /method
│   ├── solve/                       # /random + reusable SolveBoardWidget
│   └── strengths/                   # /strengths + ThemeExplainerSheet
└── widgets/                          # Cross-feature shared UI
    ├── empty_state.dart             # Standard zero-data widget
    ├── error_view.dart              # Themed AsyncValue.error replacement
    ├── pro_lock.dart                # ProBadge + ProGate widgets
    └── captured_row.dart            # Material differential (bot game)

assets/
├── db/
│   └── puzzles.sqlite               # Bundled Lichess puzzle library
├── icon/                            # Launcher icon source
└── sounds/
    ├── move.mp3 / capture.mp3 / check.mp3
    ├── correct.mp3 / wrong.mp3      # Volume capped 0.35 in SoundEffect enum
    ├── hint.mp3
    └── round_complete.mp3

tool/
└── build_puzzle_db.dart             # Dev tool — ingests Lichess CSV → assets/db/puzzles.sqlite
```

### Architecture rules
- **All async data flows through Riverpod providers.** UI never calls a repository method directly via `ref.read` for reading — uses `ref.watch(<provider>)` so cache invalidation propagates.
- **One repository = one Drift Dao-equivalent.** Repositories own their providers (e.g. `puzzleRepositoryProvider`, `puzzleSeedProvider`).
- **Models are immutable.** No `mutable` fields, no `setX()` setters. Use `copyWith`.
- **Features never import from each other** except through `widgets/` and explicit `services/`.
- **Generated code (`*.g.dart`) is committed.** Re-run via `dart run build_runner build --delete-conflicting-outputs`.

### State model summary

| State | Type | Where |
|---|---|---|
| User Elo + attempts | `StreamProvider<UserState>` | `userStateProvider` ([user_state_repository.dart](lib/data/repositories/user_state_repository.dart)) |
| Pro entitlement | `NotifierProvider<ProStatusNotifier, ProStatus>` | `proStatusProvider` ([pro_status.dart](lib/services/pro_status.dart)) |
| Sets list | `FutureProvider<List<PuzzleSet>>` | `allSetsProvider` |
| Strength analysis | `FutureProvider<List<WeaknessEntry>>` | `weaknessAnalysisProvider` |
| Active bot game | `FutureProvider<BotGameSnapshot?>` | `activeBotGameProvider` |
| App preferences (mute, theme, animations, etc.) | `NotifierProvider<…, T>` | [app_preferences.dart](lib/services/app_preferences.dart) |

---

## 2. DATABASE OG LAGRING (Drift / SQLite)

### Runtime database
- File: `<applicationSupportDirectory>/puzzles.sqlite`
- On first cold start, [`AppDatabase._openConnection()`](lib/data/database/app_database.dart) checks if the file exists. If absent, it copies `assets/db/puzzles.sqlite` from the bundle (`rootBundle.load('assets/db/puzzles.sqlite')`) into the support dir. If the asset is missing or fails to load, Drift creates an empty database — the app's `ensureSeeded()` injects one fallback puzzle so /random doesn't crash.
- Connection wrapped in `LazyDatabase` so the copy is awaited before the first query.

### Schema version: **7**

### Tables (in [lib/data/database/app_database.dart](lib/data/database/app_database.dart))

#### `Puzzles` → `puzzles`
| Column | Type | Constraint |
|---|---|---|
| `id` | TEXT | PRIMARY KEY |
| `fen` | TEXT | NOT NULL |
| `moves` | TEXT | NOT NULL — UCI moves separated by spaces, e.g. `"e8d7 a2e6 d7d8 f7f8"` |
| `rating` | INTEGER | NOT NULL |
| `popularity` | INTEGER | DEFAULT 0 |

#### `PuzzleThemes` → `puzzle_themes`
Many-to-many: a puzzle has many themes.
| Column | Type | Constraint |
|---|---|---|
| `puzzleId` | TEXT | composite PK, references `Puzzles.id` |
| `theme` | TEXT | composite PK |

#### `PuzzleSets` → `puzzle_sets`
| Column | Type | Constraint |
|---|---|---|
| `id` | TEXT | PRIMARY KEY (UUID v4) |
| `name` | TEXT | NOT NULL |
| `createdAt` | DATETIME | NOT NULL |
| `ratingMin` | INTEGER | NULL |
| `ratingMax` | INTEGER | NULL |
| `themesJson` | TEXT | DEFAULT `'[]'` |
| `size` | INTEGER | NOT NULL — number of puzzles in the set |
| `isSystem` | BOOL | DEFAULT false |
| `archivedAt` | DATETIME | NULL — non-null = archived |

System row: `'__random_play__'` — the synthetic set that owns the `__random_round__` round used by /random attempts.

#### `PuzzleSetItems` → `puzzle_set_items`
| Column | Type | Constraint |
|---|---|---|
| `setId` | TEXT | composite PK, references `PuzzleSets.id` |
| `position` | INTEGER | composite PK (0-indexed slot in the set) |
| `puzzleId` | TEXT | NOT NULL — **no FK constraint** (Drift schema doesn't declare it; relies on application invariants) |

#### `Rounds` → `rounds`
| Column | Type | Constraint |
|---|---|---|
| `id` | TEXT | PRIMARY KEY (UUID v4 or `'__random_round__'` for the system row) |
| `setId` | TEXT | NOT NULL, references `PuzzleSets.id` |
| `roundNumber` | INTEGER | NOT NULL |
| `startedAt` | DATETIME | NOT NULL |
| `completedAt` | DATETIME | NULL |
| `currentPosition` | INTEGER | DEFAULT 0 — cursor into `PuzzleSetItems.position` |

#### `Attempts` → `attempts`
| Column | Type | Constraint |
|---|---|---|
| `id` | TEXT | PRIMARY KEY (UUID v4) |
| `roundId` | TEXT | NOT NULL, references `Rounds.id` |
| `puzzleId` | TEXT | NOT NULL |
| `position` | INTEGER | NOT NULL — index in the parent round |
| `isCorrect` | BOOL | NOT NULL |
| `timeMs` | INTEGER | NOT NULL |
| `finishedAt` | DATETIME | NOT NULL |
| `hintsUsed` | INTEGER | DEFAULT 0 |
| `userMoveUci` | TEXT | NULL — first user move (regardless of correctness), used by `puzzle_preview_screen` |

#### `BotGames` → `bot_games`
Single-row store keyed by `'active'` (only one in-progress bot game at a time).
| Column | Type |
|---|---|
| `id` | TEXT PK |
| `fen` | TEXT |
| `lastMoveUci` | TEXT NULL |
| `userSide` | TEXT (`'white'`/`'black'`) |
| `level` | INTEGER (`BotLevel.index`) |
| `createdAt` / `updatedAt` | DATETIME |

#### `UserStates` → `user_states`
Singleton (id = `'me'`).
| Column | Type | Default |
|---|---|---|
| `id` | TEXT PK | `'me'` |
| `elo` | INTEGER | 1500 |
| `attemptsTotal` | INTEGER | 0 |
| `calibrationStatus` | TEXT | `'pending'` (legacy field, unused after onboarding rewrite) |
| `updatedAt` | DATETIME | NOT NULL |

#### `EloHistory` → `elo_history`
Append-only log of every Elo-affecting attempt.
| Column | Type | Constraint |
|---|---|---|
| `id` | INTEGER | PK, AUTOINCREMENT |
| `puzzleId` | TEXT | NOT NULL |
| `puzzleRating` | INTEGER | NOT NULL |
| `eloBefore` / `eloAfter` | INTEGER | NOT NULL |
| `wasCorrect` | BOOL | NOT NULL |
| `at` | DATETIME | NOT NULL |

### Indexes (created in v7)
```sql
idx_attempts_finished_at ON attempts(finished_at)
idx_attempts_round_id    ON attempts(round_id)
idx_attempts_puzzle_id   ON attempts(puzzle_id)
idx_rounds_set_id        ON rounds(set_id)
idx_puzzle_sets_archived_at ON puzzle_sets(archived_at)
```

### Migration strategy
[`MigrationStrategy`](lib/data/database/app_database.dart) with `onCreate` (fresh install) and `onUpgrade` (versioned ladder):

- v2: create `bot_games`
- v3: create `user_states`, `elo_history`, seed default user
- v4: add `userMoveUci` column to `attempts`
- v5: add `isSystem` + `archivedAt` to `puzzle_sets`, seed `'__random_play__'`
- v6: defensive ALTER + re-seed (covers users on broken v5 migrations)
- v7: add the indexes above

When you bump the schema:
1. Increment `schemaVersion` in `AppDatabase`.
2. Add an `if (from < N) { ... }` branch to `onUpgrade`.
3. Add the same DDL to `onCreate` so fresh installs match.
4. Re-run `dart run build_runner build --delete-conflicting-outputs`.

### Foreign-key relationships
```
puzzle_themes.puzzle_id      → puzzles.id
puzzle_set_items.set_id      → puzzle_sets.id
puzzle_set_items.puzzle_id   → puzzles.id   (logical only; not enforced)
rounds.set_id                → puzzle_sets.id
attempts.round_id            → rounds.id
attempts.puzzle_id           → puzzles.id   (logical only)
elo_history.puzzle_id        → puzzles.id   (logical only)
```

### `databaseProvider`
```dart
final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase.openOnDevice();
  ref.onDispose(db.close);
  return db;
});
```
`BackupService.importFrom()` calls `ref.invalidate(databaseProvider)` to swap the underlying file at runtime.

---

## 3. KJERNEALGORITMER

### 3.1 Elo update

[`UserStateRepository.applyAttempt`](lib/data/repositories/user_state_repository.dart) → calls `_calcNewElo`:

```dart
// 3-tier K-factor — early ramp, mid taper, steady-state
final double k;
if (attemptsTotal < 10)       k = 48.0;
else if (attemptsTotal < 50)  k = 32.0;
else                          k = 16.0;

final expected = 1.0 / (1.0 + math.pow(10, (puzzleRating - userElo) / 400.0));
final actual   = isCorrect ? 1.0 : 0.0;
final delta    = (k * (actual - expected)).round();
return (userElo + delta).clamp(400, 3200);
```

**Hint penalty:** if `hintsUsed > 0 && isCorrect`, the new Elo equals the old Elo (no reward, no punishment). The attempt is still logged to `elo_history` with `eloBefore == eloAfter` so the Elo log shows the event but no movement.

**Default seed:** Elo `1500`. Onboarding can override via the level-picker (5 choices: 800/1200/1500/1800/2100).

**Bounds:** `[400, 3200]`.

**Where it's called from:**
- `/random` screen ([solve_screen.dart](lib/features/solve/solve_screen.dart) `onResult`) — the only flow that updates Elo. Set-based rounds intentionally do not, because sets are pre-filtered by rating and would skew the rating.

**EloDelta** is returned to UI and pushed onto the rolling 12-entry strip below the board.

### 3.2 Strengths / weaknesses (rating-bucketed)

**Pipeline:**
1. SQL — [`StatsRepository.globalThemesEnriched(userElo:)`](lib/data/repositories/stats_repository.dart):
   ```sql
   SELECT pt.theme,
     ((p.rating / 200) * 200) AS bucket_min,
     COUNT(*) AS total,
     SUM(CASE WHEN a.is_correct = 1 AND a.hints_used = 0 THEN 1 ELSE 0 END) AS correct,
     AVG(a.time_ms) AS avg_time_ms,
     SUM(CASE WHEN a.finished_at >= ? THEN 1 ELSE 0 END) AS recent_total,
     SUM(CASE WHEN a.finished_at >= ? AND a.is_correct = 1 AND a.hints_used = 0 THEN 1 ELSE 0 END) AS recent_correct,
     SUM(CASE WHEN a.finished_at >= ? AND a.finished_at < ? THEN 1 ELSE 0 END) AS prev_total,
     SUM(CASE WHEN a.finished_at >= ? AND a.finished_at < ? AND a.is_correct = 1 AND a.hints_used = 0 THEN 1 ELSE 0 END) AS prev_correct
   FROM attempts a
   JOIN puzzle_themes pt ON pt.puzzle_id = a.puzzle_id
   JOIN puzzles p        ON p.id        = a.puzzle_id
   WHERE pt.theme NOT IN (<kNonTacticalThemes>)
   GROUP BY pt.theme, bucket_min
   ```
   Recent = last 30 days. Prev = 30-60 days ago. Bucket size = 200 Elo.

2. Aggregation — [`EnrichedThemeStats.fromBuckets`](lib/data/models/enriched_theme_stats.dart):
   ```dart
   final sigma = 200.0;
   double weightFor(int bucketCenter) {
     final d = (bucketCenter - userElo) / sigma;
     return math.exp(-d * d);              // Gaussian, σ = 200
   }

   wTotal       = Σ weight × bucket.total
   wCorrect     = Σ weight × bucket.correct
   wRecentTotal = Σ weight × bucket.recentTotal
   wRecentCorrect = Σ weight × bucket.recentCorrect

   wilsonLifetime = wilsonLowerBoundFractional(wCorrect, wTotal)
   wilsonRecent   = wilsonLowerBoundFractional(wRecentCorrect, wRecentTotal)

   effectiveAccuracy = 0.3 × wilsonLifetime + 0.7 × wilsonRecent
                       (skewed to recent so Elo-climb shifts shape fast)

   effectiveSampleSize = wTotal       // used for confidence
   confidence = (n < 5) ? low : (n < 20) ? medium : high
   ```
   Wilson lower-bound formula:
   ```
   p   = correct / total
   denom  = 1 + z²/n              (z = 1.96 for 95% CI)
   center = (p + z²/(2n)) / denom
   margin = z × sqrt((p(1-p) + z²/(4n)) / n) / denom
   wilson = clamp(center - margin, 0, 1)
   ```
   Implemented as `_wilsonLowerBoundFractional` so non-integer weighted samples work.

3. Speed-and-trend layer — [`WeaknessAnalyzer.analyze`](lib/data/models/weakness_entry.dart):
   ```dart
   relSpeed     = globalMedianMs / theme.averageTimeMs   // >1 = faster than baseline
   speedPenalty = clamp(1 - relSpeed, 0, 1)
   weaknessScore = 0.7 × (1 - effectiveAccuracy) + 0.3 × speedPenalty
   ```
   Ranked descending. Top 3-6 (mode-dependent) feed the recommender's exploit pool.

4. Trend detection — `_trendFor(recent vs prev, threshold ±10%)` returns `improving | stable | declining`.

5. Phase radar data — separate query [`StatsRepository.phaseStats()`](lib/data/repositories/stats_repository.dart) returns three `PhasePoint`s (`opening`, `middlegame`, `endgame`) each with `total`, `correct`, `averageTimeMs`. Rendered by [`PhaseRadar`](lib/features/strengths/widgets/phase_radar.dart) which computes accuracy = `correct/total` and plots three vertices on a triangle (top = opening, bottom-left = middlegame, bottom-right = endgame). Concentric grid at 25/50/75/100%.

### 3.3 Recommendation modes

[`RecommendationMode`](lib/services/training_recommender.dart):

| Mode | minAttempts | drill / explore | Drill-pool size | Unattempted-seed count |
|---|---|---|---|---|
| Calibration | 0 | 30/70 | 3 | 13 |
| Discovery | 50 | 50/50 | 3 | 2 |
| Refinement | 150 | 70/30 | 4 | 1 |
| Mastery | 400 | 85/15 | 6 | 0 |

Selected by `RecommendationMode.forAttempts(user.attemptsTotal)`. Persisted in the set name (`Recommended · Calibration · May 8`).

`buildRecommended(targetSize: 150)` flow:
1. Pull `WeaknessAnalyzer` output, with current Elo.
2. **Drill pool**: top N high/medium-confidence themes (N = `mode.exploitPoolSize`).
3. **Explore pool**:
   - Calibration: 13 baseline themes prioritising never-attempted ones.
   - Else: top low-confidence attempted themes + `mode.unattemptedSeedCount` unattempted seeds from the **extended baseline** (25 themes — see `_extendedBaselineThemes`).
4. Pick `targetSize × exploitRatio` puzzles in the drill pool, the rest in explore. Both use the same `[user.elo - 200, user.elo + 100]` band, biased to harder puzzles.
5. Backfill from comfort-zone unfiltered if either pool is short.
6. `Set.themes` = drill ∪ explore ∪ derived (top-15 most frequent in Calibration, top-6 elsewhere), filtered to `kCuratedTrainingThemes` so the displayed list is meaningful training categories only.

### 3.4 Mastery detection

**There is no hardcoded mastery threshold in the data layer.** [`RoundComparison`](lib/data/models/round_comparison.dart) returns deltas only:
```dart
timeSavings    = previous.totalTime - current.totalTime
speedupPercent = (prev.medianTime - current.medianTime) / prev.medianTime * 100
accuracyDelta  = current.accuracy - previous.accuracy
medianDelta    = previous.medianTime - current.medianTime
```
The 90 % accuracy / 35 % speedup numbers exist only as **copy strings** in the recommended-set explainer dialog. If you want a real "set is mastered" gate, add it in `set_detail_screen.dart` reading `RoundComparison.speedupPercent >= 35 && current.accuracy >= 0.9`.

### 3.5 Random puzzle selection

[`puzzle_repository.dart`](lib/data/repositories/puzzle_repository.dart) `eloRandomPuzzleProvider`:
```dart
min = (user.elo - 100).clamp(600, 2900)
max = (user.elo + 100).clamp(700, 3000)
SELECT * FROM puzzles WHERE rating BETWEEN min AND max ORDER BY RANDOM() LIMIT 1
```
Falls back to global random if the band is empty. Invalidated on screen mount in `solve_screen.dart` `initState` so the user always gets a fresh puzzle.

### 3.6 Set-based puzzle order

`PuzzleSetItems.position` is monotonic 0..size-1, set at creation time in [`SetRepository.createWithIds`](lib/data/repositories/set_repository.dart). `Round.currentPosition` is the cursor; the session screen advances it on each attempt and persists in [`RoundRepository.recordAttempt`](lib/data/repositories/round_repository.dart). On the second-and-later round of the same set, the same `position`s are replayed in identical order — that's the Woodpecker mechanic.

### 3.7 Puzzle solving control loop

[`SolveBoardController`](lib/features/solve/solve_board_controller.dart) is the brain:
- Plays the setup move (the first UCI in `puzzle.uciMoves`) after a 150 ms delay.
- Tracks `expectedMoveIndex` through the solution line.
- On `MoveCheck.wrong`: sets `SolveStatus.wrong`, plays user move, queues a Stockfish reply via `_replyAndEnterExploring`, then transitions to `SolveStatus.exploring` so the user can keep playing the position freely.
- On `MoveCheck.correctAndDone`: status `solved`, plays subtle correct chime 220ms after the move sound, fires `onResult`.
- `revealSolution()` plays the entire solution as an animated replay (used by "Show solution" button).
- Sound timing: user moves are instant (anim duration = 0), opponent / replay moves are delayed to land at animation end.

### 3.8 Bot game control loop

[`BotGameController`](lib/features/bot/bot_controller.dart):
- Bot move delay: 400 ms (in `_botMoveDelay`).
- `requestHint()` / `takeback()` respect the game's `BotAssistMode` (Challenge/Friendly/Assisted = 3/2/1 crowns).
- `_history` stack is pushed before every move so takeback can pop until it's the user's turn again.
- Stockfish strength is set in `_bootstrap()` via `setElo` (UCI ≥ 1320) or `setSkillLevel` (sub-1320 fallback).
- `BotGameOutcome` outcomes (`userWon`/`botWon`/`draw`/`resigned`) trigger correct/wrong sounds delayed 600 ms so they don't overlap the last move.

---

## 4. FORRETNINGSLOGIKK OG TILGANGSKONTROLL (Pro / Freemium)

### Source of truth: `lib/services/pro_status.dart`

Constants:
```dart
const String kProProductId = 'pro_lifetime';   // Google Play product ID
const bool kDevForceLocked = false;            // Set true to preview as free user
const _kPaidProKey            = 'pro_paid';
const _kGrandfatheredKey      = 'pro_grandfathered';
const _kGrandfatherAppliedKey = 'pro_grandfather_applied';
```

`ProStatusNotifier.build()` resolution order:
1. `kDevForceLocked` → always `locked` (skips prefs, used to verify paywall flows).
2. `kDebugMode` → `ProSource.debugBuild` (Pro for free).
3. SharedPreferences:
   - First-ever run with existing data (`attempts > 0` OR `sets.isNotEmpty`) → set `pro_grandfathered = true`. **Grandfathering only fires once**, controlled by `pro_grandfather_applied`.
   - `pro_grandfathered` → `ProSource.grandfathered`.
   - `pro_paid` → `ProSource.paid`.
4. Default → `locked`.

`InAppPurchase.instance.purchaseStream` is subscribed during `_bootstrap`. On `purchased` or `restored` it sets `pro_paid = true` and updates state. `restorePurchases()` runs once on cold start.

### Paid feature catalogue

| Feature | Free | Pro | Gating site |
|---|---|---|---|
| Random puzzles | ∞ | ∞ | — |
| Custom sets (active) | 1 | ∞ | [`set_builder_screen.dart`](lib/features/set_builder/set_builder_screen.dart) `_createSet` |
| Recommended training | 1 lifetime | ∞ | [`set_builder_screen.dart`](lib/features/set_builder/set_builder_screen.dart) `_buildRecommended` (checks `name.startsWith('Recommended ·')`) |
| Tactical themes | 11 free + lock-icon for the rest | All | `_themeChip` in builder; long-press shows `ThemeExplainerSheet` regardless of lock |
| Bot games | All 7 levels + all 3 assistance modes | Same | Intentionally not gated |
| Strengths analysis | Sneak-peek with blurred bars | Full | [`strengths_screen.dart`](lib/features/strengths/strengths_screen.dart) `_StrengthsSneakPeek` |
| Weakness drill | Locked | Available | [`drill_screen.dart`](lib/features/progression/drill_screen.dart) wrapped in `ProGate` |
| Elo history | Last 30 days + banner | Unlimited | [`elo_history_screen.dart`](lib/features/elo_history/elo_history_screen.dart) `_ClippedHistoryBanner` |
| Backup / Import | Locked | Available | [`settings_screen.dart`](lib/features/settings/settings_screen.dart) ListTiles around `_exportData` / `_importData` |
| Board themes | Default only | All 23 | **Not yet wired** — see Technical debt |
| Confetti on big rounds | On (toggleable) | On | Free — listed as Pro flavour but not gated |

### Where to hook IAP for production

1. **List the product in Play Console**: name `pro_lifetime`, type "managed product" (non-consumable), price 149 NOK (or whatever you set).
2. **License testers** in Play Console → Setup → License testing — add tester Google emails.
3. **Internal testing track** in Play Console → Testing → Internal testing — upload a signed release AAB.
4. **No code change needed for store-side**: `pro_status.dart` already calls `InAppPurchase.instance.queryProductDetails({kProProductId})` and `buyNonConsumable(...)`. The product ID just has to exist on the store.
5. **Apple/iOS** is intentionally not wired. When/if iOS launches: `InAppPurchase.instance.completePurchase(p)` is already called in `_handlePurchases`, which is the iOS server-receipt step on Apple, so the same code works.

### Paywall UX

- `PaywallScreen.show(context, headline:, subhead:)` is a fullscreen-dialog modal. Auto-dismisses when `proStatusProvider.isPro` flips to true (via `ref.listen`).
- `ProGate({featureTitle, featureBlurb, child})` replaces the screen body for non-Pro users with an icon + title + Unlock button.
- `ProBadge({compact: bool})` is the gold pill used inline.
- Paywall content is hardcoded in `paywall_screen.dart` `_Feature(...)` rows. Update these when the plan changes.

---

## 5. ENGINE OG ASSETS

### Stockfish

[`StockfishService`](lib/services/stockfish_service.dart) wraps `multistockfish`:

- **Lazy start**: `start()` returns a shared `_startFuture` to prevent concurrent inits (race-safe). Resets `_startFuture` to null on error so retries unblock.
- **State**: polls `Stockfish.instance.state.value` against `StockfishState.ready`.
- **Strength**:
  - For `BotLevel.elo != null` (Casual+): `setoption name UCI_LimitStrength value true` + `setoption name UCI_Elo value <elo>`.
  - For Newcomer/Beginner/Novice: `setoption name UCI_LimitStrength value false` + `setoption name Skill Level value <0..20>` + reduced depth.
- **Per-call**: `bestMove(fen:, depth:)` issues `position fen <fen>` then `go depth <N>`. Reads stdout regex-line-by-line, completes when a `bestmove` line arrives. 30 s timeout.
- **Serialization**: `_serialize<T>(fn)` chains every engine call through `_serial` so two `go`s never overlap. Crucial — multistockfish's stdin would otherwise interleave commands.

### Sound

[`SoundService`](lib/services/sound_service.dart):
- `SoundEffect` enum carries `assetPath` and `volume` (default 1.0; correct/wrong = 0.35 to feel subtle).
- `warmup()` once, on app start. Preloads each effect with `setSource(AssetSource(...))` and `setVolume(...)` so the first user move is not a cold-decode.
- `play()` seeks to zero and resumes (low-latency replay).
- `playAfter(effect, delay)` schedules via `Future.delayed`.
- Cold-path fallback if warmup didn't run: a fresh `AudioPlayer` per call, also volume-applied.

### Puzzle library

- Source: Lichess open puzzle dump (https://database.lichess.org/) → CSV → parsed by [`tool/build_puzzle_db.dart`](tool/build_puzzle_db.dart).
- Tool produces `assets/db/puzzles.sqlite` with the `puzzles` and `puzzle_themes` tables populated. Run it locally during development; the result is shipped in the APK.
- Run instructions live in `tool/build_puzzle_db.dart` header comments — typically:
  ```
  dart run tool/build_puzzle_db.dart <path-to-lichess-db.csv>
  ```
- App-side parsing: [`PuzzleRepository.getById`](lib/data/repositories/puzzle_repository.dart) hydrates a `Puzzle` row + joins themes via a separate query. UCI moves are split on spaces from `Puzzles.moves`.

### Ensure-seeded fallback

`PuzzleRepository.ensureSeeded()` injects a single mate-in-2 puzzle (id `'00sHx'`, rating 1760) on cold start when the table is empty. Also deletes a corrupt legacy puzzle (id `'0Z2D0'`) if present. This is the bandaid that keeps /random alive when the bundled asset is missing.

---

## 6. TEKNISK GJELD OG "VIBE-CHECK"

Honest list of where the codebase has shortcuts you should know about:

### Architecture

- **`features/home/home_screen.dart` is over 900 lines.** A monolith with `_HeroStats`, `_ResumeBotCard`, `_ContinueTrainingCard`, `_QuickActionsGrid`, `_SetTile`, `_SectionLabel`, `_StatPill`, `_ContinueTrainingCard`, `_QuickAction`, `_InsightsGrid`, `_MySetsHeader`, `_EmptySetsHint` all inline + a top-level `_showSetActions` function. Extract into smaller files when you next touch it.
- **`features/strengths/strengths_screen.dart` is over 800 lines** with 12+ private widgets. Same pattern.
- **`features/set_detail/set_detail_screen.dart`** has a top-level `_showAllThemes` function next to 7 widgets — file boundaries are loose. The handover-document writer (this AI) stuck close to existing patterns to avoid risk.
- **`features/solve/solve_board_widget.dart`** — `LastMoveSquareBorder` is a custom-painted overlay because chessground's Shape API only does circles and arrows. Brittle if chessground changes its board sizing math.

### Database / SQL

- **`puzzle_set_items.puzzle_id` has no FK.** Deleting a puzzle from `puzzles` would orphan rows. Acceptable today because the puzzle library is read-only, but if you ever rebuild the bundled DB watch for stale references.
- **`globalThemesEnriched` SQL is heavy** — JOIN of attempts × puzzle_themes × puzzles, GROUP BY (theme, bucket), with multiple CASE-WHEN aggregates. Indexed by `idx_attempts_finished_at`/`puzzle_id`. At ~5k attempts the query is ~80 ms on Pixel 7a; at ~50k it's ~600 ms. Cache the result with a Riverpod `keepAlive: true` if you start seeing scroll jank on Strengths.
- **No DB encryption.** Backup files are plain SQLite — anyone who gets the file sees all attempts. Probably fine for chess training, but flag it before shipping anything more sensitive.
- **Migration v6 is a defensive band-aid** for users on broken v5 (some had `is_system` or `archived_at` missing). Keep the column-presence check forever — removing it could break those legacy installs.

### Services

- **`StockfishService` 30-second timeout** — if Stockfish hangs (rare but possible on cheap devices), the future just throws and the bot game falls back to "Engine error" → draw. Could be more graceful with a retry.
- **`SoundService` cold-path** keeps creating `AudioPlayer`s per missed effect and never disposes them on the failure branch. Memory leak only if many distinct effects fail to warm up; in practice all 7 succeed.
- **`pro_status.dart` `_handlePurchases`** does no server-side receipt verification. A determined user could spoof Pro by patching SharedPreferences. Acceptable for a 149-NOK one-time-purchase indie launch — escalate to server-side validation if the install base grows.
- **`stats_repository.dart` Wilson Z-score is fixed at 1.96** (95 % CI). Effective sample-size confidence buckets (5, 20) were inherited from the pre-bucketing version and may need tuning now that the metric represents weighted samples.

### UI / behaviour

- **Off-screen Chessboard warmup in `main.dart`** sits at `(-2000, -2000)` with size 320. Janky workaround for chessground's first-render shader compile. Works but feels gross — replace if Flutter ever exposes a proper `precacheRender` hook.
- **`solve_screen.dart` `_eloLog` is in-memory only** — closing the app loses the chip strip. By design (it's an ephemeral session log) but document it because users will ask.
- **`_StrengthsSneakPeek`'s sample placeholders** (`_LockedBar(accuracy: i == 0 ? 0.55 : 0.65, ...)`) are hardcoded fake numbers when the user has zero high-confidence themes. Don't read those as truth.
- **Pro gating on board themes is not implemented.** The plan promises 23 themes Pro-locked but [`board_appearance.dart`](lib/services/board_appearance.dart) and the Settings pickers still let everyone pick freely. TODO before launch.
- **`_calibrationBaselineThemes` and `_extendedBaselineThemes`** are constants in `training_recommender.dart`. They should arguably live in `tactical_themes.dart` next to `kCuratedTrainingThemes` to keep all theme constants in one place.
- **Set rename / theme picker** in builder uses a `Material+InkWell+StadiumBorder` custom chip because Flutter's `FilterChip` swallows long-press for its built-in tooltip. If Flutter fixes this, replace with the standard chip.

### Testing

- **`test/` directory is empty.** No widget tests, no integration tests, no unit tests on the recommender / Wilson math. Add at minimum:
  - Unit tests on `EnrichedThemeStats.fromBuckets` (verify weighting falloff by Elo distance).
  - Unit tests on `_calcNewElo` (K-factor steps, hint penalty).
  - Golden test on `PaywallScreen` (so layout changes don't break the buy CTA).

### Build

- **`flutter install --debug` uninstalls before installing**, wiping app data. Beta testers need to know not to use `flutter install` for upgrades — sideload via Files app instead, or use `flutter run`. Document in the README before handing out to testers.
- **No CI.** No GitHub Actions, no automated APK builds. Manual `flutter build apk --debug` only.

---

## 7. MELDING TIL NESTE AI

You are taking over a Flutter chess training app called **Woodpecker Chess**. Read this entire file before touching anything — it is the only context handover.

### Build your context in this order

1. **`pubspec.yaml`** — confirm dependency versions match what this doc claims.
2. **`lib/main.dart`** + **`lib/router.dart`** — see what screens exist and how the app boots.
3. **`lib/data/database/app_database.dart`** — the schema is the contract. Everything else flows from these tables.
4. **`lib/services/training_recommender.dart`** + **`lib/data/models/enriched_theme_stats.dart`** + **`lib/data/models/weakness_entry.dart`** — the analytics core. **Read these in full** before changing any recommender behaviour. The bucketed-Wilson-with-Gaussian-Elo-weighting is the most non-obvious piece of the codebase — it's not standard ML, it's applied stats, and the math is correct as written.
5. **`lib/services/pro_status.dart`** — gating is checked everywhere. Trace one feature (e.g. Strengths) to see the pattern.
6. **`lib/features/solve/solve_board_controller.dart`** — the puzzle solving state machine. The key insight is that `wrong` moves enter "exploring" mode (free play of the position) instead of stopping, so the user can see what happens. Match this pattern when adding new flows.

### Rules of thumb specific to this codebase

- **Never delete `__random_play__` or `__random_round__`** — the system rows that own random-puzzle attempts. `ResetService` preserves them; mirror that if you write new reset logic.
- **Sound `SoundEffect.correct/wrong` are gated to 0.35 volume on purpose.** The user explicitly asked for them to be subtle. Don't bump them.
- **Animation timing**: user moves play their sound at `Duration.zero`, opponent / replay moves at `animDuration()`. Don't break that asymmetry — it's why the app feels responsive on user input but synchronised on bot input.
- **Em-dashes are forbidden in user-facing strings.** The user dislikes them; a sed-sweep was done to remove all `—` in `lib/`. Use `-` instead.
- **All Norwegian copy in this conversation is the user's voice. The app UI is English-only.** Don't introduce Norwegian strings into the codebase.
- **`flutter install` wipes data.** Build APKs with `flutter build apk --debug` and let the user sideload them, or use `flutter run` with hot restart. **Never** chain `flutter build apk && flutter install` without warning the user.
- **Drift codegen**: when you change a table, run `dart run build_runner build --delete-conflicting-outputs`. Commit `app_database.g.dart` alongside the source.
- **`kDevForceLocked = false`** in production. If you flip it to `true` for testing, flip it back before any release build.
- **The Pro paywall content is hardcoded.** When you add a new Pro feature, also add a `_Feature(...)` row in `paywall_screen.dart` so the buyer sees what they're getting.

### How to verify a non-trivial change

1. `flutter analyze` — no errors. Warnings about unused imports while you wire something up are normal; clean them before committing.
2. `flutter build apk --debug` — must succeed.
3. Manually test the relevant screen on a real device. The off-screen Chessboard warmup means emulators behave differently; trust the Pixel.
4. If you touch the recommender or Wilson math, hand-calculate one case to verify (the Anna-1100→1500 walkthrough in the conversation is one such case).

### What the user values

- **Data-driven justifications.** "We do X because Wilson lower-bound, Gaussian σ=200, 30/70 recent-bias" plays better than "we do X because it feels right". When the user asks why a number is what it is, give them the formula.
- **Honest tech-debt assessments.** When a shortcut was taken, say so. When something is brittle, flag it. The user has paid for premium polish in conversation tone — match that with rigour.
- **Short text, dense information.** Don't pad. The user reads carefully and dislikes filler.
- **Norwegian replies are fine** if the user writes in Norwegian. Mirror the language they choose.

Good luck. The codebase is in better shape than the line-count suggests; the analytics layer in particular is genuinely thoughtful and worth preserving.

---

## APPENDIX A — ROUTE TABLE

Defined in [`lib/router.dart`](lib/router.dart). Initial location: `/`.

| Path | Builder | Path params / extra |
|---|---|---|
| `/` | `HomeScreen` | — |
| `/random` | `SolveScreen` | — |
| `/elo-history` | `EloHistoryScreen` | — |
| `/progression` | `GlobalProgressionScreen` | — |
| `/strengths` | `StrengthsScreen` | — |
| `/settings` | `SettingsScreen` | — |
| `/about` | `AboutScreen` | — |
| `/method` | `WoodpeckerMethodScreen` | — |
| `/puzzles/:puzzleId` | `PuzzlePreviewScreen` | `puzzleId` |
| `/sets/new` | `SetBuilderScreen` | — |
| `/archived` | `ArchivedSetsScreen` | — |
| `/play-bot` | `BotSetupScreen` | — |
| `/play-bot/game` | `BotGameScreen` | `extra: BotConfig` OR `extra: ({BotConfig config, BotGameSnapshot? snapshot})` for resume |
| `/sets/:setId` | `SetDetailScreen` | `setId` |
| `/sets/:setId/rounds/:roundId` | `SessionScreen` | `setId`, `roundId` |
| `/sets/:setId/progression` | `ProgressionScreen` | `setId` |
| `/sets/:setId/drill` | `DrillScreen` | `setId` |

The `/play-bot/game` route uses Dart record types in `extra`. If you change the BotConfig type or add new resume modes, update the type-check ladder in [`router.dart`](lib/router.dart) line 56-65.

`PaywallScreen` is **not** routed — it is pushed via `PaywallScreen.show(context, headline:, subhead:)` as a fullscreen `MaterialPageRoute` so deep-linking can't bypass it.

The `OnboardingScreen` is also not routed — pushed as a fullscreen dialog by `_HomeScreenState._maybeShowOnboarding` if `onboardedProvider` is false.

---

## APPENDIX B — RIVERPOD PROVIDER CATALOGUE

Every named provider in `lib/data/repositories/` and `lib/services/`. Use `ref.watch` for UI, `ref.read` for one-shot actions, `ref.invalidate(provider)` to force refresh.

### Repositories (Provider — singletons)
- `databaseProvider` — `AppDatabase`
- `puzzleRepositoryProvider` — `PuzzleRepository`
- `setRepositoryProvider` — `SetRepository`
- `roundRepositoryProvider` — `RoundRepository`
- `statsRepositoryProvider` — `StatsRepository`
- `userStateRepositoryProvider` — `UserStateRepository`
- `botGameRepositoryProvider` — `BotGameRepository`

### Services (Provider — singletons)
- `stockfishServiceProvider` — `StockfishService`
- `soundServiceProvider` — `SoundService`
- `backupServiceProvider` — `BackupService`
- `resetServiceProvider` — `ResetService`
- `trainingRecommenderProvider` — `TrainingRecommender`
- `sharedPreferencesProvider` — `SharedPreferences` (FutureProvider)
- `appPreferencesProvider` — `AppPreferences` (FutureProvider)

### User state (live)
- `userStateProvider` — `StreamProvider<UserState>` — Elo, attemptsTotal
- `proStatusProvider` — `NotifierProvider<ProStatusNotifier, ProStatus>` — Pro entitlement
- `isProProvider` — `Provider<bool>` — convenience boolean
- `proProductProvider` — `FutureProvider<ProductDetails?>` — IAP product info from Play

### Preferences (NotifierProvider, all writeable via `.notifier.set(...)`)
- `mutedProvider` — `bool`, default false
- `themeModeProvider` — `ThemeMode`, default system
- `onboardedProvider` — `bool`, default true
- `autoAdvanceProvider` — `bool`, default false
- `showCoordinatesProvider` — `bool`, default true
- `showLegalMovesProvider` — `bool`, default true
- `confettiEnabledProvider` — `bool`, default true
- `autoFlipBoardProvider` — `bool`, default true
- `hintsEnabledProvider` — `bool`, default true
- `animationSpeedProvider` — `AnimationSpeed`, default normal
- `boardThemeProvider` — `BoardTheme` (in [board_appearance.dart](lib/services/board_appearance.dart))
- `pieceSetProvider` — `PieceSet`

### Puzzle / set queries
- `puzzleSeedProvider` — `FutureProvider<void>` — runs `ensureSeeded` once on cold start
- `currentPuzzleProvider` — `FutureProvider<Puzzle>` (legacy, prefer eloRandom)
- `eloRandomPuzzleProvider` — `FutureProvider<Puzzle>` — drives /random
- `puzzleByIdProvider` — `FutureProvider.family<Puzzle, String>`
- `puzzleExampleForThemeProvider` — `FutureProvider.family<Puzzle?, String>` — used by ThemeExplainerSheet
- `allSetsProvider` — `FutureProvider<List<PuzzleSet>>` — non-archived, non-system
- `archivedSetsProvider` — `FutureProvider<List<PuzzleSet>>`
- `setByIdProvider` — `FutureProvider.family<PuzzleSet?, String>`

### Round / session queries
- `roundsForSetProvider` — `FutureProvider.family<List<Round>, String>`
- `roundStatsProvider` — `FutureProvider.family<RoundStats, String>` — by roundId
- `setRoundsStatsProvider` — `FutureProvider.family<List<RoundStats>, String>` — all rounds in a set
- `roundComparisonProvider` — `FutureProvider.family<RoundComparison?, String>` — current vs previous
- `recentSetActivityProvider` — `FutureProvider<RecentSetActivity?>` — drives Continue Training card
- `lastAttemptForPuzzleProvider` — `FutureProvider.family<AttemptRow?, String>`

### Stats
- `globalStatsProvider` — `FutureProvider<GlobalStats>` — total attempts/correct/time
- `globalThemeStatsProvider` — `FutureProvider<List<ThemeStats>>` — flat per-theme list
- `enrichedThemeStatsProvider` — `FutureProvider<List<EnrichedThemeStats>>` — bucketed (takes `userElo`)
- `globalMedianTimeProvider` — `FutureProvider<int>` — median solve ms across all attempts
- `phaseStatsProvider` — `FutureProvider<PhaseStats>` — opening/middlegame/endgame triple
- `themeStatsProvider` — `FutureProvider.family<List<ThemeStats>, String>` — per-set
- `weaknessAnalysisProvider` — `FutureProvider<List<WeaknessEntry>>` — combines enriched + median + globalStats
- `outliersProvider` — `FutureProvider.family<List<OutlierAttempt>, ({String setId, int roundNumber})>`
- `problemPuzzlesProvider` — `FutureProvider.family<List<ProblemPuzzle>, String>` — per-set repeated failures, drives drill
- `setActivitiesProvider` — `FutureProvider<List<SetActivity>>`
- `dailyActivityProvider` — `FutureProvider<List<DailyActivity>>` — 30-day chart
- `eloHistoryProvider` — `FutureProvider<List<EloHistoryEntry>>`
- `allTacticalThemesProvider` — `FutureProvider<List<String>>` — every theme that exists in the bundled DB

### Bot
- `activeBotGameProvider` — `StreamProvider<BotGameSnapshot?>` — drives "Resume vs bot" card

When you add a new feature, prefer creating a `FutureProvider.family` keyed by id over loading raw rows in widget code — it lets Riverpod cache and dedupe.

---

## APPENDIX C — APP PREFERENCES STORAGE

All stored in `SharedPreferences` via [`AppPreferences`](lib/services/app_preferences.dart). Keys are namespaced `app.*` and `pro.*` (Pro keys live in `pro_status.dart`).

| Key | Type | Default | Provider |
|---|---|---|---|
| `app.muted` | bool | false | `mutedProvider` |
| `app.themeMode` | string `'light'`/`'dark'`/`'system'` | system | `themeModeProvider` |
| `app.onboarded` | bool | false | `onboardedProvider` (UI defaults to true to avoid flash) |
| `app.autoAdvance` | bool | false | `autoAdvanceProvider` |
| `app.boardTheme` | string (BoardTheme.name) | first in list | `boardThemeProvider` |
| `app.pieceSet` | string (PieceSet.name) | cburnett | `pieceSetProvider` |
| `app.showCoordinates` | bool | true | `showCoordinatesProvider` |
| `app.showLegalMoves` | bool | true | `showLegalMovesProvider` |
| `app.animationSpeed` | string `'off'/'fast'/'normal'/'slow'` | normal | `animationSpeedProvider` |
| `app.confetti` | bool | true | `confettiEnabledProvider` |
| `app.autoFlipBoard` | bool | true | `autoFlipBoardProvider` |
| `app.hintsEnabled` | bool | true | `hintsEnabledProvider` |
| `pro_paid` | bool | false | `proStatusProvider` (set on IAP confirmation) |
| `pro_grandfathered` | bool | false | `proStatusProvider` (set once on first run if user has data) |
| `pro_grandfather_applied` | bool | false | `proStatusProvider` (so the grandfather check only runs once) |

`AnimationSpeed` enum:

| Name | Duration | Label |
|---|---|---|
| `off` | 0 ms | Off |
| `fast` | 350 ms | Fast |
| `normal` | 550 ms | Normal (default) |
| `slow` | 800 ms | Slow |

---

## APPENDIX D — BOT CONFIGURATION

[`BotLevel`](lib/features/bot/bot_config.dart) — 7 levels. Stockfish `UCI_Elo` only goes down to 1320, so sub-1300 levels use `Skill Level` + reduced depth instead.

| Level | UCI_Elo | Skill | Depth | Notes |
|---|---|---|---|---|
| Newcomer | — | 0 | 1 | Picks first legal move-ish |
| Beginner | — | 3 | 3 | Light mistakes |
| Novice | — | 8 | 5 | Casual club beginner |
| Casual | 1320 | — | 8 | UCI_Elo floor |
| Intermediate | 1700 | — | 12 | |
| Advanced | 2100 | — | 16 | |
| Expert | 2400 | — | 20 | Stronger than most users |

[`BotAssistMode`](lib/features/bot/bot_config.dart):

| Mode | Crowns | Hint limit | Takeback limit |
|---|---|---|---|
| Challenge | 3 | 0 | 0 |
| Friendly | 2 | 3 | 3 |
| Assisted | 1 | unlimited (-1) | unlimited (-1) |

Default = Friendly. `BotConfig.assistMode` is passed to `BotGameController`.

`BotColor`: `white`, `black`, `random` (resolved at game-start in `bot_setup_screen`).

---

## APPENDIX E — STATUS ENUMS

### `SolveStatus` ([solve_state.dart](lib/features/solve/solve_state.dart))
- `loadingSetup` — initial 150 ms before the puzzle's first move plays
- `playing` — user is solving
- `evaluating` — currently unused (legacy from before the always-show-move pattern)
- `almostBest` — currently unused
- `inaccuracy` — currently unused
- `wrong` — user played a wrong move (then transitions to `exploring` after Stockfish reply)
- `solved` — user completed the line
- `revealed` — `revealSolution()` is animating the line
- `exploring` — free-play after a wrong move; user can play any moves, Stockfish responds

### `BotGameStatus` ([bot_controller.dart](lib/features/bot/bot_controller.dart))
- `thinking` — engine is computing
- `awaitingUser` — user's turn
- `finished` — game over (check `outcome`)

### `BotGameOutcome`
- `userWon`, `botWon`, `draw`, `resigned`

### `RecommendationMode` ([training_recommender.dart](lib/services/training_recommender.dart))
- `calibration` (0+ attempts) — 30/70 drill/explore
- `discovery` (50+) — 50/50
- `refinement` (150+) — 70/30
- `mastery` (400+) — 85/15

### `ConfidenceLevel` ([enriched_theme_stats.dart](lib/data/models/enriched_theme_stats.dart))
- `low` — `effectiveSampleSize < 5`
- `medium` — `5 ≤ effectiveSampleSize < 20`
- `high` — `effectiveSampleSize ≥ 20`

Note: thresholds compare against the **Elo-weighted** sample size, not raw count.

### `TrendDirection`
- `improving` — recent accuracy > prev by >10%
- `stable` — within ±10%
- `declining` — recent accuracy < prev by >10%

Requires both windows to have ≥3 attempts; otherwise stable.

### `ProSource` ([pro_status.dart](lib/services/pro_status.dart))
- `locked`, `debugBuild`, `grandfathered`, `paid`

---

## APPENDIX F — DESIGN TOKENS

### Light scheme (anchor in [main.dart](lib/main.dart) `_lightScheme`)

```
primary:                Color(0xFF1F6948)  // emerald
onPrimary:              Color(0xFFFFFFFF)
primaryContainer:       Color(0xFFA6E0BE)
onPrimaryContainer:     Color(0xFF002915)
secondary:              Color(0xFFB3592E)  // rust
onSecondary:            Color(0xFFFFFFFF)
secondaryContainer:     Color(0xFFFBC9A4)
onSecondaryContainer:   Color(0xFF3D1700)
tertiary:               Color(0xFFC79324)  // amber/gold
onTertiary:             Color(0xFFFFFFFF)
tertiaryContainer:      Color(0xFFFCDF8C)
onTertiaryContainer:    Color(0xFF3F2F00)
error:                  Color(0xFFB3261E)
errorContainer:         Color(0xFFFADCD7)
surface:                Color(0xFFFAF7F2)  // warm cream
onSurface:              Color(0xFF1F1B16)
onSurfaceVariant:       Color(0xFF5A4F40)
surfaceContainerLowest: Color(0xFFFFFFFF)
surfaceContainerLow:    Color(0xFFF4EFE6)
surfaceContainer:       Color(0xFFEDE6D8)
surfaceContainerHigh:   Color(0xFFE5DCC9)
surfaceContainerHighest:Color(0xFFDDD2BC)
outline:                Color(0xFF7B6F5E)
```

Dark scheme is defined directly below in `_darkScheme` — emerald shifts to a brighter mint, rust to coral, etc. Look up the exact dark hex values in [main.dart](lib/main.dart) when changing them.

### Special colours (one-off uses)

- Pro badge gradient: `#E0A82E` → `#C79324` ([pro_lock.dart](lib/widgets/pro_lock.dart))
- Last-move square border: `0xCCFFD600` (yellow, 80% alpha) ([solve_board_widget.dart](lib/features/solve/solve_board_widget.dart) `LastMoveSquareBorder`)
- Bot hint arrow: `0xCC2E7D32` (dark green, 80% alpha) ([bot_game_screen.dart](lib/features/bot/bot_game_screen.dart))
- Crown badge gold: `0xFFE0A82E` ([bot_game_screen.dart](lib/features/bot/bot_game_screen.dart) `_CrownsBadge`)
- Accuracy thresholds (theme heatmap):
  - ≥ 80% → `0xFF2E7D32` (green)
  - ≥ 60% → `0xFFF9A825` (amber)
  - else → `0xFFC62828` (red)
- Elo log strip uses `tertiaryContainer` for +Elo, `errorContainer` for −Elo, `surfaceContainerHigh` for 0/hint.

### Typography
Inter via `google_fonts`. `_buildTheme` clones `textTheme` and tightens `letterSpacing`/sizes on `displayLarge`, `headlineMedium`, `titleLarge`. **Do not call `GoogleFonts.interTextTheme()` in widget builds** — already applied at the theme level in `main.dart`.

### Spacing
- Card border radius: 16
- Dialog/bottom sheet radius: 20
- Chip radius: stadium (`StadiumBorder`)
- Default paddings: 12 / 16 / 20

---

## APPENDIX G — ANDROID MANIFEST & PERMISSIONS

[`android/app/src/main/AndroidManifest.xml`](android/app/src/main/AndroidManifest.xml):

- App label: **Woodpecker**
- Single activity: `MainActivity`, `singleTop` launch mode
- `taskAffinity=""` (no task-stack inheritance)
- Hardware-accelerated rendering enabled
- `windowSoftInputMode="adjustResize"` so the keyboard doesn't cover bottom sheets

**No declared permissions.** The app does not request:
- INTERNET (offline-only — IAP doesn't need explicit declaration with the `in_app_purchase` plugin on modern Android, it auto-injects)
- Storage (uses scoped app-support directory)
- Audio recording
- Camera / Location

If a future feature needs INTERNET (e.g. cloud-sync of attempts), add `<uses-permission android:name="android.permission.INTERNET" />` to the manifest. Google Play Billing currently works because the plugin's manifest merges in `com.android.vending.BILLING`.

`min_sdk_android: 21` (Android 5.0 Lollipop). Lower means a wider audience but `chessground` and `multistockfish` may have implicit higher floors — verify with `flutter build apk --debug` after lowering.

---

## APPENDIX H — BUILD, SIGN, RELEASE

### Debug
```
flutter build apk --debug
# APK at: build/app/outputs/flutter-apk/app-debug.apk
```

Debug builds are signed with the auto-generated debug keystore (`~/.android/debug.keystore`). All testers using the debug build must trust the same keystore — same dev machine = same key, so upgrades preserve data; different machine = signature mismatch and data is wiped on install.

**`flutter install --debug` calls `pm install` with uninstall-first behaviour.** This wipes app data. To preserve user data on upgrade:
- Use `flutter run` (hot restart preserves data)
- Or sideload via Files app on the device (Android upgrades the package and keeps data)

### Release (not yet configured)

Before shipping to Play Console:
1. Generate an upload keystore: `keytool -genkey -v -keystore upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload`
2. Add `android/key.properties` (gitignored):
   ```
   storePassword=...
   keyPassword=...
   keyAlias=upload
   storeFile=/path/to/upload-keystore.jks
   ```
3. Update `android/app/build.gradle` `signingConfigs.release` to read from key.properties.
4. `flutter build appbundle --release` produces `build/app/outputs/bundle/release/app-release.aab` for Play Console upload.
5. **Don't lose the upload keystore.** Without it you cannot ship updates to the same Play listing.

### Versioning
`pubspec.yaml`: `version: 0.1.0+1`. Format `<semver>+<build>`. Increment build number for every Play Store upload.

---

## APPENDIX I — SYSTEM ROWS AND RESET BEHAVIOUR

The DB carries two synthetic rows that must never be deleted:

- `puzzle_sets` row id `'__random_play__'` — `isSystem = true`, `archivedAt = NULL`. Owns all random-puzzle attempts so they show up in the Strengths analysis even though they aren't part of a user-built set.
- `rounds` row id `'__random_round__'` — `setId = '__random_play__'`, `roundNumber = 0`, `completedAt = NULL`. Every random-puzzle attempt is logged here.

[`ResetService.resetUserData()`](lib/services/reset_service.dart) explicitly preserves these:
- `DELETE FROM attempts` — wipes everything (random + sets)
- `DELETE FROM rounds WHERE id != '__random_round__'`
- `DELETE FROM puzzle_set_items WHERE set_id != '__random_play__'`
- `DELETE FROM puzzle_sets WHERE is_system = false`
- `DELETE FROM bot_games`
- `DELETE FROM elo_history`
- `UPDATE user_states SET elo = 1500, attempts_total = 0, calibration_status = 'pending' WHERE id = 'me'`

If you write a new "delete everything" path, mirror this pattern.

---

## APPENDIX J — KNOWN QUIRKS, BUGS, AND EDGE CASES

These are not catastrophic but a new AI must know them.

1. **`SolveStatus.evaluating`, `almostBest`, `inaccuracy` are dead** — unused after the wrong-move flow was reworked to enter `exploring` directly. Don't read them as part of the live state machine. Safe to remove if you do a cleanup pass, but test the controller carefully — they're referenced in `solve_board_widget.dart` `solveStatusFeedback` switch.

2. **/random screen still has comments referencing the old "evaluating" pause** — copy and code drifted. Low risk.

3. **`UserStateRow.calibrationStatus`** is a TEXT column with default `'pending'` from before the level-picker rewrite. No code reads it now. Leave it for schema stability.

4. **`PuzzleSetItems` has no FK on `puzzleId`.** If you ever rebuild `puzzles.sqlite` with different IDs, any existing user's sets will silently point to non-existent rows. The session screen handles missing puzzles by skipping ahead, but you'll want a migration for major puzzle-DB rebuilds.

5. **Bot game's `_history` stack is unbounded.** A 200-move bot game holds 200 entries. Memory is fine (~50 KB worst case), but if you ever support truly long games consider trimming.

6. **Stockfish `_serial` future** chains forever — every call appends. If a `go` future never completes (engine crash before `bestmove`), the rest of the chain hangs. The 30 s timeout mitigates this but doesn't recover the engine. A cold restart of the controller is needed in that pathological case.

7. **No telemetry / crash reporting.** All errors go to `debugPrint` which is silent in release builds. If a beta tester reports "the app froze" you have no logs. Adding `firebase_crashlytics` is a 2-hour add when you decide to.

8. **No internationalization.** Every string is a literal in the widget tree. Adding `flutter_localizations` later means moving ~600 strings into ARB files. Plan for that before shipping non-English markets.

9. **Off-screen Chessboard warmup** at `Positioned(left: -2000, top: -2000)` will fail in Flutter's overlay-clipping mode if you ever set `clipBehavior` differently on the root `MaterialApp`. The widget genuinely renders pixels — that's the whole point — so don't move it inside a clipped parent.

10. **`PaywallScreen.show` uses a fullscreen `MaterialPageRoute` not a modal sheet.** Back-button on Android pops it normally. If you make it a modal route or bottom sheet, ensure `ref.listen` auto-dismiss still triggers.

11. **`_StrengthsSneakPeek` placeholders** — when the user has zero high-confidence themes, two `_LockedBar` widgets show hardcoded fake accuracies (`0.55` and `0.65` weakness, `0.85` and `0.92` strength). These are visual fillers, not real data.

12. **The Strengths "Top 3 strengths" section requires ≥6 high-confidence themes** before showing anything ([strengths_screen.dart](lib/features/strengths/strengths_screen.dart) — `notEnoughForStrengths` flag). Otherwise you'd label one of someone's three themes as both their best and worst, which is false signal.

13. **`_calcNewElo` does not log the K-factor used** — when investigating odd Elo movements in beta, you have to recompute from `attemptsTotal` at the time of attempt. Adding K to `EloHistoryRow` is cheap if it becomes a debugging burden.

14. **The Wilson `z` constant of 1.96** is the 95% CI. Lower (1.0 = ~68%) gives more aggressive weakness flagging; higher (2.58 = 99%) is more conservative. Currently hardcoded; could become a tunable for the recommender.

---

## APPENDIX K — TESTING CHECKLIST FOR ANY NON-TRIVIAL CHANGE

When you change something downstream of multiple features, manually verify:

1. **Onboarding flow**: clear app data → app opens → 3-slide welcome shows → level picker sets Elo → home screen renders.
2. **Random puzzle**: tap Random → puzzle loads → solve correctly → Elo log strip shows +N → tap Next → fresh puzzle.
3. **Custom set creation**: /sets/new → pick rating + theme + size → preview → create → land in /sets/:id.
4. **Round flow**: start round → solve some puzzles correctly + wrong → round summary dialog appears at end with comparison if not first round.
5. **Bot game**: pick level + assistance + colour → play → resign or finish → outcome dialog.
6. **Bot resume**: start bot game → leave to home → "Resume vs X" card appears → tap → game restored.
7. **Strengths screen**: open with low data (sneak peek + locked bars) → open with full Pro (radar + lists).
8. **Drill screen**: open via /sets/:id/drill — Pro-gated; with Pro and a set with failed puzzles, drill plays.
9. **Settings**: every toggle persists across app restart. Recalibrate level shows 5 options, applies cleanly, snackbar confirms.
10. **Backup**: export → file is shared → import the same file back → no errors → original sets preserved.
11. **Reset all**: confirms twice → all sets gone except `__random_play__` system row → Elo back to 1500.
12. **Paywall flow**: flip `kDevForceLocked = true` → second custom set → paywall screen shows feature list + price → tap Restore → snackbar appears.

---

## APPENDIX L — DEVELOPMENT WORKFLOW REFERENCE

### Setup
```
flutter pub get
dart run build_runner build --delete-conflicting-outputs   # only if you change drift schema
```

### Run on connected device
```
flutter run                         # picks first connected device
flutter run -d 36291JEHN05094       # specific device by ID (the user's Pixel 7a)
flutter run -d windows              # desktop preview, limited by stockfish/chessground feature parity
```

### Build only (no install)
```
flutter build apk --debug
# Output: build/app/outputs/flutter-apk/app-debug.apk
```

### Analyze (lint + type-check)
```
flutter analyze
```

### Code generation (after changing Drift schema or any `*.g.dart`-using file)
```
dart run build_runner build --delete-conflicting-outputs
```

### Update puzzle library
```
dart run tool/build_puzzle_db.dart <path-to-lichess-puzzles-csv>
# Writes to assets/db/puzzles.sqlite — re-run pub get / flutter run to bundle
```

### Useful one-liners
```
# Find every TODO in lib/
grep -rn "TODO\|FIXME\|XXX" lib/

# Count lines per feature
find lib/features -name "*.dart" -exec wc -l {} + | sort -n

# List all routes
grep -h "GoRoute" lib/router.dart
```

---

## APPENDIX M — WHAT'S DEFINITELY NEXT

Honest unfinished-work list as of this handover:

1. **Lock board themes & piece sets behind Pro.** Plan promised it; pickers in Settings still show all themes regardless of Pro. Add a `isPro` flag to `BoardTheme` / `PieceSet` and gate the picker tap.
2. **List `pro_lifetime` in Play Console.** Without it, `proProductProvider` returns null and the paywall shows the fallback `'149 kr'` literal instead of the real localised price.
3. **Sign and upload to internal testing track.** Generate upload keystore, configure release signing, build AAB, upload to Play Console.
4. **License-test the IAP flow.** Add tester emails in Play Console → License testing → test "buy Pro" with a real flow that doesn't charge.
5. **No tests exist.** Add at minimum unit tests on `_calcNewElo` and `EnrichedThemeStats.fromBuckets`.
6. **Theme picker explainer.** Long-press already shows `ThemeExplainerSheet` in builder; add the same affordance in the Strengths theme breakdown if it doesn't already (verify when you get there).
7. **`AnimationSpeed.off` may break some animation-driven UX.** Confirm `setupMove` and the bot's first move feel acceptable with `Duration.zero`.
8. **Recommended set "1 free lifetime" gating** uses `name.startsWith('Recommended ·')` — fragile. If a user renames their first recommended set, the gate will let them build another for free. Consider a dedicated DB column.

This is a complete handover. Read it twice before touching code.
