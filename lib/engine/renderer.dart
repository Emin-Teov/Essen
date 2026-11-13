import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui';

import 'math3d.dart';
import 'mesh.dart';

/// First-person camera. Yaw 0 looks toward -Z; positive yaw turns right.
class Camera {
  double x = 0, y = 0, z = 0, yaw = 0, pitch = 0;
  double fovY = 58 * math.pi / 180;

  // Orthonormal basis: right, up, forward.
  double rx = 1, ry = 0, rz = 0;
  double ux = 0, uy = 1, uz = 0;
  double fx = 0, fy = 0, fz = -1;

  void update() {
    final cp = math.cos(pitch), sp = math.sin(pitch);
    final cy = math.cos(yaw), sy = math.sin(yaw);
    fx = sy * cp;
    fy = sp;
    fz = -cy * cp;
    rx = cy;
    ry = 0;
    rz = sy;
    ux = ry * fz - rz * fy;
    uy = rz * fx - rx * fz;
    uz = rx * fy - ry * fx;
  }
}

/// Painter's-algorithm triangle rasterizer built on [Canvas.drawVertices].
class Renderer {
  static const int maxTris = 30000;
  static const double near = 0.12;

  final Float32List _sp = Float32List(maxTris * 6);
  final Int32List _col = Int32List(maxTris);
  final Int32List _keys = Int32List(maxTris);
  final Float32List _outPos = Float32List(maxTris * 6);
  final Int32List _outCol = Int32List(maxTris * 3);
  int _n = 0;

  late Camera cam;
  late Lighting light;
  double cx = 0, cy = 0, focal = 1, far = 130;
  double tanX = 1, tanY = 1, kX = 1, kY = 1;
  int _fogR = 0, _fogG = 0, _fogB = 0;
  double _fogStart = 0, _fogInv = 1;
  Size size = Size.zero;

  int get triangleCount => _n;

  void begin(Camera camera, Size viewSize, Lighting lighting, double farDist) {
    cam = camera..update();
    size = viewSize;
    light = lighting;
    far = farDist;
    cx = viewSize.width / 2;
    cy = viewSize.height / 2;
    tanY = math.tan(camera.fovY / 2);
    focal = cy / tanY;
    tanX = cx / focal;
    kX = math.sqrt(1 + tanX * tanX);
    kY = math.sqrt(1 + tanY * tanY);
    _fogR = (lighting.fogColor >> 16) & 255;
    _fogG = (lighting.fogColor >> 8) & 255;
    _fogB = lighting.fogColor & 255;
    _fogStart = lighting.fogStart;
    _fogInv = 1 / (math.min(lighting.fogEnd, farDist) - lighting.fogStart);
    _n = 0;
  }

  /// Conservative sphere-vs-frustum test.
  bool sphereVisible(double x, double y, double z, double r) {
    if (r == double.infinity) return true;
    final dx = x - cam.x, dy = y - cam.y, dz = z - cam.z;
    final vz = dx * cam.fx + dy * cam.fy + dz * cam.fz;
    if (vz < -r || vz - r > far) return false;
    final vx = dx * cam.rx + dy * cam.ry + dz * cam.rz;
    if (vx.abs() > vz * tanX + r * kX) return false;
    final vy = dx * cam.ux + dy * cam.uy + dz * cam.uz;
    if (vy.abs() > vz * tanY + r * kY) return false;
    return true;
  }

