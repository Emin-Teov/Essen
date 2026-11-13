// Generates the game's 3D effect models as Wavefront OBJ + MTL files.
//
//   dart run tool/generate_effects.dart
//
// Output: assets/effects/<name>.obj and assets/effects/effects.mtl (shared
// material library). Conventions: meters, +Y up, flat effects lie in the XY
// plane facing +Z (billboards) or in the XZ plane (ground decals). Materials
// use Kd (color), d (opacity), illum 0 / Ke (emissive) and the engine
// extension `essen_flags double|emissive|nofog`.
import 'dart:io';
import 'dart:math' as math;

// ------------------------------------------------------------------ materials

class Mat {
  final String name;
  final int rgb;
  final double alpha;
  final bool glow, twoSided, noFog;
  Mat(this.name, this.rgb, {this.alpha = 1, this.glow = false, this.twoSided = false, this.noFog = false});

  String write() {
    String c(int shift) => (((rgb >> shift) & 255) / 255).toStringAsFixed(3);
    final flags = [if (twoSided) 'double', if (glow) 'emissive', if (noFog) 'nofog'];
    return [
      'newmtl $name',
      'Kd ${c(16)} ${c(8)} ${c(0)}',
      if (glow) 'Ke ${c(16)} ${c(8)} ${c(0)}' else 'Ke 0 0 0',
      'Ks 0 0 0',
      'd ${alpha.toStringAsFixed(3)}',
      'illum ${glow ? 0 : 1}',
      if (flags.isNotEmpty) 'essen_flags ${flags.join(' ')}',
      '',
    ].join('\n');
  }
}

final mats = <Mat>[
  // Slash arc: opacity rises toward the leading edge.
  Mat('slash_0', 0xD8ECFF, alpha: 0.10, glow: true, twoSided: true),
  Mat('slash_1', 0xD8ECFF, alpha: 0.28, glow: true, twoSided: true),
  Mat('slash_2', 0xE8F4FF, alpha: 0.52, glow: true, twoSided: true),
  Mat('slash_3', 0xFFFFFF, alpha: 0.82, glow: true, twoSided: true),
  Mat('slash_edge', 0xFFFFFF, alpha: 0.95, glow: true, twoSided: true),
  Mat('ring_main', 0xFFFFFF, alpha: 0.9, glow: true, twoSided: true),
  Mat('ring_soft', 0xFFFFFF, alpha: 0.3, glow: true, twoSided: true),
  Mat('flash_core', 0xFFFFFF, glow: true, twoSided: true),
  Mat('flash_ray', 0xFFF6E0, alpha: 0.9, glow: true, twoSided: true),
  Mat('flash_soft', 0xFFF0D0, alpha: 0.55, glow: true, twoSided: true),
  Mat('smoke_a', 0xA4A6AA, alpha: 0.5),
  Mat('smoke_b', 0xB4B6BA, alpha: 0.42),
  Mat('smoke_c', 0x95979C, alpha: 0.5),
  Mat('dust_a', 0xD8D0C0, alpha: 0.7),
  Mat('dust_b', 0xC4BAA8, alpha: 0.65),
  Mat('flame_core', 0xFFE27A, glow: true, twoSided: true),
  Mat('flame_mid', 0xFF9A2A, alpha: 0.95, glow: true, twoSided: true),
  Mat('flame_tip', 0xD8401A, alpha: 0.8, glow: true, twoSided: true),
  Mat('spark', 0xFFE9A0, glow: true, twoSided: true),
  Mat('ember', 0xFFB050, glow: true, twoSided: true),
  Mat('streak', 0xD8ECFF, alpha: 0.7, glow: true, twoSided: true),
  Mat('blood', 0x8A0F12),
  Mat('petal', 0xF6C3D3, twoSided: true),
  Mat('steel_face', 0xC8D0DA),
  Mat('steel_edge', 0x7A8490),
  Mat('steel_hole', 0x202428),
  Mat('arrow_shaft', 0x6B4A2E),
  Mat('arrow_head', 0x9AA0A8),
  Mat('arrow_feather', 0xEDE6D6, twoSided: true),
  Mat('alert_red', 0xFF3020, glow: true),
  Mat('alert_hot', 0xFF7A60, glow: true),
  Mat('gem_light', 0xFFE680, glow: true),
  Mat('gem_dark', 0xFFA020, glow: true),
  Mat('blind', 0xD8D8E0, glow: true),
  Mat('beacon_base', 0xFFD27A, alpha: 0.75, glow: true, twoSided: true, noFog: true),
  Mat('beacon_mid', 0xFFD27A, alpha: 0.4, glow: true, twoSided: true, noFog: true),
  Mat('beacon_top', 0xFFD27A, alpha: 0.12, glow: true, twoSided: true, noFog: true),
  Mat('gem_gold', 0xFFD27A, glow: true, noFog: true),
  Mat('gem_gold_dark', 0xC8962E, glow: true, noFog: true),
  Mat('rune', 0xFFFFFF, alpha: 0.85, glow: true, twoSided: true),
  Mat('rune_soft', 0xFFFFFF, alpha: 0.55, glow: true, twoSided: true),
  Mat('paper', 0xF1E6C8),
  Mat('scroll_red', 0xA82020),
  Mat('crate', 0x4A3220),
  Mat('crate_lid', 0xD8A940),
  Mat('rice', 0xF4F1EA),
  Mat('nori', 0x1A2418),
  Mat('bar', 0xFFFFFF, glow: true, twoSided: true),
];

