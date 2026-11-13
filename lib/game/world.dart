import 'dart:math' as math;

import '../engine/math3d.dart';
import '../engine/mesh.dart';
import '../engine/noise.dart';
import '../engine/renderer.dart';
import 'props.dart';
import 'terrain.dart';

/// Oriented box (or circle) obstacle. Walkable when the feet are near its top.
class Collider {
  final double x, z, hx, hz, c, s, y0, y1;
  final bool circle;

  Collider.box(this.x, this.z, double w, double d, double yaw, this.y0, this.y1)
      : hx = w / 2,
        hz = d / 2,
        c = math.cos(yaw),
        s = math.sin(yaw),
        circle = false;

  Collider.circle(this.x, this.z, double r, this.y0, this.y1)
      : hx = r,
        hz = r,
        c = 1,
        s = 0,
        circle = true;

  double get radius => circle ? hx : math.sqrt(hx * hx + hz * hz);

  bool containsXZ(double px, double pz) {
    final dx = px - x, dz = pz - z;
    if (circle) return dx * dx + dz * dz <= hx * hx;
    final lx = c * dx - s * dz, lz = s * dx + c * dz;
    return lx.abs() <= hx && lz.abs() <= hz;
  }
}

class Chunk {
  final TriBatch terrain = TriBatch(160);
  final TriBatch props = TriBatch(256);
  final TriBatch flora = TriBatch(256);
  final List<Collider> colliders = [];
  late final double cx, cz;
}

class FirePoint {
  final double x, y, z, size;
  FirePoint(this.x, this.y, this.z, this.size);
}

class World {
  static const double chunkSize = 32;
  static const int perSide = 20;
  static const double floraDistance = 105;

  final Terrain terrain = Terrain();
  final List<Chunk> chunks = List.generate(perSide * perSide, (_) => Chunk());
  final List<FirePoint> fires = [];
  final Map<String, Vec3> points = {};
  final math.Random rng = math.Random(7);
  final Noise2D _noise = const Noise2D(99);

  World() {
    for (var j = 0; j < perSide; j++) {
      for (var i = 0; i < perSide; i++) {
        chunks[j * perSide + i]
          ..cx = -Terrain.half + (i + 0.5) * chunkSize
          ..cz = -Terrain.half + (j + 0.5) * chunkSize;
      }
    }
    _buildTerrain();
    _buildKasumi();
    _buildCamp();
    _buildHanamura();
    _buildShrine();
    _buildCastle();
    _buildBridge(150, 'bridgeNorth');
    _buildBridge(-100, 'bridgeSouth');
    _scatter();
    for (final c in chunks) {
      c.terrain.finish();
      c.props.finish();
      c.flora.finish();
    }
    _builders.clear();
  }

  // ---------------------------------------------------------------- queries

  Chunk? chunkAt(double x, double z) {
    final i = ((x + Terrain.half) / chunkSize).floor();
    final j = ((z + Terrain.half) / chunkSize).floor();
    if (i < 0 || j < 0 || i >= perSide || j >= perSide) return null;
    return chunks[j * perSide + i];
  }

  Iterable<Collider> collidersNear(double x, double z) sync* {
    final i0 = ((x + Terrain.half) / chunkSize).floor();
    final j0 = ((z + Terrain.half) / chunkSize).floor();
    for (var j = j0 - 1; j <= j0 + 1; j++) {
      for (var i = i0 - 1; i <= i0 + 1; i++) {
        if (i < 0 || j < 0 || i >= perSide || j >= perSide) continue;
        yield* chunks[j * perSide + i].colliders;
      }
    }
  }

  /// Highest walkable surface under (x, z) reachable from [feetY].
  double groundAt(double x, double z, double feetY, {double stepUp = 0.55}) {
    var g = terrain.heightAt(x, z);
    for (final c in collidersNear(x, z)) {
      if (c.y1 > g && c.y1 <= feetY + stepUp && c.containsXZ(x, z)) g = c.y1;
    }
    return g;
  }

