import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../engine/math3d.dart';
import '../engine/mesh.dart';
import '../engine/obj_mesh.dart';
import '../engine/renderer.dart';
import '../l10n/l10n.dart';
import '../story/story.dart';
import 'effects.dart';
import 'enemy.dart';
import 'figures.dart';
import 'fx.dart';
import 'player.dart';
import 'terrain.dart';
import 'world.dart';

enum Phase { playing, dialog, chapterComplete, dead }

/// Per-frame control state written by the UI.
class GameInput {
  double moveX = 0, moveY = 0; // joystick, -1..1 (moveY + = forward)
  double lookDX = 0, lookDY = 0; // accumulated pixels
  bool attack = false, shuriken = false, jump = false, smoke = false, crouch = false;

  void consume() {
    lookDX = 0;
    lookDY = 0;
    attack = shuriken = jump = smoke = crouch = false;
  }
}

class Npc {
  final String id;
  final Vec3 pos;
  final double yaw;
  final FigureStyle style;
  final FigureAnim anim = FigureAnim();
  bool visible = true;

  Npc(this.id, this.pos, this.yaw, this.style);
}

class Toast {
  final String text;
  final bool big;
  double t = 0;
  Toast(this.text, this.big);
}

class Game extends ChangeNotifier {
  static const double viewDistance = 125;
  static const double swingTime = 0.38;
  static const double camBoom = 4.3;
  static const double camShoulder = 0.55;

  final World world;
  final int chapterIndex;
  final Chapter chapter;
  final Set<String> codex;
  final void Function(String id)? onUnlock;

  final Player player = Player();
  final List<Enemy> enemies = [];
  final List<Projectile> projectiles = [];
  final Particles particles = Particles();
  final List<Pickup> pickups = [];
  final List<Npc> npcs = [];
  final GameInput input = GameInput();
  final List<Toast> toasts = [];
  final math.Random rng = math.Random();
  final Lighting lighting;

  Phase phase = Phase.playing;
  final List<DialogLine> dialog = [];
  VoidCallback? _afterDialog;
  int objIndex = 0;
  int collected = 0;
  bool duelEngaged = false;
  int? endingChoice;
  double time = 0;
  int kills = 0, shadowKills = 0;
  final Vec3 checkpoint = Vec3.zero();
  double checkpointYaw = 0;
  int _spawnSeed = 1;

  // Rendering.
  final Renderer renderer = Renderer();
  final SkyPainter sky = SkyPainter();
  final Camera camera = Camera();
  final TriBatch _dyn = TriBatch(2048);
  late final MeshBuilder _dynB = MeshBuilder(_dyn, math.Random(3))..jitter = 0;

  Game(this.world, this.chapterIndex, {Set<String>? codex, this.onUnlock})
      : chapter = Story.chapters[chapterIndex],
        codex = codex ?? {},
        lighting = Story.chapters[chapterIndex].lighting() {
    world.relight(lighting);
    final start = world.points[chapter.startPoint]!;
    player.reset(start.x, start.y, start.z, chapter.startYaw);
    for (final s in chapter.spawns) {
      _spawn(s);
    }
    for (final p in chapter.pickups) {
      _addPickup(p);
    }
    for (final n in chapter.npcs) {
      final p = world.points[n.point]!;
      final style = switch (n.id) {
        'soun' => FigureStyle.soun,
        'tsuru' => FigureStyle.tsuru,
        _ => FigureStyle.hotaru,
      };
      final npc = Npc(n.id, p.copy(), n.yaw, style);
      if (n.id == 'soun') npc.anim.pose = Pose.kneel;
      if (n.id == 'tsuru') npc.anim.hunch = 0.35;
      npcs.add(npc);
    }
    _unlock('essen');
    _updateCamera(1);
    _startObjective();
  }

  Objective? get objective =>
      objIndex < chapter.objectives.length ? chapter.objectives[objIndex] : null;

  // ------------------------------------------------------------------ setup

  void _spawn(SpawnDef s) {
    double x = s.x, z = s.z;
    if (s.point != null) {
      final p = world.points[s.point]!;
      x = p.x;
      z = p.z;
    }
    final e = Enemy(s.kind, s.group, x, world.terrain.heightAt(x, z), z, s.wander, _spawnSeed++);
    if (s.kind == EnemyKind.rival) {
      e.passive = true;
      e.yaw = yawTowards(x, z, player.pos.x, player.pos.z);
    }
    enemies.add(e);
  }

  void _addPickup(PickupDef d) {
    double x = d.x, z = d.z;
    if (d.point != null) {
      final p = world.points[d.point]!;
      x = p.x;
      z = p.z;
    }
    pickups.add(Pickup(d, Vec3(x, world.groundAt(x, z, world.terrain.heightAt(x, z) + 1.5), z)));
  }

  void _unlock(String id) {
    if (codex.add(id)) {
      onUnlock?.call(id);
      final e = Story.codexById(id);
      if (e != null && id != 'essen') toast(tr('toast.codex', {'t': e.title}));
    }
  }

  void toast(String text, {bool big = false}) {
    toasts.add(Toast(text, big));
    if (toasts.length > 4) toasts.removeAt(0);
  }

  // ------------------------------------------------------------------ dialog

  void showDialog(List<DialogLine> lines, [VoidCallback? then]) {
    if (lines.isEmpty) {
      then?.call();
      return;
    }
    dialog.addAll(lines);
    if (then != null) {
      final prev = _afterDialog;
      _afterDialog = prev == null ? then : () {
        prev();
        then();
      };
    }
    if (phase == Phase.playing) phase = Phase.dialog;
    notifyListeners();
  }

  DialogLine? get currentLine => dialog.isEmpty ? null : dialog.first;

  void advanceDialog() {
    if (dialog.isEmpty) return;
    if (dialog.first.choices != null) return; // must choose
    dialog.removeAt(0);
    _dialogMaybeDone();
  }

