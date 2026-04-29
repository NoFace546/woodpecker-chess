# Puzzle database asset

This folder is where the bundled `puzzles.sqlite` file lives. Until that file is built and placed here, the app falls back to an in-memory seed (defined in `lib/data/repositories/puzzle_repository.dart`).

## Building puzzles.sqlite

1. Download the Lichess puzzle CSV: https://database.lichess.org/lichess_db_puzzle.csv.zst
2. Decompress: `zstd -d lichess_db_puzzle.csv.zst`
3. From the project root, run:
   ```
   dart run tool/build_puzzle_db.dart path/to/lichess_db_puzzle.csv
   ```
4. After the file appears here, add this to `pubspec.yaml` under `flutter:`:
   ```yaml
   assets:
     - assets/db/puzzles.sqlite
   ```
5. Run `flutter pub get` and `flutter run` — the app will copy the asset to local storage on first launch.

The Lichess puzzle dataset is released under CC0; please credit Lichess in the app's About screen as good practice.