  /// Distance from the camera to a sphere's center (XZ + Y).
  double distanceTo(double x, double y, double z) {
    final dx = x - cam.x, dy = y - cam.y, dz = z - cam.z;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  void drawBatch(TriBatch b) {
    if (b.count == 0 || !sphereVisible(b.bx, b.by, b.bz, b.br)) return;
    final pos = b.pos, nrm = b.nrm, flags = b.flags, shaded = b.shaded;
    final camX = cam.x, camY = cam.y, camZ = cam.z;
    final rx = cam.rx, ry = cam.ry, rz = cam.rz;
    final ux = cam.ux, uy = cam.uy, uz = cam.uz;
    final fx = cam.fx, fy = cam.fy, fz = cam.fz;
    final tX = tanX, tY = tanY, farD = far;
    for (var i = 0; i < b.count; i++) {
      final p = i * 9;
      final ax = pos[p] - camX, ay = pos[p + 1] - camY, az = pos[p + 2] - camZ;
      final flag = flags[i];
      if (flag & fDouble == 0) {
        final n = i * 3;
        if (ax * nrm[n] + ay * nrm[n + 1] + az * nrm[n + 2] >= 0) continue;
      }
      final bx = pos[p + 3] - camX, by = pos[p + 4] - camY, bz = pos[p + 5] - camZ;
      final qx = pos[p + 6] - camX, qy = pos[p + 7] - camY, qz = pos[p + 8] - camZ;

      final az2 = ax * fx + ay * fy + az * fz;
      final bz2 = bx * fx + by * fy + bz * fz;
      final cz2 = qx * fx + qy * fy + qz * fz;
      if (az2 < near && bz2 < near && cz2 < near) continue;
      if (az2 > farD && bz2 > farD && cz2 > farD) continue;
      final ax2 = ax * rx + ay * ry + az * rz;
      final bx2 = bx * rx + by * ry + bz * rz;
      final cx2 = qx * rx + qy * ry + qz * rz;
      if (ax2 > az2 * tX && bx2 > bz2 * tX && cx2 > cz2 * tX) continue;
      if (ax2 < -az2 * tX && bx2 < -bz2 * tX && cx2 < -cz2 * tX) continue;
      final ay2 = ax * ux + ay * uy + az * uz;
      final by2 = bx * ux + by * uy + bz * uz;
      final cy2 = qx * ux + qy * uy + qz * uz;
      if (ay2 > az2 * tY && by2 > bz2 * tY && cy2 > cz2 * tY) continue;
      if (ay2 < -az2 * tY && by2 < -bz2 * tY && cy2 < -cz2 * tY) continue;

      final depth = (az2 + bz2 + cz2) * (1 / 3);
      // Fog.
      var c = shaded[i];
      var f = (depth - _fogStart) * _fogInv;
      if (f > 0 && flag & fNoFog == 0) {
        if (f > 1) f = 1;
        final r = (c >> 16) & 255, g = (c >> 8) & 255, bl = c & 255;
        c = (c & 0xFF000000) |
            ((r + (_fogR - r) * f).toInt() << 16) |
            ((g + (_fogG - g) * f).toInt() << 8) |
            (bl + (_fogB - bl) * f).toInt();
      }
      final bias = flag & fGround != 0 ? 3.0 : (flag & fWater != 0 ? 2.5 : 0.0);
      _clipEmit(ax2, ay2, az2, bx2, by2, bz2, cx2, cy2, cz2, c, depth + bias);
    }
  }

  void _clipEmit(double ax, double ay, double az, double bx, double by,
      double bz, double qx, double qy, double qz, int color, double depth) {
    final inA = az >= near, inB = bz >= near, inC = qz >= near;
    final ins = (inA ? 1 : 0) + (inB ? 1 : 0) + (inC ? 1 : 0);
    if (ins == 3) {
      _emit(ax, ay, az, bx, by, bz, qx, qy, qz, color, depth);
      return;
    }
    // Rotate so that the "odd" vertex is first.
    if (ins == 1) {
      if (inB) {
        _clip1(bx, by, bz, qx, qy, qz, ax, ay, az, color, depth);
      } else if (inC) {
        _clip1(qx, qy, qz, ax, ay, az, bx, by, bz, color, depth);
      } else {
        _clip1(ax, ay, az, bx, by, bz, qx, qy, qz, color, depth);
      }
    } else {
      if (!inA) {
        _clip2(ax, ay, az, bx, by, bz, qx, qy, qz, color, depth);
      } else if (!inB) {
        _clip2(bx, by, bz, qx, qy, qz, ax, ay, az, color, depth);
      } else {
        _clip2(qx, qy, qz, ax, ay, az, bx, by, bz, color, depth);
      }
    }
  }

  // A inside; B, C outside.
  void _clip1(double ax, double ay, double az, double bx, double by, double bz,
      double qx, double qy, double qz, int color, double depth) {
    final t1 = (near - az) / (bz - az);
    final t2 = (near - az) / (qz - az);
    _emit(ax, ay, az, ax + (bx - ax) * t1, ay + (by - ay) * t1, near,
        ax + (qx - ax) * t2, ay + (qy - ay) * t2, near, color, depth);
  }

  // A outside; B, C inside.
  void _clip2(double ax, double ay, double az, double bx, double by, double bz,
      double qx, double qy, double qz, int color, double depth) {
    final t1 = (near - bz) / (az - bz);
    final t2 = (near - qz) / (az - qz);
    final b1x = bx + (ax - bx) * t1, b1y = by + (ay - by) * t1;
    final c1x = qx + (ax - qx) * t2, c1y = qy + (ay - qy) * t2;
    _emit(b1x, b1y, near, bx, by, bz, qx, qy, qz, color, depth);
    _emit(b1x, b1y, near, qx, qy, qz, c1x, c1y, near, color, depth);
  }

  void _emit(double ax, double ay, double az, double bx, double by, double bz,
      double qx, double qy, double qz, int color, double depth) {
    if (_n >= maxTris) return;
    final o = _n * 6;
    final sp = _sp;
    sp[o] = cx + ax * focal / az;
    sp[o + 1] = cy - ay * focal / az;
    sp[o + 2] = cx + bx * focal / bz;
    sp[o + 3] = cy - by * focal / bz;
    sp[o + 4] = cx + qx * focal / qz;
    sp[o + 5] = cy - qy * focal / qz;
    _col[_n] = color;
    var dk = (depth * 128).toInt();
    if (dk < 0) dk = 0;
    if (dk > 32767) dk = 32767;
    _keys[_n] = (dk << 16) | _n;
    _n++;
  }

  final Paint _paint = Paint();

  void flush(Canvas canvas) {
    final n = _n;
    if (n == 0) return;
    final keys = Int32List.sublistView(_keys, 0, n)..sort();
    final out = _outPos, oc = _outCol, sp = _sp, col = _col;
    var w = 0;
    for (var k = n - 1; k >= 0; k--) {
      final idx = keys[k] & 0xffff;
      final s = idx * 6, d = w * 6;
      out[d] = sp[s];
      out[d + 1] = sp[s + 1];
      out[d + 2] = sp[s + 2];
      out[d + 3] = sp[s + 3];
      out[d + 4] = sp[s + 4];
      out[d + 5] = sp[s + 5];
      final c = col[idx];
      oc[w * 3] = c;
      oc[w * 3 + 1] = c;
      oc[w * 3 + 2] = c;
      w++;
    }
    final vertices = Vertices.raw(
      VertexMode.triangles,
      Float32List.sublistView(out, 0, n * 6),
      colors: Int32List.sublistView(oc, 0, n * 3),
    );
    canvas.drawVertices(vertices, BlendMode.dst, _paint);
    vertices.dispose();
  }

  /// Projects a world point to the screen; null when behind the camera.
  Offset? project(double x, double y, double z) {
    final dx = x - cam.x, dy = y - cam.y, dz = z - cam.z;
    final vz = dx * cam.fx + dy * cam.fy + dz * cam.fz;
    if (vz < near) return null;
    final vx = dx * cam.rx + dy * cam.ry + dz * cam.rz;
    final vy = dx * cam.ux + dy * cam.uy + dz * cam.uz;
    return Offset(cx + vx * focal / vz, cy - vy * focal / vz);
  }
}

/// Paints the sky gradient, celestial body, stars and distant ridges.
class SkyPainter {
  final List<double> _stars;

