import 'dart:math' as math;

/// Small mutable 3D vector used by gameplay code.
class Vec3 {
  double x, y, z;

  Vec3(this.x, this.y, this.z);
  Vec3.zero() : x = 0, y = 0, z = 0;

  Vec3 copy() => Vec3(x, y, z);

  void set(double nx, double ny, double nz) {
    x = nx;
    y = ny;
    z = nz;
  }

  void setFrom(Vec3 o) {
    x = o.x;
    y = o.y;
    z = o.z;
  }

  Vec3 operator +(Vec3 o) => Vec3(x + o.x, y + o.y, z + o.z);
  Vec3 operator -(Vec3 o) => Vec3(x - o.x, y - o.y, z - o.z);
  Vec3 operator *(double s) => Vec3(x * s, y * s, z * s);

  double get length => math.sqrt(x * x + y * y + z * z);

  double distTo(Vec3 o) {
    final dx = x - o.x, dy = y - o.y, dz = z - o.z;
    return math.sqrt(dx * dx + dy * dy + dz * dz);
  }

  double distXZ(Vec3 o) {
    final dx = x - o.x, dz = z - o.z;
    return math.sqrt(dx * dx + dz * dz);
  }
}

const double pi2 = math.pi * 2;

double clampD(double v, double lo, double hi) => v < lo ? lo : (v > hi ? hi : v);

double lerpD(double a, double b, double t) => a + (b - a) * t;

double smoothstep(double e0, double e1, double x) {
  final t = clampD((x - e0) / (e1 - e0), 0, 1);
  return t * t * (3 - 2 * t);
}

/// Wraps an angle into the range -pi..pi.
double wrapAngle(double a) {
  while (a > math.pi) {
    a -= pi2;
  }
  while (a < -math.pi) {
    a += pi2;
  }
  return a;
}

/// Yaw that faces from (fromX, fromZ) toward (toX, toZ).
/// Forward for a yaw is (sin(yaw), -cos(yaw)) on the XZ plane.
double yawTowards(double fromX, double fromZ, double toX, double toZ) =>
    math.atan2(toX - fromX, -(toZ - fromZ));

int lerpColor(int a, int b, double t) {
  final ar = (a >> 16) & 255, ag = (a >> 8) & 255, ab = a & 255;
  final br = (b >> 16) & 255, bg = (b >> 8) & 255, bb = b & 255;
  final aa = (a >> 24) & 255;
  final r = (ar + (br - ar) * t).round();
  final g = (ag + (bg - ag) * t).round();
  final bl = (ab + (bb - ab) * t).round();
  return (aa << 24) | (r << 16) | (g << 8) | bl;
}

int scaleColor(int c, double s) {
  final a = (c >> 24) & 255;
  final r = (((c >> 16) & 255) * s).round().clamp(0, 255);
  final g = (((c >> 8) & 255) * s).round().clamp(0, 255);
  final b = ((c & 255) * s).round().clamp(0, 255);
  return (a << 24) | (r << 16) | (g << 8) | b;
}