  void choose(int index) {
    endingChoice = index;
    if (dialog.isNotEmpty) dialog.removeAt(0);
    _dialogMaybeDone();
  }

  void _dialogMaybeDone() {
    if (dialog.isEmpty) {
      if (phase == Phase.dialog) phase = Phase.playing;
      final cb = _afterDialog;
      _afterDialog = null;
      cb?.call();
    }
    notifyListeners();
  }

  // ------------------------------------------------------------------ objectives

  void _startObjective() {
    final o = objective;
    if (o == null) return;
    checkpoint.setFrom(player.pos);
    checkpointYaw = player.yaw;
    collected = 0;
    duelEngaged = false;
    for (final s in o.spawns) {
      _spawn(s);
    }
    for (final p in o.pickups) {
      _addPickup(p);
    }
    if (o.type != ObjType.duel) showDialog(o.before);
    notifyListeners();
  }

  bool _groupCleared(String group) {
    for (final e in enemies) {
      if (e.group == group && e.hostile) return false;
    }
    return true;
  }

  void _checkObjective() {
    final o = objective;
    if (o == null || phase != Phase.playing) return;
    switch (o.type) {
      case ObjType.reach:
        final p = world.points[o.point]!;
        if (player.pos.distXZ(p) < o.radius) _completeObjective();
      case ObjType.eliminate:
      case ObjType.defeat:
        if (_groupCleared(o.group!)) _completeObjective();
      case ObjType.collect:
        if (collected >= o.count) _completeObjective();
      case ObjType.duel:
        if (!duelEngaged) {
          final p = world.points[o.point]!;
          if (player.pos.distXZ(p) < o.radius) {
            duelEngaged = true;
            showDialog(o.before, () {
              for (final e in enemies) {
                if (e.group == o.group) {
                  e.passive = false;
                  e.alert(player.pos.x, player.pos.z);
                }
              }
            });
          }
        } else if (_groupCleared(o.group!)) {
          _completeObjective();
        }
    }
  }

  void _completeObjective() {
    final o = objective!;
    for (final id in o.unlock) {
      _unlock(id);
    }
    toast(tr('toast.objective'));
    final p = player.pos;
    particles.ring(p.x, p.y, p.z, 0xC0FFD27A, 3.5, life: 0.8);
    showDialog(o.after, () {
      for (final a in o.actions) {
        _runAction(a);
      }
      objIndex++;
      if (objIndex >= chapter.objectives.length) {
        phase = Phase.chapterComplete;
        notifyListeners();
      } else {
        _startObjective();
      }
    });
    if (o.after.isEmpty) notifyListeners();
  }

  void _runAction(String a) {
    final parts = a.split(':');
    switch (parts[0]) {
      case 'removeNpc':
        for (final n in npcs) {
          if (n.id == parts[1]) {
            n.visible = false;
            particles.burst(PKind.smoke, n.pos.x, n.pos.y + 1, n.pos.z, 12, 2, 1.5, 0.4);
          }
        }
      case 'npcPose':
        for (final n in npcs) {
          if (n.id == parts[1]) n.anim.pose = Pose.lying;
        }
      case 'heal':
        player.hp = Player.maxHp;
    }
  }

  void onBossHalf() {
    final o = objective;
    if (o != null && o.midBoss.isNotEmpty) showDialog(o.midBoss);
  }

  void onEnemyKilled(Enemy e) {
    kills++;
  }

  /// Where the HUD and the light beacon should point.
  Vec3? get objectiveTarget {
    final o = objective;
    if (o == null) return null;
    switch (o.type) {
      case ObjType.reach:
      case ObjType.duel:
        return world.points[o.point];
      case ObjType.eliminate:
      case ObjType.defeat:
        Enemy? best;
        var bd = double.infinity;
        for (final e in enemies) {
          if (e.group != o.group || !e.hostile) continue;
          final d = e.pos.distXZ(player.pos);
          if (d < bd) {
            bd = d;
            best = e;
          }
        }
        return best?.pos;
      case ObjType.collect:
        Pickup? best;
        var bd = double.infinity;
        for (final p in pickups) {
          if (p.taken || p.kind != o.pickupKind) continue;
          final d = p.pos.distXZ(player.pos);
          if (d < bd) {
            bd = d;
            best = p;
          }
        }
        return best?.pos;
    }
  }

  String get objectiveText {
    final o = objective;
    if (o == null) return '';
    switch (o.type) {
      case ObjType.eliminate:
      case ObjType.defeat:
        final left = enemies.where((e) => e.group == o.group && e.hostile).length;
        return '${o.text}  (${tr('hud.left', {'n': left})})';
      case ObjType.collect:
        return '${o.text}  ($collected/${o.count})';
      default:
        return o.text;
    }
  }

  /// Highest awareness among nearby enemies (0..1+), for the HUD eye.
  double get detection {
    var d = 0.0;
    for (final e in enemies) {
      if (!e.hostile || e.passive) continue;
      if (e.pos.distXZ(player.pos) > 40) continue;
      if (e.suspicion > d) d = e.suspicion;
    }
    return d;
  }

  // ------------------------------------------------------------------ combat API

  void raiseAlarm(Enemy source) {
    source.alert(player.pos.x, player.pos.z);
    for (final e in enemies) {
      if (e == source || !e.hostile || e.passive) continue;
      if (e.pos.distXZ(source.pos) < 20 && e.state != AiState.blind) {
        e.alert(player.pos.x, player.pos.z);
      }
    }
  }

