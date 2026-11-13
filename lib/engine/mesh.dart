import 'dart:math' as math;
import 'dart:typed_data';

import 'math3d.dart';
import 'obj_mesh.dart';

/// Triangle flags.
const int fDouble = 1; // never back-face culled
const int fEmissive = 2; // ignores lighting
const int fGround = 4; // terrain: drawn behind objects when depths are close
const int fWater = 8; // water surface
const int fNoFog = 16; // ignores distance fog (beacons)

/// Scene lighting + atmosphere for a time of day.
class Lighting {
  final String name;
  late final double lx, ly, lz; // normalized direction towards the sun/moon
  final double sunR, sunG, sunB;
  final double ambR, ambG, ambB;
  final int fogColor;
  final double fogStart, fogEnd;
  final int skyTop, skyHorizon;
  final int sunDiscColor;
  final double sunDiscSize;
  final bool night;

  Lighting({
    required this.name,
    required double dirX,
    required double dirY,
    required double dirZ,
    required this.sunR,
    required this.sunG,
    required this.sunB,
    required this.ambR,
    required this.ambG,
    required this.ambB,
    required this.fogColor,
    required this.fogStart,
    required this.fogEnd,
    required this.skyTop,
    required this.skyHorizon,
    required this.sunDiscColor,
    this.sunDiscSize = 1.0,
    this.night = false,
  }) {
    final l = math.sqrt(dirX * dirX + dirY * dirY + dirZ * dirZ);
    lx = dirX / l;
    ly = dirY / l;
    lz = dirZ / l;
  }

  static final moonlit = Lighting(
    name: 'night',
    dirX: -0.4, dirY: 0.7, dirZ: 0.5,
    sunR: 0.35, sunG: 0.42, sunB: 0.65,
    ambR: 0.30, ambG: 0.32, ambB: 0.48,
    fogColor: 0xFF141B2E, fogStart: 25, fogEnd: 125,
    skyTop: 0xFF05070F, skyHorizon: 0xFF1B2440,
    sunDiscColor: 0xFFE8ECFF, sunDiscSize: 0.8, night: true,
  );

  static final dawn = Lighting(
    name: 'dawn',
    dirX: 0.8, dirY: 0.25, dirZ: -0.3,
    sunR: 1.0, sunG: 0.72, sunB: 0.55,
    ambR: 0.48, ambG: 0.50, ambB: 0.60,
    fogColor: 0xFFB9B4BE, fogStart: 15, fogEnd: 110,
    skyTop: 0xFF5D7196, skyHorizon: 0xFFE7C0A5,
    sunDiscColor: 0xFFFFE2B0, sunDiscSize: 1.3,
  );

  static final day = Lighting(
    name: 'day',
    dirX: 0.35, dirY: 0.85, dirZ: 0.4,
    sunR: 0.95, sunG: 0.92, sunB: 0.82,
    ambR: 0.48, ambG: 0.52, ambB: 0.60,
    fogColor: 0xFFC4D6E6, fogStart: 45, fogEnd: 140,
    skyTop: 0xFF4F8AD0, skyHorizon: 0xFFCFE0EE,
    sunDiscColor: 0xFFFFFBE8,
  );

  static final sunset = Lighting(
    name: 'sunset',
    dirX: -0.85, dirY: 0.18, dirZ: -0.35,
    sunR: 1.05, sunG: 0.55, sunB: 0.35,
    ambR: 0.45, ambG: 0.36, ambB: 0.45,
    fogColor: 0xFF8E4A44, fogStart: 30, fogEnd: 130,
    skyTop: 0xFF2C1F45, skyHorizon: 0xFFE07848,
    sunDiscColor: 0xFFFF9A50, sunDiscSize: 1.6,
  );
}

/// A growable list of world-space triangles with per-face normals & colors.
class TriBatch {
  Float32List pos;
  Float32List nrm;
  Int32List base;
  Int32List shaded;
  Uint8List flags;
  int count = 0;

  // Bounding sphere (infinite radius = always considered visible).
  double bx = 0, by = 0, bz = 0, br = double.infinity;