// ------------------------------------------------------------------ OBJ builder

class Obj {
  final String name, description;
  final List<List<double>> v = [];
  final List<(String, List<int>)> faces = [];
  String m = 'default';
  Obj(this.name, this.description);

  int vert(double x, double y, double z) {
    v.add([x, y, z]);
    return v.length; // OBJ indices are 1-based
  }

  void use(String mat) => m = mat;
  void face(List<int> ids) => faces.add((m, ids));

  /// Triangle wound counter-clockwise when seen from outside, i.e. its normal
  /// points away from (cx, cy, cz).
  void outTri(int a, int b, int c, double cx, double cy, double cz) {
    final pa = v[a - 1], pb = v[b - 1], pc = v[c - 1];
    final ux = pb[0] - pa[0], uy = pb[1] - pa[1], uz = pb[2] - pa[2];
    final wx = pc[0] - pa[0], wy = pc[1] - pa[1], wz = pc[2] - pa[2];
    final nx = uy * wz - uz * wy, ny = uz * wx - ux * wz, nz = ux * wy - uy * wx;
    final mx = (pa[0] + pb[0] + pc[0]) / 3 - cx;
    final my = (pa[1] + pb[1] + pc[1]) / 3 - cy;
    final mz = (pa[2] + pb[2] + pc[2]) / 3 - cz;
    face(nx * mx + ny * my + nz * mz >= 0 ? [a, b, c] : [a, c, b]);
  }

  void outQuad(int a, int b, int c, int d, double cx, double cy, double cz) {
    outTri(a, b, c, cx, cy, cz);
    outTri(a, c, d, cx, cy, cz);
  }

  String write() {
    final sb = StringBuffer()
      ..writeln('# Essen 3D effect: $name')
      ..writeln('# $description')
      ..writeln('# Generated by tool/generate_effects.dart — units: meters, +Y up.')
      ..writeln('mtllib effects.mtl')
      ..writeln('o $name');
    for (final p in v) {
      sb.writeln('v ${p[0].toStringAsFixed(4)} ${p[1].toStringAsFixed(4)} ${p[2].toStringAsFixed(4)}');
    }
    String? cur;
    for (final (mat, ids) in faces) {
      if (mat != cur) {
        sb.writeln('usemtl $mat');
        cur = mat;
      }
      sb.writeln('f ${ids.join(' ')}');
    }
    return sb.toString();
  }
}

// ------------------------------------------------------------------ primitives

/// Axis-aligned box; [top] material for the +Y face.
void box(Obj o, double x0, double y0, double z0, double x1, double y1, double z1, String mat,
    {String? top}) {
  final cx = (x0 + x1) / 2, cy = (y0 + y1) / 2, cz = (z0 + z1) / 2;
  final c = [
    o.vert(x0, y0, z0), o.vert(x1, y0, z0), o.vert(x1, y0, z1), o.vert(x0, y0, z1),
    o.vert(x0, y1, z0), o.vert(x1, y1, z0), o.vert(x1, y1, z1), o.vert(x0, y1, z1),
  ];
  o.use(mat);
  o.outQuad(c[0], c[1], c[2], c[3], cx, cy, cz);
  o.outQuad(c[0], c[1], c[5], c[4], cx, cy, cz);
  o.outQuad(c[1], c[2], c[6], c[5], cx, cy, cz);
  o.outQuad(c[2], c[3], c[7], c[6], cx, cy, cz);
  o.outQuad(c[3], c[0], c[4], c[7], cx, cy, cz);
  o.use(top ?? mat);
  o.outQuad(c[4], c[5], c[6], c[7], cx, cy, cz);
}

