# Gameplay systems

## Player (game/player.dart, Game._updatePlayer)
- `yaw` / `pitch` steer the **camera**. `facing` is the body direction.
- Movement is relative to the camera:
  - joystick magnitude > 0.92 → sprint (7.4 m/s); walk is 4.4 m/s; crouch is 2.5 m/s
  - in water ×0.55; while swinging on the ground ×0.35
- While moving, the body turns toward the movement direction at 13 rad/s.
- Jump: 8.2 m/s, gravity 24 m/s². A second tap in the air gives a 7.2 m/s double jump. Landing faster than 8 m/s spawns a ring and dust.
- Collision: `World.collide(pos, 0.38, 1.7)` pushes out of circle/box colliders. `World.groundAt` returns terrain or a walkable collider top within a 0.55 m step-up.
- HP is 100 and regenerates 5/s after 5 s without damage. Shuriken max 15, smoke max 4.

## Camera (Game._updateCamera)
- The boom is 4.3 m (0.85× when crouched) from a pivot at chest height, shifted 0.55 m to the right (over the shoulder).
- It ray-marches 16 steps and shortens when it would enter terrain or a collider. It snaps closer instantly and eases back out (×3/s).
- Pitch is clamped to [−1.1, 0.55]. Essen is hidden when the boom is shorter than 0.9 m.

## Combat
- **Slash** (`_playerAttack`):
  - 0.4 s cooldown, 0.38 s swing, the hit resolves at 0.12 s
  - the combo cycles overhead (48 dmg) → right-to-left (32) → left-to-right (32)
  - soft lock: the nearest hostile within 4.8 m and within 1.9 rad of the camera or body; Essen turns to face it and lunges if it's more than 1.9 m away
  - hits every enemy within reach (2.9 m, more for big foes) inside a ±1.0 rad cone of `facing`
- **Shadow strike:** instant kill when the target isn't boss-like and is unaware (idle, blind, or suspicious below 0.8) and the strike comes from behind or the enemy isn't merely suspicious.
- **Shuriken:** aims along the camera ray, snapping to an enemy within 0.12 rad of the crosshair. Thrown from the hand at 36 m/s. 34 dmg, doubled on unaware targets.
- **Smoke:** blinds enemies within 9 m (4.5 s, 1.8 s for bosses) and hides the player for 3 s.
- **Blocking:** alert enemies facing the player (not mid-windup) block melee by chance (`EnemyStats.block`).

## Enemies (game/enemy.dart)
`AiState`: idle (patrol) → suspicious → alert → (attack phases) ; blind ; yielded (rival) ; dead.
- **Perception:**
  - view range 24 m (11 m crouched, ×0.7 at night, ×1.25 when the player sprints)
  - ±60° cone, or close proximity
  - terrain line of sight (`World.lineOfSight`)
- **Suspicion:** grows with closeness. It reaches 1 → `Game.raiseAlarm` alerts allies within 20 m. Lost sight for 8 s → back to suspicious.
- **Melee:** windup (arm raises), then strike; the hit lands if the player is within range and inside a 0.95 rad cone. **Archers** keep 6–22 m and shoot leading arrows.
- `EnemyStats`: samurai / archer / rival / boss. The rival yields at 30% HP and never dies. The boss triggers the objective's `.mid` dialog at 50% and winds up 25% faster.
- `passive` enemies (the rival before the duel dialog) only turn to face the player.

## Respawn
On death the player returns to the checkpoint (position at objective start) with full HP and at least 6 shuriken and 1 smoke bomb. Living enemies reset to home with full HP; dead ones stay dead.

## Pickups
`health` (+45 HP, not taken at full HP), `supply` (+8 shuriken, +2 smoke), `scroll` (counts toward collect objectives, unlocks codex, shows dialog). Pickup radius is about 1.6 m.
