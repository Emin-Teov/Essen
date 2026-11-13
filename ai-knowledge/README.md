# AI knowledge base — Essen

Start here. These notes help an AI assistant (or a new developer) work on the project quickly and safely.
Read the file for the area you are about to touch before you change code.

| File | Read it when you… |
|---|---|
| [architecture.md](architecture.md) | need the big picture: module map, frame loop, data flow |
| [conventions.md](conventions.md) | touch anything 3D: units, yaw conventions (there are **two**), coordinates, colors, code style |
| [rendering.md](rendering.md) | change the renderer, add geometry or effects, or worry about performance |
| [gameplay.md](gameplay.md) | change the player, camera, enemies, combat or pickups |
| [story-and-content.md](story-and-content.md) | add or edit chapters, objectives, dialogue, codex or world locations |
| [localization.md](localization.md) | add or change any player-facing text, or add a language |
| [assets-and-icons.md](assets-and-icons.md) | add or change icons, flags or launcher icons |
| [effects-3d-models.md](effects-3d-models.md) | add or change 3D effects (OBJ/MTL models in assets/effects) |
| [testing.md](testing.md) | verify a change, including checking visuals without a device |
| [gotchas.md](gotchas.md) | hit a confusing error, before you "fix" something odd |
| [recipes.md](recipes.md) | step-by-step guides: new enemy, prop, location, chapter, pickup, language |

## Quick facts
- **What:** *Essen*, a third-person open-world 3D shinobi game for phones, in landscape. It is set in fictional feudal Japan (Hōmura Province). The story bible is in `../STORY.md`.
- **Stack:** Flutter (stable 3.41+, Dart 3.11). The only extra dependency is `shared_preferences`.
- **No game engine.** A custom software 3D renderer projects and sorts triangles in Dart, then draws them with one `Canvas.drawVertices` call per frame.
- **Languages:** English, Azerbaijani, Japanese. Every player-facing string goes through `lib/l10n/`.
- **Platforms:** Android and iOS are the targets. Windows/macOS desktop works for keyboard testing.
- **Commands:**
  - `flutter analyze` must report no issues.
  - `flutter test test/` must pass.
  - `flutter test tool/generate_icons_test.dart` regenerates all icons.
  - `dart run tool/generate_effects.dart` regenerates the 3D effect models (OBJ/MTL).
- **Shell:** the dev machine is Windows. Python is not installed, so don't write Python helper scripts; use Dart, bash or PowerShell.
