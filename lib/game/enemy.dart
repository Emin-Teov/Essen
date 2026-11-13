import 'dart:math' as math;

import '../engine/math3d.dart';
import '../engine/mesh.dart';
import '../l10n/l10n.dart';
import '../story/story.dart';
import 'effects.dart';
import 'figures.dart';
import 'game.dart';

enum AiState { idle, suspicious, alert, blind, yielded, dead }

class EnemyStats {
  final double hp, walk, run, range, damage, windup, cooldown, block;
  const EnemyStats(this.hp, this.walk, this.run, this.range, this.damage,
      this.windup, this.cooldown, this.block);

  static const samurai = EnemyStats(100, 1.5, 4.4, 2.1, 16, 0.6, 0.95, 0.18);
  static const archer = EnemyStats(60, 1.4, 3.8, 24, 11, 0.95, 2.0, 0);
  static const rival = EnemyStats(420, 1.6, 5.0, 2.3, 17, 0.45, 0.75, 0.35);
  static const boss = EnemyStats(720, 1.6, 5.0, 2.8, 24, 0.55, 0.75, 0.28);
}

class Enemy {
  final EnemyKind kind;
  final String group;
  final Vec3 pos;
  final Vec3 home;
  final double wander;
  final EnemyStats stats;
  final FigureStyle style;
  final FigureAnim anim = FigureAnim();
  final math.Random rng;

  double yaw;
  late double hp;
  AiState state = AiState.idle;
  double suspicion = 0;
  double tx, tz; // patrol target
  double idleTimer = 0;
  double lastX = 0, lastZ = 0; // last known player position
  double lostSight = 0;
  double cooldown = 0;
  int attackPhase = 0; // 0 none, 1 windup, 2 follow-through
  double attackT = 0;
  double blindT = 0;
  double staggerT = 0;
  double deadT = 0;
  double hitFlash = 0;
  bool passive = false; // waits (rival before the duel)
  bool halfTriggered = false;

  Enemy(this.kind, this.group, double x, double y, double z, this.wander, int seed)
      : pos = Vec3(x, y, z),
        home = Vec3(x, y, z),
        tx = x,
        tz = z,
        rng = math.Random(seed),
        yaw = math.Random(seed).nextDouble() * pi2,
        stats = switch (kind) {
          EnemyKind.samurai => EnemyStats.samurai,
          EnemyKind.archer => EnemyStats.archer,
          EnemyKind.rival => EnemyStats.rival,
          EnemyKind.boss => EnemyStats.boss,
        },
        style = switch (kind) {
          EnemyKind.samurai => FigureStyle.samurai,
          EnemyKind.archer => FigureStyle.archer,
          EnemyKind.rival => FigureStyle.rival,
          EnemyKind.boss => FigureStyle.boss,
        } {
    hp = stats.hp;
  }

  bool get alive => state != AiState.dead;
  bool get hostile => alive && state != AiState.yielded;
  bool get isBossLike => kind == EnemyKind.boss || kind == EnemyKind.rival;
  bool get ranged => kind == EnemyKind.archer;
  bool get aware => state == AiState.alert;
  double get centerY => pos.y + 1.1 * style.scale;

  void resetToHome() {
    if (!alive) return;
    pos.setFrom(home);
    hp = stats.hp;
    state = AiState.idle;
    suspicion = 0;
    attackPhase = 0;
    cooldown = 0;
    halfTriggered = false;
    anim.armRaise = 0.25;
  }

  void alert(double px, double pz) {
    if (!hostile || passive) return;
    if (state != AiState.alert) {
      state = AiState.alert;
      suspicion = 1;
    }
    lastX = px;
    lastZ = pz;
    lostSight = 0;
  }

  // ------------------------------------------------------------------ update

