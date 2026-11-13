# Rendering

## Pipeline (engine/renderer.dart)
Each frame:
1. `Renderer.begin(camera, size, lighting, far)` computes the focal length, frustum tangents and fog constants.
2. `drawBatch(TriBatch)` runs per triangle:
   - the batch's bounding sphere is frustum-culled first
   - **back-face cull** in world space (`dot(n, v0 − cam) ≥ 0` → skip) unless the triangle has `fDouble`
   - transform to view space (camera right/up/forward basis)
   - trivial reject: behind the near plane, beyond `far`, or fully outside a side plane
   - fog lerps toward `fogColor` by mean depth, unless the triangle has `fNoFog`
   - **near-plane clipping** (`near = 0.12`) can split one triangle into two
   - project and store screen coords, color and a sort key `(depth·128) << 16 | index`
3. `flush(canvas)` sorts the keys, writes triangles **far → near** (painter's algorithm), then makes one `Vertices.raw` + `drawVertices(BlendMode.dst)` call. Vertex colors carry alpha.

Limits: `Renderer.maxTris = 30000` triangles per frame. The sort index uses 16 bits, so never raise the limit above 65535.

## Triangle flags (engine/mesh.dart)
| Flag | Meaning |
|---|---|
| `fDouble` | Never back-face culled (foliage, cloth, effects) |
| `fEmissive` | Ignores lighting (fire, effects, markers) |
| `fGround` | Terrain: +3 m sort bias so objects standing on it draw after it |
| `fWater` | Water: +2.5 m sort bias (between terrain and objects) |
| `fNoFog` | Ignores distance fog (objective beacon) |

`MeshBuilder.flags` is OR-ed into every triangle it emits. Set it, build, then reset it to 0. Primitives like `box()` take no flag parameter.

## Geometry building (MeshBuilder)
- Transform stack: `push`/`pop`, `translate`, `rotateX/Y/Z`, `scale`.
- Primitives: `box` (base-centered), `frustum`, `cylinder` (cone when `rt = 0`), `gable`, `ico` (20 faces), `octa` (8 faces), `hexa`, `quad2` / `tri2` (double-sided), and `worldTri` (raw world coords, ignores the transform).
- Convex primitives orient faces outward automatically (they flip using the primitive center), so winding order doesn't matter.
- Shading is flat: `TriBatch.relight(Lighting)` bakes lambert + hemisphere ambient into `shaded`.
  - Static batches are relit once per chapter.
  - The dynamic batch is relit every frame.

## Static world (game/world.dart)
- 20 × 20 chunks of 32 m. Each chunk has three batches:
  - `terrain` (4 m grid + water quads)
  - `props` (buildings, rocks; drawn up to the far plane)
  - `flora` (trees and bamboo; only within `World.floraDistance = 105 m`, hidden by fog)
- Use `World.place(..., flora: true)` for vegetation.

## Dynamic geometry
Built every frame into `Game._dyn`, so keep it cheap.
- **Characters use three levels of detail** (`figures.dart`, see "Character level of detail" below). They are skipped when off-frustum or beyond the view distance.
- **Effect particles and projectiles** are skipped before their model is built when they are outside the view or would be smaller than about a pixel (`Particles.draw`, `Game.render`).
- **Every 3D effect is an OBJ model instance** from `Fx` (assets/effects, see effects-3d-models.md), emitted with `MeshBuilder.mesh(model, alpha:, tint:, tintAmount:)`.
- `Particles` (effects.dart) holds transient effects:
  - flame, smoke, puff (dust), spark, blood, petal, ember
  - `flash` (star burst), `ring` (ground shockwave), `streak` (projectile trail)
  - helpers: `particles.flash(...)`, `particles.ring(...)`, `particles.burst(...)`
  - capped at 700 particles
- Other in-world feedback built in `Game.render`:
  - `_slashTrail` (`slash_arc` oriented per combo via `swingPose`)
  - `_enemyMarker` (`alert_mark`, `suspicion_gem`, `blind_stars`, `bar_quad` health bar)
  - `_objectiveBeacon` (`objective_beacon` pillar + `objective_gem`)
  - pickups (`pickup_*` models + `pickup_ring`)

## Performance budget
- Measured peaks are about 1–5k triangles per frame (see the test output "peak N triangles/frame").
- Keep peaks under about 8k for mid-range phones.
- Cost is dominated by the per-triangle Dart loop and the sort. Prefer fewer, larger faces.

## Sky
`SkyPainter` draws a gradient, stars (night), sun/moon disc, three procedural ridge silhouettes and ground haze.
It is pure 2D canvas, drawn before the 3D pass.

## Known painter's-algorithm artifacts
Painter's sorting has no depth buffer. Large triangles that intersect can sort wrongly; the ground and water biases hide most cases. When adding big flat geometry, split it into smaller pieces or give it a bias flag.

## Character level of detail
`drawFigure(..., lod:)` has three builds:

| Level | Used for | Cost (samurai / Essen) | What it shows |
|---|---|---|---|
| `Lod.high` | within 12 m, nearest 4 characters, and Essen always | ~1000 / ~600 tris | knees and elbows, layered laced armor, helmet neck guard and side flaps, faces, curved katana with guard and wrap, sheaths, yumi bow and quiver, shinobi hood, mask, leg wraps and split-toe socks |
| `Lod.mid` | 12–40 m, or beyond the high-detail cap | ~250 tris | the original simpler model |
| `Lod.low` | beyond 40 m | ~80 tris | about ten boxes |

- `Game.render` sorts visible characters nearest-first and gives `Lod.high` to at most `Lod.maxHigh` (4) of them, so a big crowd can't blow the budget.
- Thresholds live in `Lod`.
- Cheap detail rule: thin trim (lacing, eyes, brows, edges) uses `_stripe` / `_stripeSide`, a 2-triangle quad. Never use a 12-triangle box for something that only shows one face.
- `test/figures_test.dart` enforces that each level is cheaper than the one above, and budgets of under 1200 triangles for high and under 100 for low.
- Measured worst case (10 enemies surrounding Essen): about 5.4k triangles and 2.8 ms per frame on desktop.
