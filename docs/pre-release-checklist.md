# Pre-release Checklist

Use this before sharing an APK with testers or uploading a build later.

## 1. Start Clean

- Confirm the worktree is clean or only contains intentional release changes:
  `git status`
- Push the latest commits before sharing a build:
  `git push`
- Do not uninstall the app on test devices unless you explicitly want to wipe
  local progress.

## 2. Run Checks

```powershell
flutter analyze
flutter test
```

If either fails, fix that before sharing the build.

## 3. Data Safety

- Open Settings -> Data safety.
- Export a backup and confirm the status changes to `Last backup: just now.`
- Open Restore backup and cancel before replacing data.
- Open Reset all progress and cancel. Confirm the dialog shows backup status.
- If switching between debug and release-signed builds, export a backup first.

## 4. Core Phone Smoke Test

Run on the connected phone:

```powershell
flutter run -d 36291JEHN05094
```

Check:

- Home loads and Resume last set count looks correct.
- Random puzzle loads.
- A set round can be opened.
- Recommended training opens the size picker.
- Recommended sizes show 50, 150, and 300 puzzles, with 150 marked Best.
- Analyze opens from a puzzle.
- Analysis allows trying moves and undoing exploration moves.
- Report puzzle opens the report flow.
- Settings opens without layout overflow.

## 5. Puzzle Quality Controls

- If a bad puzzle is found, add it to
  `assets/config/disabled_puzzles.json`.
- Keep old attempts and rounds. Do not delete puzzle rows from user databases.
- Run analyze/tests after changing the disabled puzzle list.

## 6. Build To Share

For day-to-day local testing, prefer debug:

```powershell
flutter build apk --debug
```

Release builds are for later Play/internal testing. Before release builds, read
`docs/release-data-safety.md`, especially the signing-key section.

## 7. Final Sanity

- App opens without obvious jank.
- No visible yellow/black Flutter overflow warnings.
- Backup export works.
- No data was lost during update testing.
- `git status` is clean after committing.
