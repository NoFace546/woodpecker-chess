# Woodpecker Chess

A focused chess tactics trainer built around the **Woodpecker Method** by GMs
Axel Smith and Hans Tikkanen — solving the same set of tactical puzzles in
repeated rounds to build fast, automatic pattern recognition.

## What it does

- Adaptive Elo rating that converges quickly using each puzzle's Lichess rating.
- One-tap **Recommended training** — builds a ~150-puzzle set tailored to your
  weaknesses, designed to be drilled across 5–7 rounds.
- Per-set progression tracking: round-by-round accuracy, median solve time,
  35%-faster-than-round-1 mastery detection.
- Strengths & weaknesses analysis by tactical theme.
- Random play tuned to your current Elo.
- Play vs Stockfish, 7 difficulty levels.
- Local backup/restore — your data, your control.

## Privacy

100% local. No accounts, no analytics, no servers, no ads.
[Privacy policy](docs/privacy.md).

## Built with

- [Flutter](https://flutter.dev)
- [Lichess open puzzles](https://database.lichess.org) (CC0)
- [Stockfish](https://stockfishchess.org) (GPL-3.0)
- [chessground](https://pub.dev/packages/chessground) and
  [dartchess](https://pub.dev/packages/dartchess) by Lichess (GPL-3.0)
- [drift](https://pub.dev/packages/drift) for local SQLite storage
- [riverpod](https://pub.dev/packages/flutter_riverpod) for state

## License

GPL-3.0. See [LICENSE](LICENSE).

Because Woodpecker Chess links GPL-3.0 chess libraries from Lichess, the
entire app inherits GPL-3.0. Source must remain available.

## Building from source

```bash
flutter pub get

# Build the puzzle database (one-time):
# Download lichess_db_puzzle.csv.zst from database.lichess.org, decompress, then:
dart run tool/build_puzzle_db.dart path/to/lichess_db_puzzle.csv

# Run on a connected device or emulator:
flutter run

# Build a release APK:
flutter build apk --release
```

The bundled `assets/db/puzzles.sqlite` (~60 MB) ships in the repo for convenience.