  SkyPainter() : _stars = _makeStars();

  static List<double> _makeStars() {
    final r = math.Random(99);
    return [
      for (var i = 0; i < 220; i++) ...[r.nextDouble() * pi2, 0.05 + r.nextDouble() * 1.3, r.nextDouble()]
    ];
  }

  static double _ridge(double a, int layer) {
    final s = layer * 1.7;
    return (0.045 + 0.02 * layer) +
        0.035 * math.sin(a * 3 + s) +
        0.025 * math.sin(a * 7.3 + s * 2) +
        0.012 * math.sin(a * 17.1 + s * 3) +
        0.006 * math.sin(a * 41 + s);
  }

  void paint(Canvas canvas, Size size, Renderer r, Lighting l, double time) {
    final cam = r.cam;
    final horizon = r.cy + math.tan(cam.pitch) * r.focal;
    final rect = Offset.zero & size;
    final skyPaint = Paint()
      ..shader = Gradient.linear(
        Offset(0, horizon - size.height * 1.2),
        Offset(0, horizon),
        [Color(l.skyTop), Color(l.skyHorizon)],
      );
    canvas.drawRect(rect, skyPaint);

    if (l.night) {
      final starPaint = Paint();
      for (var i = 0; i < _stars.length; i += 3) {
        final az = _stars[i], el = _stars[i + 1];
        final dx = math.sin(az) * math.cos(el), dz = -math.cos(az) * math.cos(el);
        final p = r.project(cam.x + dx * 100, cam.y + math.sin(el) * 100, cam.z + dz * 100);
        if (p == null) continue;
        final tw = 0.55 + 0.45 * math.sin(time * 2 + i);
        starPaint.color = Color.fromARGB((200 * tw * _stars[i + 2] + 40).toInt(), 255, 255, 255);
        canvas.drawCircle(p, 0.6 + _stars[i + 2], starPaint);
      }
    }

    // Sun or moon.
    final sp = r.project(cam.x + l.lx * 100, cam.y + l.ly * 100, cam.z + l.lz * 100);
    if (sp != null) {
      final rad = size.height * 0.05 * l.sunDiscSize;
      canvas.drawCircle(sp, rad * 3.5, Paint()
        ..color = Color(l.sunDiscColor).withValues(alpha: 0.12)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rad * 1.5));
      canvas.drawCircle(sp, rad, Paint()..color = Color(l.sunDiscColor));
      if (l.night) {
        canvas.drawCircle(sp + Offset(rad * 0.35, -rad * 0.2), rad * 0.85,
            Paint()..color = Color(l.skyTop).withValues(alpha: 0.25));
      }
    }

    // Distant mountain ridges.
    for (var layer = 2; layer >= 0; layer--) {
      final path = Path()..moveTo(0, size.height);
      for (var x = 0.0; x <= size.width + 8; x += 8) {
        final a = cam.yaw + math.atan((x - r.cx) / r.focal);
        final elev = _ridge(a, layer);
        path.lineTo(x, horizon - math.tan(elev) * r.focal);
      }
      path.lineTo(size.width, size.height);
      path.close();
      final darkness = [0.55, 0.38, 0.22][layer];
      final c = lerpColor(l.fogColor, l.night ? 0xFF05060C : 0xFF1E2A33, darkness);
      canvas.drawPath(path, Paint()..color = Color(c));
    }
    // Ground haze below the horizon.
    canvas.drawRect(Rect.fromLTRB(0, horizon, size.width, size.height),
        Paint()..color = Color(l.fogColor));
  }
}