  TriBatch([int capacity = 64])
      : pos = Float32List(capacity * 9),
        nrm = Float32List(capacity * 3),
        base = Int32List(capacity),
        shaded = Int32List(capacity),
        flags = Uint8List(capacity);

  int get capacity => flags.length;

  void clear() => count = 0;

  void _grow() {
    final cap = capacity * 2;
    pos = Float32List(cap * 9)..setRange(0, count * 9, pos);
    nrm = Float32List(cap * 3)..setRange(0, count * 3, nrm);
    base = Int32List(cap)..setRange(0, count, base);
    shaded = Int32List(cap)..setRange(0, count, shaded);
    flags = Uint8List(cap)..setRange(0, count, flags);
  }

  void add(double ax, double ay, double az, double bx_, double by_, double bz_,
      double cx, double cy, double cz, double nx, double ny, double nz,
      int color, int flag) {
    if (count >= capacity) _grow();
    final p = count * 9;
    pos[p] = ax;
    pos[p + 1] = ay;
    pos[p + 2] = az;
    pos[p + 3] = bx_;
    pos[p + 4] = by_;
    pos[p + 5] = bz_;
    pos[p + 6] = cx;
    pos[p + 7] = cy;
    pos[p + 8] = cz;
    final n = count * 3;
    nrm[n] = nx;
    nrm[n + 1] = ny;
    nrm[n + 2] = nz;
    base[count] = color;
    shaded[count] = color;
    flags[count] = flag;
    count++;
  }

  /// Shrinks storage to fit and computes the bounding sphere.
  void finish() {
    if (count < capacity) {
      pos = Float32List.fromList(Float32List.sublistView(pos, 0, count * 9));
      nrm = Float32List.fromList(Float32List.sublistView(nrm, 0, count * 3));
      base = Int32List.fromList(Int32List.sublistView(base, 0, count));
      shaded = Int32List.fromList(Int32List.sublistView(shaded, 0, count));
      flags = Uint8List.fromList(Uint8List.sublistView(flags, 0, count));
    }
    if (count == 0) {
      br = 0;
      return;
    }
    var minX = double.infinity, minY = double.infinity, minZ = double.infinity;
    var maxX = -double.infinity, maxY = -double.infinity, maxZ = -double.infinity;
    for (var i = 0; i < count * 9; i += 3) {
      final x = pos[i], y = pos[i + 1], z = pos[i + 2];
      if (x < minX) minX = x;
      if (y < minY) minY = y;
      if (z < minZ) minZ = z;
      if (x > maxX) maxX = x;
      if (y > maxY) maxY = y;
      if (z > maxZ) maxZ = z;
    }
    bx = (minX + maxX) / 2;
    by = (minY + maxY) / 2;
    bz = (minZ + maxZ) / 2;
    final dx = maxX - bx, dy = maxY - by, dz = maxZ - bz;
    br = math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  /// Bakes lighting into [shaded]. Called once for static geometry
  /// (and again whenever the time of day changes).
  void relight(Lighting l) {
    for (var i = 0; i < count; i++) {
      shaded[i] = shadeColor(base[i], flags[i], nrm[i * 3], nrm[i * 3 + 1],
          nrm[i * 3 + 2], l);
    }
  }

  static int shadeColor(
      int c, int flag, double nx, double ny, double nz, Lighting l) {
    if (flag & fEmissive != 0) return c;
    var d = nx * l.lx + ny * l.ly + nz * l.lz;
    if (d < 0) {
      // Double-sided foliage receives light on both faces.
      d = flag & fDouble != 0 ? -d * 0.6 : 0;
    }
    final hemi = 0.78 + 0.22 * ny;
    final fr = l.ambR * hemi + l.sunR * d;
    final fg = l.ambG * hemi + l.sunG * d;
    final fb = l.ambB * hemi + l.sunB * d;
    final r = (((c >> 16) & 255) * fr).round().clamp(0, 255);
    final g = (((c >> 8) & 255) * fg).round().clamp(0, 255);
    final b = ((c & 255) * fb).round().clamp(0, 255);
    return (c & 0xFF000000) | (r << 16) | (g << 8) | b;
  }
}

/// Builds geometry into a [TriBatch] using a transform stack.
/// All primitives are convex; faces are automatically oriented outward.
class MeshBuilder {
  final TriBatch out;
  final math.Random rng;
  double jitter = 0.06;
  int flags = 0;

