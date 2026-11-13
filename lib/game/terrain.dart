import 'dart:math' as math;
import 'dart:typed_data';

import '../engine/math3d.dart';
import '../engine/noise.dart';

/// Named places of the Kurogane valley.
class Places {
  static const kasumiX = -200.0, kasumiZ = 170.0; // ruined Hidden Mist village
  static const campX = -60.0, campZ = 30.0; // bamboo war camp
  static const hanamuraX = 60.0, hanamuraZ = 150.0; // farming village
  static const shrineX = 170.0, shrineZ = 40.0; // sakura shrine
  static const castleX = 120.0, castleZ = -190.0; // Iron Dragon Keep

  static double riverX(double z) =>
      20 + 35 * math.sin(z / 80) + 10 * math.sin(z / 31);

  /// Roads as polylines of (x, z) pairs.
  static final List<List<double>> roads = [
    [kasumiX, kasumiZ, -150, 120, -110, 70, campX, campZ],
    [campX, campZ, -10, 90, 30, 130, hanamuraX, hanamuraZ],
    [hanamuraX, hanamuraZ, 115, 120, 150, 75, shrineX, shrineZ],
    [shrineX, shrineZ, 160, -40, 135, -110, castleX, castleZ + 40, castleX, castleZ],
    [campX, campZ, -30, -50, riverX(-100), -100, 70, -125, castleX, castleZ + 40],
  ];
}

/// Heightmap terrain on a regular grid.
class Terrain {
  static const double half = 320;
  static const double cell = 4;
  static const int cells = 160;
  static const int verts = cells + 1;
  static const double waterLevel = -2.0;

  final Noise2D noise = const Noise2D(1337);
  final Noise2D noise2 = const Noise2D(4242);
  final Float32List heights = Float32List(verts * verts);
  final Float32List roadDist = Float32List(verts * verts);

  late final List<List<double>> _flatZones; // x, z, radius, height

  Terrain() {
    _flatZones = <List<double>>[
      [Places.kasumiX, Places.kasumiZ, 44],
      [Places.campX, Places.campZ, 34],
      [Places.hanamuraX, Places.hanamuraZ, 40],
      [Places.shrineX, Places.shrineZ, 28],
      [Places.castleX, Places.castleZ, 56],
    ].map((z) => <double>[z[0], z[1], z[2], math.max(_base(z[0], z[1]), waterLevel + 2.5)]).toList();
    for (var j = 0; j < verts; j++) {
      for (var i = 0; i < verts; i++) {
        final x = -half + i * cell, z = -half + j * cell;
        heights[j * verts + i] = _final(x, z);
        roadDist[j * verts + i] = _roadDistance(x, z);
      }
    }
  }

  double _hill(double x, double z, double cx, double cz, double r, double h) {
    final dx = x - cx, dz = z - cz;
    return h * math.exp(-(dx * dx + dz * dz) / (r * r));
  }

  double _base(double x, double z) {
    var h = (noise.fbm(x / 150 + 10, z / 150 + 10) - 0.45) * 26;
    h += (noise2.fbm(x / 38, z / 38, 3) - 0.5) * 5;
    final d = math.max(x.abs(), z.abs());
    final edge = smoothstep(220, 305, d);
    h += edge * (40 + 50 * noise2.fbm(x / 70, z / 70));
    h += _hill(x, z, Places.castleX, Places.castleZ, 60, 15);
    h += _hill(x, z, Places.shrineX, Places.shrineZ, 45, 11);
    h += _hill(x, z, Places.kasumiX, Places.kasumiZ, 85, 6);
    return h;
  }

  double _final(double x, double z) {
    var h = _base(x, z);
    for (final f in _flatZones) {
      final dx = x - f[0], dz = z - f[1];
      final d = math.sqrt(dx * dx + dz * dz);
      final t = smoothstep(f[2], f[2] * 0.6, d);
      h = lerpD(h, f[3], t);
    }
    // River carving.
    final rd = (x - Places.riverX(z)).abs();
    final carve = smoothstep(17, 7, rd);
    h = lerpD(h, waterLevel - 1.7, carve);
    return h;
  }

  double _roadDistance(double x, double z) {
    var best = 1e9;
    for (final road in Places.roads) {
      for (var k = 0; k + 3 < road.length; k += 2) {
        final ax = road[k], az = road[k + 1], bx = road[k + 2], bz = road[k + 3];
        final abx = bx - ax, abz = bz - az;
        final t = clampD(((x - ax) * abx + (z - az) * abz) / (abx * abx + abz * abz), 0, 1);
        final px = ax + abx * t - x, pz = az + abz * t - z;
        final d = px * px + pz * pz;
        if (d < best) best = d;
      }
    }
    return math.sqrt(best);
  }

  double h(int i, int j) => heights[j * verts + i];

  /// Height at a world position, matching the rendered triangles exactly.
  double heightAt(double x, double z) {
    final gx = clampD((x + half) / cell, 0, cells - 0.0001);
    final gz = clampD((z + half) / cell, 0, cells - 0.0001);
    final i = gx.floor(), j = gz.floor();
    final u = gx - i, v = gz - j;
    final h00 = h(i, j), h10 = h(i + 1, j), h01 = h(i, j + 1), h11 = h(i + 1, j + 1);
    if (u >= v) {
      return h00 + (h10 - h00) * u + (h11 - h10) * v;
    }
    return h00 + (h11 - h01) * u + (h01 - h00) * v;
  }

  double roadDistanceAt(double x, double z) {
    final i = ((x + half) / cell).round().clamp(0, cells);
    final j = ((z + half) / cell).round().clamp(0, cells);
    return roadDist[j * verts + i];
  }

  bool inBounds(double x, double z) => x.abs() < half - 8 && z.abs() < half - 8;
}
