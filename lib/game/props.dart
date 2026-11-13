import 'dart:math' as math;

import '../engine/math3d.dart';
import '../engine/mesh.dart';

/// Shared palette.
class Pal {
  static const wood = 0xFF6B4A2E;
  static const darkWood = 0xFF3E2A1A;
  static const plaster = 0xFFE6DEC9;
  static const thatch = 0xFF8C7342;
  static const tile = 0xFF3A3F47;
  static const stone = 0xFF7D7A72;
  static const darkStone = 0xFF57544F;
  static const vermilion = 0xFFD2452B;
  static const black = 0xFF1C1A1A;
  static const charred = 0xFF2A2420;
  static const ash = 0xFF4A4542;
  static const pine = 0xFF2F5A32;
  static const cedar = 0xFF27452B;
  static const trunk = 0xFF4E3626;
  static const sakura = 0xFFF2B5C8;
  static const sakuraDeep = 0xFFE590AE;
  static const bamboo = 0xFF8DAF4A;
  static const bambooLeaf = 0xFF6C9A3A;
  static const maple = 0xFFC8452A;
  static const cloth = 0xFFECE6D8;
  static const clanRed = 0xFF9E1B1B;
  static const gold = 0xFFD8A940;
  static const water = 0xD0305E7A;
  static const paddy = 0xD05D8A86;
}

void pineTree(MeshBuilder b, double s) {
  b.cylinder(0, 0, 0, 0.28 * s, 0.18 * s, 3.2 * s, 5, Pal.trunk, caps: false);
  for (var i = 0; i < 3; i++) {
    final y = (1.6 + i * 1.5) * s;
    final r = (2.4 - i * 0.65) * s;
    b.cylinder(0, y, 0, r, 0, 2.6 * s, 6, i.isEven ? Pal.pine : scaleColor(Pal.pine, 1.12));
  }
}

void cedarTree(MeshBuilder b, double s) {
  b.cylinder(0, 0, 0, 0.32 * s, 0.2 * s, 4 * s, 5, Pal.trunk, caps: false);
  b.cylinder(0, 2.5 * s, 0, 1.9 * s, 0, 7.5 * s, 6, Pal.cedar);
  b.cylinder(0, 5.5 * s, 0, 1.3 * s, 0, 5.5 * s, 6, scaleColor(Pal.cedar, 1.15));
}

void sakuraTree(MeshBuilder b, double s) {
  b.push();
  b.rotateZ(0.12);
  b.cylinder(0, 0, 0, 0.3 * s, 0.2 * s, 2.6 * s, 5, 0xFF3D2A24, caps: false);
  b.pop();
  b.ico(0.3 * s, 3.4 * s, 0, 2.2 * s, 1.5 * s, 2.2 * s, Pal.sakura, colorJitter: 0.1);
  b.octa(-1.4 * s, 3.0 * s, 0.8 * s, 1.5 * s, 1.0 * s, 1.4 * s, Pal.sakuraDeep);
  b.octa(1.6 * s, 3.1 * s, -0.9 * s, 1.4 * s, 1.0 * s, 1.5 * s, Pal.sakura);
}

void mapleTree(MeshBuilder b, double s) {
  b.cylinder(0, 0, 0, 0.25 * s, 0.16 * s, 2.4 * s, 5, Pal.trunk, caps: false);
  b.ico(0, 3.1 * s, 0, 1.9 * s, 1.4 * s, 1.9 * s, Pal.maple, colorJitter: 0.14);
  b.octa(1.1 * s, 2.6 * s, 0.6 * s, 1.1 * s, 0.8 * s, 1.1 * s, 0xFFE07A2E);
}

void bambooClump(MeshBuilder b, math.Random rng) {
  final n = 4 + rng.nextInt(3);
  for (var i = 0; i < n; i++) {
    final a = rng.nextDouble() * pi2, d = rng.nextDouble() * 1.3;
    final x = math.cos(a) * d, z = math.sin(a) * d;
    final h = 7 + rng.nextDouble() * 4;
    b.push();
    b.translate(x, 0, z);
    b.rotateZ((rng.nextDouble() - 0.5) * 0.12);
    b.rotateX((rng.nextDouble() - 0.5) * 0.12);
    b.cylinder(0, 0, 0, 0.11, 0.09, h, 4, Pal.bamboo, caps: false);
    // Leaf sprays.
    for (var k = 0; k < 2; k++) {
      final y = h * (0.65 + k * 0.25);
      final la = rng.nextDouble() * pi2;
      final lx = math.cos(la) * 1.6, lz = math.sin(la) * 1.6;
      b.tri2(0, y, 0, lx, y - 0.6, lz, lx * 0.6 - lz * 0.4, y + 0.3, lz * 0.6 + lx * 0.4,
          b.jit(Pal.bambooLeaf, 0.15));
      b.tri2(0, y + 0.2, 0, -lx, y - 0.4, -lz, -lx * 0.5 + lz * 0.5, y + 0.4, -lz * 0.5 - lx * 0.5,
          b.jit(Pal.bambooLeaf, 0.15));
    }
    b.pop();
  }
}