  Float64List _m = _identity();
  final List<Float64List> _stack = [];

  MeshBuilder(this.out, [math.Random? random]) : rng = random ?? math.Random(1);

  static Float64List _identity() =>
      Float64List.fromList([1, 0, 0, 0, 1, 0, 0, 0, 1, 0, 0, 0]);

  void reset() {
    _m = _identity();
    _stack.clear();
  }

  void push() => _stack.add(Float64List.fromList(_m));
  void pop() => _m = _stack.removeLast();

  void translate(double x, double y, double z) {
    final m = _m;
    m[9] += m[0] * x + m[1] * y + m[2] * z;
    m[10] += m[3] * x + m[4] * y + m[5] * z;
    m[11] += m[6] * x + m[7] * y + m[8] * z;
  }

  void _mul(double r00, double r01, double r02, double r10, double r11,
      double r12, double r20, double r21, double r22) {
    final m = _m;
    for (var row = 0; row < 3; row++) {
      final a = m[row * 3], b = m[row * 3 + 1], c = m[row * 3 + 2];
      m[row * 3] = a * r00 + b * r10 + c * r20;
      m[row * 3 + 1] = a * r01 + b * r11 + c * r21;
      m[row * 3 + 2] = a * r02 + b * r12 + c * r22;
    }
  }

  void rotateY(double a) {
    final c = math.cos(a), s = math.sin(a);
    _mul(c, 0, s, 0, 1, 0, -s, 0, c);
  }

  void rotateX(double a) {
    final c = math.cos(a), s = math.sin(a);
    _mul(1, 0, 0, 0, c, -s, 0, s, c);
  }

  void rotateZ(double a) {
    final c = math.cos(a), s = math.sin(a);
    _mul(c, -s, 0, s, c, 0, 0, 0, 1);
  }

  void scale(double sx, double sy, double sz) => _mul(sx, 0, 0, 0, sy, 0, 0, 0, sz);

  // Transformed point scratch.
  double _tx = 0, _ty = 0, _tz = 0;
  void _xf(double x, double y, double z) {
    final m = _m;
    _tx = m[0] * x + m[1] * y + m[2] * z + m[9];
    _ty = m[3] * x + m[4] * y + m[5] * z + m[10];
    _tz = m[6] * x + m[7] * y + m[8] * z + m[11];
  }

  int jit(int color, [double? amount]) {
    final j = amount ?? jitter;
    if (j == 0) return color;
    return scaleColor(color, 1 + (rng.nextDouble() * 2 - 1) * j);
  }

  /// Emits a world-space triangle. If [hasCenter], it is flipped to face away
  /// from (ox, oy, oz).
  void worldTri(double ax, double ay, double az, double bx, double by,
      double bz, double cx, double cy, double cz, int color,
      {int flag = 0, bool hasCenter = false, double ox = 0, double oy = 0, double oz = 0}) {
    final ux = bx - ax, uy = by - ay, uz = bz - az;
    final vx = cx - ax, vy = cy - ay, vz = cz - az;
    var nx = uy * vz - uz * vy;
    var ny = uz * vx - ux * vz;
    var nz = ux * vy - uy * vx;
    final len = math.sqrt(nx * nx + ny * ny + nz * nz);
    if (len < 1e-9) return;
    nx /= len;
    ny /= len;
    nz /= len;
    if (hasCenter) {
      final mx = (ax + bx + cx) / 3 - ox;
      final my = (ay + by + cy) / 3 - oy;
      final mz = (az + bz + cz) / 3 - oz;
      if (mx * nx + my * ny + mz * nz < 0) {
        out.add(ax, ay, az, cx, cy, cz, bx, by, bz, -nx, -ny, -nz, color,
            flag | flags);
        return;
      }
    }
    out.add(ax, ay, az, bx, by, bz, cx, cy, cz, nx, ny, nz, color, flag | flags);
  }

