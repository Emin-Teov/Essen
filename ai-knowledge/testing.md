# Testing and verification

```sh
flutter analyze            # must be "No issues found!"
flutter test test/         # unit + integration tests (~2 s)
```

## What the tests cover
- **test/widget_test.dart**
  - the world builds (prints build time and static triangle count) and contains every named point the story uses
  - codex ids referenced by the story exist
  - every chapter simulates 120 frames with input and renders to a `PictureRecorder` (prints peak triangles per frame: the performance budget check)
  - the player stays on the terrain
  - chapter 1 can be completed end to end
  - the third-person camera never goes below the terrain and stays near the player; moving forward turns the body toward the camera direction
  - the rival yields instead of dying
  - the title screen renders at phone landscape size (390 px tall) without overflow
- **test/effects_test.dart**
  - every OBJ in assets/effects parses and its materials exist in effects.mtl
  - MTL flags and opacity, OBJ quad triangulation and `v/vt/vn` indices
  - every particle kind renders through the game
- **test/l10n_test.dart**
  - identical key sets across languages for UI strings, story strings, paragraphs and dialogs
  - choice lines match across languages
  - every chapter, objective and codex entry resolves to real text
  - `upper()` handles Azerbaijani İ
  - a chapter starts in Japanese and in Azerbaijani

## Checking visuals without a device
You can render real frames to PNG headlessly and inspect them:
1. Create a temporary `test/snapshot_tmp_test.dart`.
2. Inside a `testWidgets`:
   - build `World()` and a `Game`, position the player, call `update` a few times
   - `g.render(canvas, Size(844, 390))` into a `PictureRecorder`
   - optionally paint `HudPainter(g, Controls(), ValueNotifier(0))` on top
   - inside `tester.runAsync`: `picture.toImage(...)` → `toByteData(format: png)` → write to a scratch folder
3. Load HUD icons first with `await tester.runAsync(GameIcons.load)`, and effect models with `Fx.loadFromDirectory()`.
4. Open the PNGs, then **delete the temporary test**. Don't commit files that write outside the repo.

Note: Flutter's test environment renders all text with the placeholder "Ahem" font (solid boxes). That's expected; real devices show proper text in every language.

## Manual play
- `flutter run` on an Android/iOS device (landscape).
- `flutter run -d windows` for desktop keyboard play:
  - WASD to move, arrows to orbit the camera, Shift to run
  - Space jump, J slash, K shuriken, C crouch, Q smoke, Esc pause