  void update(Game g, double dt) {
    hitFlash = math.max(0, hitFlash - dt * 4);
    if (state == AiState.dead) {
      deadT += dt;
      anim.fall = math.min(1, deadT / 0.6);
      anim.walkAmount = 0;
      return;
    }
    if (state == AiState.yielded) {
      anim.pose = Pose.kneel;
      anim.walkAmount = 0;
      anim.armRaise = 0.1;
      return;
    }
    cooldown -= dt;
    final p = g.player;
    final dx = p.pos.x - pos.x, dz = p.pos.z - pos.z;
    final dist = math.sqrt(dx * dx + dz * dz);
    final toPlayer = math.atan2(dx, -dz);

    if (staggerT > 0) {
      staggerT -= dt;
      anim.walkAmount = 0;
      _settle(g);
      return;
    }

    if (state == AiState.blind) {
      blindT -= dt;
      anim.armRaise = 1.9 + math.sin(blindT * 9) * 0.3;
      anim.walkAmount = 0.4;
      anim.walkPhase += dt * 4;
      yaw += math.sin(blindT * 3) * dt * 2;
      if (blindT <= 0) {
        state = AiState.suspicious;
        suspicion = 0.5;
        lastX = p.pos.x;
        lastZ = p.pos.z;
        anim.armRaise = 0.25;
      }
      _settle(g);
      return;
    }

    if (passive) {
      yaw = _turn(yaw, toPlayer, dt * 2);
      anim.walkAmount = 0;
      _settle(g);
      return;
    }

    // Perception.
    final seen = _canSee(g, dist, toPlayer);
    if (seen) {
      final range = _viewRange(g);
      final close = dist < (p.crouch ? 1.5 : 3.0);
      final rate = close ? 4.0 : (1 - dist / range) * 2.4 + 0.3;
      suspicion = math.min(1.5, suspicion + rate * dt);
    } else if (state != AiState.alert) {
      suspicion = math.max(0, suspicion - 0.22 * dt);
    }

    switch (state) {
      case AiState.idle:
        _patrol(g, dt);
        if (suspicion > 0.3) {
          state = AiState.suspicious;
          lastX = p.pos.x;
          lastZ = p.pos.z;
        }
      case AiState.suspicious:
        if (seen) {
          lastX = p.pos.x;
          lastZ = p.pos.z;
        }
        final ldx = lastX - pos.x, ldz = lastZ - pos.z;
        final ld = math.sqrt(ldx * ldx + ldz * ldz);
        if (ld > 1.5) {
          _moveTo(g, lastX, lastZ, stats.walk * 0.8, dt);
        } else {
          anim.walkAmount = 0;
          yaw += dt * 0.8;
        }
        if (suspicion >= 1) {
          g.raiseAlarm(this);
        } else if (suspicion <= 0) {
          state = AiState.idle;
          tx = home.x;
          tz = home.z;
        }
      case AiState.alert:
        if (seen) {
          lastX = p.pos.x;
          lastZ = p.pos.z;
          lostSight = 0;
        } else {
          lostSight += dt;
          if (lostSight > 8 && attackPhase == 0) {
            state = AiState.suspicious;
            suspicion = 0.7;
          }
        }
        if (attackPhase != 0) {
          _attack(g, dt, dist, toPlayer);
        } else if (ranged) {
          _archer(g, dt, dist, toPlayer, seen);
        } else {
          _melee(g, dt, dist, toPlayer);
        }
      default:
        break;
    }
    _settle(g);
  }

  double _viewRange(Game g) {
    var r = g.player.crouch ? 11.0 : 24.0;
    if (g.lighting.night) r *= 0.7;
    if (g.player.sprinting) r *= 1.25;
    return r;
  }

  bool _canSee(Game g, double dist, double toPlayer) {
    if (g.player.hiddenT > 0 || g.player.dead) return false;
    final range = _viewRange(g);
    if (dist > range) return false;
    final ang = wrapAngle(toPlayer - yaw).abs();
    final near = dist < (g.player.crouch ? 1.6 : 3.5);
    if (ang > 1.05 && !near && state != AiState.alert) return false;
    if (state == AiState.alert && ang > 1.6 && !near) return false;
    return g.world.lineOfSight(pos.x, pos.y + 1.6, pos.z, g.player.pos.x,
        g.player.pos.y + g.player.eye, g.player.pos.z);
  }

  void _patrol(Game g, double dt) {
    if (wander <= 0.5) {
      anim.walkAmount = 0;
      return;
    }
    final dx = tx - pos.x, dz = tz - pos.z;
    if (dx * dx + dz * dz < 1.0) {
      anim.walkAmount = 0;
      idleTimer -= dt;
      if (idleTimer <= 0) {
        final a = rng.nextDouble() * pi2, d = rng.nextDouble() * wander;
        tx = home.x + math.cos(a) * d;
        tz = home.z + math.sin(a) * d;
        idleTimer = 2 + rng.nextDouble() * 4;
      }
      return;
    }
    _moveTo(g, tx, tz, stats.walk, dt);
  }

  void _melee(Game g, double dt, double dist, double toPlayer) {
    final range = stats.range * style.scale;
    if (dist > range * 0.85) {
      _moveTo(g, lastX, lastZ, stats.run, dt);
    } else {
      anim.walkAmount = 0;
      yaw = _turn(yaw, toPlayer, dt * 7);
    }
    if (cooldown <= 0 && dist < range + 0.3) {
      attackPhase = 1;
      attackT = 0;
    }
  }

  void _archer(Game g, double dt, double dist, double toPlayer, bool seen) {
    if (!seen || dist > 22) {
      _moveTo(g, lastX, lastZ, stats.run, dt);
      return;
    }
    if (dist < 6) {
      // Back away while facing the player.
      yaw = _turn(yaw, toPlayer, dt * 6);
      final bx = pos.x - math.sin(yaw) * 2, bz = pos.z + math.cos(yaw) * 2;
      final f = stats.walk * dt;
      pos.x += (bx - pos.x) / 2 * f;
      pos.z += (bz - pos.z) / 2 * f;
      anim.walkAmount = 0.6;
      anim.walkPhase -= dt * 6;
    } else {
      anim.walkAmount = 0;
      yaw = _turn(yaw, toPlayer, dt * 6);
    }
    if (cooldown <= 0) {
      attackPhase = 1;
      attackT = 0;
    }
  }