/// Octahedron; upper faces use [topMat], lower faces [bottomMat].
void octa(Obj o, double cx, double cy, double cz, double rx, double ry, double rz,
    String topMat, String bottomMat) {
  final top = o.vert(cx, cy + ry, cz), bot = o.vert(cx, cy - ry, cz);
  final ring = [
    o.vert(cx + rx, cy, cz), o.vert(cx, cy, cz + rz), o.vert(cx - rx, cy, cz), o.vert(cx, cy, cz - rz),
  ];
  for (var i = 0; i < 4; i++) {
    final a = ring[i], b = ring[(i + 1) % 4];
    o.use(topMat);
    o.outTri(a, b, top, cx, cy, cz);
    o.use(bottomMat);
    o.outTri(a, b, bot, cx, cy, cz);
  }
}

/// Cylinder along X from [x0] to [x1].
void cylinderX(Obj o, double x0, double x1, double r, int seg, String mat) {
  final a = <int>[], b = <int>[];
  for (var i = 0; i < seg; i++) {
    final t = i / seg * math.pi * 2;
    a.add(o.vert(x0, math.cos(t) * r, math.sin(t) * r));
    b.add(o.vert(x1, math.cos(t) * r, math.sin(t) * r));
  }
  final ca = o.vert(x0, 0, 0), cb = o.vert(x1, 0, 0);
  final mx = (x0 + x1) / 2;
  o.use(mat);
  for (var i = 0; i < seg; i++) {
    final j = (i + 1) % seg;
    o.outQuad(a[i], a[j], b[j], b[i], mx, 0, 0);
    o.outTri(ca, a[i], a[j], mx, 0, 0);
    o.outTri(cb, b[i], b[j], mx, 0, 0);
  }
}

/// Flat diamond in a plane spanned by axis vectors (ux,uy,uz) and (wx,wy,wz).
void diamond(Obj o, double cx, double cy, double cz, List<double> u, List<double> w,
    double halfU, double halfW, String mat) {
  int p(double s, double t) => o.vert(cx + u[0] * s + w[0] * t, cy + u[1] * s + w[1] * t, cz + u[2] * s + w[2] * t);
  final a = p(-halfU, 0), b = p(0, halfW), c = p(halfU, 0), d = p(0, -halfW);
  o.use(mat);
  o.face([a, d, c]);
  o.face([a, c, b]);
}

// ------------------------------------------------------------------ effects

Obj slashArc() {
  final o = Obj('slash_arc', 'Crescent sword trail in the XZ plane around the wielder; forward is -Z, '
      'the bright leading edge is on the -X side. Rotate about Z by 90° for vertical cuts, mirror X for backhand.');
  const n = 14, r = 1.95;
  final outer = <int>[], inner = <int>[], edgeIn = <int>[], edgeOut = <int>[];
  for (var i = 0; i <= n; i++) {
    final u = i / n;
    final th = (75 - 150 * u) * math.pi / 180; // +75° (right) → -75° (left)
    final s = math.sin(th), c = -math.cos(th);
    final ri = r - 1.15 * math.pow(math.sin(math.pi * u), 0.8);
    outer.add(o.vert(s * r, 0, c * r));
    inner.add(o.vert(s * ri, 0, c * ri));
    edgeIn.add(o.vert(s * (r - 0.06), 0.004, c * (r - 0.06)));
    edgeOut.add(o.vert(s * (r + 0.02), 0.004, c * (r + 0.02)));
  }
  for (var i = 0; i < n; i++) {
    final u = (i + 0.5) / n;
    o.use(u < 0.35 ? 'slash_0' : u < 0.6 ? 'slash_1' : u < 0.85 ? 'slash_2' : 'slash_3');
    o.face([inner[i], outer[i], outer[i + 1]]);
    o.face([inner[i], outer[i + 1], inner[i + 1]]);
  }
  o.use('slash_edge');
  for (var i = n ~/ 2; i < n; i++) {
    o.face([edgeIn[i], edgeOut[i], edgeOut[i + 1]]);
    o.face([edgeIn[i], edgeOut[i + 1], edgeIn[i + 1]]);
  }
  return o;
}

