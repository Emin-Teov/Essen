import 'dart:math' as math;

import '../engine/math3d.dart';
import '../engine/mesh.dart';
import '../engine/obj_mesh.dart';
import '../engine/renderer.dart';
import '../story/story.dart';
import 'fx.dart';

class Projectile {
  final Vec3 pos;
  final Vec3 vel;
  final bool fromPlayer;
  final double damage;
  double life = 4;
  double spin = 0;
  bool stuck = false;

  Projectile(this.pos, this.vel, {required this.fromPlayer, required this.damage});

  void draw(MeshBuilder b) {
    final m = fromPlayer ? Fx.shuriken : Fx.arrow;
    if (m == null) return;
    b.reset();
    b.translate(pos.x, pos.y, pos.z);
    final hz = math.sqrt(vel.x * vel.x + vel.z * vel.z);
    b.rotateY(math.atan2(vel.x, vel.z));
    if (fromPlayer) {
      b.rotateY(spin);
    } else {
      b.rotateX(-math.atan2(vel.y, hz));
    }
    b.mesh(m);
  }
}

enum PKind { spark, smoke, flame, petal, blood, ember, puff, flash, ring, streak }

class Particle {
  double x, y, z, vx, vy, vz;
  double life, maxLife, size;
  final PKind kind;
  double phase;
  int color = 0xFFFFFFFF; // tint for flash / ring / streak

  Particle(this.kind, this.x, this.y, this.z, this.vx, this.vy, this.vz,
      this.life, this.size)
      : maxLife = life,
        phase = 0;
}

/// All transient 3D effects. Each particle is an instance of an OBJ model from
/// [Fx], placed, scaled, tinted and faded per frame.
class Particles {
  static const int maxCount = 700;
  final List<Particle> list = [];
  final math.Random rng = math.Random(5);

  Particle? add(PKind kind, double x, double y, double z, double vx, double vy,
      double vz, double life, double size) {
    if (list.length >= maxCount) return null;
    final p = Particle(kind, x, y, z, vx, vy, vz, life, size)..phase = rng.nextDouble() * pi2;
    list.add(p);
    return p;
  }

  void burst(PKind kind, double x, double y, double z, int n, double speed,
      double life, double size) {
    for (var i = 0; i < n; i++) {
      final a = rng.nextDouble() * pi2;
      final e = rng.nextDouble() * 2 - 0.6;
      final s = speed * (0.4 + rng.nextDouble() * 0.6);
      add(kind, x, y, z, math.cos(a) * s, e * s, math.sin(a) * s,
          life * (0.6 + rng.nextDouble() * 0.6), size);
    }
  }

  /// Star-burst impact flash (impact_flash.obj).
  void flash(double x, double y, double z, int color, double size) {
    add(PKind.flash, x, y, z, 0, 0, 0, 0.16, size)?.color = color;
  }

  /// Expanding ground shockwave (shockwave_ring.obj).
  void ring(double x, double y, double z, int color, double radius, {double life = 0.45}) {
    add(PKind.ring, x, y + 0.06, z, 0, 0, 0, life, radius)?.color = color;
  }

  void update(double dt) {
    for (final p in list) {
      p.life -= dt;
      switch (p.kind) {
        case PKind.spark:
        case PKind.blood:
          p.vy -= 12 * dt;
        case PKind.flame:
          p.vy += 1.5 * dt;
        case PKind.smoke:
          p.vx *= 1 - dt * 1.5;
          p.vz *= 1 - dt * 1.5;
          p.vy *= 1 - dt * 1.2;
          p.size += dt * 0.9;
        case PKind.puff:
          p.size += dt * 1.5;
          p.vx *= 1 - dt * 3;
          p.vz *= 1 - dt * 3;
        case PKind.petal:
          p.phase += dt * 2;
          p.vx = math.sin(p.phase) * 0.8 + 0.6;
          p.vz = math.cos(p.phase * 0.7) * 0.6;
        case PKind.ember:
          p.phase += dt * 3;
          p.vx += math.sin(p.phase) * dt * 2;
        case PKind.flash:
        case PKind.ring:
        case PKind.streak:
          break;
      }
      p.x += p.vx * dt;
      p.y += p.vy * dt;
      p.z += p.vz * dt;
    }
    list.removeWhere((p) => p.life <= 0);
  }

  static double _alphaOf(int c) => ((c >> 24) & 255) / 255;

