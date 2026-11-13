// Validates the 3D effect models in assets/effects (OBJ + MTL).
//
//   dart run tool/validate_effects.dart          # report problems
//   dart run tool/validate_effects.dart --fix    # also remove faces with invalid indices
//
// Checks: every expected model exists, face indices are in range, materials
// exist in effects.mtl, and the estimated per-frame cost (triangles x typical
// live copies) stays reasonable for phones.
import 'dart:io';

import 'package:essen/engine/obj_mesh.dart';

/// Typical number of copies alive in a busy frame.
const instances = <String, int>{
  'flame': 120, 'smoke_puff': 40, 'dust_puff': 20, 'spark': 30, 'ember': 50, 'streak': 30,
  'blood_drop': 30, 'petal': 90, 'impact_flash': 6, 'shockwave_ring': 4, 'slash_arc': 1,
  'shuriken': 6, 'arrow': 6, 'alert_mark': 6, 'suspicion_gem': 6, 'blind_stars': 4,
  'bar_quad': 12, 'objective_beacon': 1, 'objective_gem': 2, 'pickup_ring': 4,
  'pickup_scroll': 2, 'pickup_supply': 2, 'pickup_onigiri': 2,
};

/// Models whose spawn rate the game scales down automatically when they are
/// heavier than this reference triangle count (Game._emitScale).
const adaptive = <String, int>{'flame': 16, 'smoke_puff': 24, 'petal': 8, 'ember': 8};

/// Per-effect frame budget in triangles.
const frameBudget = 2500;

void main(List<String> args) {
  final fix = args.contains('--fix');
  const dir = 'assets/effects';
  final mtlFile = File('$dir/effects.mtl');
  if (!mtlFile.existsSync()) {
    stderr.writeln('Missing $dir/effects.mtl');
    exitCode = 1;
    return;
  }
  final mtl = ObjMesh.parseMtl(mtlFile.readAsStringSync());
  var errors = 0, warnings = 0;

  for (final entry in instances.entries) {
    final name = entry.key;
    final file = File('$dir/$name.obj');
    if (!file.existsSync()) {
      stdout.writeln('✗ $name.obj — missing');
      errors++;
      continue;
    }
    var src = file.readAsStringSync();
    final issues = <String>[];

    if (!src.contains('mtllib effects.mtl')) issues.add('warning: no "mtllib effects.mtl" line');
    final vertCount = RegExp(r'^v\s', multiLine: true).allMatches(src).length;

    // Invalid faces.
    final lines = src.split('\n');
    final keep = <String>[];
    var bad = 0;
    var seen = 0;
    for (final line in lines) {
      final t = line.trim();
      if (t.startsWith('v ')) seen++;
      if (t.startsWith('f ')) {
        final idx = t.split(RegExp(r'\s+')).skip(1).map((s) {
          final i = int.tryParse(s.split('/').first) ?? 0;
          return i < 0 ? seen + i + 1 : i;
        }).toList();
        if (idx.length < 3 || idx.any((i) => i < 1 || i > vertCount)) {
          bad++;
          continue;
        }
      }
      keep.add(line);
    }
    if (bad > 0) {
      if (fix) {
        src = keep.join('\n');
        file.writeAsStringSync(src);
        issues.add('fixed: removed $bad face(s) referencing vertices outside 1..$vertCount');
      } else {
        issues.add('ERROR: $bad face(s) reference vertices outside 1..$vertCount (run with --fix to remove them)');
        errors++;
      }
    }

    final mesh = ObjMesh.parse(name, src, mtl);
    for (final w in mesh.warnings.where((w) => w.contains('unknown material'))) {
      issues.add('ERROR: $w (add it to effects.mtl)');
      errors++;
    }
    final tris = mesh.triangleCount;
    if (tris == 0) {
      issues.add('ERROR: no triangles');
      errors++;
    } else {
      // Adaptive effects spawn fewer copies when heavy (down to 30%).
      final ref = adaptive[name];
      final scale = ref == null ? 1.0 : (ref / (tris > ref ? tris : ref)).clamp(0.3, 1.0);
      final cost = (tris * entry.value * scale).round();
      if (ref != null && scale < 1) {
        issues.add('note: spawn rate auto-scaled to ${(scale * 100).round()}% because the model has '
            '$tris triangles (reference $ref)');
      }
      if (cost > frameBudget) {
        issues.add('warning: ~$cost triangles per busy frame ($tris tris x ~${(entry.value * scale).round()} copies) '
            'exceeds $frameBudget — simplify the model to keep phones smooth');
        warnings++;
      }
    }
    final mark = issues.any((i) => i.startsWith('ERROR')) ? '✗' : (issues.isEmpty ? '✓' : '!');
    stdout.writeln('$mark $name.obj — $vertCount verts, $tris tris');
    for (final i in issues) {
      stdout.writeln('    $i');
    }
  }
  stdout.writeln('\n$errors error(s), $warnings warning(s).');
  if (errors > 0) exitCode = 1;
}
