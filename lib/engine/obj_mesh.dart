import 'dart:typed_data';

import 'mesh.dart';

/// A material from a Wavefront .mtl file.
///
/// Recognized statements: `newmtl`, `Kd r g b`, `d alpha`, `Tr transparency`,
/// `Ke r g b` (non-zero = emissive), `illum 0` (emissive) and the engine
/// extension `essen_flags [double] [emissive] [nofog]` (ignored by other tools).
class ObjMaterial {
  final String name;
  int color = 0xFFCCCCCC;
  int flags = 0;

  ObjMaterial(this.name);
}

/// Triangle mesh loaded from a Wavefront .obj file, with per-face color and
/// render flags taken from its materials. Positions are in model space.
class ObjMesh {
  final String name;
  final Float32List pos; // 9 floats per triangle
  final Int32List colors;
  final Uint8List flags;

  ObjMesh._(this.name, this.pos, this.colors, this.flags);

  int get triangleCount => colors.length;

  static Map<String, ObjMaterial> parseMtl(String src) {
    final out = <String, ObjMaterial>{};
    ObjMaterial? cur;
    var alpha = 1.0;
    void close() {
      final m = cur;
      if (m == null) return;
      final a = (alpha.clamp(0.0, 1.0) * 255).round();
      m.color = (a << 24) | (m.color & 0xFFFFFF);
    }

    for (final raw in src.split('\n')) {
      final line = raw.trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final p = line.split(RegExp(r'\s+'));
      switch (p[0]) {
        case 'newmtl':
          close();
          cur = out[p[1]] = ObjMaterial(p[1]);
          alpha = 1;
        case 'Kd':
          cur?.color = 0xFF000000 | (_c(p[1]) << 16) | (_c(p[2]) << 8) | _c(p[3]);
        case 'd':
          alpha = double.parse(p[1]);
        case 'Tr':
          alpha = 1 - double.parse(p[1]);
        case 'Ke':
          if (p.skip(1).any((v) => double.parse(v) > 0)) cur?.flags |= fEmissive;
        case 'illum':
          if (p[1] == '0') cur?.flags |= fEmissive;
        case 'essen_flags':
          for (final f in p.skip(1)) {
            cur?.flags |= switch (f) {
              'double' => fDouble,
              'emissive' => fEmissive,
              'nofog' => fNoFog,
              _ => 0,
            };
          }
      }
    }
    close();
    return out;
  }

  static int _c(String v) => (double.parse(v).clamp(0.0, 1.0) * 255).round();

  /// Problems found while parsing (bad face indices, unknown materials).
  /// Faulty faces are skipped instead of failing the whole model.
  final List<String> warnings = [];

  /// Parses an .obj source. Polygons are fan-triangulated; `v/vt/vn` indices
  /// and negative (relative) indices are supported. Statements other than
  /// `v`, `f` and `usemtl` (`vn`, `vt`, `o`, `g`, `s`, `mtllib`) are ignored.
  static ObjMesh parse(String name, String src, Map<String, ObjMaterial> materials) {
    final lines = src.split('\n');
    // Pass 1: all vertices (faces may legally precede later vertices).
    final v = <double>[];
    for (final raw in lines) {
      final line = raw.trim();
      if (!line.startsWith('v ')) continue;
      final p = line.split(RegExp(r'\s+'));
      v
        ..add(double.parse(p[1]))
        ..add(double.parse(p[2]))
        ..add(double.parse(p[3]));
    }
    final vertCount = v.length ~/ 3;
    final pos = <double>[];
    final colors = <int>[];
    final flags = <int>[];
    final warnings = <String>[];
    var badFaces = 0;
    var mat = ObjMaterial('default');
    var seen = 0; // vertices declared so far, for relative indices
    for (var n = 0; n < lines.length; n++) {
      final line = lines[n].trim();
      if (line.isEmpty || line.startsWith('#')) continue;
      final p = line.split(RegExp(r'\s+'));
      switch (p[0]) {
        case 'v':
          seen++;
        case 'usemtl':
          final m = materials[p[1]];
          if (m == null) warnings.add('line ${n + 1}: unknown material "${p[1]}"');
          mat = m ?? ObjMaterial(p[1]);
        case 'f':
          final idx = [
            for (final t in p.skip(1))
              () {
                final i = int.tryParse(t.split('/').first) ?? 0;
                return i < 0 ? seen + i : i - 1;
              }()
          ];
          if (idx.length < 3 || idx.any((i) => i < 0 || i >= vertCount)) {
            if (badFaces++ < 5) {
              warnings.add('line ${n + 1}: face "$line" references a vertex outside 1..$vertCount — skipped');
            }
            continue;
          }
          for (var k = 1; k + 1 < idx.length; k++) {
            for (final i in [idx[0], idx[k], idx[k + 1]]) {
              pos
                ..add(v[i * 3])
                ..add(v[i * 3 + 1])
                ..add(v[i * 3 + 2]);
            }
            colors.add(mat.color);
            flags.add(mat.flags);
          }
      }
    }
    if (badFaces > 5) warnings.add('... ${badFaces - 5} more invalid faces skipped');
    return ObjMesh._(name, Float32List.fromList(pos), Int32List.fromList(colors),
        Uint8List.fromList(flags))
      ..warnings.addAll(warnings);
  }
}
