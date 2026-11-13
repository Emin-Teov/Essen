# Gotchas

- **Flutter name clashes.** Material already exports `Ink` and `Flow`. That's why the UI color class is `Hue` and the navigation helper is `Journey` (in `flow.dart`). Check before naming a new top-level class (`Material`, `Card`, `Icon`, `Table` and so on are all taken).
- **Two yaw conventions** (entity vs prop). See conventions.md. Symptoms of mixing them up: houses facing the wrong way, colliders offset from meshes, enemies walking backwards.
- **Compare angles with `wrapAngle(a − b)`.** Raw subtraction can be off by 2π.
- **Upper-casing:** use `upper()` and never `toUpperCase()` in UI. Azerbaijani needs `i → İ`.
- **Dart 3 switch:** an empty `case X:` falls through to the next case; a non-empty case never does. `Particles.update` relies on this.
- **Painter's algorithm:** there is no depth buffer. New large flat geometry may sort wrongly; split it or use `fGround`/`fWater` biases. Effects that must read clearly should be emissive and double-sided.
- **`MeshBuilder.box/frustum/cylinder` take no flag argument.** Set `b.flags = fEmissive` (for example) before the call and reset it to 0 after.
- **Dynamic builder state:** `drawFigure` and most helpers call `b.reset()` first. When you emit raw `worldTri`s, call `b.reset()` yourself if the transform matters.
- **World build in an isolate:** `World` must stay sendable (no closures, sockets or UI objects in fields). `_builders` is cleared at the end of the constructor for that reason.
- **The Game notifier is not per-frame.** Calling `notifyListeners()` every frame would rebuild the widget tree. Repaint goes through `GameScreen._frame`.
- **Objective completion needs `phase == playing`.** If a pickup opens a dialog on the same frame, completion waits until the dialog closes. That's intended.
- **Tests render text as boxes** (Ahem font). That's not a bug.
- **Hand-edited effect models:** an off-by-one in a generator or exporter (faces pointing past the last vertex) used to crash loading and hang the game on the loading screen. Loading is now fault-tolerant, but always run `dart run tool/validate_effects.dart` after editing `assets/effects/`.
- **Spawn rates must be frame-rate independent.** Use `Game._spawnCount(rate, dt)`, never `(dt * rate).ceil()`, which spawns at least one per frame.
- **Windows shell:** no Python. Bash (Git Bash) and PowerShell are available. `sed -i` works in Bash.
- **iOS orientation:** portrait was removed from Info.plist, so `UIRequiresFullScreen` must stay true or App Store validation fails for iPad.
