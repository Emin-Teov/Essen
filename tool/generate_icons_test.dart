// Generates the game's icon assets as PNG files.
//
//   flutter test tool/generate_icons_test.dart
//
// Writes:
//   assets/icons/*.png      HUD buttons + language flags (loaded at runtime)
//   launcher icons          every existing PNG in the Android mipmaps, iOS/macOS
//                           AppIcon sets and web/icons is re-rendered at its
//                           current pixel size.
import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

typedef IconPainter = void Function(Canvas c, Size s);

const _cream = Color(0xFFF4ECDC);
const _gold = Color(0xFFE2B04A);
const _crimson = Color(0xFFC0392B);
const _ink = Color(0xFF14121A);

void main() {
  testWidgets('generate icons', (tester) async {
    final icons = <String, IconPainter>{
      'slash': _slash,
      'shuriken': _shuriken,
      'jump': _jump,
      'smoke': _smoke,
      'crouch': _crouch,
      'pause': _pause,
    };
    for (final e in icons.entries) {
      await _write(tester, 'assets/icons/${e.key}.png', 192, 192, e.value);
    }
    await _write(tester, 'assets/icons/flag_en.png', 144, 96, _flagEn);
    await _write(tester, 'assets/icons/flag_az.png', 144, 96, _flagAz);
    await _write(tester, 'assets/icons/flag_ja.png', 144, 96, _flagJa);
    await _write(tester, 'assets/icons/app_icon.png', 512, 512, _appIcon);

    // Launcher icons: keep every slot's existing size.
    final dirs = [
      'android/app/src/main/res',
      'ios/Runner/Assets.xcassets/AppIcon.appiconset',
      'macos/Runner/Assets.xcassets/AppIcon.appiconset',
      'web/icons',
    ];
    final targets = <File>[File('web/favicon.png')];
    for (final d in dirs) {
      final dir = Directory(d);
      if (!dir.existsSync()) continue;
      targets.addAll(dir
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.png') && !f.path.contains('launch_')));
    }
    for (final f in targets) {
      if (!f.existsSync()) continue;
      final size = _pngSize(f.readAsBytesSync());
      final maskable = f.path.contains('maskable');
      await _write(tester, f.path, size.$1, size.$2,
          (c, s) => _appIcon(c, s, safeZone: maskable ? 0.8 : 1.0));
    }
  });
}

(int, int) _pngSize(Uint8List b) {
  final d = ByteData.sublistView(b);
  return (d.getUint32(16), d.getUint32(20));
}

Future<void> _write(WidgetTester tester, String path, int w, int h, IconPainter paint) async {
  final rec = ui.PictureRecorder();
  final canvas = Canvas(rec);
  paint(canvas, Size(w.toDouble(), h.toDouble()));
  final pic = rec.endRecording();
  await tester.runAsync(() async {
    final img = await pic.toImage(w, h);
    final data = await img.toByteData(format: ui.ImageByteFormat.png);
    File(path)
      ..createSync(recursive: true)
      ..writeAsBytesSync(data!.buffer.asUint8List());
  });
  // ignore: avoid_print
  print('wrote $path ($w x $h)');
}

/// Draws [shape] with a soft drop shadow and dark outline for legibility on
/// any background.
void _glyph(Canvas c, Size s, Path shape, Paint fill) {
  final k = s.width / 192;
  c.drawPath(shape.shift(Offset(0, 5 * k)), Paint()
    ..color = Colors.black.withValues(alpha: 0.45)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, 5 * k));
  c.drawPath(shape, Paint()
    ..color = _ink
    ..style = PaintingStyle.stroke
    ..strokeWidth = 7 * k
    ..strokeJoin = StrokeJoin.round);
  c.drawPath(shape, fill);
}

Paint _grad(Rect r, List<Color> colors, {bool vertical = true}) => Paint()
  ..shader = LinearGradient(
    begin: vertical ? Alignment.topCenter : Alignment.topLeft,
    end: vertical ? Alignment.bottomCenter : Alignment.bottomRight,
    colors: colors,
  ).createShader(r);

// ---------------------------------------------------------------- HUD icons