  void damagePlayer(double dmg, Enemy? from) {
    if (player.dead || phase != Phase.playing) return;
    player.hp -= dmg;
    player.hurtFlash = 1;
    player.sinceHurt = 0;
    player.shake = 0.35;
    final p = player.pos;
    particles.flash(p.x, p.y + 1.2, p.z, 0xE0FF4030, 0.55);
    particles.burst(PKind.blood, p.x, p.y + 1.2, p.z, 6, 2.5, 0.5, 0.06);
    if (player.hp <= 0) {
      player.hp = 0;
      phase = Phase.dead;
      notifyListeners();
    }
  }

  void fireArrow(Enemy e) {
    final sx = e.pos.x, sy = e.pos.y + 1.45 * e.style.scale, sz = e.pos.z;
    final tx = player.pos.x + player.vel.x * 0.35;
    final ty = player.pos.y + player.eye * 0.75;
    final tz = player.pos.z + player.vel.z * 0.35;
    final dx = tx - sx, dy = ty - sy, dz = tz - sz;
    final d = math.sqrt(dx * dx + dy * dy + dz * dz);
    const speed = 30.0;
    final t = d / speed;
    final spread = 0.04 + (player.crouch ? 0.03 : 0);
    projectiles.add(Projectile(
      Vec3(sx, sy, sz),
      Vec3(dx / t + (rng.nextDouble() - 0.5) * spread * speed,
          dy / t + 0.5 * 9.8 * 0.6 * t, dz / t + (rng.nextDouble() - 0.5) * spread * speed),
      fromPlayer: false,
      damage: e.stats.damage,
    ));
  }

  void respawn() {
    player.reset(checkpoint.x, checkpoint.y, checkpoint.z, checkpointYaw);
    player.shuriken = math.max(player.shuriken, 6);
    player.smoke = math.max(player.smoke, 1);
    for (final e in enemies) {
      e.resetToHome();
    }
    projectiles.clear();
    phase = Phase.playing;
    if (objective?.type == ObjType.duel && duelEngaged) {
      for (final e in enemies) {
        if (e.kind == EnemyKind.rival && e.hostile) e.alert(player.pos.x, player.pos.z);
      }
    }
    particles.ring(player.pos.x, player.pos.y, player.pos.z, 0xC0B8D8FF, 3, life: 0.7);
    notifyListeners();
  }

  /// Nearest hostile enemy in front of the camera / body within [range].
  Enemy? _softTarget(double range) {
    final p = player;
    Enemy? best;
    var bestScore = double.infinity;
    for (final e in enemies) {
      if (!e.hostile || e.passive) continue;
      final d = e.pos.distXZ(p.pos);
      if (d > range || (e.pos.y - p.pos.y).abs() > 2.2) continue;
      final a = yawTowards(p.pos.x, p.pos.z, e.pos.x, e.pos.z);
      final off = math.min(wrapAngle(a - p.yaw).abs(), wrapAngle(a - p.facing).abs());
      if (off > 1.9) continue;
      final score = d + off * 1.5;
      if (score < bestScore) {
        bestScore = score;
        best = e;
      }
    }
    return best;
  }

  void _playerAttack() {
    final p = player;
    if (p.attackCooldown > 0) return;
    p.attackT = 0;
    p.attackHitDone = false;
    p.combo = (p.combo + 1) % 3;
    p.attackCooldown = 0.4;
    final target = _softTarget(4.8);
    if (target != null) {
      p.facing = yawTowards(p.pos.x, p.pos.z, target.pos.x, target.pos.z);
      if (target.pos.distXZ(p.pos) > 1.9) p.lungeT = 0.14;
    } else if (input.moveX.abs() + input.moveY.abs() < 0.1) {
      p.facing = p.yaw;
    }
  }

  void _resolveSwing() {
    final p = player;
    var hitAny = false;
    for (final e in enemies) {
      if (!e.hostile || e.passive) continue;
      final reach = 2.9 + (e.style.scale - 1) * 1.5;
      final d = e.pos.distXZ(p.pos);
      if (d > reach || (e.pos.y - p.pos.y).abs() > 2.2) continue;
      final ang = wrapAngle(yawTowards(p.pos.x, p.pos.z, e.pos.x, e.pos.z) - p.facing).abs();
      if (ang > 1.0 && d > 1.0) continue;
      final behind = wrapAngle(yawTowards(e.pos.x, e.pos.z, p.pos.x, p.pos.z) - e.yaw).abs() > 1.9;
      final unaware = e.state == AiState.idle ||
          e.state == AiState.blind ||
          (e.state == AiState.suspicious && e.suspicion < 0.8);
      final shadow = !e.isBossLike && unaware && (behind || e.state != AiState.suspicious);
      final dmg = p.combo == 0 ? 48.0 : 32.0;
      if (e.takeHit(this, dmg, shadowStrike: shadow, fromYaw: p.facing)) {
        hitAny = true;
        if (shadow) {
          shadowKills++;
          toast(tr('toast.shadow'), big: true);
          particles.flash(e.pos.x, e.centerY, e.pos.z, 0xF0FF2A2A, 1.4);
          particles.ring(e.pos.x, e.pos.y, e.pos.z, 0xD0E02020, 3.2, life: 0.6);
        } else {
          particles.flash(e.pos.x, e.centerY, e.pos.z, 0xF0FFFFFF, 0.8);
        }
      }
    }
    if (hitAny) player.shake = math.max(player.shake, 0.12);
  }

