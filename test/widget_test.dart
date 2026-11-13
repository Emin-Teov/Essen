import 'dart:ui';

import 'package:essen/engine/math3d.dart';
import 'package:essen/game/enemy.dart';
import 'package:essen/game/fx.dart';
import 'package:essen/game/game.dart';
import 'package:essen/game/world.dart';
import 'package:essen/story/story.dart';
import 'package:essen/ui/title_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late World world;

  setUpAll(() {
    final sw = Stopwatch()..start();
    Fx.loadFromDirectory();
    world = World();
    // ignore: avoid_print
    print('World built in ${sw.elapsedMilliseconds} ms');
  });

  test('world has every named point used by the story', () {
    final needed = <String>{};
    for (final ch in Story.chapters) {
      needed.add(ch.startPoint);
      for (final n in ch.npcs) {
        needed.add(n.point);
      }
      for (final o in ch.objectives) {
        if (o.point != null) needed.add(o.point!);
        for (final s in o.spawns) {
          if (s.point != null) needed.add(s.point!);
        }
        for (final p in o.pickups) {
          if (p.point != null) needed.add(p.point!);
        }
      }
    }
    for (final n in needed) {
      expect(world.points.containsKey(n), isTrue, reason: 'missing point $n');
    }
    final tris = world.chunks.fold<int>(0, (s, c) => s + c.terrain.count + c.props.count + c.flora.count);
    // ignore: avoid_print
    print('Static triangles: $tris');
    expect(tris, greaterThan(50000));
  });

  test('codex ids referenced by the story exist', () {
    for (final ch in Story.chapters) {
      for (final o in ch.objectives) {
        for (final id in o.unlock) {
          expect(Story.codexById(id), isNotNull, reason: id);
        }
        for (final p in o.pickups) {
          if (p.codex != null) expect(Story.codexById(p.codex!), isNotNull, reason: p.codex);
        }
      }
    }
  });

  test('every chapter simulates and renders', () {
    for (var i = 0; i < Story.chapters.length; i++) {
      final g = Game(world, i);
      var maxTris = 0;
      for (var f = 0; f < 120; f++) {
        while (g.phase == Phase.dialog) {
          final line = g.currentLine!;
          line.choices != null ? g.choose(0) : g.advanceDialog();
        }
        g.input
          ..moveY = 1
          ..lookDX = 3;
        if (f % 20 == 0) g.input.attack = true;
        if (f % 37 == 0) g.input.shuriken = true;
        if (f == 50) g.input.jump = true;
        g.update(1 / 30);
        final rec = PictureRecorder();
        g.render(Canvas(rec), const Size(844, 390));
        rec.endRecording().dispose();
        if (g.renderer.triangleCount > maxTris) maxTris = g.renderer.triangleCount;
      }
      // ignore: avoid_print
      print('Chapter ${i + 1}: peak $maxTris triangles/frame, ${g.enemies.length} enemies');
      expect(maxTris, greaterThan(200));
    }
  });

  test('player stands on the terrain and collides with houses', () {
    final g = Game(world, 0);
    final p = g.player;
    for (var f = 0; f < 60; f++) {
      g.update(1 / 30);
    }
    expect((p.pos.y - world.terrain.heightAt(p.pos.x, p.pos.z)).abs(), lessThan(0.6));
  });

  test('chapter one can be completed by clearing the looters', () {
    final g = Game(world, 0);
    void flush() {
      while (g.phase == Phase.dialog) {
        g.advanceDialog();
      }
    }

    flush();
    final kasumi = world.points['kasumi']!;
    g.player.pos.setFrom(kasumi);
    g.update(1 / 30);
    flush();
    expect(g.objIndex, 1);
    for (final e in g.enemies.where((e) => e.group == 'looters')) {
      e.takeHit(g, 1, shadowStrike: true);
    }
    g.update(1 / 30);
    flush();
    expect(g.objIndex, 2);
    g.player.pos.setFrom(world.points['soun']!);
    g.update(1 / 30);
    flush();
    expect(g.phase, Phase.chapterComplete);
    expect(g.codex.contains('soun'), isTrue);
  });

  test('third-person camera stays behind Essen and out of the ground', () {
    final g = Game(world, 2);
    while (g.phase == Phase.dialog) {
      g.advanceDialog();
    }
    final p = g.player;
    for (var f = 0; f < 240; f++) {
      g.input
        ..moveY = 1
        ..moveX = f < 120 ? 0.5 : -0.5
        ..lookDX = 6
        ..lookDY = f.isEven ? 4 : -3;
      g.update(1 / 30);
      final c = g.camera;
      expect(c.y, greaterThan(world.terrain.heightAt(c.x, c.z)), reason: 'frame $f');
      final dx = c.x - p.pos.x, dz = c.z - p.pos.z;
      expect(dx * dx + dz * dz, lessThan(6.0 * 6.0));
    }
    // Moving forward turns the body toward the camera direction.
    for (var f = 0; f < 30; f++) {
      while (g.phase == Phase.dialog) {
        g.advanceDialog();
      }
      g.input
        ..moveX = 0
        ..moveY = 1;
      g.update(1 / 30);
    }
    expect(g.phase, isNot(Phase.dialog));
    expect(wrapAngle(p.facing - p.yaw).abs(), lessThan(0.2));
  });

  test('rival yields instead of dying', () {
    final g = Game(world, 2);
    final rival = Enemy(EnemyKind.rival, 'rival', 0, 0, 0, 0, 1);
    for (var i = 0; i < 40; i++) {
      rival.takeHit(g, 50, shadowStrike: false, fromYaw: rival.yaw);
    }
    expect(rival.state, AiState.yielded);
    expect(rival.alive, isTrue);
  });

  testWidgets('title screen renders', (tester) async {
    tester.view.physicalSize = const Size(1688, 780);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(const MaterialApp(home: TitleScreen()));
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.text('Essen'), findsOneWidget);
    expect(find.text('NEW JOURNEY'), findsOneWidget);
  });
}