void rock(MeshBuilder b, double s, math.Random rng) {
  b.ico(0, 0.3 * s, 0, (1 + rng.nextDouble() * 0.6) * s, (0.7 + rng.nextDouble() * 0.4) * s,
      (1 + rng.nextDouble() * 0.6) * s, rng.nextBool() ? Pal.stone : Pal.darkStone,
      colorJitter: 0.1);
}

void bush(MeshBuilder b, double s, int color) {
  b.octa(0, 0.45 * s, 0, 1.0 * s, 0.6 * s, 0.9 * s, color);
}

/// Japanese farmhouse (minka), 8 x 6 footprint.
void house(MeshBuilder b, {bool thatched = true}) {
  b.box(0, 0, 0, 8.4, 0.5, 6.4, Pal.darkStone);
  b.box(0, 0.5, 0, 8, 2.6, 6, Pal.plaster);
  // Timber frame posts.
  for (final px in [-4.0, -1.3, 1.3, 4.0]) {
    b.box(px, 0.5, 3.02, 0.25, 2.6, 0.12, Pal.darkWood);
    b.box(px, 0.5, -3.02, 0.25, 2.6, 0.12, Pal.darkWood);
  }
  b.box(0, 2.85, 0, 8.1, 0.25, 6.1, Pal.darkWood);
  // Door.
  b.box(0, 0.5, 3.04, 1.6, 2.0, 0.08, Pal.wood);
  if (thatched) {
    b.gable(0, 3.0, 0, 9.6, 7.6, 3.4, Pal.thatch);
  } else {
    b.gable(0, 3.0, 0, 9.4, 7.4, 2.4, Pal.tile);
    b.box(0, 5.35, 0, 9.6, 0.25, 0.4, Pal.black);
  }
}

/// A house destroyed by fire.
void burnedHouse(MeshBuilder b, math.Random rng) {
  b.box(0, 0, 0, 8.4, 0.5, 6.4, Pal.ash);
  // Broken walls.
  b.box(-2.5, 0.5, -3, 3, 1.6 + rng.nextDouble(), 0.3, Pal.charred);
  b.box(3.85, 0.5, 0, 0.3, 1.2 + rng.nextDouble() * 1.4, 6, Pal.charred);
  b.box(1.5, 0.5, 3, 2.5, 0.8, 0.3, Pal.charred);
  // Standing and fallen posts.
  for (final p in [[-4.0, -3.0], [4.0, -3.0], [-4.0, 3.0], [4.0, 3.0]]) {
    b.box(p[0], 0.5, p[1], 0.3, 1.5 + rng.nextDouble() * 1.6, 0.3, Pal.black);
  }
  b.push();
  b.translate(0, 1.2, 0);
  b.rotateZ(0.45);
  b.box(0, 0, 0, 7, 0.28, 0.28, Pal.black);
  b.pop();
  b.push();
  b.translate(-1, 0.8, 1);
  b.rotateX(-0.6);
  b.rotateY(0.4);
  b.box(0, 0, 0, 0.3, 0.3, 5, Pal.black);
  b.pop();
  // Collapsed roof section.
  b.push();
  b.translate(1.5, 0.6, -0.5);
  b.rotateZ(-0.35);
  b.gable(0, 0, 0, 4.5, 4.5, 1.2, 0xFF3A3430);
  b.pop();
}

void torii(MeshBuilder b, {double w = 5, double h = 5.2}) {
  final hw = w / 2;
  b.cylinder(-hw, 0, 0, 0.26, 0.22, h, 6, Pal.vermilion);
  b.cylinder(hw, 0, 0, 0.26, 0.22, h, 6, Pal.vermilion);
  b.box(0, h * 0.74, 0, w + 0.8, 0.32, 0.36, Pal.vermilion);
  b.box(0, h, 0, w + 2.2, 0.3, 0.6, Pal.vermilion);
  b.frustum(0, h + 0.3, 0, w + 2.4, 0.7, w + 2.9, 0.75, 0.32, Pal.black);
  b.box(0, h * 0.74 + 0.32, 0, 0.35, h * 0.26 - 0.32, 0.3, Pal.vermilion);
}