  void _throwShuriken() {
    final p = player;
    if (p.shuriken <= 0) {
      toast(tr('toast.noShuriken'));
      return;
    }
    if (p.throwT >= 0 && p.throwT < 0.25) return;
    p.shuriken--;
    p.throwT = 0;
    final cam = camera;
    // Aim along the camera ray, snapping to an enemy near the crosshair.
    Enemy? best;
    var bestA = 0.12;
    for (final e in enemies) {
      if (!e.hostile || e.pos.distXZ(p.pos) > 36) continue;
      final vx = e.pos.x - cam.x, vy = e.centerY - cam.y, vz = e.pos.z - cam.z;
      final d = math.sqrt(vx * vx + vy * vy + vz * vz);
      if (d < 0.5) continue;
      final cos = (vx * cam.fx + vy * cam.fy + vz * cam.fz) / d;
      final a = math.acos(cos.clamp(-1.0, 1.0));
      if (a < bestA) {
        bestA = a;
        best = e;
      }
    }
    final tx = best?.pos.x ?? cam.x + cam.fx * 45;
    final ty = best?.centerY ?? cam.y + cam.fy * 45;
    final tz = best?.pos.z ?? cam.z + cam.fz * 45;
    p.facing = yawTowards(p.pos.x, p.pos.z, tx, tz);
    final ox = p.pos.x + math.sin(p.facing) * 0.45;
    final oy = p.pos.y + 1.35 - p.anim.crouch * 0.38;
    final oz = p.pos.z - math.cos(p.facing) * 0.45;
    var dx = tx - ox, dy = ty - oy, dz = tz - oz;
    final d = math.sqrt(dx * dx + dy * dy + dz * dz);
    dx /= d;
    dy = dy / d + d * 0.0035;
    dz /= d;
    const speed = 36.0;
    projectiles.add(Projectile(Vec3(ox, oy, oz), Vec3(dx * speed, dy * speed, dz * speed),
        fromPlayer: true, damage: 34));
  }

  void _smokeBomb() {
    final p = player;
    if (p.smoke <= 0) {
      toast(tr('toast.noSmoke'));
      return;
    }
    p.smoke--;
    p.hiddenT = 3.0;
    particles.flash(p.pos.x, p.pos.y + 0.8, p.pos.z, 0xF0FFFFFF, 1.6);
    particles.ring(p.pos.x, p.pos.y, p.pos.z, 0xB0D0D4DC, 9, life: 0.7);
    for (var i = 0; i < 26; i++) {
      final a = rng.nextDouble() * pi2, d = rng.nextDouble() * 3;
      particles.add(PKind.smoke, p.pos.x + math.cos(a) * d, p.pos.y + 0.3 + rng.nextDouble() * 1.5,
          p.pos.z + math.sin(a) * d, math.cos(a) * 3, 0.6, math.sin(a) * 3, 3.5, 0.7);
    }
    for (final e in enemies) {
      if (!e.hostile || e.passive) continue;
      if (e.pos.distXZ(p.pos) < 9) {
        e.state = AiState.blind;
        e.blindT = e.isBossLike ? 1.8 : 4.5;
        e.suspicion = 0;
        e.attackPhase = 0;
      }
    }
  }

  // ------------------------------------------------------------------ update

  void update(double dt) {
    time += dt;
    for (final t in toasts) {
      t.t += dt;
    }
    toasts.removeWhere((t) => t.t > 2.6);
    _ambient(dt);
    particles.update(dt);
    for (final n in npcs) {
      n.anim.walkPhase += dt;
      n.anim.scarfWave += dt;
    }
    if (phase != Phase.playing) {
      if (phase == Phase.dialog) {
        // Let the camera be steered while reading.
        player.yaw = wrapAngle(player.yaw + input.lookDX * 0.0055);
      }
      _animatePlayer(dt);
      _updateCamera(dt);
      input.consume();
      return;
    }
    _updatePlayer(dt);
    _animatePlayer(dt);
    for (final e in enemies) {
      e.update(this, dt);
    }
    _separateEnemies();
    _updateProjectiles(dt);
    _updatePickups();
    _checkObjective();
    _updateCamera(dt);
    input.consume();
  }