  /// Pushes a cylinder (feet at p, given radius/height) out of obstacles.
  void collide(Vec3 p, double r, double height, {double stepUp = 0.55}) {
    for (final c in collidersNear(p.x, p.z)) {
      if (p.y + height < c.y0 || p.y >= c.y1 - stepUp) continue;
      final dx = p.x - c.x, dz = p.z - c.z;
      if (c.circle) {
        final rr = c.hx + r;
        final d2 = dx * dx + dz * dz;
        if (d2 < rr * rr && d2 > 1e-8) {
          final d = math.sqrt(d2);
          p.x = c.x + dx / d * rr;
          p.z = c.z + dz / d * rr;
        }
        continue;
      }
      final lx = c.c * dx - c.s * dz, lz = c.s * dx + c.c * dz;
      final px = lx.abs() - c.hx, pz = lz.abs() - c.hz;
      if (px >= r || pz >= r) continue;
      double nlx = lx, nlz = lz;
      if (px > 0 && pz > 0) {
        // Corner region: push radially from the corner.
        final cxl = lx.sign * c.hx, czl = lz.sign * c.hz;
        final ex = lx - cxl, ez = lz - czl;
        final d = math.sqrt(ex * ex + ez * ez);
        if (d >= r || d < 1e-8) continue;
        nlx = cxl + ex / d * r;
        nlz = czl + ez / d * r;
      } else if (px > pz) {
        nlx = lx.sign * (c.hx + r);
      } else {
        nlz = lz.sign * (c.hz + r);
      }
      p.x = c.x + c.c * nlx + c.s * nlz;
      p.z = c.z - c.s * nlx + c.c * nlz;
    }
  }

  /// Rough terrain line-of-sight between two eye points.
  bool lineOfSight(double ax, double ay, double az, double bx, double by, double bz) {
    for (var i = 1; i < 8; i++) {
      final t = i / 8;
      final x = ax + (bx - ax) * t, y = ay + (by - ay) * t, z = az + (bz - az) * t;
      if (terrain.heightAt(x, z) > y) return false;
    }
    return true;
  }

  void relight(Lighting l) {
    for (final c in chunks) {
      c.terrain.relight(l);
      c.props.relight(l);
      c.flora.relight(l);
    }
  }

  void render(Renderer r) {
    final cam = r.cam;
    final reach = r.far + chunkSize * 0.75;
    for (final c in chunks) {
      final dx = c.cx - cam.x, dz = c.cz - cam.z;
      final d = math.sqrt(dx * dx + dz * dz);
      if (d > reach) continue;
      r.drawBatch(c.terrain);
      r.drawBatch(c.props);
      if (d < floraDistance) r.drawBatch(c.flora);
    }
  }

  // ---------------------------------------------------------------- building

  final Map<TriBatch, MeshBuilder> _builders = {};

  MeshBuilder _builderFor(TriBatch t) =>
      _builders.putIfAbsent(t, () => MeshBuilder(t, rng));

  /// Places a prop at (x, z) on the terrain (or at [y]) rotated by [yaw].
  void place(double x, double z, double yaw, void Function(MeshBuilder b) build,
      {double? y, bool flora = false}) {
    final chunk = chunkAt(x, z);
    if (chunk == null) return;
    final b = _builderFor(flora ? chunk.flora : chunk.props)..reset();
    b.translate(x, y ?? terrain.heightAt(x, z), z);
    b.rotateY(yaw);
    build(b);
    b.reset();
  }

  void addCollider(Collider c) {
    final r = c.radius;
    final added = <Chunk>{};
    for (final ox in [-r, 0.0, r]) {
      for (final oz in [-r, 0.0, r]) {
        final ch = chunkAt(c.x + ox, c.z + oz);
        if (ch != null && added.add(ch)) ch.colliders.add(c);
      }
    }
  }