void stoneLantern(MeshBuilder b) {
  b.box(0, 0, 0, 0.8, 0.25, 0.8, Pal.stone);
  b.cylinder(0, 0.25, 0, 0.18, 0.15, 0.9, 6, Pal.stone);
  b.box(0, 1.15, 0, 0.7, 0.15, 0.7, Pal.stone);
  b.box(0, 1.3, 0, 0.5, 0.45, 0.5, 0xFFE8C877, topColor: Pal.stone);
  b.frustum(0, 1.75, 0, 1.1, 1.1, 0.2, 0.2, 0.45, Pal.darkStone);
}

/// Five-storied pagoda.
void pagoda(MeshBuilder b) {
  b.box(0, 0, 0, 9, 1, 9, Pal.stone);
  var y = 1.0;
  for (var i = 0; i < 5; i++) {
    final w = 6.0 - i * 0.75;
    b.box(0, y, 0, w, 2.4, w, Pal.vermilion);
    b.box(0, y + 2.2, 0, w + 0.2, 0.2, w + 0.2, Pal.plaster);
    final rw = w + 3.0;
    b.frustum(0, y + 2.4, 0, rw, rw, w * 0.55, w * 0.55, 1.1, Pal.tile);
    y += 3.5;
  }
  b.cylinder(0, y - 0.1, 0, 0.18, 0.08, 4.5, 6, Pal.gold);
  for (var k = 0; k < 4; k++) {
    b.cylinder(0, y + 0.6 + k * 0.8, 0, 0.45, 0.45, 0.12, 6, Pal.gold);
  }
}

/// Main hall of a shrine.
void shrineHall(MeshBuilder b) {
  b.box(0, 0, 0, 14, 1.2, 10, Pal.stone);
  b.box(0, 1.2, 0, 12, 3.5, 8, Pal.vermilion);
  b.box(0, 1.2, 4.02, 4, 3.0, 0.1, Pal.wood);
  b.frustum(0, 4.7, 0, 16.5, 12.5, 7, 3, 2.8, Pal.tile);
  b.gable(0, 7.4, 0, 8.5, 3.4, 1.4, Pal.tile);
  b.box(0, 8.75, 0, 9, 0.3, 0.4, Pal.gold);
  // Steps.
  for (var i = 0; i < 3; i++) {
    b.box(0, i * 0.4, 5.5 + i * -0.5 + 1, 4.5, 0.4, 1.0, Pal.stone);
  }
}

void tent(MeshBuilder b) {
  b.gable(0, 0, 0, 5, 4.2, 2.6, Pal.cloth, endColor: 0xFFD8D0C0);
  b.box(0, 0, 0, 0.12, 2.6, 0.12, Pal.darkWood);
}

/// Panels of a war-camp curtain (maku) along the local x axis.
void curtainWall(MeshBuilder b, double length) {
  final hl = length / 2;
  b.quad2(-hl, 0.4, 0, hl, 0.4, 0, hl, 1.5, 0, -hl, 1.5, 0, Pal.cloth);
  b.quad2(-hl, 1.5, 0, hl, 1.5, 0, hl, 1.9, 0, -hl, 1.9, 0, Pal.black);
  b.quad2(-hl, 1.9, 0, hl, 1.9, 0, hl, 2.4, 0, -hl, 2.4, 0, Pal.cloth);
  for (var x = -hl; x <= hl + 0.01; x += length / math.max(1, (length / 4).round())) {
    b.box(x, 0, 0, 0.12, 2.6, 0.12, Pal.darkWood);
  }
}

/// Tall nobori war banner.
void banner(MeshBuilder b, int color) {
  b.cylinder(0, 0, 0, 0.06, 0.05, 5.2, 4, Pal.darkWood, caps: false);
  b.quad2(0.05, 2.0, 0, 1.0, 2.0, 0, 1.0, 5.0, 0, 0.05, 5.0, 0, color);
  b.quad2(0.35, 4.0, 0.01, 0.75, 4.0, 0.01, 0.75, 4.4, 0.01, 0.35, 4.4, 0.01, Pal.cloth);
}

