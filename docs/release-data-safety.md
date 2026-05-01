# Release Data Safety Checklist

Use this before every build that testers install over an existing app.

## Never wipe tester data accidentally

- Keep `applicationId = "com.woodpecker.chess"` unchanged.
- Use the same signing key for updates within the same install track.
- Increment `pubspec.yaml` build number before every Play Console upload.
- Prefer Play Internal testing for release builds.
- Prefer `flutter run` for debug builds.
- Avoid `flutter install` when preserving device data matters.
- Do not uninstall the app unless you explicitly want to wipe local data.

## Debug vs release

Android treats apps with the same package name but different signing keys as
different upgrade identities. A release build cannot update a debug-signed app
in place, and Android may require uninstalling first. That deletes app data.

If a tester already has a debug build with data worth keeping, export a backup
from Settings before moving them to a Play-signed release build.

## Database migrations

Before shipping a schema bump:

- Increase `schemaVersion` in `AppDatabase`.
- Add an `onUpgrade` branch for the new version.
- Make fresh install behavior match upgraded install behavior.
- Add or update a migration smoke test under `test/data/database`.
- Verify existing `puzzle_sets`, `rounds`, `attempts`, `user_states`, and
  `elo_history` survive.

For puzzle removals, do not delete puzzle rows from user databases. Mark puzzle
ids in `disabled_puzzles` and filter them out of future random, custom, and
recommended selection. Existing attempts and historical stats should remain
readable.