void _slash(Canvas c, Size s) {
  final w = s.width, k = w / 192;
  final r = Offset.zero & s;
  // Sweeping arc.
  final arc = Path()
    ..moveTo(w * 0.86, w * 0.18)
    ..quadraticBezierTo(w * 0.80, w * 0.78, w * 0.16, w * 0.86)
    ..quadraticBezierTo(w * 0.70, w * 0.66, w * 0.86, w * 0.18)
    ..close();
  c.drawPath(arc, _grad(r, [Colors.white.withValues(alpha: 0.95), const Color(0x0099D8FF)], vertical: false));
  // Katana on the diagonal.
  c.save();
  c.translate(w / 2, w / 2);
  c.rotate(math.pi / 4);
  final blade = Path()
    ..moveTo(-6 * k, 10 * k)
    ..lineTo(-6 * k, -62 * k)
    ..quadraticBezierTo(-2 * k, -80 * k, 7 * k, -86 * k)
    ..lineTo(6 * k, 10 * k)
    ..close();
  _glyph(c, s, blade, _grad(Rect.fromLTWH(-8 * k, -86 * k, 16 * k, 96 * k),
      [Colors.white, const Color(0xFF9AA6B4)], vertical: false));
  final guard = Path()..addOval(Rect.fromCenter(center: Offset(0, 14 * k), width: 34 * k, height: 12 * k));
  _glyph(c, s, guard, Paint()..color = _gold);
  final handle = Path()
    ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(-7 * k, 20 * k, 14 * k, 56 * k), Radius.circular(5 * k)));
  _glyph(c, s, handle, Paint()..color = const Color(0xFF2A1A1A));
  final wrap = Paint()..color = _crimson;
  for (var y = 24.0; y < 72; y += 11) {
    c.drawPath(
        Path()
          ..moveTo(0, y * k)
          ..lineTo(6 * k, (y + 5) * k)
          ..lineTo(0, (y + 10) * k)
          ..lineTo(-6 * k, (y + 5) * k)
          ..close(),
        wrap);
  }
  c.restore();
}

void _shuriken(Canvas c, Size s) {
  final w = s.width, k = w / 192;
  final ctr = Offset(w / 2, w / 2);
  final star = Path();
  for (var i = 0; i < 8; i++) {
    final a = i * math.pi / 4 - math.pi / 2;
    final r = i.isEven ? 80 * k : 22 * k;
    final p = ctr + Offset(math.cos(a), math.sin(a)) * r;
    i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
  }
  star.close();
  _glyph(c, s, star, Paint()
    ..shader = RadialGradient(colors: const [Colors.white, Color(0xFFB8C2CE), Color(0xFF5E6874)])
        .createShader(Rect.fromCircle(center: ctr - Offset(14 * k, 14 * k), radius: 90 * k)));
  // Bevel lines.
  final bevel = Paint()
    ..color = Colors.white.withValues(alpha: 0.55)
    ..strokeWidth = 2 * k;
  for (var i = 0; i < 4; i++) {
    final a = i * math.pi / 2 - math.pi / 2;
    c.drawLine(ctr, ctr + Offset(math.cos(a), math.sin(a)) * 74 * k, bevel);
  }
  c.drawCircle(ctr, 13 * k, Paint()..color = _ink);
  c.drawCircle(ctr, 13 * k, Paint()
    ..color = _gold
    ..style = PaintingStyle.stroke
    ..strokeWidth = 3 * k);
}

void _jump(Canvas c, Size s) {
  final w = s.width, k = w / 192;
  final r = Offset.zero & s;
  for (var i = 0; i < 2; i++) {
    final y = (78 + i * 46) * k;
    final chevron = Path()
      ..moveTo(36 * k, y + 22 * k)
      ..lineTo(96 * k, y - 34 * k)
      ..lineTo(156 * k, y + 22 * k)
      ..lineTo(132 * k, y + 22 * k)
      ..lineTo(96 * k, y - 10 * k)
      ..lineTo(60 * k, y + 22 * k)
      ..close();
    _glyph(c, s, chevron, _grad(r, i == 0 ? [Colors.white, _gold] : [_gold, const Color(0xFFB07A20)]));
  }
  // Ground ripple.
  c.drawOval(Rect.fromCenter(center: Offset(96 * k, 168 * k), width: 110 * k, height: 18 * k), Paint()
    ..color = _cream.withValues(alpha: 0.7)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 4 * k);
}