void crate(MeshBuilder b) {
  b.box(0, 0, 0, 1.0, 0.8, 0.8, Pal.wood, topColor: scaleColor(Pal.wood, 1.15));
  b.box(0, 0.8, 0, 1.04, 0.08, 0.84, Pal.darkWood);
}

void well(MeshBuilder b) {
  b.cylinder(0, 0, 0, 1.0, 1.0, 0.9, 8, Pal.stone, topColor: 0xFF1B2630);
  b.box(-1, 0, 0, 0.15, 2.4, 0.15, Pal.darkWood);
  b.box(1, 0, 0, 0.15, 2.4, 0.15, Pal.darkWood);
  b.gable(0, 2.4, 0, 2.6, 1.6, 0.6, Pal.thatch);
}

void haystack(MeshBuilder b) {
  b.cylinder(0, 0, 0, 0.9, 0.7, 1.2, 6, 0xFFC9A55A);
  b.cylinder(0, 1.2, 0, 0.75, 0, 1.0, 6, 0xFFB8944C);
}

void ricePaddy(MeshBuilder b, double w, double d) {
  b.box(0, -0.2, 0, w, 0.4, d, 0xFF6B5A3A);
  final hw = w / 2 - 0.3, hd = d / 2 - 0.3;
  final c = b.jit(Pal.paddy, 0.04);
  b.tri2(-hw, 0.22, -hd, hw, 0.22, -hd, hw, 0.22, hd, c, flag: fWater);
  b.tri2(-hw, 0.22, -hd, hw, 0.22, hd, -hw, 0.22, hd, c, flag: fWater);
  // Rice sprouts.
  for (var x = -hw + 0.6; x < hw; x += 1.2) {
    for (var z = -hd + 0.6; z < hd; z += 1.4) {
      b.tri2(x, 0.2, z, x + 0.2, 0.2, z, x + 0.1, 0.65, z, 0xFF7FB04A);
    }
  }
}

void campfire(MeshBuilder b) {
  for (var i = 0; i < 6; i++) {
    final a = i / 6 * pi2;
    b.box(math.cos(a) * 0.7, 0, math.sin(a) * 0.7, 0.35, 0.25, 0.35, Pal.stone);
  }
  b.push();
  b.rotateY(0.5);
  b.box(0, 0.05, 0, 1.2, 0.18, 0.18, Pal.black);
  b.rotateY(1.2);
  b.box(0, 0.12, 0, 1.2, 0.18, 0.18, Pal.black);
  b.pop();
}

void weaponRack(MeshBuilder b) {
  b.box(-1, 0, 0, 0.12, 1.8, 0.12, Pal.darkWood);
  b.box(1, 0, 0, 0.12, 1.8, 0.12, Pal.darkWood);
  b.box(0, 1.5, 0, 2.2, 0.1, 0.1, Pal.darkWood);
  for (var i = 0; i < 4; i++) {
    b.box(-0.75 + i * 0.5, 0, 0.08, 0.05, 2.6, 0.05, Pal.wood);
    b.cylinder(-0.75 + i * 0.5, 2.6, 0.08, 0.06, 0, 0.35, 4, 0xFFB8BEC6);
  }
}

/// Stretch of castle wall along local x: sloped stone base, plaster, tile cap.
void castleWall(MeshBuilder b, double length) {
  b.frustum(0, -2, 0, length, 6.5, length, 3.5, 6, Pal.stone, topColor: Pal.darkStone);
  b.box(0, 4, 0, length, 2.0, 1.4, Pal.plaster);
  b.frustum(0, 6, 0, length + 0.4, 2.4, length, 0.4, 0.7, Pal.tile);
}

/// Corner watch tower (yagura).
void turret(MeshBuilder b) {
  b.frustum(0, -2, 0, 10, 10, 8, 8, 7, Pal.stone);
  b.box(0, 5, 0, 7, 3, 7, Pal.plaster);
  b.frustum(0, 8, 0, 9.5, 9.5, 3, 3, 2.2, Pal.tile);
}

void gatehouse(MeshBuilder b) {
  b.frustum(-6.5, -2, 0, 6, 8, 4.5, 6.5, 7, Pal.stone);
  b.frustum(6.5, -2, 0, 6, 8, 4.5, 6.5, 7, Pal.stone);
  b.box(0, 5, 0, 18, 3.4, 7, Pal.plaster);
  b.box(0, 4.6, 0, 9, 0.4, 7.2, Pal.darkWood);
  b.frustum(0, 8.4, 0, 21, 10, 13, 2.4, 2.6, Pal.tile);
  b.box(0, 11, 0, 13.5, 0.3, 0.6, Pal.black);
}