Obj shockwaveRing() {
  final o = Obj('shockwave_ring', 'Unit-radius ground ring in the XZ plane; scale it up over time and fade it out.');
  const seg = 28;
  void annulus(double r0, double r1, double y, String mat) {
    final a = <int>[], b = <int>[];
    for (var i = 0; i < seg; i++) {
      final t = i / seg * math.pi * 2;
      a.add(o.vert(math.cos(t) * r0, y, math.sin(t) * r0));
      b.add(o.vert(math.cos(t) * r1, y, math.sin(t) * r1));
    }
    o.use(mat);
    for (var i = 0; i < seg; i++) {
      final j = (i + 1) % seg;
      o.face([a[i], b[j], b[i]]);
      o.face([a[i], a[j], b[j]]);
    }
  }

  annulus(0.62, 0.86, 0, 'ring_soft');
  annulus(0.86, 1.0, 0.003, 'ring_main');
  return o;
}

Obj impactFlash() {
  final o = Obj('impact_flash', 'Star-burst hit flash in the XY plane facing +Z (billboard), radius 1.');
  final c = o.vert(0, 0, 0.004);
  final ring = [for (var i = 0; i < 8; i++) o.vert(math.cos(i * math.pi / 4) * 0.2, math.sin(i * math.pi / 4) * 0.2, 0.004)];
  o.use('flash_core');
  for (var i = 0; i < 8; i++) {
    o.face([c, ring[i], ring[(i + 1) % 8]]);
  }
  void ray(double a, double len, double half, String mat) {
    final ca = math.cos(a), sa = math.sin(a), cb = -sa, sb = ca;
    final b0 = o.vert(ca * 0.12 + cb * half, sa * 0.12 + sb * half, 0);
    final b1 = o.vert(ca * 0.12 - cb * half, sa * 0.12 - sb * half, 0);
    final tip = o.vert(ca * len, sa * len, 0);
    o.use(mat);
    o.face([b1, tip, b0]);
  }

  for (var i = 0; i < 4; i++) {
    ray(i * math.pi / 2, 1.0, 0.09, 'flash_ray');
    ray(i * math.pi / 2 + math.pi / 4, 0.55, 0.06, 'flash_soft');
  }
  return o;
}

Obj smokePuff() {
  final o = Obj('smoke_puff', 'Lumpy smoke blob, radius ~1 (icosahedron with jittered vertices).');
  final rnd = math.Random(11);
  final t = (1 + math.sqrt(5)) / 2;
  final base = [
    [-1, t, 0], [1, t, 0], [-1, -t, 0], [1, -t, 0], [0, -1, t], [0, 1, t],
    [0, -1, -t], [0, 1, -t], [t, 0, -1], [t, 0, 1], [-t, 0, -1], [-t, 0, 1],
  ];
  final ids = [
    for (final p in base)
      () {
        final l = math.sqrt(p[0] * p[0] + p[1] * p[1] + p[2] * p[2]);
        final r = 0.8 + rnd.nextDouble() * 0.35;
        return o.vert(p[0] / l * r, p[1] / l * r * 0.85, p[2] / l * r);
      }()
  ];
  const f = [
    0, 11, 5, 0, 5, 1, 0, 1, 7, 0, 7, 10, 0, 10, 11, 1, 5, 9, 5, 11, 4, 11, 10, 2, 10, 7, 6, 7, 1, 8,
    3, 9, 4, 3, 4, 2, 3, 2, 6, 3, 6, 8, 3, 8, 9, 4, 9, 5, 2, 4, 11, 6, 2, 10, 8, 6, 7, 9, 8, 1,
  ];
  for (var i = 0; i < f.length; i += 3) {
    o.use(['smoke_a', 'smoke_b', 'smoke_c'][(i ~/ 3) % 3]);
    o.outTri(ids[f[i]], ids[f[i + 1]], ids[f[i + 2]], 0, 0, 0);
  }
  return o;
}

Obj dustPuff() {
  final o = Obj('dust_puff', 'Small dust cloud (jittered octahedron), radius ~1.');
  octa(o, 0, 0, 0, 1.0, 0.7, 0.9, 'dust_a', 'dust_b');
  return o;
}