  /// Emits a loaded model with the current transform. [alpha] scales each
  /// material's opacity; [tint] blends material colors toward a color by
  /// [tintAmount] (0..1).
  void mesh(ObjMesh m, {double alpha = 1, int? tint, double tintAmount = 0, int flag = 0}) {
    if (alpha <= 0.01) return;
    final p = m.pos;
    final tr = tint == null ? 0 : (tint >> 16) & 255;
    final tg = tint == null ? 0 : (tint >> 8) & 255;
    final tb = tint == null ? 0 : tint & 255;
    for (var i = 0; i < m.triangleCount; i++) {
      var c = m.colors[i];
      final a = (((c >> 24) & 255) * alpha).round().clamp(0, 255);
      if (tint != null && tintAmount > 0) {
        final r = (c >> 16) & 255, g = (c >> 8) & 255, b = c & 255;
        c = (((r + (tr - r) * tintAmount).round()) << 16) |
            (((g + (tg - g) * tintAmount).round()) << 8) |
            (b + (tb - b) * tintAmount).round();
      }
      c = (a << 24) | (c & 0xFFFFFF);
      final o = i * 9;
      _xf(p[o], p[o + 1], p[o + 2]);
      final ax = _tx, ay = _ty, az = _tz;
      _xf(p[o + 3], p[o + 4], p[o + 5]);
      final bx = _tx, by = _ty, bz = _tz;
      _xf(p[o + 6], p[o + 7], p[o + 8]);
      worldTri(ax, ay, az, bx, by, bz, _tx, _ty, _tz, c, flag: m.flags[i] | flag);
    }
  }

  /// Turns the local XY plane (+Z normal) toward the camera.
  void billboard(double camYaw, double camPitch) {
    rotateY(-camYaw);
    rotateX(camPitch);
  }

  /// Local-space triangle oriented away from a local center.
  void tri(double ax, double ay, double az, double bx, double by, double bz,
      double cx, double cy, double cz, int color,
      double ox, double oy, double oz, {int flag = 0}) {
    _xf(ox, oy, oz);
    final wox = _tx, woy = _ty, woz = _tz;
    _xf(ax, ay, az);
    final wax = _tx, way = _ty, waz = _tz;
    _xf(bx, by, bz);
    final wbx = _tx, wby = _ty, wbz = _tz;
    _xf(cx, cy, cz);
    worldTri(wax, way, waz, wbx, wby, wbz, _tx, _ty, _tz, color,
        flag: flag, hasCenter: true, ox: wox, oy: woy, oz: woz);
  }

  /// Local-space double-sided triangle (foliage, cloth, flames).
  void tri2(double ax, double ay, double az, double bx, double by, double bz,
      double cx, double cy, double cz, int color, {int flag = 0}) {
    _xf(ax, ay, az);
    final wax = _tx, way = _ty, waz = _tz;
    _xf(bx, by, bz);
    final wbx = _tx, wby = _ty, wbz = _tz;
    _xf(cx, cy, cz);
    worldTri(wax, way, waz, wbx, wby, wbz, _tx, _ty, _tz, color,
        flag: flag | fDouble);
  }

  /// Double-sided quad in local space.
  void quad2(double ax, double ay, double az, double bx, double by, double bz,
      double cx, double cy, double cz, double dx, double dy, double dz,
      int color, {int flag = 0}) {
    final c = jit(color);
    tri2(ax, ay, az, bx, by, bz, cx, cy, cz, c, flag: flag);
    tri2(ax, ay, az, cx, cy, cz, dx, dy, dz, c, flag: flag);
  }