  void draw(MeshBuilder b, Camera cam, Renderer r) {
    for (final p in list) {
      final t = 1 - p.life / p.maxLife; // 0 → 1 over lifetime
      final dx = p.x - cam.x, dy = p.y - cam.y, dz = p.z - cam.z;
      final d2 = dx * dx + dy * dy + dz * dz;
      if (d2 > 90 * 90) continue;
      // Skip effects outside the view or smaller than about a pixel before
      // spending time building their model.
      final radius = p.kind == PKind.ring ? p.size * 1.3 : p.size * 2.5;
      if (radius * r.focal < 0.7 * math.sqrt(d2)) continue;
      if (!r.sphereVisible(p.x, p.y, p.z, radius)) continue;
      final ObjMesh? m;
      var s = p.size;
      var alpha = 1.0;
      int? tint;
      var tintAmount = 0.0;
      var billboard = false;
      double spinY = p.phase, spinX = 0;
      switch (p.kind) {
        case PKind.smoke:
          m = Fx.smoke;
          tint = 0xC8CACE;
          tintAmount = t;
          alpha = math.min(t / 0.12, 1) * (1 - t);
        case PKind.puff:
          m = Fx.dust;
          alpha = 1 - t;
        case PKind.flame:
          m = Fx.flame;
          s *= (1 - t * 0.7) * 1.3;
          tint = 0x8A1E0A;
          tintAmount = t * 0.85;
        case PKind.spark:
          m = Fx.spark;
          s *= 2.5;
          spinX = p.phase;
        case PKind.blood:
          m = Fx.blood;
          s *= 1.8;
          spinX = p.phase;
        case PKind.petal:
          m = Fx.petal;
          s *= 1.6;
          spinX = p.phase * 0.7;
        case PKind.ember:
          m = Fx.ember;
          s *= 2.2 * (1 - t * 0.5);
          tint = 0xAA2A10;
          tintAmount = t;
        case PKind.streak:
          m = Fx.streak;
          s *= 1.2 * (1 - t * 0.6);
          alpha = _alphaOf(p.color) * (1 - t);
          tint = p.color;
          tintAmount = 1;
          billboard = true;
        case PKind.flash:
          m = Fx.flash;
          s *= 0.6 + t * 0.8;
          alpha = _alphaOf(p.color) * (1 - t);
          tint = p.color;
          tintAmount = 0.7;
          billboard = true;
        case PKind.ring:
          m = Fx.ring;
          alpha = _alphaOf(p.color) * (1 - t);
          tint = p.color;
          tintAmount = 1;
      }
      if (m == null) continue;
      b.reset();
      b.translate(p.x, p.y, p.z);
      if (p.kind == PKind.ring) {
        final rr = p.size * (0.25 + t * 0.95);
        b.scale(rr, 1, rr);
      } else {
        if (billboard) {
          b.billboard(cam.yaw, cam.pitch);
          b.rotateZ(spinY);
        } else {
          b.rotateY(spinY);
          if (spinX != 0) b.rotateX(spinX);
        }
        b.scale(s, s, s);
      }
      b.mesh(m, alpha: alpha, tint: tint, tintAmount: tintAmount);
    }
  }
}

class Pickup {
  final PickupDef def;
  final Vec3 pos;
  bool taken = false;

  Pickup(this.def, this.pos);

  String get kind => def.kind;

  int get glow => def.kind == 'scroll' ? 0xFFFFD27A : (def.kind == 'supply' ? 0xFF9EC8FF : 0xFFA8F0A0);

  void draw(MeshBuilder b, double time) {
    final item = switch (def.kind) {
      'scroll' => Fx.scroll,
      'supply' => Fx.supply,
      _ => Fx.onigiri,
    };
    final bob = math.sin(time * 2.5 + pos.x) * 0.12;
    if (item != null) {
      b.reset();
      b.translate(pos.x, pos.y + 0.7 + bob, pos.z);
      b.rotateY(time * 1.6);
      if (def.kind == 'scroll') b.rotateZ(0.5);
      b.mesh(item);
    }
    final ring = Fx.pickupRing;
    if (ring != null) {
      b.reset();
      b.translate(pos.x, pos.y + 0.05, pos.z);
      b.rotateY(time);
      final s = 1 + math.sin(time * 3) * 0.06;
      b.scale(s, 1, s);
      b.mesh(ring, tint: glow, tintAmount: 1);
    }
    final mote = Fx.ember;
    if (mote != null) {
      for (var k = 0; k < 3; k++) {
        final ph = (time * 0.6 + k / 3) % 1.0;
        final a = k * 2.1 + time;
        b.reset();
        b.translate(pos.x + math.cos(a) * 0.5, pos.y + ph * 1.8, pos.z + math.sin(a) * 0.5);
        b.rotateY(a);
        b.scale(0.5, 0.5, 0.5);
        b.mesh(mote, alpha: 1 - ph, tint: glow, tintAmount: 1);
      }
    }
  }
}