  void _updatePlayer(double dt) {
    final p = player;
    final inp = input;
    p.yaw = wrapAngle(p.yaw + inp.lookDX * 0.0055);
    p.pitch = clampD(p.pitch - inp.lookDY * 0.0045, -1.1, 0.55);

    if (inp.crouch) p.crouch = !p.crouch;
    if (inp.jump) {
      if (p.onGround) {
        p.vel.y = 8.2;
        p.jumps = 1;
        p.onGround = false;
        p.crouch = false;
        particles.burst(PKind.puff, p.pos.x, p.pos.y + 0.1, p.pos.z, 5, 1.6, 0.45, 0.18);
      } else if (p.jumps < 2) {
        p.vel.y = 7.2;
        p.jumps = 2;
        particles.ring(p.pos.x, p.pos.y, p.pos.z, 0xB0E8F0FF, 1.6, life: 0.35);
        particles.burst(PKind.puff, p.pos.x, p.pos.y, p.pos.z, 6, 1.5, 0.4, 0.2);
      }
    }
    if (inp.attack) _playerAttack();
    if (inp.shuriken) _throwShuriken();
    if (inp.smoke) _smokeBomb();

    // Movement relative to the camera.
    var mx = inp.moveX, my = inp.moveY;
    final mag = math.sqrt(mx * mx + my * my);
    if (mag > 1) {
      mx /= mag;
      my /= mag;
    }
    p.sprinting = mag > 0.92 && !p.crouch;
    var speed = p.crouch ? 2.5 : (p.sprinting ? 7.4 : 4.4);
    final ground = world.terrain.heightAt(p.pos.x, p.pos.z);
    final inWater = ground < Terrain.waterLevel - 0.5 && p.pos.y < Terrain.waterLevel;
    if (inWater) speed *= 0.55;
    if (p.attacking && p.onGround) speed *= 0.35;
    final fx = math.sin(p.yaw), fz = -math.cos(p.yaw);
    final rx = math.cos(p.yaw), rz = math.sin(p.yaw);
    var tvx = (fx * my + rx * mx) * speed;
    var tvz = (fz * my + rz * mx) * speed;
    if (mag > 0.1 && !p.attacking && p.throwT < 0) {
      final want = math.atan2(tvx, -tvz);
      final d = wrapAngle(want - p.facing);
      final step = dt * 13;
      p.facing = wrapAngle(d.abs() <= step ? want : p.facing + d.sign * step);
    }
    if (p.lungeT > 0) {
      p.lungeT -= dt;
      tvx = math.sin(p.facing) * 7.5;
      tvz = -math.cos(p.facing) * 7.5;
    }
    final accel = math.min(1.0, dt * (p.onGround ? 12 : 3.5));
    p.vel.x += (tvx - p.vel.x) * accel;
    p.vel.z += (tvz - p.vel.z) * accel;
    p.vel.y -= 24 * dt;
    if (inWater && p.vel.y < -3) p.vel.y = -3;
    if (!p.onGround) p.fallSpeed = math.max(p.fallSpeed, -p.vel.y);

    final wasGround = p.onGround;
    p.pos.x += p.vel.x * dt;
    p.pos.z += p.vel.z * dt;
    p.pos.y += p.vel.y * dt;
    world.collide(p.pos, Player.radius, 1.7);
    const lim = Terrain.half - 12;
    p.pos.x = clampD(p.pos.x, -lim, lim);
    p.pos.z = clampD(p.pos.z, -lim, lim);
    final g = world.groundAt(p.pos.x, p.pos.z, p.pos.y);
    if (p.pos.y <= g || (wasGround && p.vel.y <= 0 && p.pos.y - g < 0.45)) {
      if (!wasGround && p.fallSpeed > 8) {
        final k = math.min(1.0, (p.fallSpeed - 8) / 8);
        particles.ring(p.pos.x, g, p.pos.z, 0xA0E6DCC8, 1.5 + k * 1.5, life: 0.4);
        particles.burst(PKind.puff, p.pos.x, g + 0.1, p.pos.z, 6 + (k * 6).round(), 2.4, 0.5, 0.2);
        p.shake = math.max(p.shake, 0.1 * k);
      }
      p.pos.y = g;
      p.vel.y = 0;
      p.onGround = true;
      p.jumps = 0;
      p.fallSpeed = 0;
    } else {
      p.onGround = false;
    }

    final hspeed = math.sqrt(p.vel.x * p.vel.x + p.vel.z * p.vel.z);
    if (p.onGround && p.sprinting && hspeed > 5 && !inWater) {
      p.dustT -= dt;
      if (p.dustT <= 0) {
        p.dustT = 0.14;
        particles.add(PKind.puff, p.pos.x - math.sin(p.facing) * 0.3, p.pos.y + 0.08,
            p.pos.z + math.cos(p.facing) * 0.3, (rng.nextDouble() - 0.5), 0.5,
            (rng.nextDouble() - 0.5), 0.45, 0.12);
      }
    }
    final targetEye = p.crouch ? 1.05 : 1.65;
    p.eye += (targetEye - p.eye) * math.min(1, dt * 10);

    // Timers.
    p.attackCooldown -= dt;
    if (p.attackT >= 0) {
      p.attackT += dt;
      if (!p.attackHitDone && p.attackT > 0.12) {
        p.attackHitDone = true;
        _resolveSwing();
      }
      if (p.attackT > swingTime) p.attackT = -1;
    }
    if (p.throwT >= 0) {
      p.throwT += dt;
      if (p.throwT > 0.35) p.throwT = -1;
    }
    p.hurtFlash = math.max(0, p.hurtFlash - dt * 1.8);
    p.shake = math.max(0, p.shake - dt);
    p.hiddenT = math.max(0, p.hiddenT - dt);
    p.sinceHurt += dt;
    if (p.sinceHurt > 5 && p.hp < Player.maxHp) {
      p.hp = math.min(Player.maxHp, p.hp + 5 * dt);
    }
  }

  /// Arm angle and torso twist for a swing at progress [t] (0..1).
  static (double, double) swingPose(double t, int combo) {
    switch (combo) {
      case 1: // right to left
        return (1.55, t < 0.2 ? lerpD(0, -1.0, t / 0.2) : lerpD(-1.0, 1.15, math.min(1, (t - 0.2) / 0.3)));
      case 2: // left to right
        return (1.4, t < 0.2 ? lerpD(0, 1.0, t / 0.2) : lerpD(1.0, -1.15, math.min(1, (t - 0.2) / 0.3)));
      default: // overhead cut
        return (
          t < 0.25 ? lerpD(0.6, 2.9, t / 0.25) : lerpD(2.9, 0.45, math.min(1, (t - 0.25) / 0.25)),
          0.0
        );
    }
  }

  void _animatePlayer(double dt) {
    final p = player;
    final an = p.anim;
    final hs = math.sqrt(p.vel.x * p.vel.x + p.vel.z * p.vel.z);
    final k = math.min(1.0, dt * 10);
    an.walkAmount += (hs / 4.4 - an.walkAmount) * k;
    an.walkPhase += dt * hs * 2.3;
    an.crouch += ((p.crouch ? 1.0 : 0.0) - an.crouch) * k;
    an.air += ((p.onGround ? 0.0 : 1.0) - an.air) * k;
    an.scarfWave += dt * (1 + hs * 0.35);
    an.scarfLift += ((hs / 7).clamp(0.0, 1.0) + (p.onGround ? 0 : 0.4) - an.scarfLift) * k;
    if (p.attackT >= 0) {
      final (arm, twist) = swingPose(p.attackT / swingTime, p.combo);
      an.armRaise = arm;
      an.twist = twist;
    } else if (p.throwT >= 0) {
      final t = p.throwT / 0.35;
      an.armRaise = t < 0.3 ? lerpD(0.3, 2.6, t / 0.3) : lerpD(2.6, 1.0, math.min(1, (t - 0.3) / 0.4));
      an.twist = 0.4 * (1 - t);
    } else {
      final rest = p.sprinting ? 0.95 : 0.35;
      an.armRaise += (rest - an.armRaise) * k;
      an.twist += (0 - an.twist) * k;
    }
    an.leftArm = p.sprinting ? -0.7 : 0.2 + math.sin(an.walkPhase) * 0.3 * math.min(1.0, an.walkAmount);
  }