  /// Generic convex hexahedron. Corners: bottom 0-3, top 4-7, both ordered
  /// (-x,-z), (+x,-z), (+x,+z), (-x,+z).
  void hexa(List<double> c, int color, {int? topColor, bool bottom = true}) {
    var ox = 0.0, oy = 0.0, oz = 0.0;
    for (var i = 0; i < 8; i++) {
      ox += c[i * 3];
      oy += c[i * 3 + 1];
      oz += c[i * 3 + 2];
    }
    ox /= 8;
    oy /= 8;
    oz /= 8;
    void face(int a, int b, int cc, int d, int col) {
      final k = jit(col);
      tri(c[a * 3], c[a * 3 + 1], c[a * 3 + 2], c[b * 3], c[b * 3 + 1],
          c[b * 3 + 2], c[cc * 3], c[cc * 3 + 1], c[cc * 3 + 2], k, ox, oy, oz);
      tri(c[a * 3], c[a * 3 + 1], c[a * 3 + 2], c[cc * 3], c[cc * 3 + 1],
          c[cc * 3 + 2], c[d * 3], c[d * 3 + 1], c[d * 3 + 2], k, ox, oy, oz);
    }

    if (bottom) face(0, 1, 2, 3, color);
    face(4, 5, 6, 7, topColor ?? color);
    face(0, 1, 5, 4, color);
    face(1, 2, 6, 5, color);
    face(2, 3, 7, 6, color);
    face(3, 0, 4, 7, color);
  }

  /// Box with its base centered at (x, y0, z).
  void box(double x, double y0, double z, double w, double h, double d,
      int color, {int? topColor, bool bottom = true}) {
    frustum(x, y0, z, w, d, w, d, h, color, topColor: topColor, bottom: bottom);
  }

  /// Truncated pyramid (roofs, castle bases).
  void frustum(double x, double y0, double z, double wb, double db, double wt,
      double dt, double h, int color, {int? topColor, bool bottom = true}) {
    final hb = wb / 2, hdb = db / 2, ht = wt / 2, hdt = dt / 2, y1 = y0 + h;
    hexa([
      x - hb, y0, z - hdb, x + hb, y0, z - hdb, x + hb, y0, z + hdb, x - hb, y0, z + hdb, //
      x - ht, y1, z - hdt, x + ht, y1, z - hdt, x + ht, y1, z + hdt, x - ht, y1, z + hdt,
    ], color, topColor: topColor, bottom: bottom);
  }

  /// Cylinder / cone along +y with base at (x, y0, z).
  void cylinder(double x, double y0, double z, double rb, double rt, double h,
      int seg, int color, {bool caps = true, int? topColor}) {
    final oy = y0 + h * 0.5;
    final y1 = y0 + h;
    for (var i = 0; i < seg; i++) {
      final a0 = i / seg * pi2, a1 = (i + 1) / seg * pi2;
      final c0 = math.cos(a0), s0 = math.sin(a0), c1 = math.cos(a1), s1 = math.sin(a1);
      final col = jit(color);
      if (rt <= 0.0001) {
        tri(x + c0 * rb, y0, z + s0 * rb, x + c1 * rb, y0, z + s1 * rb, x, y1, z,
            col, x, oy, z);
      } else {
        tri(x + c0 * rb, y0, z + s0 * rb, x + c1 * rb, y0, z + s1 * rb,
            x + c1 * rt, y1, z + s1 * rt, col, x, oy, z);
        tri(x + c0 * rb, y0, z + s0 * rb, x + c1 * rt, y1, z + s1 * rt,
            x + c0 * rt, y1, z + s0 * rt, col, x, oy, z);
        if (caps) {
          tri(x, y1, z, x + c0 * rt, y1, z + s0 * rt, x + c1 * rt, y1, z + s1 * rt,
              topColor ?? color, x, oy, z);
        }
      }
      if (caps) {
        tri(x, y0, z, x + c0 * rb, y0, z + s0 * rb, x + c1 * rb, y0, z + s1 * rb,
            col, x, oy, z);
      }
    }
  }