void _smoke(Canvas c, Size s) {
  final w = s.width, k = w / 192;
  final cloud = Path();
  for (final (x, y, r) in [(104.0, 70.0, 34.0), (136.0, 88.0, 30.0), (82.0, 96.0, 28.0), (120.0, 112.0, 30.0), (150.0, 58.0, 20.0)]) {
    cloud.addOval(Rect.fromCircle(center: Offset(x * k, y * k), radius: r * k));
  }
  _glyph(c, s, cloud, Paint()
    ..shader = RadialGradient(colors: const [Colors.white, Color(0xFFB4B8C0)])
        .createShader(Rect.fromCircle(center: Offset(100 * k, 60 * k), radius: 90 * k)));
  final bomb = Path()..addOval(Rect.fromCircle(center: Offset(62 * k, 136 * k), radius: 34 * k));
  _glyph(c, s, bomb, Paint()
    ..shader = RadialGradient(colors: const [Color(0xFF5A5F6E), Color(0xFF15161C)])
        .createShader(Rect.fromCircle(center: Offset(50 * k, 124 * k), radius: 44 * k)));
  c.drawCircle(Offset(50 * k, 124 * k), 8 * k, Paint()..color = Colors.white.withValues(alpha: 0.35));
  c.drawLine(Offset(78 * k, 110 * k), Offset(92 * k, 96 * k), Paint()
    ..color = const Color(0xFFC8A060)
    ..strokeWidth = 5 * k
    ..strokeCap = StrokeCap.round);
  c.drawCircle(Offset(94 * k, 94 * k), 9 * k, Paint()
    ..color = const Color(0xFFFFC040)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, 4 * k));
  c.drawCircle(Offset(94 * k, 94 * k), 4 * k, Paint()..color = Colors.white);
}

void _crouch(Canvas c, Size s) {
  final w = s.width, k = w / 192;
  // Hooded shinobi head — the stealth stance.
  final hood = Path()
    ..moveTo(96 * k, 22 * k)
    ..cubicTo(150 * k, 22 * k, 168 * k, 70 * k, 162 * k, 112 * k)
    ..cubicTo(156 * k, 150 * k, 130 * k, 170 * k, 96 * k, 170 * k)
    ..cubicTo(62 * k, 170 * k, 36 * k, 150 * k, 30 * k, 112 * k)
    ..cubicTo(24 * k, 70 * k, 42 * k, 22 * k, 96 * k, 22 * k)
    ..close();
  _glyph(c, s, hood, _grad(Offset.zero & s, const [Color(0xFF3A4458), Color(0xFF12151E)]));
  final band = Path()
    ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(46 * k, 78 * k, 100 * k, 30 * k), Radius.circular(14 * k)));
  c.drawPath(band, Paint()..color = const Color(0xFFE6BC98));
  for (final x in [74.0, 118.0]) {
    final eye = Path()
      ..moveTo((x - 14) * k, 94 * k)
      ..quadraticBezierTo(x * k, 82 * k, (x + 14) * k, 94 * k)
      ..quadraticBezierTo(x * k, 100 * k, (x - 14) * k, 94 * k)
      ..close();
    c.drawPath(eye, Paint()..color = _ink);
    c.drawCircle(Offset(x * k, 92 * k), 3 * k, Paint()..color = const Color(0xFF9EC8E8));
  }
  final scarf = Path()
    ..moveTo(40 * k, 146 * k)
    ..quadraticBezierTo(96 * k, 176 * k, 152 * k, 146 * k)
    ..lineTo(160 * k, 166 * k)
    ..quadraticBezierTo(96 * k, 196 * k, 32 * k, 166 * k)
    ..close();
  _glyph(c, s, scarf, Paint()..color = _crimson);
}

void _pause(Canvas c, Size s) {
  final w = s.width, k = w / 192;
  for (final x in [52.0, 112.0]) {
    final bar = Path()
      ..addRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x * k, 40 * k, 28 * k, 112 * k), Radius.circular(9 * k)));
    _glyph(c, s, bar, _grad(Offset.zero & s, [Colors.white, _cream]));
  }
}

// ---------------------------------------------------------------- flags

void _rounded(Canvas c, Size s, void Function() body) {
  final r = RRect.fromRectAndRadius(Offset.zero & s, Radius.circular(s.height * 0.12));
  c.save();
  c.clipRRect(r);
  body();
  // Glossy highlight.
  c.drawRect(Rect.fromLTWH(0, 0, s.width, s.height / 2),
      Paint()..color = Colors.white.withValues(alpha: 0.08));
  c.restore();
  c.drawRRect(r, Paint()
    ..color = Colors.black.withValues(alpha: 0.35)
    ..style = PaintingStyle.stroke
    ..strokeWidth = 2);
}