  bool _cameraBlocked(double x, double y, double z) {
    if (world.terrain.heightAt(x, z) + 0.25 > y) return true;
    for (final c in world.collidersNear(x, z)) {
      if (y > c.y0 && y < c.y1 + 0.25 && c.containsXZ(x, z)) return true;
    }
    return false;
  }

  /// Third-person orbit camera with collision against terrain and buildings.
  void _updateCamera(double dt) {
    final p = player;
    final cam = camera
      ..yaw = p.yaw
      ..pitch = p.pitch
      ..update();
    final pivotY = p.pos.y + 1.55 - p.anim.crouch * 0.45;
    final px = p.pos.x + cam.rx * camShoulder;
    final pz = p.pos.z + cam.rz * camShoulder;
    var want = p.crouch ? camBoom * 0.85 : camBoom;
    const steps = 16;
    for (var i = 1; i <= steps; i++) {
      final s = want * i / steps;
      if (_cameraBlocked(px - cam.fx * s, pivotY - cam.fy * s, pz - cam.fz * s)) {
        want = math.max(0.5, s - 0.35);
        break;
      }
    }
    p.camDist = want < p.camDist ? want : p.camDist + (want - p.camDist) * math.min(1, dt * 3);
    cam
      ..x = px - cam.fx * p.camDist
      ..y = pivotY - cam.fy * p.camDist
      ..z = pz - cam.fz * p.camDist;
  }

  void _separateEnemies() {
    for (var i = 0; i < enemies.length; i++) {
      final a = enemies[i];
      if (!a.alive) continue;
      for (var j = i + 1; j < enemies.length; j++) {
        final b = enemies[j];
        if (!b.alive) continue;
        final dx = b.pos.x - a.pos.x, dz = b.pos.z - a.pos.z;
        final d2 = dx * dx + dz * dz;
        if (d2 < 0.81 && d2 > 1e-6) {
          final d = math.sqrt(d2);
          final push = (0.9 - d) / 2;
          a.pos.x -= dx / d * push;
          a.pos.z -= dz / d * push;
          b.pos.x += dx / d * push;
          b.pos.z += dz / d * push;
        }
      }
      final dx = player.pos.x - a.pos.x, dz = player.pos.z - a.pos.z;
      final d2 = dx * dx + dz * dz;
      final min = 0.75 * a.style.scale;
      if (d2 < min * min && d2 > 1e-6) {
        final d = math.sqrt(d2);
        a.pos.x -= dx / d * (min - d);
        a.pos.z -= dz / d * (min - d);
      }
    }
  }

  void _updateProjectiles(double dt) {
    for (final pr in projectiles) {
      pr.life -= dt;
      if (pr.stuck) continue;
      pr.vel.y -= (pr.fromPlayer ? 3.5 : 5.9) * dt;
      pr.pos.x += pr.vel.x * dt;
      pr.pos.y += pr.vel.y * dt;
      pr.pos.z += pr.vel.z * dt;
      pr.spin += dt * 25;
      particles.add(PKind.streak, pr.pos.x, pr.pos.y, pr.pos.z, 0, 0, 0, 0.18,
          pr.fromPlayer ? 0.07 : 0.05)?.color = pr.fromPlayer ? 0xB0B8DCFF : 0x90E8E0D0;
      if (pr.pos.y < world.terrain.heightAt(pr.pos.x, pr.pos.z)) {
        pr.stuck = true;
        pr.life = math.min(pr.life, 3);
        particles.burst(PKind.puff, pr.pos.x, pr.pos.y + 0.05, pr.pos.z, 3, 1, 0.3, 0.08);
        continue;
      }
      for (final c in world.collidersNear(pr.pos.x, pr.pos.z)) {
        if (pr.pos.y > c.y0 && pr.pos.y < c.y1 && c.containsXZ(pr.pos.x, pr.pos.z)) {
          pr.stuck = true;
          pr.life = math.min(pr.life, 3);
          if (pr.fromPlayer) {
            particles.burst(PKind.spark, pr.pos.x, pr.pos.y, pr.pos.z, 5, 3, 0.25, 0.04);
            particles.flash(pr.pos.x, pr.pos.y, pr.pos.z, 0xE0FFE9A0, 0.35);
          }
          break;
        }
      }
      if (pr.stuck) continue;
      if (pr.fromPlayer) {
        for (final e in enemies) {
          if (!e.hostile || e.passive) continue;
          final dx = e.pos.x - pr.pos.x, dy = e.centerY - pr.pos.y, dz = e.pos.z - pr.pos.z;
          final r = 0.6 * e.style.scale;
          if (dx * dx + dz * dz < r * r && dy.abs() < 0.95 * e.style.scale) {
            final unaware = e.state == AiState.idle || e.state == AiState.blind;
            e.takeHit(this, unaware ? pr.damage * 2 : pr.damage,
                shadowStrike: false, fromYaw: math.atan2(pr.vel.x, -pr.vel.z));
            particles.flash(pr.pos.x, pr.pos.y, pr.pos.z, 0xF0E8F4FF, 0.6);
            pr.life = 0;
            break;
          }
        }
      } else {
        final dx = player.pos.x - pr.pos.x;
        final dy = player.pos.y + player.eye * 0.6 - pr.pos.y;
        final dz = player.pos.z - pr.pos.z;
        if (dx * dx + dz * dz < 0.36 && dy.abs() < 1.0) {
          damagePlayer(pr.damage, null);
          pr.life = 0;
        }
      }
    }
    projectiles.removeWhere((p) => p.life <= 0);
  }

