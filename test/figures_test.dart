import 'dart:math' as math;

import 'package:essen/engine/mesh.dart';
import 'package:essen/game/figures.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const styles = {
    'essen': FigureStyle.essen,
    'samurai': FigureStyle.samurai,
    'archer': FigureStyle.archer,
    'rival': FigureStyle.rival,
    'boss': FigureStyle.boss,
    'soun': FigureStyle.soun,
    'tsuru': FigureStyle.tsuru,
    'hotaru': FigureStyle.hotaru,
  };

  int tris(FigureStyle st, int lod, FigureAnim an) {
    final batch = TriBatch(1024);
    drawFigure(MeshBuilder(batch, math.Random(1)), 0, 0, 0, 0, st, an, lod: lod);
    return batch.count;
  }

  test('each level of detail is cheaper than the one before, within budget', () {
    for (final e in styles.entries) {
      final an = FigureAnim();
      final high = tris(e.value, Lod.high, an);
      final mid = tris(e.value, Lod.mid, an);
      final low = tris(e.value, Lod.low, an);
      expect(high, greaterThan(mid), reason: e.key);
      expect(mid, greaterThan(low), reason: e.key);
      expect(high, lessThan(1200), reason: '${e.key} high-detail budget');
      expect(low, lessThan(100), reason: '${e.key} low-detail budget');
    }
  });

  test('every pose builds at every level of detail', () {
    final poses = <FigureAnim>[
      FigureAnim()..walkAmount = 1.2,
      FigureAnim()..crouch = 1,
      FigureAnim()..air = 1,
      FigureAnim()..pose = Pose.kneel,
      FigureAnim()..pose = Pose.lying,
      FigureAnim()..fall = 0.5,
      FigureAnim()
        ..bowDraw = 1
        ..armRaise = 2.8
        ..twist = 1,
    ];
    for (final st in styles.values) {
      for (final an in poses) {
        for (final lod in [Lod.high, Lod.mid, Lod.low]) {
          expect(tris(st, lod, an), greaterThan(30));
        }
      }
    }
  });

  test('distance picks the level of detail', () {
    expect(lodForDistance(5), Lod.high);
    expect(lodForDistance(20), Lod.mid);
    expect(lodForDistance(60), Lod.low);
  });
}
