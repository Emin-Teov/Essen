# Architecture

## Module map

```
lib/
  main.dart              App entry: landscape lock, immersive mode, loads Progress,
                         rebuilds MaterialApp (keyed by language) when the language changes.
  engine/                Game-agnostic 3D code. Imports nothing from game/ or ui/.
    math3d.dart          Vec3, clampD, lerpD, smoothstep, wrapAngle, yawTowards, color helpers
    noise.dart           Deterministic value noise + fBm (terrain, scatter)
    mesh.dart            Lighting presets, triangle flags, TriBatch (triangle storage),
                         MeshBuilder (transform stack + convex primitives)
    renderer.dart        Camera, Renderer (cull/clip/fog/sort/drawVertices), SkyPainter
    obj_mesh.dart        Wavefront OBJ/MTL loader -> ObjMesh (per-face color + flags)
  game/                  Simulation + world content. No Flutter widgets.
    terrain.dart         Places (named coordinates, river, roads), Terrain heightmap
    props.dart           Pal (palette) + builder functions for every static prop
    world.dart           World: chunks, colliders, collision queries, builds all locations
    figures.dart         Humanoid models (FigureStyle + FigureAnim -> drawFigure)
    player.dart          Player state (position, camera yaw/pitch, body facing, timers)
    enemy.dart           Enemy stats + stealth AI state machine + hit handling
    effects.dart         Projectile, Particles (all 3D effects), Pickup — instances of Fx models
    fx.dart              Fx: loads assets/effects/*.obj effect models
    game.dart            Game: owns everything, runs objectives/dialog/combat, update + render
  story/story.dart       Story STRUCTURE only: chapters, objectives, spawns, pickups, codex ids
  l10n/                  All player-facing TEXT
    l10n.dart            Lang, StoryText, L10n lookup, tr(), upper()
    ui_strings.dart      UI strings for all languages
    story_en|az|ja.dart  Story text (titles, objectives, paragraphs, dialogue, codex)
  ui/                    Flutter widgets
    title_screen.dart    Menu, chapter select, language picker, how-to
    flow.dart            Journey: navigation between story pages, chapters, title
    story_screen.dart    Chapter intro/outro/epilogue pages
    game_screen.dart     WorldCache, game loop (Ticker), touch + keyboard input, overlays
    hud.dart             Controls (button layout) + HudPainter (screen-space HUD)
    game_icons.dart      Loads assets/icons/*.png for the HUD
    codex_screen.dart, backdrop.dart (painted menu art), theme.dart (Hue colors, InkButton),
    progress.dart        Saved progress + language (shared_preferences)
tool/generate_icons_test.dart   Offline icon/launcher-icon generator (run via flutter test)
tool/generate_effects.dart      3D effect model generator -> assets/effects/*.obj + effects.mtl (dart run)
test/                           Unit/integration tests (see testing.md)
```

## Dependency direction
`engine` ← `game` ← `story` / `l10n` ← `ui`.
`story` and `l10n` import each other: structure looks up text by key, and text files use `DialogLine`/`Spk` from story. Keep `engine` free of game imports.

## Frame loop (GameScreen._tick → Game)
1. `Ticker` gives `dt`, clamped to 0.05 s and skipped while paused.
2. Keyboard state is folded into `game.input`; holding the SLASH button sets `input.attack` every frame.
3. `Game.update(dt)`:
   - time, toasts, ambient particles (fires, petals, embers), particle update
   - when the phase isn't `playing`: only animate the player and camera, then return
   - `_updatePlayer`: look, jump, actions, camera-relative movement, physics, collision, timers
   - `_animatePlayer`: walk, crouch, air, scarf and swing poses
   - each enemy runs `update(game, dt)` (AI), then `_separateEnemies`
   - `_updateProjectiles`, `_updatePickups`, `_checkObjective`
   - `_updateCamera`: third-person boom with collision
   - `input.consume()`
4. `_frame` ValueNotifier ticks → `_WorldPainter` calls `Game.render(canvas)`, then `HudPainter` paints on top.

## Render (Game.render)
`Renderer.begin` → `SkyPainter.paint` → `World.render` (chunk batches) → build the **dynamic batch** (`_dyn`) through `_dynB`. Every effect is an instance of an OBJ model from `Fx` (see effects-3d-models.md):
player figure, slash trail, enemies + 3D markers, NPCs, pickups, projectiles, objective beacon, particles
→ `_dyn.relight` → `drawBatch(_dyn)` → `flush` (sort + one `drawVertices`).

## Game phases
`Phase.playing | dialog | chapterComplete | dead`.
- `showDialog(lines, then)` queues lines and sets `dialog`. `advanceDialog` and `choose(i)` drain the queue, then run `then`.
- The `ChangeNotifier` only notifies on phase or dialog changes, never per frame. Per-frame repaint goes through `_frame`.

## World lifetime
`World()` is deterministic and fairly heavy (~120k static triangles, 0.2 s on desktop).
`WorldCache.get()` builds it once in `Isolate.run` (falling back to the UI isolate) and shares it between chapters.
Each `Game` calls `world.relight(chapter lighting)`. Static geometry is never rebuilt.