  /// Box collider whose local frame matches a prop placed with [yaw].
  /// (lx, lz) are offsets in the prop's local frame.
  void boxAt(double x, double z, double yaw, double lx, double lz, double w,
      double d, double y0, double y1) {
    final c = math.cos(yaw), s = math.sin(yaw);
    addCollider(Collider.box(x + c * lx + s * lz, z - s * lx + c * lz, w, d, yaw, y0, y1));
  }

  /// World position of a local offset for a prop at (x, z) with [yaw].
  (double, double) local(double x, double z, double yaw, double lx, double lz) {
    final c = math.cos(yaw), s = math.sin(yaw);
    return (x + c * lx + s * lz, z - s * lx + c * lz);
  }

  void _point(String name, double x, double z, [double yOffset = 0]) {
    points[name] = Vec3(x, terrain.heightAt(x, z) + yOffset, z);
  }

  int _terrainColor(double x, double z, double h, double ny, math.Random r) {
    const wl = Terrain.waterLevel;
    int c;
    if (h < wl - 0.3) {
      c = 0xFF5E5A44;
    } else if (h < wl + 0.8) {
      c = 0xFFB0A07A;
    } else {
      c = lerpColor(0xFF4C7834, 0xFF6E9440, _noise.value(x / 16, z / 16));
      final dCamp = _dist(x, z, Places.campX, Places.campZ);
      if (dCamp < 90) c = lerpColor(c, 0xFF85994A, smoothstep(90, 50, dCamp));
      final dShrine = _dist(x, z, Places.shrineX, Places.shrineZ);
      final dHana = _dist(x, z, Places.hanamuraX, Places.hanamuraZ);
      if ((dShrine < 60 || dHana < 50) && r.nextDouble() < 0.18) c = 0xFFD9A8B8;
      final dK = _dist(x, z, Places.kasumiX, Places.kasumiZ);
      if (dK < 50) c = lerpColor(c, 0xFF3B3733, smoothstep(50, 20, dK));
      if (ny < 0.85) c = lerpColor(c, 0xFF6E6A60, smoothstep(0.85, 0.62, ny));
      if (h > 26) c = lerpColor(c, 0xFF77736B, smoothstep(26, 34, h));
      if (h > 46) c = lerpColor(c, 0xFFE8ECF0, smoothstep(46, 54, h));
      final road = terrain.roadDistanceAt(x, z);
      if (road < 3.4) c = lerpColor(c, 0xFF8A7552, smoothstep(3.4, 1.6, road));
      // Gravel courtyards.
      if ((x - Places.castleX).abs() < 38 && (z - Places.castleZ).abs() < 38) c = 0xFF9C968A;
      if (dShrine < 15) c = 0xFFA8A296;
    }
    return scaleColor(c, 0.94 + r.nextDouble() * 0.1);
  }

  static double _dist(double x, double z, double px, double pz) {
    final dx = x - px, dz = z - pz;
    return math.sqrt(dx * dx + dz * dz);
  }

  void _buildTerrain() {
    final t = terrain;
    const cpc = 8; // cells per chunk
    final r = math.Random(3);
    for (var cj = 0; cj < perSide; cj++) {
      for (var ci = 0; ci < perSide; ci++) {
        final b = _builderFor(chunks[cj * perSide + ci].terrain);
        for (var j = cj * cpc; j < (cj + 1) * cpc; j++) {
          for (var i = ci * cpc; i < (ci + 1) * cpc; i++) {
            final x0 = -Terrain.half + i * Terrain.cell, z0 = -Terrain.half + j * Terrain.cell;
            final x1 = x0 + Terrain.cell, z1 = z0 + Terrain.cell;
            final h00 = t.h(i, j), h10 = t.h(i + 1, j), h01 = t.h(i, j + 1), h11 = t.h(i + 1, j + 1);
            _groundTri(b, x0, h00, z0, x1, h10, z0, x1, h11, z1, r);
            _groundTri(b, x0, h00, z0, x1, h11, z1, x0, h01, z1, r);
            const wl = Terrain.waterLevel;
            if (math.min(math.min(h00, h10), math.min(h01, h11)) < wl) {
              final c = scaleColor(Pal.water, 0.95 + r.nextDouble() * 0.1);
              b.worldTri(x0, wl, z0, x1, wl, z1, x1, wl, z0, c, flag: fWater);
              b.worldTri(x0, wl, z0, x0, wl, z1, x1, wl, z1, c, flag: fWater);
            }
          }
        }
      }
    }
  }