void _flagEn(Canvas c, Size s) {
  _rounded(c, s, () {
    final w = s.width, h = s.height;
    c.drawRect(Offset.zero & s, Paint()..color = const Color(0xFF012169));
    final white = Paint()
      ..color = Colors.white
      ..strokeWidth = h * 0.2;
    final red = Paint()
      ..color = const Color(0xFFC8102E)
      ..strokeWidth = h * 0.07;
    c.drawLine(Offset.zero, Offset(w, h), white);
    c.drawLine(Offset(w, 0), Offset(0, h), white);
    c.drawLine(Offset.zero, Offset(w, h), red);
    c.drawLine(Offset(w, 0), Offset(0, h), red);
    c.drawRect(Rect.fromCenter(center: Offset(w / 2, h / 2), width: w, height: h * 0.33), Paint()..color = Colors.white);
    c.drawRect(Rect.fromCenter(center: Offset(w / 2, h / 2), width: h * 0.33, height: h), Paint()..color = Colors.white);
    c.drawRect(Rect.fromCenter(center: Offset(w / 2, h / 2), width: w, height: h * 0.2), Paint()..color = const Color(0xFFC8102E));
    c.drawRect(Rect.fromCenter(center: Offset(w / 2, h / 2), width: h * 0.2, height: h), Paint()..color = const Color(0xFFC8102E));
  });
}

void _flagAz(Canvas c, Size s) {
  _rounded(c, s, () {
    final w = s.width, h = s.height;
    c.drawRect(Rect.fromLTWH(0, 0, w, h / 3), Paint()..color = const Color(0xFF00B5E2));
    c.drawRect(Rect.fromLTWH(0, h / 3, w, h / 3), Paint()..color = const Color(0xFFEF3340));
    c.drawRect(Rect.fromLTWH(0, h * 2 / 3, w, h / 3), Paint()..color = const Color(0xFF509E2F));
    // Crescent.
    final ctr = Offset(w * 0.47, h / 2);
    c.drawCircle(ctr, h * 0.15, Paint()..color = Colors.white);
    c.drawCircle(ctr + Offset(h * 0.04, 0), h * 0.125, Paint()..color = const Color(0xFFEF3340));
    // Eight-pointed star.
    final sc = Offset(w * 0.58, h / 2);
    final star = Path();
    for (var i = 0; i < 16; i++) {
      final a = i * math.pi / 8;
      final r = i.isEven ? h * 0.075 : h * 0.033;
      final p = sc + Offset(math.cos(a), math.sin(a)) * r;
      i == 0 ? star.moveTo(p.dx, p.dy) : star.lineTo(p.dx, p.dy);
    }
    c.drawPath(star..close(), Paint()..color = Colors.white);
  });
}

void _flagJa(Canvas c, Size s) {
  _rounded(c, s, () {
    c.drawRect(Offset.zero & s, Paint()..color = Colors.white);
    c.drawCircle(Offset(s.width / 2, s.height / 2), s.height * 0.3, Paint()..color = const Color(0xFFBC002D));
  });
}

// ---------------------------------------------------------------- app icon