Obj flame() {
  final o = Obj('flame', 'Flame tongue: two crossed vertical planes, base at the origin, 1.25 m tall.');
  for (final axisX in [true, false]) {
    int p(double s, double y) => axisX ? o.vert(s, y, 0) : o.vert(0, y, s);
    final b = p(0, 0), l1 = p(-0.32, 0.35), r1 = p(0.32, 0.35);
    final l2 = p(-0.18, 0.8), r2 = p(0.18, 0.8), tip = p(0, 1.25);
    o.use('flame_core');
    o.face([b, r1, l1]);
    o.use('flame_mid');
    o.face([l1, r1, r2]);
    o.face([l1, r2, l2]);
    o.use('flame_tip');
    o.face([l2, r2, tip]);
  }
  return o;
}

Obj spark() {
  final o = Obj('spark', 'Hot spark: two crossed diamonds along Y, 1 m long (scale down).');
  diamond(o, 0, 0, 0, [0, 1, 0], [1, 0, 0], 0.5, 0.08, 'spark');
  diamond(o, 0, 0, 0, [0, 1, 0], [0, 0, 1], 0.5, 0.08, 'spark');
  return o;
}

Obj ember() {
  final o = Obj('ember', 'Floating ember / glow mote: two crossed small diamonds, ~0.3 m.');
  diamond(o, 0, 0, 0, [0, 1, 0], [1, 0, 0], 0.15, 0.06, 'ember');
  diamond(o, 0, 0, 0, [0, 1, 0], [0, 0, 1], 0.15, 0.06, 'ember');
  return o;
}

Obj streak() {
  final o = Obj('streak', 'Motion streak in the XY plane facing +Z (billboard), 2 m long.');
  diamond(o, 0, 0, 0, [0, 1, 0], [1, 0, 0], 1.0, 0.25, 'streak');
  return o;
}

Obj bloodDrop() {
  final o = Obj('blood_drop', 'Blood droplet (triangular bipyramid), ~0.8 m tall (scale down).');
  final top = o.vert(0, 0.5, 0), bot = o.vert(0, -0.3, 0);
  final ring = [for (var i = 0; i < 3; i++) o.vert(math.cos(i * 2.094) * 0.25, -0.05, math.sin(i * 2.094) * 0.25)];
  o.use('blood');
  for (var i = 0; i < 3; i++) {
    o.outTri(ring[i], ring[(i + 1) % 3], top, 0, 0.05, 0);
    o.outTri(ring[i], ring[(i + 1) % 3], bot, 0, 0.05, 0);
  }
  return o;
}

Obj petal() {
  final o = Obj('petal', 'Cherry-blossom petal, slightly cupped, ~0.6 m long (scale down).');
  final bump = o.vert(0, 0.12, 0.3);
  final rim = [o.vert(0, 0, 0), o.vert(0.35, 0.05, 0.25), o.vert(0, 0.08, 0.6), o.vert(-0.35, 0.05, 0.25)];
  o.use('petal');
  for (var i = 0; i < 4; i++) {
    o.face([bump, rim[i], rim[(i + 1) % 4]]);
  }
  return o;
}

Obj shuriken() {
  final o = Obj('shuriken', 'Four-pointed throwing star lying in the XZ plane, 0.36 m across.');
  const h = 0.012;
  final top = <int>[], bot = <int>[];
  for (var i = 0; i < 8; i++) {
    final a = i * math.pi / 4;
    final r = i.isEven ? 0.18 : 0.055;
    top.add(o.vert(math.cos(a) * r, h, math.sin(a) * r));
    bot.add(o.vert(math.cos(a) * r, -h, math.sin(a) * r));
  }
  final ct = o.vert(0, h, 0), cb = o.vert(0, -h, 0);
  for (var i = 0; i < 8; i++) {
    final j = (i + 1) % 8;
    o.use('steel_face');
    o.outTri(ct, top[i], top[j], 0, 0, 0);
    o.outTri(cb, bot[i], bot[j], 0, 0, 0);
    o.use('steel_edge');
    o.outQuad(top[i], top[j], bot[j], bot[i], 0, 0, 0);
  }
  // Center hole (dark caps just above both faces).
  for (final y in [h + 0.001, -h - 0.001]) {
    final c = o.vert(0, y, 0);
    final ring = [for (var i = 0; i < 6; i++) o.vert(math.cos(i * math.pi / 3) * 0.028, y, math.sin(i * math.pi / 3) * 0.028)];
    o.use('steel_hole');
    for (var i = 0; i < 6; i++) {
      o.outTri(c, ring[i], ring[(i + 1) % 6], 0, y > 0 ? -1 : 1, 0);
    }
  }
  return o;
}