  /// Triangular prism roof; ridge along the x axis.
  void gable(double x, double y0, double z, double w, double d, double h,
      int color, {int? endColor}) {
    final hw = w / 2, hd = d / 2, y1 = y0 + h;
    final ox = x, oy = y0 + h / 3, oz = z;
    final c1 = jit(color), c2 = jit(color), ce = endColor ?? scaleColor(color, 0.85);
    // Slopes.
    tri(x - hw, y0, z - hd, x + hw, y0, z - hd, x + hw, y1, z, c1, ox, oy, oz);
    tri(x - hw, y0, z - hd, x + hw, y1, z, x - hw, y1, z, c1, ox, oy, oz);
    tri(x - hw, y0, z + hd, x + hw, y0, z + hd, x + hw, y1, z, c2, ox, oy, oz);
    tri(x - hw, y0, z + hd, x + hw, y1, z, x - hw, y1, z, c2, ox, oy, oz);
    // Ends.
    tri(x - hw, y0, z - hd, x - hw, y0, z + hd, x - hw, y1, z, ce, ox, oy, oz);
    tri(x + hw, y0, z - hd, x + hw, y0, z + hd, x + hw, y1, z, ce, ox, oy, oz);
    // Underside.
    final cu = scaleColor(color, 0.6);
    tri(x - hw, y0, z - hd, x + hw, y0, z - hd, x + hw, y0, z + hd, cu, ox, oy, oz);
    tri(x - hw, y0, z - hd, x + hw, y0, z + hd, x - hw, y0, z + hd, cu, ox, oy, oz);
  }

  static final List<double> _icoV = () {
    final t = (1 + math.sqrt(5)) / 2;
    final v = <double>[
      -1, t, 0, 1, t, 0, -1, -t, 0, 1, -t, 0, //
      0, -1, t, 0, 1, t, 0, -1, -t, 0, 1, -t, //
      t, 0, -1, t, 0, 1, -t, 0, -1, -t, 0, 1,
    ];
    final l = math.sqrt(1 + t * t);
    return [for (final c in v) c / l];
  }();
  static const List<int> _icoF = [
    0, 11, 5, 0, 5, 1, 0, 1, 7, 0, 7, 10, 0, 10, 11, 1, 5, 9, 5, 11, 4, //
    11, 10, 2, 10, 7, 6, 7, 1, 8, 3, 9, 4, 3, 4, 2, 3, 2, 6, 3, 6, 8, 3, 8, 9,
    4, 9, 5, 2, 4, 11, 6, 2, 10, 8, 6, 7, 9, 8, 1,
  ];

  /// Low-poly ellipsoid (20 faces) — foliage, rocks, smoke.
  void ico(double x, double y, double z, double rx, double ry, double rz,
      int color, {double? colorJitter}) {
    final v = _icoV;
    for (var f = 0; f < _icoF.length; f += 3) {
      final a = _icoF[f] * 3, b = _icoF[f + 1] * 3, c = _icoF[f + 2] * 3;
      tri(x + v[a] * rx, y + v[a + 1] * ry, z + v[a + 2] * rz,
          x + v[b] * rx, y + v[b + 1] * ry, z + v[b + 2] * rz,
          x + v[c] * rx, y + v[c + 1] * ry, z + v[c + 2] * rz,
          jit(color, colorJitter), x, y, z);
    }
  }

  /// Octahedron (8 faces) — cheap blobs and particles.
  void octa(double x, double y, double z, double rx, double ry, double rz,
      int color, {int flag = 0}) {
    const d = [1, 0, 0, 0, 0, 1, -1, 0, 0, 0, 0, -1];
    for (var i = 0; i < 4; i++) {
      final ax = d[i * 3] * rx, az = d[i * 3 + 2] * rz;
      final j = (i + 1) % 4;
      final bx = d[j * 3] * rx, bz = d[j * 3 + 2] * rz;
      final c = flag & fEmissive != 0 ? color : jit(color);
      tri(x + ax, y, z + az, x + bx, y, z + bz, x, y + ry, z, c, x, y, z, flag: flag);
      tri(x + ax, y, z + az, x + bx, y, z + bz, x, y - ry, z, c, x, y, z, flag: flag);
    }
  }
}