  void _updatePickups() {
    final p = player;
    for (final pk in pickups) {
      if (pk.taken) continue;
      final dx = pk.pos.x - p.pos.x, dz = pk.pos.z - p.pos.z;
      if (dx * dx + dz * dz > 2.6 || (pk.pos.y - p.pos.y).abs() > 2.5) continue;
      switch (pk.kind) {
        case 'health':
          if (p.hp >= Player.maxHp) continue;
          p.hp = math.min(Player.maxHp, p.hp + 45);
          toast(tr('toast.health'));
        case 'supply':
          p.shuriken = math.min(Player.maxShuriken, p.shuriken + 8);
          p.smoke = math.min(Player.maxSmoke, p.smoke + 2);
          toast(tr('toast.supply'));
        case 'scroll':
          collected++;
          if (pk.def.codex != null) _unlock(pk.def.codex!);
          showDialog(pk.def.dialog);
      }
      pk.taken = true;
      particles.ring(pk.pos.x, pk.pos.y, pk.pos.z, (0xC0 << 24) | (pk.glow & 0xFFFFFF), 2.2);
      particles.flash(pk.pos.x, pk.pos.y + 0.8, pk.pos.z, pk.glow, 0.7);
    }
  }

  /// Spawn-rate multiplier that keeps heavy effect models (see Fx) inside the
  /// frame budget: a model with more triangles than [reference] spawns fewer,
  /// slightly larger copies.
  static double _emitScale(ObjMesh? m, int reference) =>
      m == null ? 1 : (reference / math.max(reference, m.triangleCount)).clamp(0.3, 1.0);

  /// Frame-rate independent spawn count for [rate] per second.
  int _spawnCount(double rate, double dt) {
    final x = rate * dt;
    return x.floor() + (rng.nextDouble() < x - x.floor() ? 1 : 0);
  }

  void _ambient(double dt) {
    final p = player;
    final flameK = _emitScale(Fx.flame, 16);
    for (final f in world.fires) {
      final dx = f.x - p.pos.x, dz = f.z - p.pos.z;
      if (dx * dx + dz * dz > 75 * 75) continue;
      final n = _spawnCount(15 * f.size * flameK, dt);
      final grow = 1 + (1 - flameK) * 0.6;
      for (var i = 0; i < n; i++) {
        particles.add(PKind.flame, f.x + (rng.nextDouble() - 0.5) * f.size * 1.4, f.y,
            f.z + (rng.nextDouble() - 0.5) * f.size * 1.4, (rng.nextDouble() - 0.5) * 0.4,
            1.2 + rng.nextDouble() * 1.6, (rng.nextDouble() - 0.5) * 0.4,
            0.5 + rng.nextDouble() * 0.5, (0.45 * f.size + rng.nextDouble() * 0.25) * grow);
      }
      if (rng.nextDouble() < dt * 3 * _emitScale(Fx.smoke, 24)) {
        particles.add(PKind.smoke, f.x, f.y + 2.5, f.z, 0.3, 1.2, 0.1, 3.0, 0.5 * f.size);
      }
    }
    if (chapter.petals && rng.nextDouble() < dt * 14 * _emitScale(Fx.petal, 8)) {
      final a = rng.nextDouble() * pi2, d = rng.nextDouble() * 22;
      particles.add(PKind.petal, p.pos.x + math.cos(a) * d, p.pos.y + 6 + rng.nextDouble() * 4,
          p.pos.z + math.sin(a) * d, 0, -0.9, 0, 7, 0.06);
    }
    if (chapter.embers && rng.nextDouble() < dt * 10 * _emitScale(Fx.ember, 8)) {
      final a = rng.nextDouble() * pi2, d = rng.nextDouble() * 18;
      particles.add(PKind.ember, p.pos.x + math.cos(a) * d, p.pos.y + rng.nextDouble() * 2,
          p.pos.z + math.sin(a) * d, 0.3, 0.8 + rng.nextDouble(), 0.2, 4, 0.05);
    }
  }

  // ------------------------------------------------------------------ render

  void render(Canvas canvas, Size size) {
    final p = player;
    final cam = camera;
    final baseYaw = cam.yaw, basePitch = cam.pitch;
    if (p.shake > 0) {
      cam.yaw += (rng.nextDouble() - 0.5) * p.shake * 0.06;
      cam.pitch += (rng.nextDouble() - 0.5) * p.shake * 0.06;
    }
    final r = renderer..begin(cam, size, lighting, viewDistance);
    sky.paint(canvas, size, r, lighting, time);
    world.render(r);

    _dyn.clear();
    final b = _dynB;
    if (p.camDist > 0.9) {
      drawFigure(b, p.pos.x, p.pos.y, p.pos.z, p.facing, FigureStyle.essen, p.anim, lod: Lod.high);
    }
    _slashTrail(b);
    // Visible characters, nearest first, so the high-detail budget goes to
    // the closest ones; the rest use cheaper levels of detail.
    final visible = <(double, Enemy?, Npc?)>[];
    for (final e in enemies) {
      if (e.state == AiState.dead && e.deadT > 45) continue;
      if (!r.sphereVisible(e.pos.x, e.pos.y + 1, e.pos.z, 1.6 * e.style.scale)) continue;
      final d = r.distanceTo(e.pos.x, e.pos.y + 1, e.pos.z);
      if (d <= viewDistance) visible.add((d, e, null));
    }
    for (final n in npcs) {
      if (!n.visible || !r.sphereVisible(n.pos.x, n.pos.y + 1, n.pos.z, 1.6)) continue;
      visible.add((r.distanceTo(n.pos.x, n.pos.y + 1, n.pos.z), null, n));
    }
    visible.sort((a, b) => a.$1.compareTo(b.$1));
    var highLeft = Lod.maxHigh;
    for (final (d, e, n) in visible) {
      var lod = lodForDistance(d);
      if (lod == Lod.high && highLeft-- <= 0) lod = Lod.mid;
      if (e != null) {
        e.draw(b, lod: lod);
        _enemyMarker(b, e);
      } else {
        drawFigure(b, n!.pos.x, n.pos.y, n.pos.z, n.yaw, n.style, n.anim, lod: lod);
      }
    }
    for (final pk in pickups) {
      if (pk.taken || !r.sphereVisible(pk.pos.x, pk.pos.y + 1, pk.pos.z, 2)) continue;
      pk.draw(b, time);
    }
    for (final pr in projectiles) {
      if (!r.sphereVisible(pr.pos.x, pr.pos.y, pr.pos.z, 0.7)) continue;
      pr.draw(b);
    }
    _objectiveBeacon(b);
    particles.draw(b, cam, r);
    _dyn.relight(lighting);
    r.drawBatch(_dyn);
    r.flush(canvas);
    cam
      ..yaw = baseYaw
      ..pitch = basePitch;
  }

