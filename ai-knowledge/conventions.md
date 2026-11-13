# Conventions

## Units and axes
- 1 unit = 1 meter. **+Y is up.** The ground plane is XZ.
- "North" is **−Z**: the compass N appears when the camera yaw is 0.
- The world spans x, z ∈ [−320, 320] (`Terrain.half`). The playable area is clamped to ±308 by the player code.
- Mountains rise along the borders; the river meanders north–south (`Places.riverX(z)`).

## ⚠️ Two different yaw conventions
This is the #1 source of bugs. Know which one you are using.

1. **Entity / camera yaw** (player.yaw, player.facing, enemy.yaw, camera.yaw):
   forward = `(sin(yaw), 0, −cos(yaw))`; positive yaw turns **right** (clockwise seen from above).
   - Use `yawTowards(fromX, fromZ, toX, toZ)` to aim.
   - `drawFigure(..., yaw, ...)` applies `rotateY(−yaw)` internally, because models face local −Z.
2. **Prop yaw** (`World.place(x, z, yaw, build)`, `World.boxAt`, `World.local`):
   the builder's `rotateY(yaw)` maps local **+Z** to world `(sin(yaw), 0, cos(yaw))` and local +X to `(cos, 0, −sin)`.
   - To make a prop's front (+Z, e.g. a house door) face a point, use `math.atan2(targetX − x, targetZ − z)`.
   - Colliders created with `boxAt(x, z, yaw, lx, lz, ...)` share the prop's frame, so pass the same yaw.

Always use `wrapAngle(a − b)` to compare angles; raw differences can be ±2π off.

## Models
- Characters face local −Z, and their right hand is at local +X.
- Torso pivot is at y = 0.9; the shoulders are at (±0.31, 0.42) relative to the pivot. In high detail the arm is upper arm 0.3 + forearm 0.31 (elbow bend), and the leg is thigh 0.47 + shin 0.47 (knee bend).
- `FigureStyle.kind` (samurai / ashigaru / shinobi / robed) is derived from the style: hood → shinobi, helmet → samurai, hat → ashigaru, else robed. It selects the outfit details in high detail.
- Props are built in local coordinates with y = 0 at the ground.

## Colors
- `int` ARGB (`0xAARRGGBB`), never `Color`, inside engine and game code.
- The alpha channel is honored, so translucent effects work: water `0xD0…`, beacon `0x60…`.
- Use the `Pal` constants (props.dart) for the shared palette and `Hue` (ui/theme.dart) for UI colors.
- `MeshBuilder.jitter` adds per-face brightness noise for the low-poly look. It is 0 for the dynamic batch.

## Code style
- Match the surrounding code: terse doc comments on classes and non-obvious methods, few inline comments.
- Hot paths (renderer, particles) use typed lists and local variables, and avoid allocating in loops.
- No player-facing string literals outside `lib/l10n/`. Use `tr('key')`, `L10n.s(...)` and `upper(...)` (see localization.md).
- Dart 3 switch statements: an empty `case` falls through to the next one. Non-empty cases don't fall through.
- Avoid class names that clash with Flutter widgets (see gotchas.md: `Ink`, `Flow`).