Obj arrow() {
  final o = Obj('arrow', 'Arrow pointing along +Z, 1.05 m long, centered on the shaft.');
  box(o, -0.015, -0.015, -0.45, 0.015, 0.015, 0.45, 'arrow_shaft');
  final tip = o.vert(0, 0, 0.6);
  final base = [o.vert(-0.035, -0.035, 0.45), o.vert(0.035, -0.035, 0.45), o.vert(0.035, 0.035, 0.45), o.vert(-0.035, 0.035, 0.45)];
  o.use('arrow_head');
  for (var i = 0; i < 4; i++) {
    o.outTri(base[i], base[(i + 1) % 4], tip, 0, 0, 0.5);
  }
  o.outQuad(base[0], base[1], base[2], base[3], 0, 0, 0.5);
  o.use('arrow_feather');
  final f = [o.vert(-0.06, 0, -0.45), o.vert(0.06, 0, -0.45), o.vert(0.03, 0, -0.28), o.vert(-0.03, 0, -0.28)];
  o.face([f[0], f[1], f[2]]);
  o.face([f[0], f[2], f[3]]);
  final g = [o.vert(0, -0.06, -0.45), o.vert(0, 0.06, -0.45), o.vert(0, 0.03, -0.28), o.vert(0, -0.03, -0.28)];
  o.face([g[0], g[1], g[2]]);
  o.face([g[0], g[2], g[3]]);
  return o;
}

Obj alertMark() {
  final o = Obj('alert_mark', 'Red "!" awareness marker floating over a detected enemy; base at the origin.');
  box(o, -0.06, 0.18, -0.06, 0.06, 0.62, 0.06, 'alert_red', top: 'alert_hot');
  box(o, -0.06, 0, -0.06, 0.06, 0.12, 0.06, 'alert_red', top: 'alert_hot');
  return o;
}

Obj suspicionGem() {
  final o = Obj('suspicion_gem', 'Spinning yellow gem over a suspicious enemy.');
  octa(o, 0, 0, 0, 0.1, 0.16, 0.1, 'gem_light', 'gem_dark');
  return o;
}

Obj blindStars() {
  final o = Obj('blind_stars', 'Three motes orbiting the head of a blinded enemy (spin about Y).');
  for (var k = 0; k < 3; k++) {
    final a = k * math.pi * 2 / 3;
    octa(o, math.cos(a) * 0.35, 0, math.sin(a) * 0.35, 0.07, 0.07, 0.07, 'blind', 'blind');
  }
  return o;
}

Obj objectiveBeacon() {
  final o = Obj('objective_beacon', 'Light pillar of crossed planes, 1 x 1 m with bands fading upward; scale to size. Ignores fog.');
  const bands = [(0.0, 0.12, 'beacon_base'), (0.12, 0.5, 'beacon_mid'), (0.5, 1.0, 'beacon_top')];
  for (final axisX in [true, false]) {
    for (final (y0, y1, mat) in bands) {
      int p(double s, double y) => axisX ? o.vert(s, y, 0) : o.vert(0, y, s);
      final a = p(-0.5, y0), b = p(0.5, y0), c = p(0.5, y1), d = p(-0.5, y1);
      o.use(mat);
      o.face([a, b, c]);
      o.face([a, c, d]);
    }
  }
  return o;
}

Obj objectiveGem() {
  final o = Obj('objective_gem', 'Golden marker gem floating over objectives. Ignores fog.');
  octa(o, 0, 0, 0, 0.35, 0.55, 0.35, 'gem_gold', 'gem_gold_dark');
  return o;
}

Obj pickupRing() {
  final o = Obj('pickup_ring', 'Segmented rune circle on the ground under pickups (XZ plane), tinted per pickup.');
  for (var k = 0; k < 8; k++) {
    final a0 = k * math.pi / 4;
    final seg = <(int, int)>[];
    for (var i = 0; i <= 3; i++) {
      final a = a0 + i / 3 * (math.pi / 6);
      seg.add((o.vert(math.cos(a) * 0.62, 0, math.sin(a) * 0.62), o.vert(math.cos(a) * 0.76, 0, math.sin(a) * 0.76)));
    }
    o.use('rune');
    for (var i = 0; i < 3; i++) {
      o.face([seg[i].$1, seg[i + 1].$2, seg[i].$2]);
      o.face([seg[i].$1, seg[i + 1].$1, seg[i + 1].$2]);
    }
    final mid = a0 + math.pi / 6 + math.pi / 24;
    diamond(o, math.cos(mid) * 0.5, 0.002, math.sin(mid) * 0.5, [math.cos(mid), 0, math.sin(mid)],
        [-math.sin(mid), 0, math.cos(mid)], 0.06, 0.03, 'rune_soft');
  }
  return o;
}

