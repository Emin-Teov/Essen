# Story and content

The **narrative** (characters, plot, endings) is in `../STORY.md`. Keep it in sync when the story changes.

## Structure vs text
- `lib/story/story.dart` holds **structure** only: chapters, objectives, spawns, pickups, NPCs, codex ids.
- All text lives in `lib/l10n/story_{en,az,ja}.dart`, keyed by id (see localization.md).

## Chapter
`Chapter(number, kanji, lighting, startPoint, startYaw, objectives, spawns, pickups, npcs, petals, embers)`
- Text keys: `ch<N>.title`, `ch<N>.intro` (paragraphs), `ch<N>.outro` (paragraphs; empty for the last chapter, which shows the ending instead).
- `lighting` is a `Lighting` preset: `moonlit`, `dawn`, `day`, `sunset`.
- `spawns` and `pickups` exist from chapter start (roaming patrols, supplies).

## Objective
`Objective(id, type, {point, radius, group, pickupKind, count, spawns, pickups, actions, unlock})`
- `id` (e.g. `c3.o2`) is the text key of the objective line. Dialog keys derive from it:
  - `<id>.before`: shown when the objective starts. For `duel`, it's shown when the player reaches the point instead.
  - `<id>.after`: shown on completion.
  - `<id>.mid`: boss at half health (`defeat` objectives).
  - A missing key means no dialog.
- Types:
  - `reach`: be within `radius` of world point `point`.
  - `eliminate` / `defeat`: no hostile enemy left in `group`.
  - `collect`: pick up `count` pickups of `pickupKind` (spawned via `pickups`).
  - `duel`: the rival in `group` waits passively until the player is within `radius` of `point`. After the `before` dialog it fights, and the objective completes when it yields.
- `spawns`: enemies created when the objective starts.
- `actions`: run after the `after` dialog. Supported:
  - `removeNpc:<id>`
  - `npcPose:<id>:dead` (lying pose)
  - `heal`
  - Add new ones in `Game._runAction`.
- `unlock`: codex ids unlocked on completion.

## Endings
The last `after` dialog of chapter 4 ends with a `DialogLine` that has `choices` (2 options).
`Game.endingChoice` 0 → mercy, 1 → vengeance. `Journey.chapterComplete` shows `ending.mercy` or `ending.vengeance` with their titles.

## World points (game/world.dart → `world.points`)
Points are named while the locations are built. Objectives, spawns, pickups and NPCs refer to them by name:

`start, kasumi, soun, camp, orders, campSupply, hanamura, tsuru, duel, shrine, shrinePath, castleGate, cage, arena, castle, bridgeNorth, bridgeSouth`

Location centers are in `Places` (terrain.dart):

| Place | Coordinates | Notes |
|---|---|---|
| Kasumi | (−200, 170) | ruined village |
| Camp | (−60, 30) | bamboo |
| Hanamura | (60, 150) | the river crosses it |
| Shrine | (170, 40) | hill |
| Castle | (120, −190) | hill, gate faces north (+Z side) |

The test "world has every named point used by the story" fails if a referenced point is missing.

## Codex
`Story.codex` lists `CodexEntry(id, category)`, where category is `Characters`, `Places` or `Lore`. Text keys are `codex.<id>.title` and `codex.<id>.text`.
Entries unlock through `Objective.unlock` or `PickupDef.codex`. `essen` is unlocked from the start. Progress is saved by `Progress`.