void _appIcon(Canvas c, Size s, {double safeZone = 1.0}) {
  final w = s.width;
  final r = Offset.zero & s;
  c.drawRect(r, Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Color(0xFF241536), Color(0xFF7A2236), Color(0xFFE47A40)],
      stops: [0, 0.6, 1],
    ).createShader(r));
  c.save();
  // Keep artwork inside the maskable safe zone when requested.
  c.translate(w * (1 - safeZone) / 2, w * (1 - safeZone) / 2);
  c.scale(safeZone);
  // Sun.
  final sun = Offset(w * 0.64, w * 0.4);
  c.drawCircle(sun, w * 0.34, Paint()
    ..color = const Color(0x55FF6A3A)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.05));
  c.drawCircle(sun, w * 0.24, Paint()..color = const Color(0xFFE8452C));
  // Mountains.
  final m1 = Path()
    ..moveTo(0, w * 0.78)
    ..lineTo(w * 0.22, w * 0.56)
    ..lineTo(w * 0.36, w * 0.66)
    ..lineTo(w * 0.58, w * 0.48)
    ..lineTo(w * 0.82, w * 0.66)
    ..lineTo(w, w * 0.58)
    ..lineTo(w, w)
    ..lineTo(0, w)
    ..close();
  c.drawPath(m1, Paint()..color = const Color(0xFF3A1E36));
  final m2 = Path()
    ..moveTo(0, w * 0.86)
    ..lineTo(w * 0.3, w * 0.72)
    ..lineTo(w * 0.6, w * 0.84)
    ..lineTo(w, w * 0.74)
    ..lineTo(w, w)
    ..lineTo(0, w)
    ..close();
  c.drawPath(m2, Paint()..color = const Color(0xFF1C0F1E));
  // Katana behind the head.
  c.save();
  c.translate(w * 0.5, w * 0.6);
  c.rotate(-0.75);
  c.drawRect(Rect.fromLTWH(-w * 0.012, -w * 0.5, w * 0.024, w * 0.62), Paint()
    ..shader = const LinearGradient(colors: [Colors.white, Color(0xFF8A96A6)])
        .createShader(Rect.fromLTWH(-w * 0.012, -w * 0.5, w * 0.024, w * 0.62)));
  c.drawOval(Rect.fromCenter(center: Offset(0, w * 0.13), width: w * 0.09, height: w * 0.03),
      Paint()..color = _gold);
  c.drawRect(Rect.fromLTWH(-w * 0.016, w * 0.14, w * 0.032, w * 0.16), Paint()..color = const Color(0xFF2A1A1A));
  c.restore();
  // Hooded head.
  final hc = Offset(w * 0.46, w * 0.64);
  final hood = Path()
    ..moveTo(hc.dx, hc.dy - w * 0.26)
    ..cubicTo(hc.dx + w * 0.2, hc.dy - w * 0.26, hc.dx + w * 0.25, hc.dy - w * 0.04, hc.dx + w * 0.22, hc.dy + w * 0.1)
    ..cubicTo(hc.dx + w * 0.18, hc.dy + w * 0.26, hc.dx + w * 0.08, hc.dy + w * 0.34, hc.dx, hc.dy + w * 0.34)
    ..cubicTo(hc.dx - w * 0.08, hc.dy + w * 0.34, hc.dx - w * 0.18, hc.dy + w * 0.26, hc.dx - w * 0.22, hc.dy + w * 0.1)
    ..cubicTo(hc.dx - w * 0.25, hc.dy - w * 0.04, hc.dx - w * 0.2, hc.dy - w * 0.26, hc.dx, hc.dy - w * 0.26)
    ..close();
  c.drawPath(hood.shift(Offset(0, w * 0.015)), Paint()
    ..color = Colors.black.withValues(alpha: 0.5)
    ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.02));
  c.drawPath(hood, Paint()
    ..shader = const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF3A4458), Color(0xFF0E1018)],
    ).createShader(hood.getBounds()));
  final band = RRect.fromRectAndRadius(
      Rect.fromCenter(center: hc + Offset(0, -w * 0.03), width: w * 0.34, height: w * 0.085),
      Radius.circular(w * 0.04));
  c.drawRRect(band, Paint()..color = const Color(0xFFE6BC98));
  for (final dx in [-0.075, 0.075]) {
    final e = hc + Offset(w * dx, -w * 0.03);
    final eye = Path()
      ..moveTo(e.dx - w * 0.045, e.dy + w * 0.005)
      ..quadraticBezierTo(e.dx, e.dy - w * 0.035, e.dx + w * 0.045, e.dy + w * 0.005)
      ..quadraticBezierTo(e.dx, e.dy + w * 0.02, e.dx - w * 0.045, e.dy + w * 0.005)
      ..close();
    c.drawPath(eye, Paint()..color = _ink);
    c.drawCircle(e + Offset(0, -w * 0.004), w * 0.01, Paint()..color = const Color(0xFFA8D4F0));
  }
  // Red scarf streaming in the wind.
  final scarf = Path()
    ..moveTo(hc.dx - w * 0.2, hc.dy + w * 0.2)
    ..quadraticBezierTo(hc.dx, hc.dy + w * 0.28, hc.dx + w * 0.2, hc.dy + w * 0.2)
    ..quadraticBezierTo(hc.dx + w * 0.36, hc.dy + w * 0.12, hc.dx + w * 0.5, hc.dy + w * 0.2)
    ..quadraticBezierTo(hc.dx + w * 0.36, hc.dy + w * 0.22, hc.dx + w * 0.22, hc.dy + w * 0.3)
    ..quadraticBezierTo(hc.dx, hc.dy + w * 0.38, hc.dx - w * 0.2, hc.dy + w * 0.3)
    ..close();
  c.drawPath(scarf, Paint()..color = _crimson);
  c.restore();
}