  void _attack(Game g, double dt, double dist, double toPlayer) {
    attackT += dt;
    var windup = stats.windup;
    if (kind == EnemyKind.boss && hp < stats.hp / 2) windup *= 0.75;
    anim.walkAmount = 0;
    if (ranged) {
      if (attackPhase == 1) {
        yaw = _turn(yaw, toPlayer, dt * 6);
        anim.bowDraw = math.min(1, attackT / windup);
        if (attackT >= windup) {
          g.fireArrow(this);
          attackPhase = 2;
          attackT = 0;
          anim.bowDraw = 0;
        }
      } else if (attackT > 0.3) {
        attackPhase = 0;
        cooldown = stats.cooldown * (0.8 + rng.nextDouble() * 0.5);
      }
      return;
    }
    if (attackPhase == 1) {
      if (attackT < windup * 0.7) yaw = _turn(yaw, toPlayer, dt * 5);
      anim.armRaise = lerpD(0.25, 2.75, math.min(1, attackT / windup));
      if (attackT >= windup) {
        attackPhase = 2;
        attackT = 0;
        final range = stats.range * style.scale + 0.45;
        final ang = wrapAngle(toPlayer - yaw).abs();
        if (dist < range && ang < 0.95 && (g.player.pos.y - pos.y).abs() < 2) {
          g.damagePlayer(stats.damage, this);
        }
      }
    } else {
      anim.armRaise = lerpD(2.75, 0.5, math.min(1, attackT / 0.14));
      if (attackT > 0.45) {
        attackPhase = 0;
        anim.armRaise = 0.25;
        cooldown = stats.cooldown * (0.8 + rng.nextDouble() * 0.6);
      }
    }
  }

  double _turn(double from, double to, double maxStep) {
    final d = wrapAngle(to - from);
    if (d.abs() <= maxStep) return to;
    return from + d.sign * maxStep;
  }

  void _moveTo(Game g, double x, double z, double speed, double dt) {
    final want = math.atan2(x - pos.x, -(z - pos.z));
    yaw = _turn(yaw, want, dt * 6);
    final facing = wrapAngle(want - yaw).abs() < 1.2;
    if (!facing) {
      anim.walkAmount = 0.2;
      return;
    }
    var s = speed;
    if (g.world.terrain.heightAt(pos.x, pos.z) < -2.6) s *= 0.6;
    pos.x += math.sin(yaw) * s * dt;
    pos.z -= math.cos(yaw) * s * dt;
    anim.walkAmount = math.min(1, s / 3);
    anim.walkPhase += dt * s * 2.6;
  }

  void _settle(Game g) {
    g.world.collide(pos, 0.4 * style.scale, 1.8);
    pos.y = g.world.groundAt(pos.x, pos.z, pos.y + 0.3);
  }

  // ------------------------------------------------------------------ combat

  /// Returns true if the hit landed (not blocked).
  bool takeHit(Game g, double dmg, {required bool shadowStrike, double fromYaw = 0}) {
    if (!hostile) return false;
    if (shadowStrike) {
      hp = 0;
      _die(g);
      return true;
    }
    final facingPlayer = wrapAngle(fromYaw + math.pi - yaw).abs() < 0.9;
    if (state == AiState.alert && attackPhase != 1 && facingPlayer &&
        rng.nextDouble() < stats.block) {
      g.particles.burst(PKind.spark, pos.x + math.sin(yaw) * 0.5, centerY + 0.2,
          pos.z - math.cos(yaw) * 0.5, 10, 4, 0.35, 0.05);
      g.toast(tr('toast.blocked'));
      cooldown = math.min(cooldown, 0.2);
      return false;
    }
    hp -= dmg;
    hitFlash = 1;
    g.particles.burst(PKind.blood, pos.x, centerY, pos.z, 8, 3, 0.6, 0.06);
    if (kind == EnemyKind.rival && hp <= stats.hp * 0.3) {
      hp = stats.hp * 0.3;
      state = AiState.yielded;
      attackPhase = 0;
      return true;
    }
    if (hp <= 0) {
      _die(g);
      return true;
    }
    if (!isBossLike || rng.nextDouble() < 0.25) {
      staggerT = 0.32;
      attackPhase = 0;
      anim.armRaise = 0.25;
    }
    alert(g.player.pos.x, g.player.pos.z);
    g.raiseAlarm(this);
    if (kind == EnemyKind.boss && !halfTriggered && hp < stats.hp / 2) {
      halfTriggered = true;
      g.onBossHalf();
    }
    return true;
  }

  void _die(Game g) {
    state = AiState.dead;
    deadT = 0;
    attackPhase = 0;
    g.particles.burst(PKind.blood, pos.x, centerY, pos.z, 16, 4, 0.8, 0.07);
    g.onEnemyKilled(this);
  }

  // ------------------------------------------------------------------ render

  void draw(MeshBuilder b, {int lod = Lod.mid}) {
    if (state == AiState.dead && deadT > 45) return;
    drawFigure(b, pos.x, pos.y, pos.z, yaw, style, anim, lod: lod);
  }
}
