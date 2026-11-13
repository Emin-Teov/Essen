# Recipes

## Add a new enemy type
1. `story.dart`: add a value to `EnemyKind`.
2. `enemy.dart`: add an `EnemyStats` constant, then map the kind in both `switch` expressions in the `Enemy` constructor (stats and style).
3. `figures.dart`: add a `FigureStyle` (colors, helmet or hat, weapon, scale, `lacing`). Its `kind` picks the outfit; new outfit details belong in `_high` (and only there). Keep `test/figures_test.dart` budgets green.
4. If it behaves differently, branch in `Enemy.update` (see how `ranged` archers use `_archer`).
5. Use it in a `SpawnDef` and run the tests.

## Add a static prop
1. `props.dart`: write `void myProp(MeshBuilder b, ...)` in local coordinates (y = 0 is the ground; the front faces +Z).
2. Place it in a `World._build*` method with `place(x, z, yaw, myProp)`. Pass `flora: true` for vegetation.
3. Add a collider, either `boxAt(x, z, yaw, 0, 0, w, d, y0, y1)` or `addCollider(Collider.circle(...))`. A collider top within 0.55 m of the feet is walkable.

## Add a world location
1. `terrain.dart`: add center coordinates to `Places`. If it needs flat ground, add a flat zone to `Terrain._flatZones`. Optionally add a road to `Places.roads`.
2. `world.dart`: write `_buildMyPlace()` and call it from the `World()` constructor before `_scatter()`. Add an exclusion zone in `_excluded` so trees don't grow inside it. Register named points with `_point('name', x, z)`.
3. The terrain is deterministic, so test and snapshot the result (testing.md).

## Add a chapter or objective
1. `story.dart`: append a `Chapter` (or an `Objective`) with a new id (`c5.o1`, …).
2. Add text to **all three** files `story_en/az/ja.dart`: `ch5.title`, `ch5.intro`, `ch5.outro`, `c5.o1`, plus any `c5.o1.before/.after` dialogs.
3. `flow.dart`: add a color mood to `Journey._moods` for the new chapter index.
4. If the new chapter isn't the last one, the ending logic in `Journey.chapterComplete` still triggers after the last chapter. Move the choice line to the new final objective.
5. Run `flutter test test/`. The l10n and world-point tests catch missing keys and points.

## Add a pickup kind
1. `effects.dart`: model it in `Pickup.draw` and give it a glow color in `Pickup.glow`.
2. `game.dart`: handle it in `_updatePickups`, adding a `toast.*` UI string in all languages.

## Add a UI string
1. Add the key to all three maps in `ui_strings.dart`.
2. Use `tr('key')`, wrapped in `upper()` when the text is shown in capitals.

## Add a language
1. `l10n.dart`: add a value to `Lang`, a case in `storyFor`, and a mapping in `fromCode`.
2. `ui_strings.dart`: add a full map, including `lang.name` (the language's own name) and the 8 `compass` labels.
3. Create `story_xx.dart` with `const storyXx = StoryText(...)` covering every key in `story_en.dart`.
4. Icon generator: write a `_flagXx` painter, add a `_write` call for `assets/icons/flag_xx.png`, then run the generator.
5. If the language has special casing rules, extend `upper()`.
6. Run `flutter test test/l10n_test.dart`.

## Add a 3D effect
- One-shot impacts: `particles.flash(x, y, z, argb, size)` and `particles.ring(x, y, z, argb, radius)`.
- Directional bursts: `particles.burst(PKind.x, ...)`.
- A new effect **model**: follow effects-3d-models.md → "Adding an effect model". Generate the OBJ, register it in `Fx`, then instance it with `MeshBuilder.mesh`.
- A new transient effect kind: add it to `PKind`, update it in `Particles.update`, then pick its model, scale, tint and fade in `Particles.draw`.
- Persistent world markers: build them in `Game.render` next to `_enemyMarker` and `_objectiveBeacon`.