/// Multi-tier main keep (tenshu).
void castleKeep(MeshBuilder b) {
  b.frustum(0, -1, 0, 26, 26, 20, 20, 8, Pal.stone, topColor: Pal.darkStone);
  final tiers = [
    [17.0, 4.5],
    [13.0, 4.0],
    [9.5, 3.6],
    [6.5, 3.4],
  ];
  var y = 7.0;
  for (var i = 0; i < tiers.length; i++) {
    final w = tiers[i][0], h = tiers[i][1];
    b.box(0, y, 0, w, h, w, i == tiers.length - 1 ? Pal.black : Pal.plaster);
    // Window band.
    b.box(0, y + h * 0.45, 0, w + 0.08, 0.5, w + 0.08, Pal.darkWood);
    final rw = w + 4;
    b.frustum(0, y + h, 0, rw, rw, w * 0.7, w * 0.7, 1.4, Pal.tile);
    if (i < tiers.length - 1) {
      // Decorative gable dormers.
      b.gable(0, y + h + 0.2, rw / 2 - 1.2, 4, 2.5, 1.6, Pal.tile);
      b.gable(0, y + h + 0.2, -rw / 2 + 1.2, 4, 2.5, 1.6, Pal.tile);
    }
    y += h + 1.4;
  }
  b.gable(0, y, 0, 6, 4, 2.2, Pal.tile);
  // Golden shachihoko ornaments.
  b.box(-3, y + 2.0, 0, 0.5, 1.0, 0.4, Pal.gold);
  b.box(3, y + 2.0, 0, 0.5, 1.0, 0.4, Pal.gold);
}

void cage(MeshBuilder b) {
  b.box(0, 0, 0, 3.4, 0.3, 3.4, Pal.darkWood);
  b.box(0, 2.6, 0, 3.4, 0.3, 3.4, Pal.darkWood);
  for (var i = 0; i < 6; i++) {
    final t = -1.55 + i * 0.62;
    b.box(t, 0.3, -1.6, 0.14, 2.3, 0.14, Pal.black);
    b.box(t, 0.3, 1.6, 0.14, 2.3, 0.14, Pal.black);
    b.box(-1.6, 0.3, t, 0.14, 2.3, 0.14, Pal.black);
    b.box(1.6, 0.3, t, 0.14, 2.3, 0.14, Pal.black);
  }
}

/// Bridge deck along local x with railings; posts reach down to [postDepth].
void bridge(MeshBuilder b, double length, double width, double postDepth) {
  b.box(0, -0.35, 0, length, 0.35, width, Pal.wood, topColor: scaleColor(Pal.wood, 1.1));
  final hw = width / 2;
  b.box(0, 0.9, -hw, length, 0.12, 0.14, Pal.vermilion);
  b.box(0, 0.9, hw, length, 0.12, 0.14, Pal.vermilion);
  for (var x = -length / 2; x <= length / 2 + 0.01; x += length / 6) {
    b.box(x, 0, -hw, 0.18, 1.0, 0.18, Pal.vermilion);
    b.box(x, 0, hw, 0.18, 1.0, 0.18, Pal.vermilion);
    if (x.abs() < length / 2 - 1) {
      b.box(x, -postDepth, -hw + 0.3, 0.3, postDepth - 0.35, 0.3, Pal.darkWood);
      b.box(x, -postDepth, hw - 0.3, 0.3, postDepth - 0.35, 0.3, Pal.darkWood);
    }
  }
}

void fence(MeshBuilder b, double length) {
  final hl = length / 2;
  b.box(0, 0.8, 0, length, 0.1, 0.08, Pal.wood);
  b.box(0, 0.4, 0, length, 0.1, 0.08, Pal.wood);
  for (var x = -hl; x <= hl + 0.01; x += 2) {
    b.box(x, 0, 0, 0.14, 1.1, 0.14, Pal.darkWood);
  }
}

void memorialStone(MeshBuilder b) {
  b.box(0, 0, 0, 1.6, 0.4, 1.2, Pal.darkStone);
  b.frustum(0, 0.4, 0, 0.9, 0.5, 0.75, 0.4, 2.0, Pal.stone);
}