Obj pickupScroll() {
  final o = Obj('pickup_scroll', 'Rolled scroll (story note pickup) along X, centered.');
  cylinderX(o, -0.3, 0.3, 0.09, 8, 'paper');
  cylinderX(o, -0.37, -0.3, 0.12, 8, 'scroll_red');
  cylinderX(o, 0.3, 0.37, 0.12, 8, 'scroll_red');
  return o;
}

Obj pickupSupply() {
  final o = Obj('pickup_supply', 'Supply crate (shuriken + smoke refill) with a gold lid and star emblem.');
  box(o, -0.3, -0.25, -0.225, 0.3, 0.2, 0.225, 'crate', top: 'crate_lid');
  for (var i = 0; i < 4; i++) {
    final a = i * math.pi / 2;
    diamond(o, math.cos(a) * 0.1, 0.204, math.sin(a) * 0.1, [math.cos(a), 0, math.sin(a)],
        [-math.sin(a), 0, math.cos(a)], 0.1, 0.03, 'steel_face');
  }
  return o;
}

Obj pickupOnigiri() {
  final o = Obj('pickup_onigiri', 'Rice ball (health pickup): triangular prism with a nori band.');
  final f = [o.vert(0, 0.22, 0.1), o.vert(-0.25, -0.2, 0.1), o.vert(0.25, -0.2, 0.1)];
  final b = [o.vert(0, 0.22, -0.1), o.vert(-0.25, -0.2, -0.1), o.vert(0.25, -0.2, -0.1)];
  o.use('rice');
  o.outTri(f[0], f[1], f[2], 0, 0, 0);
  o.outTri(b[0], b[1], b[2], 0, 0, 0);
  for (var i = 0; i < 3; i++) {
    o.outQuad(f[i], f[(i + 1) % 3], b[(i + 1) % 3], b[i], 0, -0.06, 0);
  }
  box(o, -0.11, -0.21, -0.105, 0.11, -0.04, 0.105, 'nori');
  return o;
}

Obj barQuad() {
  final o = Obj('bar_quad', 'Unit quad (0..1 in X and Y) facing +Z for billboard health bars; tinted at runtime.');
  final a = o.vert(0, 0, 0), b = o.vert(1, 0, 0), c = o.vert(1, 1, 0), d = o.vert(0, 1, 0);
  o.use('bar');
  o.face([a, b, c]);
  o.face([a, c, d]);
  return o;
}

void main() {
  final dir = Directory('assets/effects')..createSync(recursive: true);
  final objs = [
    slashArc(), shockwaveRing(), impactFlash(), smokePuff(), dustPuff(), flame(), spark(), ember(),
    streak(), bloodDrop(), petal(), shuriken(), arrow(), alertMark(), suspicionGem(), blindStars(),
    objectiveBeacon(), objectiveGem(), pickupRing(), pickupScroll(), pickupSupply(), pickupOnigiri(),
    barQuad(),
  ];
  File('${dir.path}/effects.mtl').writeAsStringSync(
      '# Essen effect materials. Generated by tool/generate_effects.dart.\n'
      '# essen_flags: double = two-sided, emissive = unlit glow, nofog = ignores distance fog.\n\n'
      '${mats.map((m) => m.write()).join('\n')}');
  final used = <String>{};
  for (final o in objs) {
    File('${dir.path}/${o.name}.obj').writeAsStringSync(o.write());
    used.addAll(o.faces.map((f) => f.$1));
    stdout.writeln('wrote ${o.name}.obj  (${o.v.length} verts, ${o.faces.length} faces)');
  }
  final missing = used.difference(mats.map((m) => m.name).toSet());
  if (missing.isNotEmpty) throw StateError('Materials missing from effects.mtl: $missing');
  stdout.writeln('wrote effects.mtl (${mats.length} materials)');
}