  /// Crescent slash arc (slash_arc.obj) following the current cut.
  void _slashTrail(MeshBuilder b) {
    final p = player;
    final arc = Fx.slashArc;
    if (p.attackT < 0 || arc == null) return;
    final t = p.attackT / swingTime;
    if (t < 0.16 || t > 0.72) return;
    final k = (t - 0.16) / 0.56; // 0 → 1 across the visible window
    final alpha = math.sin(k * math.pi).clamp(0.0, 1.0);
    b.reset();
    b.translate(p.pos.x, p.pos.y + 1.2 - p.anim.crouch * 0.38, p.pos.z);
    b.rotateY(-p.facing);
    switch (p.combo) {
      case 1: // right → left: bright edge ends on the left
        b.rotateY(-0.35 + k * 0.7);
      case 2: // backhand: mirrored
        b.rotateY(0.35 - k * 0.7);
        b.scale(-1, 1, 1);
      default: // overhead: vertical arc, bright edge at the bottom front
        b.rotateZ(math.pi / 2);
        b.rotateY(-0.3 + k * 0.6);
    }
    b.mesh(arc, alpha: alpha, tint: p.combo == 0 ? 0xFFF0D8 : null, tintAmount: 0.5);
  }

  /// Floating 3D awareness marker and health bar over an enemy.
  void _enemyMarker(MeshBuilder b, Enemy e) {
    if (!e.hostile || e.passive) return;
    if (e.pos.distXZ(player.pos) > 45) return;
    final top = e.pos.y + 2.25 * e.style.scale;
    final bob = math.sin(time * 5 + e.pos.x) * 0.06;
    b.reset();
    if (e.state == AiState.alert) {
      final m = Fx.alert;
      if (m != null) {
        b.translate(e.pos.x, top + 0.25 + bob, e.pos.z);
        b.rotateY(time * 2);
        b.mesh(m);
      }
    } else if (e.state == AiState.blind) {
      final m = Fx.blind;
      if (m != null) {
        b.translate(e.pos.x, top, e.pos.z);
        b.rotateY(time * 4);
        b.mesh(m);
      }
    } else if (e.suspicion > 0.04) {
      final m = Fx.suspicion;
      if (m != null) {
        final s = 0.8 + 1.2 * e.suspicion.clamp(0, 1);
        b.translate(e.pos.x, top + 0.2 + bob, e.pos.z);
        b.rotateY(time * 4);
        b.scale(s, s, s);
        b.mesh(m, tint: 0xFF9A20, tintAmount: e.suspicion.clamp(0.0, 1.0) * 0.6);
      }
    }
    // Billboard health bar (bar_quad.obj) for wounded regular foes.
    final bar = Fx.bar;
    if (bar != null && e.hp < e.stats.hp && !e.isBossLike) {
      const w = 0.9, h = 0.08;
      final f = (e.hp / e.stats.hp).clamp(0.0, 1.0);
      b.reset();
      b.translate(e.pos.x, top + 0.02, e.pos.z);
      b.billboard(camera.yaw, camera.pitch);
      b.translate(-w / 2, 0, 0);
      b.push();
      b.scale(w, h, 1);
      b.mesh(bar, alpha: 0.75, tint: 0x101010, tintAmount: 1);
      b.pop();
      b.translate(0, 0, 0.01);
      b.scale(w * f, h, 1);
      b.mesh(bar, tint: 0xD63A2F, tintAmount: 1);
    }
  }

  /// Golden light pillar (objective_beacon.obj) and gem over the objective.
  void _objectiveBeacon(MeshBuilder b) {
    final o = objective;
    final t = objectiveTarget;
    final gem = Fx.gem, beacon = Fx.beacon;
    if (o == null || t == null || phase != Phase.playing || gem == null || beacon == null) return;
    final d = t.distXZ(player.pos);
    final pulse = 1 + math.sin(time * 3) * 0.15;
    b.reset();
    if (o.type == ObjType.eliminate || o.type == ObjType.defeat) {
      // A small gem over the nearest target instead of a pillar.
      b.translate(t.x, t.y + 3.7 + math.sin(time * 4) * 0.1, t.z);
      b.rotateY(time * 2);
      b.scale(0.45 * pulse, 0.45 * pulse, 0.45 * pulse);
      b.mesh(gem, tint: 0xFFC040, tintAmount: 0.5);
      return;
    }
    if (d < 3) return;
    final w = math.max(0.5, d * 0.012) * pulse;
    b.translate(t.x, t.y, t.z);
    b.push();
    b.rotateY(time * 0.3);
    b.scale(w, 45, w);
    b.mesh(beacon);
    b.pop();
    b.translate(0, 2.6 + math.sin(time * 2) * 0.15, 0);
    b.rotateY(time * 1.5);
    b.scale(pulse, pulse, pulse);
    b.mesh(gem);
  }
}