  void _groundTri(MeshBuilder b, double ax, double ay, double az, double bx,
      double by, double bz, double cx, double cy, double cz, math.Random r) {
    // Upward normal: order so that cross product points up.
    final ux = bx - ax, uy = by - ay, uz = bz - az;
    final vx = cx - ax, vy = cy - ay, vz = cz - az;
    var nx = uy * vz - uz * vy, ny = uz * vx - ux * vz, nz = ux * vy - uy * vx;
    final len = math.sqrt(nx * nx + ny * ny + nz * nz);
    nx /= len;
    ny /= len;
    nz /= len;
    final color = _terrainColor((ax + bx + cx) / 3, (az + bz + cz) / 3,
        (ay + by + cy) / 3, ny.abs(), r);
    if (ny < 0) {
      b.out.add(ax, ay, az, cx, cy, cz, bx, by, bz, -nx, -ny, -nz, color, fGround);
    } else {
      b.out.add(ax, ay, az, bx, by, bz, cx, cy, cz, nx, ny, nz, color, fGround);
    }
  }

  // Standard collider for a house prop.
  void _houseCollider(double x, double z, double yaw, [double s = 1]) {
    final y = terrain.heightAt(x, z);
    boxAt(x, z, yaw, 0, 0, 8.4 * s, 6.4 * s, y - 1, y + 6);
  }

