/// Deterministic 2D value noise with fractal (fBm) layering.
class Noise2D {
  final int seed;

  const Noise2D(this.seed);

  double _hash(int x, int y) {
    var h = (x * 374761393 + y * 668265263 + seed * 1442695041) & 0x7fffffff;
    h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff;
    h = h ^ (h >> 16);
    return (h & 0xffffff) / 0xffffff;
  }

  /// Smooth value noise in 0..1.
  double value(double x, double y) {
    final xi = x.floor(), yi = y.floor();
    final xf = x - xi, yf = y - yi;
    final u = xf * xf * (3 - 2 * xf);
    final v = yf * yf * (3 - 2 * yf);
    final a = _hash(xi, yi), b = _hash(xi + 1, yi);
    final c = _hash(xi, yi + 1), d = _hash(xi + 1, yi + 1);
    final top = a + (b - a) * u;
    final bottom = c + (d - c) * u;
    return top + (bottom - top) * v;
  }

  /// Fractal noise in roughly 0..1.
  double fbm(double x, double y, [int octaves = 4]) {
    var sum = 0.0, amp = 0.5, freq = 1.0, norm = 0.0;
    for (var i = 0; i < octaves; i++) {
      sum += value(x * freq, y * freq) * amp;
      norm += amp;
      amp *= 0.5;
      freq *= 2.03;
    }
    return sum / norm;
  }
}
