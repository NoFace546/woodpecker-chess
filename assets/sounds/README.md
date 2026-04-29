# Sound assets

Drop short MP3 files here to enable in-app SFX. Without these files, the app stays silent (no crashes — `SoundService` just skips missing assets).

Expected filenames (referenced by [lib/services/sound_service.dart](../../lib/services/sound_service.dart)):

| File | Trigger |
|---|---|
| `move.mp3` | Each puzzle move (correct, intermediate) |
| `capture.mp3` | Capture move (currently unused — reserved) |
| `check.mp3` | Position is in check (currently unused — reserved) |
| `correct.mp3` | Puzzle solved |
| `wrong.mp3` | Wrong move detected |
| `hint.mp3` | Hint button used |
| `round_complete.mp3` | Round finished |

## Where to find sounds

**Lichess Mobile** ships open-source SFX under AGPL-3.0:
https://github.com/lichess-org/mobile/tree/main/assets/sounds

If you bundle from Lichess, your distributed APK becomes AGPL-3.0. For permissive licensing, source from Freesound.org (CC0) or generate your own.

## Format notes

- MP3 is recommended for size; OGG and WAV also work via `audioplayers`.
- Keep each file under ~50 KB. Long sounds will overlap and feel unresponsive.
- Mono, 22 kHz is plenty for short SFX.

## Bundling

Add to `pubspec.yaml` under `flutter > assets:` once you have files:
```yaml
  assets:
    - assets/db/puzzles.sqlite
    - assets/sounds/
```