  void _buildKasumi() {
    const kx = Places.kasumiX, kz = Places.kasumiZ;
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4 + math.pi / 8;
      // Leave the road to the east open.
      if ((wrapAngle(a - (-math.pi / 4))).abs() < 0.5) continue;
      final x = kx + math.cos(a) * 24, z = kz + math.sin(a) * 24;
      final yaw = math.atan2(kx - x, kz - z); // door (+z) faces the square
      place(x, z, yaw, (b) => burnedHouse(b, rng));
      _houseCollider(x, z, yaw);
      final y = terrain.heightAt(x, z);
      fires.add(FirePoint(x + rng.nextDouble() * 3 - 1.5, y + 0.6, z + rng.nextDouble() * 3 - 1.5, 1.0));
      if (i.isEven) fires.add(FirePoint(x + 2, y + 0.6, z - 1, 0.7));
    }
    // Ruined dojo.
    const dx = kx - 6, dz = kz - 14;
    place(dx, dz, 0, (b) {
      b.scale(1.5, 1.3, 1.5);
      burnedHouse(b, rng);
    });
    _houseCollider(dx, dz, 0, 1.5);
    final dy = terrain.heightAt(dx, dz);
    fires.add(FirePoint(dx + 4, dy + 0.8, dz + 2, 1.3));
    fires.add(FirePoint(dx - 5, dy + 0.8, dz - 1, 0.9));
    _point('soun', dx, dz + 7.5);
    // Village heart.
    place(kx, kz, 0.3, memorialStone);
    boxAt(kx, kz, 0.3, 0, 0, 1.6, 1.2, terrain.heightAt(kx, kz) - 1, terrain.heightAt(kx, kz) + 2.4);
    place(kx + 8, kz + 6, 0, well);
    addCollider(Collider.circle(kx + 8, kz + 6, 1.1, terrain.heightAt(kx + 8, kz + 6) - 1,
        terrain.heightAt(kx + 8, kz + 6) + 2.4));
    // Broken watchtower.
    place(kx + 20, kz - 20, 0.4, (b) {
      for (final p in [[-1.5, -1.5], [1.5, -1.5], [-1.5, 1.5]]) {
        b.box(p[0], 0, p[1], 0.35, 6, 0.35, Pal.black);
      }
      b.box(1.5, 0, 1.5, 0.35, 2.5, 0.35, Pal.black);
      b.push();
      b.translate(0, 5.5, 0);
      b.rotateZ(0.25);
      b.box(0, 0, 0, 3.6, 0.25, 3.6, Pal.charred);
      b.pop();
    });
    for (var i = 0; i < 6; i++) {
      final a = rng.nextDouble() * pi2, d = 30 + rng.nextDouble() * 10;
      place(kx + math.cos(a) * d, kz + math.sin(a) * d, a, (b) => fence(b, 6));
    }
    _point('kasumi', kx, kz);
    _point('start', kx - 38, kz + 48);
  }

  void _buildCamp() {
    const cx = Places.campX, cz = Places.campZ;
    final y = terrain.heightAt(cx, cz);
    void wall(double lx, double lz, double len, double yaw) {
      place(cx + lx, cz + lz, yaw, (b) => curtainWall(b, len), y: y);
      boxAt(cx + lx, cz + lz, yaw, 0, 0, len, 0.3, y - 1, y + 2.6);
    }

    wall(0, -10, 28, 0);
    wall(-9, 10, 10, 0);
    wall(9, 10, 10, 0);
    wall(14, 0, 20, math.pi / 2);
    wall(-14, -5.5, 9, math.pi / 2);
    wall(-14, 5.5, 9, math.pi / 2);
    for (final t in [[-7.0, -5.0], [0.0, -5.5]]) {
      place(cx + t[0], cz + t[1], 0, tent, y: y);
      boxAt(cx + t[0], cz + t[1], 0, 0, 0, 5, 4.2, y - 1, y + 2.6);
    }
    // Commander tent.
    place(cx + 8, cz - 5, 0, (b) {
      b.scale(1.3, 1.3, 1.3);
      tent(b);
    }, y: y);
    boxAt(cx + 8, cz - 5, 0, 0, 0, 6.5, 5.5, y - 1, y + 3.4);
    place(cx + 8, cz + 0.5, 0, (b) {
      b.box(0, 0, 0, 2.4, 0.8, 1.2, Pal.darkWood, topColor: 0xFF8C1F1F);
    }, y: y);
    boxAt(cx + 8, cz + 0.5, 0, 0, 0, 2.4, 1.2, y - 1, y + 0.8);
    _point('orders', cx + 8, cz + 0.5, 0.95);
    place(cx, cz + 2, 0, campfire, y: y);
    fires.add(FirePoint(cx, y + 0.3, cz + 2, 0.8));
    for (final p in [[-14.0, -10.0], [14.0, -10.0], [-5.0, 10.5], [5.0, 10.5], [-14.0, 10.0], [14.0, 10.0]]) {
      place(cx + p[0], cz + p[1], 0, (b) => banner(b, Pal.clanRed), y: y);
    }
    place(cx - 10, cz + 4, math.pi / 2, weaponRack, y: y);
    for (final p in [[-11.0, 7.0], [-9.8, 7.4], [-10.4, 6.0]]) {
      place(cx + p[0], cz + p[1], rng.nextDouble(), crate, y: y);
      boxAt(cx + p[0], cz + p[1], 0, 0, 0, 1.0, 1.0, y - 1, y + 0.8);
    }
    _point('campSupply', cx - 10.4, cz + 9);
    _point('camp', cx, cz);
  }

  void _buildHanamura() {
    const hx = Places.hanamuraX, hz = Places.hanamuraZ;
    final houses = <List<double>>[
      [8, -16, 0.1], [22, -12, -0.2], [12, 10, 0.0], [28, 12, 0.3],
      [18, 22, 0.0], [34, -2, -1.5], [-40, -12, 1.4], [-38, 14, 1.7],
    ];
    for (var k = 0; k < houses.length; k++) {
      final h = houses[k];
      final x = hx + h[0], z = hz + h[1];
      place(x, z, h[2], (b) => house(b, thatched: k != 4));
      _houseCollider(x, z, h[2]);
    }
    _point('tsuru', hx + 18, hz + 27.5);
    // Paddies.
    for (var i = 0; i < 2; i++) {
      for (var j = 0; j < 2; j++) {
        final x = hx + 46 + i * 9, z = hz - 22 + j * 7;
        place(x, z, 0, (b) => ricePaddy(b, 8.4, 6.4));
      }
    }
    for (final p in [[40.0, 8.0], [42.0, 11.0], [6.0, -4.0]]) {
      place(hx + p[0], hz + p[1], 0, haystack);
      addCollider(Collider.circle(hx + p[0], hz + p[1], 0.9, -100, terrain.heightAt(hx + p[0], hz + p[1]) + 2.2));
    }
    place(hx + 14, hz - 1, 0, well);
    addCollider(Collider.circle(hx + 14, hz - 1, 1.1, -100, terrain.heightAt(hx + 14, hz - 1) + 2.4));
    place(hx + 33, hz + 26, -0.8, (b) => torii(b, w: 3.6, h: 4));
    place(hx + 36, hz + 29, -0.8, stoneLantern);
    _point('hanamura', hx + 10, hz);
  }

  void _buildShrine() {
    const sx = Places.shrineX, sz = Places.shrineZ;
    // Direction toward the approach road.
    var ax = 150 - sx, az = 75 - sz;
    final al = math.sqrt(ax * ax + az * az);
    ax /= al;
    az /= al;
    final yaw = math.atan2(ax, az); // local +z faces the approach
    final y = terrain.heightAt(sx, sz);
    final (hx, hz) = local(sx, sz, yaw, 0, -8);
    place(hx, hz, yaw, shrineHall, y: y);
    boxAt(hx, hz, yaw, 0, 0, 14, 10, y - 1, y + 9);
    final (px, pz) = local(sx, sz, yaw, -15, -3);
    place(px, pz, yaw, pagoda, y: y);
    boxAt(px, pz, yaw, 0, 0, 9, 9, y - 1, y + 24);
    for (var k = 0; k < 5; k++) {
      final d = 12.0 + k * 7;
      final tx = sx + ax * d, tz = sz + az * d;
      place(tx, tz, yaw, torii);
      final ty = terrain.heightAt(tx, tz);
      for (final side in [-2.5, 2.5]) {
        final (cx, cz) = local(tx, tz, yaw, side, 0);
        addCollider(Collider.circle(cx, cz, 0.35, ty - 1, ty + 6));
      }
      if (k < 4) {
        for (final side in [-4.0, 4.0]) {
          final (lx, lz) = local(sx + ax * (d + 3.5), sz + az * (d + 3.5), yaw, side, 0);
          place(lx, lz, yaw, stoneLantern);
          addCollider(Collider.circle(lx, lz, 0.45, -100, terrain.heightAt(lx, lz) + 2.2));
        }
      }
    }
    for (var i = 0; i < 10; i++) {
      final a = i / 10 * pi2 + 0.3;
      final d = 19 + rng.nextDouble() * 6;
      final x = sx + math.cos(a) * d, z = sz + math.sin(a) * d;
      if ((x - sx) * ax + (z - sz) * az > 12) continue; // keep the path clear
      final s = 1.0 + rng.nextDouble() * 0.4;
      place(x, z, rng.nextDouble() * pi2, (b) => sakuraTree(b, s), flora: true);
      addCollider(Collider.circle(x, z, 0.4 * s, -100, terrain.heightAt(x, z) + 5));
    }
    _point('duel', sx + ax * 5, sz + az * 5);
    _point('shrine', sx, sz);
    _point('shrinePath', sx + ax * 46, sz + az * 46);
  }

  void _buildCastle() {
    const cx = Places.castleX, cz = Places.castleZ;
    final y = terrain.heightAt(cx, cz);
    void wall(double lx, double lz, double len, double yaw) {
      place(cx + lx, cz + lz, yaw, (b) => castleWall(b, len), y: y);
      boxAt(cx + lx, cz + lz, yaw, 0, 0, len, 5.2, y - 3, y + 7);
    }

    wall(0, -40, 80, 0);
    wall(-40, 0, 80, math.pi / 2);
    wall(40, 0, 80, math.pi / 2);
    wall(-24.5, 40, 31, 0);
    wall(24.5, 40, 31, 0);
    for (final p in [[-40.0, -40.0], [40.0, -40.0], [-40.0, 40.0], [40.0, 40.0]]) {
      place(cx + p[0], cz + p[1], 0, turret, y: y);
      boxAt(cx + p[0], cz + p[1], 0, 0, 0, 10, 10, y - 3, y + 10);
    }
    place(cx, cz + 40, 0, gatehouse, y: y);
    boxAt(cx, cz + 40, 0, -6.5, 0, 6, 8, y - 3, y + 11);
    boxAt(cx, cz + 40, 0, 6.5, 0, 6, 8, y - 3, y + 11);
    place(cx, cz - 14, 0, castleKeep, y: y);
    boxAt(cx, cz - 14, 0, 0, 0, 26, 26, y - 2, y + 30);
    place(cx - 18, cz + 10, 0, cage, y: y);
    boxAt(cx - 18, cz + 10, 0, 0, 0, 3.6, 3.6, y - 1, y + 2.9);
    for (final p in [[24.0, 14.0], [24.0, -2.0]]) {
      place(cx + p[0], cz + p[1], math.pi / 2, (b) => house(b, thatched: false), y: y);
      _houseCollider(cx + p[0], cz + p[1], math.pi / 2);
    }
    for (final p in [[-6.0, 34.0], [6.0, 34.0], [-12.0, 2.0], [12.0, 2.0]]) {
      place(cx + p[0], cz + p[1], 0, stoneLantern, y: y);
      addCollider(Collider.circle(cx + p[0], cz + p[1], 0.45, y - 1, y + 2.2));
    }
    for (final p in [[-30.0, 30.0], [30.0, 30.0], [-10.0, 46.0], [10.0, 46.0]]) {
      place(cx + p[0], cz + p[1], 0, (b) => banner(b, Pal.clanRed));
    }
    place(cx - 26, cz - 20, 0, (b) => sakuraTree(b, 1.3), y: y, flora: true);
    addCollider(Collider.circle(cx - 26, cz - 20, 0.5, y - 1, y + 5));
    _point('castleGate', cx, cz + 52);
    _point('cage', cx - 18, cz + 14.5);
    _point('arena', cx, cz + 8);
    _point('castle', cx, cz);
  }

  void _buildBridge(double z, String name) {
    final rx = Places.riverX(z);
    // Align with the river's local direction.
    final slope = (Places.riverX(z + 1) - Places.riverX(z - 1)) / 2;
    final yaw = math.atan(slope);
    const len = 38.0;
    final (ex1, ez1) = local(rx, z, yaw, -len / 2, 0);
    final (ex2, ez2) = local(rx, z, yaw, len / 2, 0);
    final deck = math.max(terrain.heightAt(ex1, ez1), terrain.heightAt(ex2, ez2)) + 0.25;
    final depth = deck - (Terrain.waterLevel - 2);
    place(rx, z, yaw, (b) => bridge(b, len, 4, depth), y: deck);
    boxAt(rx, z, yaw, 0, 0, len, 4, deck - 0.6, deck);
    boxAt(rx, z, yaw, 0, -2, len, 0.3, deck - 0.6, deck + 1.0);
    boxAt(rx, z, yaw, 0, 2, len, 0.3, deck - 0.6, deck + 1.0);
    points[name] = Vec3(rx, deck, z);
  }

  bool _excluded(double x, double z) {
    const zones = [
      [Places.kasumiX, Places.kasumiZ, 46.0],
      [Places.campX, Places.campZ, 22.0],
      [Places.hanamuraX, Places.hanamuraZ, 44.0],
      [Places.shrineX, Places.shrineZ, 30.0],
      [Places.castleX, Places.castleZ, 66.0],
    ];
    for (final zn in zones) {
      if (_dist(x, z, zn[0], zn[1]) < zn[2]) return true;
    }
    for (final b in ['bridgeNorth', 'bridgeSouth']) {
      final p = points[b]!;
      if (_dist(x, z, p.x, p.z) < 24) return true;
    }
    return false;
  }

  void _scatter() {
    final forest = const Noise2D(512);
    for (var n = 0; n < 5200; n++) {
      final x = (rng.nextDouble() * 2 - 1) * 296;
      final z = (rng.nextDouble() * 2 - 1) * 296;
      final h = terrain.heightAt(x, z);
      if (h < Terrain.waterLevel + 1.0 || h > 44) continue;
      if (terrain.roadDistanceAt(x, z) < 4.5 || _excluded(x, z)) continue;
      final slope = (terrain.heightAt(x + 2, z) - h).abs() + (terrain.heightAt(x, z + 2) - h).abs();
      final roll = rng.nextDouble();
      final dCamp = _dist(x, z, Places.campX, Places.campZ);
      final dShrine = _dist(x, z, Places.shrineX, Places.shrineZ);
      final dHana = _dist(x, z, Places.hanamuraX, Places.hanamuraZ);
      final density = forest.fbm(x / 80, z / 80);
      final yaw = rng.nextDouble() * pi2;

      if (dCamp < 85) {
        if (roll < 0.55) {
          place(x, z, yaw, (b) => bambooClump(b, rng), flora: true);
          addCollider(Collider.circle(x, z, 1.1, h - 1, h + 8));
        }
        continue;
      }
      if (roll < 0.05 && slope < 3) {
        final s = 0.6 + rng.nextDouble() * 1.2;
        place(x, z, yaw, (b) => rock(b, s, rng));
        addCollider(Collider.circle(x, z, s * 1.1, h - 1, h + s * 0.9));
        continue;
      }
      if (dShrine < 75 || dHana < 70) {
        if (roll < 0.30) {
          final s = 0.9 + rng.nextDouble() * 0.5;
          if (rng.nextDouble() < 0.7) {
            place(x, z, yaw, (b) => sakuraTree(b, s), flora: true);
          } else {
            place(x, z, yaw, (b) => mapleTree(b, s), flora: true);
          }
          addCollider(Collider.circle(x, z, 0.35 * s, h - 1, h + 5));
        }
        continue;
      }
      final treeChance = density > 0.52 ? 0.75 : 0.08;
      if (roll < treeChance) {
        final s = 0.8 + rng.nextDouble() * 0.7;
        if (rng.nextDouble() < 0.55) {
          place(x, z, yaw, (b) => pineTree(b, s), flora: true);
        } else {
          place(x, z, yaw, (b) => cedarTree(b, s), flora: true);
        }
        addCollider(Collider.circle(x, z, 0.35 * s, h - 1, h + 8));
      } else if (roll < treeChance + 0.08) {
        final s = 0.7 + rng.nextDouble() * 0.8;
        place(x, z, yaw, (b) => bush(b, s, rng.nextBool() ? 0xFF3E6B30 : 0xFF557A36), flora: true);
      }
    }
  }
}
