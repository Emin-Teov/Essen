import 'dart:io';
import 'dart:ui';

import 'package:essen/engine/mesh.dart';
import 'package:essen/engine/obj_mesh.dart';
import 'package:essen/game/effects.dart';
import 'package:essen/game/fx.dart';
import 'package:essen/game/game.dart';
import 'package:essen/game/world.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(Fx.loadFromDirectory);

  test('every effect model loads with triangles and known materials', () {
    final mtl = ObjMesh.parseMtl(File('assets/effects/effects.mtl').readAsStringSync());
    for (final n in Fx.names) {
      final src = File('assets/effects/$n.obj').readAsStringSync();
      expect(src, contains('mtllib effects.mtl'));
      for (final line in src.split('\n').where((l) => l.startsWith('usemtl '))) {
        expect(mtl.containsKey(line.substring(7).trim()), isTrue, reason: '$n: $line');
      }
      expect(Fx.meshes[n]!.triangleCount, greaterThan(0), reason: n);
    }
    expect(Fx.loaded, isTrue);
  });

  test('effect files load without problems', () {
    expect(Fx.problems, isEmpty,
        reason: 'Run `dart run tool/validate_effects.dart` for details: ${Fx.problems}');
  });

  test('a broken OBJ skips bad faces instead of crashing', () {
    final mesh = ObjMesh.parse('broken', '''
v 0 0 0
v 1 0 0
v 0 1 0
f 1 2 3
f 2 3 9
f 1 x 2
''', {});
    expect(mesh.triangleCount, 1);
    expect(mesh.warnings, isNotEmpty);
  });

  test('MTL flags and opacity are parsed', () {
    final m = ObjMesh.parseMtl('''
newmtl glow
Kd 1 0.5 0
d 0.5
illum 0
essen_flags double nofog
newmtl lit
Kd 0 0 1
illum 2
''');
    expect(m['glow']!.color, 0x80FF8000);
    expect(m['glow']!.flags, fEmissive | fDouble | fNoFog);
    expect(m['lit']!.color, 0xFF0000FF);
    expect(m['lit']!.flags, 0);
  });

  test('OBJ quads and v/vt/vn indices are triangulated', () {
    final mesh = ObjMesh.parse('q', '''
v 0 0 0
v 1 0 0
v 1 1 0
v 0 1 0
f 1/1/1 2/2/1 3/3/1 4/4/1
''', {});
    expect(mesh.triangleCount, 2);
    expect(mesh.pos.sublist(9, 18), [0, 0, 0, 1, 1, 0, 0, 1, 0]);
  });

  test('effects render through the game', () {
    final world = World();
    final g = Game(world, 1);
    while (g.phase == Phase.dialog) {
      g.advanceDialog();
    }
    final p = g.player.pos;
    for (final k in PKind.values) {
      g.particles.add(k, p.x + 2, p.y + 1, p.z - 3, 0, 0, 0, 1, 0.4);
    }
    g.particles.flash(p.x, p.y + 1, p.z - 2, 0xFFFFFFFF, 1);
    g.particles.ring(p.x, p.y, p.z, 0xFFFFD27A, 3);
    g.player.attackT = 0.15;
    g.update(1 / 30);
    final rec = PictureRecorder();
    g.render(Canvas(rec), const Size(844, 390));
    rec.endRecording().dispose();
    expect(g.renderer.triangleCount, greaterThan(300));
  });
}
