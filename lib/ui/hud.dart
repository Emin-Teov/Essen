import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../engine/math3d.dart';
import '../game/enemy.dart';
import '../game/game.dart';
import '../game/player.dart';
import '../game/terrain.dart';
import '../l10n/l10n.dart';
import '../story/story.dart';
import 'game_icons.dart';
import 'theme.dart';

enum Btn { attack, shuriken, jump, smoke, crouch, pause }

/// Touch-control layout and live state shared by the screen and the painter.
class Controls {
  Size size = Size.zero;
  int? joyPointer;
  Offset joyOrigin = Offset.zero, joyPos = Offset.zero;
  int? lookPointer;
  Offset lookLast = Offset.zero;
  final Map<int, Btn> pressed = {};

  double get s => (size.height / 400).clamp(0.8, 1.5);
  double get joyRadius => 58 * s;

  Map<Btn, (Offset, double)> get buttons {
    final w = size.width, h = size.height, k = s;
    return {
      Btn.attack: (Offset(w - 88 * k, h - 88 * k), 48 * k),
      Btn.jump: (Offset(w - 192 * k, h - 52 * k), 32 * k),
      Btn.shuriken: (Offset(w - 180 * k, h - 140 * k), 30 * k),
      Btn.smoke: (Offset(w - 98 * k, h - 198 * k), 28 * k),
      Btn.crouch: (Offset(w - 272 * k, h - 56 * k), 29 * k),
      Btn.pause: (Offset(30 * k, 30 * k), 20 * k),
    };
  }

  Btn? hit(Offset p) {
    for (final e in buttons.entries) {
      if ((p - e.value.$1).distance <= e.value.$2 * 1.15) return e.key;
    }
    return null;
  }

  bool isDown(Btn b) => pressed.values.contains(b);
}

/// Screen-space HUD. World-space feedback (alert markers, objective beacon,
/// slash trails, impacts) is rendered in 3D by [Game.render].
class HudPainter extends CustomPainter {
  final Game game;
  final Controls controls;

  HudPainter(this.game, this.controls, Listenable repaint) : super(repaint: repaint);

  static final Map<String, TextPainter> _cache = {};

  void _text(Canvas c, String s, Offset at,
      {double size = 13, Color color = Hue.paper, FontWeight weight = FontWeight.w600,
      double align = 0, double letter = 0, double? maxWidth, bool shadow = true}) {
    final key = '$s|$size|${color.toARGB32()}|$weight|$letter|$maxWidth';
    var tp = _cache[key];
    if (tp == null) {
      tp = TextPainter(
        text: TextSpan(
          text: s,
          style: TextStyle(
            fontSize: size,
            color: color,
            fontWeight: weight,
            letterSpacing: letter,
            shadows: shadow ? const [Shadow(color: Colors.black87, blurRadius: 4)] : null,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: maxWidth ?? double.infinity);
      if (_cache.length > 400) _cache.clear();
      _cache[key] = tp;
    }
    tp.paint(c, at - Offset(tp.width * align, 0));
  }

  @override
  void paint(Canvas canvas, Size size) {
    controls.size = size;
    final p = game.player;
    _vignette(canvas, size, p);
    if (game.phase != Phase.playing) return;
    _crosshair(canvas, size);
    _status(canvas, size, p);
    _compass(canvas, size, p);
    _minimap(canvas, size, p);
    _bossBar(canvas, size);
    _toasts(canvas, size);
    _controls(canvas, size, p);
  }

  // ------------------------------------------------------------------ overlays

  void _vignette(Canvas c, Size size, Player p) {
    final rect = Offset.zero & size;
    var red = p.hurtFlash * 0.55;
    if (p.hp < 35 && !p.dead) red = math.max(red, (0.25 + math.sin(game.time * 5) * 0.1) * (1 - p.hp / 35));
    if (p.dead) red = 0.6;
    if (red > 0.01) {
      c.drawRect(rect, Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, const Color(0xFF8A0000).withValues(alpha: red.clamp(0, 1))],
          stops: const [0.55, 1],
        ).createShader(rect));
    }
    if (p.hiddenT > 0 || p.crouch) {
      final a = p.hiddenT > 0 ? 0.45 : 0.22;
      c.drawRect(rect, Paint()
        ..shader = RadialGradient(
          colors: [Colors.transparent, const Color(0xFF0A0F1E).withValues(alpha: a)],
          stops: const [0.6, 1],
        ).createShader(rect));
    }
  }

  void _crosshair(Canvas c, Size size) {
    final ctr = size.center(Offset.zero);
    final paint = Paint()
      ..color = Colors.white60
      ..strokeWidth = 1.6;
    for (final d in [const Offset(1, 0), const Offset(-1, 0), const Offset(0, 1), const Offset(0, -1)]) {
      c.drawLine(ctr + d * 4, ctr + d * 9, paint);
    }
  }

  // ------------------------------------------------------------------ status

  void _status(Canvas c, Size size, Player p) {
    final k = controls.s;
    final x0 = 60 * k, y0 = 14 * k;
    _text(c, upper(L10n.speaker(Spk.essen)), Offset(x0, y0), size: 11 * k, color: Hue.gold, letter: 3);
    final bw = 190 * k, bh = 9 * k;
    final by = y0 + 17 * k;
    c.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(x0, by, bw, bh), const Radius.circular(2)),
        Paint()..color = Colors.black54);
    c.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(x0, by, bw * (p.hp / Player.maxHp).clamp(0, 1), bh),
            const Radius.circular(2)),
        Paint()
          ..shader = const LinearGradient(colors: [Color(0xFF8E1C1C), Color(0xFFE04A3A)])
              .createShader(Rect.fromLTWH(x0, by, bw, bh)));
    final obj = game.objectiveText;
    if (obj.isNotEmpty) {
      final oy = by + bh + 10 * k;
      c.drawRect(Rect.fromLTWH(x0, oy, 2.5 * k, 30 * k), Paint()..color = Hue.gold);
      _text(c, tr('hud.chapter', {'n': game.chapter.number, 'title': upper(game.chapter.title)}),
          Offset(x0 + 8 * k, oy), size: 9 * k, color: Hue.dim, letter: 1.5);
      _text(c, obj, Offset(x0 + 8 * k, oy + 13 * k), size: 12.5 * k, maxWidth: size.width * 0.32);
    }
    // Detection eye.
    final det = game.detection;
    final eyeC = Offset(size.width / 2, 58 * k);
    final col = p.hiddenT > 0
        ? const Color(0xFF7FA8FF)
        : det >= 1
            ? const Color(0xFFFF3B30)
            : Color.lerp(Colors.white38, const Color(0xFFFFC83D), det.clamp(0, 1))!;
    final eye = Path()
      ..moveTo(eyeC.dx - 14 * k, eyeC.dy)
      ..quadraticBezierTo(eyeC.dx, eyeC.dy - 11 * k, eyeC.dx + 14 * k, eyeC.dy)
      ..quadraticBezierTo(eyeC.dx, eyeC.dy + 11 * k, eyeC.dx - 14 * k, eyeC.dy)
      ..close();
    c.drawPath(eye, Paint()
      ..color = col
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2);
    c.drawCircle(eyeC, 4 * k, Paint()..color = col);
    if (p.hiddenT > 0) {
      _text(c, tr('hud.hidden'), eyeC + Offset(0, 9 * k), size: 9 * k, color: col, align: 0.5, letter: 2);
    } else if (det >= 1) {
      _text(c, tr('hud.detected'), eyeC + Offset(0, 9 * k), size: 9 * k, color: col, align: 0.5, letter: 2);
    }
  }

  void _compass(Canvas c, Size size, Player p) {
    final k = controls.s;
    final cx = size.width / 2, y = 14 * k, half = 150 * k;
    final rect = Rect.fromLTRB(cx - half, y, cx + half, y + 22 * k);
    c.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(3)), Paint()..color = Colors.black38);
    const span = 2.2; // radians visible across the strip
    final labels = tr('compass').split(',');
    for (var i = 0; i < 8; i++) {
      final a = i * math.pi / 4;
      final d = wrapAngle(a - p.yaw);
      if (d.abs() > span / 2) continue;
      final x = cx + d / (span / 2) * half;
      _text(c, labels[i], Offset(x, y + 4 * k), size: (i.isEven ? 12 : 9) * k,
          color: i == 0 ? Hue.crimson : Hue.paper, align: 0.5);
    }
    final t = game.objectiveTarget;
    if (t != null) {
      final a = yawTowards(p.pos.x, p.pos.z, t.x, t.z);
      final d = wrapAngle(a - p.yaw).clamp(-span / 2, span / 2);
      final x = cx + d / (span / 2) * half;
      final tri = Path()
        ..moveTo(x, y + 22 * k)
        ..lineTo(x - 6 * k, y + 30 * k)
        ..lineTo(x + 6 * k, y + 30 * k)
        ..close();
      c.drawPath(tri, Paint()..color = Hue.gold);
      _text(c, '${t.distXZ(p.pos).round()} m', Offset(x, y + 31 * k), size: 9 * k, color: Hue.gold, align: 0.5);
    }
  }

  static final List<Offset> _river = [
    for (var z = -320.0; z <= 320; z += 8) Offset(Places.riverX(z), z),
  ];

  void _minimap(Canvas c, Size size, Player p) {
    final k = controls.s;
    final r = 58 * k;
    final ctr = Offset(size.width - r - 14 * k, r + 14 * k);
    const range = 90.0;
    final sc = r / range;
    final cy = math.cos(p.yaw), sy = math.sin(p.yaw);
    Offset map(double x, double z) {
      final dx = x - p.pos.x, dz = z - p.pos.z;
      final rx = dx * cy + dz * sy; // along camera right
      final fy = dx * sy - dz * cy; // along camera forward
      return ctr + Offset(rx * sc, -fy * sc);
    }

    c.save();
    c.clipPath(Path()..addOval(Rect.fromCircle(center: ctr, radius: r)));
    c.drawCircle(ctr, r, Paint()..color = const Color(0xCC14181C));
    final river = Path();
    var first = true;
    for (final o in _river) {
      final m = map(o.dx, o.dy);
      if (first) {
        river.moveTo(m.dx, m.dy);
        first = false;
      } else {
        river.lineTo(m.dx, m.dy);
      }
    }
    c.drawPath(river, Paint()
      ..color = const Color(0xFF2F5F80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 14 * sc * 1.5);
    final road = Paint()
      ..color = const Color(0xFF6E5A3E)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final rd in Places.roads) {
      final path = Path();
      for (var i = 0; i < rd.length; i += 2) {
        final m = map(rd[i], rd[i + 1]);
        i == 0 ? path.moveTo(m.dx, m.dy) : path.lineTo(m.dx, m.dy);
      }
      c.drawPath(path, road);
    }
    for (final pk in game.pickups) {
      if (pk.taken) continue;
      c.drawCircle(map(pk.pos.x, pk.pos.z), 2.5 * k, Paint()..color = Color(pk.glow));
    }
    for (final n in game.npcs) {
      if (n.visible) c.drawCircle(map(n.pos.x, n.pos.z), 3 * k, Paint()..color = const Color(0xFF6FE08A));
    }
    for (final e in game.enemies) {
      if (!e.hostile) continue;
      final alert = e.state == AiState.alert;
      c.drawCircle(map(e.pos.x, e.pos.z), (alert ? 3.6 : 2.8) * k,
          Paint()..color = alert ? const Color(0xFFFF3B30) : const Color(0xFFB04A40));
    }
    c.restore();
    c.drawCircle(ctr, r, Paint()
      ..color = Colors.white24
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5);
    final t = game.objectiveTarget;
    if (t != null) {
      var m = map(t.x, t.z) - ctr;
      if (m.distance > r - 5) m = m / m.distance * (r - 5);
      c.drawCircle(ctr + m, 4.5 * k, Paint()..color = Hue.gold);
      c.drawCircle(ctr + m, 4.5 * k, Paint()
        ..color = Colors.black
        ..style = PaintingStyle.stroke);
    }
    var n = map(p.pos.x, p.pos.z - 1000) - ctr;
    n = n / n.distance * (r - 1);
    _text(c, tr('compass').split(',').first, ctr + n - Offset(0, 6 * k),
        size: 10 * k, color: Hue.crimson, align: 0.5, weight: FontWeight.w900);
    // Player arrow shows the body facing relative to the camera.
    c.save();
    c.translate(ctr.dx, ctr.dy);
    c.rotate(wrapAngle(p.facing - p.yaw));
    final arrow = Path()
      ..moveTo(0, -7 * k)
      ..lineTo(5 * k, 5 * k)
      ..lineTo(0, 2 * k)
      ..lineTo(-5 * k, 5 * k)
      ..close();
    c.drawPath(arrow, Paint()..color = Colors.white);
    c.restore();
  }

  void _bossBar(Canvas c, Size size) {
    Enemy? boss;
    for (final e in game.enemies) {
      if (e.isBossLike && e.hostile && !e.passive && e.pos.distXZ(game.player.pos) < 45) boss = e;
    }
    if (boss == null) return;
    final k = controls.s;
    final w = size.width * 0.36, x = (size.width - w) / 2, y = 92 * k;
    final name = boss.kind == EnemyKind.boss ? tr('hud.boss.masakage') : tr('hud.boss.rendo');
    _text(c, name, Offset(size.width / 2, y - 15 * k), size: 10.5 * k, color: Hue.paper, align: 0.5, letter: 2);
    c.drawRect(Rect.fromLTWH(x, y, w, 6 * k), Paint()..color = Colors.black54);
    c.drawRect(Rect.fromLTWH(x, y, w * (boss.hp / boss.stats.hp).clamp(0, 1), 6 * k),
        Paint()..color = boss.kind == EnemyKind.boss ? const Color(0xFFB01E1E) : const Color(0xFF3A6AB8));
  }

  void _toasts(Canvas c, Size size) {
    var y = size.height * 0.3;
    for (final t in game.toasts) {
      final a = (t.t < 0.2 ? t.t / 0.2 : (t.t > 2.0 ? (2.6 - t.t) / 0.6 : 1.0)).clamp(0.0, 1.0);
      _text(c, t.text, Offset(size.width / 2, y),
          size: t.big ? 22 : 14,
          color: (t.big ? Hue.crimson : Hue.paper).withValues(alpha: a),
          weight: t.big ? FontWeight.w900 : FontWeight.w600,
          letter: t.big ? 6 : 1.5,
          align: 0.5);
      y += t.big ? 30 : 22;
    }
  }

  // ------------------------------------------------------------------ controls

  void _controls(Canvas c, Size size, Player p) {
    final ctl = controls;
    final k = ctl.s;
    if (ctl.joyPointer != null) {
      c.drawCircle(ctl.joyOrigin, ctl.joyRadius, Paint()..color = Colors.white.withValues(alpha: 0.10));
      c.drawCircle(ctl.joyOrigin, ctl.joyRadius, Paint()
        ..color = Colors.white30
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
      var d = ctl.joyPos - ctl.joyOrigin;
      if (d.distance > ctl.joyRadius) d = d / d.distance * ctl.joyRadius;
      c.drawCircle(ctl.joyOrigin + d, 24 * k, Paint()..color = Colors.white.withValues(alpha: 0.45));
    } else {
      final o = Offset(110 * k, size.height - 105 * k);
      c.drawCircle(o, ctl.joyRadius, Paint()
        ..color = Colors.white12
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5);
      c.drawCircle(o, 20 * k, Paint()..color = Colors.white10);
    }
    for (final e in ctl.buttons.entries) {
      final (o, r) = e.value;
      final down = ctl.isDown(e.key) || (e.key == Btn.crouch && p.crouch);
      c.drawCircle(o, r, Paint()
        ..shader = RadialGradient(colors: down
                ? [Hue.crimson.withValues(alpha: 0.85), const Color(0xAA5A1010)]
                : [Colors.black.withValues(alpha: 0.25), Colors.black.withValues(alpha: 0.5)])
            .createShader(Rect.fromCircle(center: o, radius: r)));
      c.drawCircle(o, r, Paint()
        ..color = down ? Hue.gold : Colors.white38
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6);
      final (icon, label) = switch (e.key) {
        Btn.attack => ('slash', tr('btn.slash')),
        Btn.jump => ('jump', tr('btn.jump')),
        Btn.shuriken => ('shuriken', '${p.shuriken}'),
        Btn.smoke => ('smoke', '${p.smoke}'),
        Btn.crouch => ('crouch', tr('btn.crouch')),
        Btn.pause => ('pause', ''),
      };
      final img = GameIcons.images[icon];
      final isz = r * (label.isEmpty ? 1.25 : 1.12);
      final ic = o - Offset(0, label.isEmpty ? 0 : r * 0.14);
      if (img != null) {
        c.drawImageRect(img, Rect.fromLTWH(0, 0, img.width.toDouble(), img.height.toDouble()),
            Rect.fromCenter(center: ic, width: isz, height: isz), Paint()..filterQuality = FilterQuality.medium);
      } else {
        _text(c, icon[0].toUpperCase(), ic - Offset(0, r * 0.35), size: r * 0.6, align: 0.5);
      }
      if (label.isNotEmpty) {
        _text(c, label, o + Offset(0, r * 0.42), size: 8.5 * k, color: Colors.white, align: 0.5, letter: 1);
      }
    }
  }

  @override
  bool shouldRepaint(covariant HudPainter old) => true;
}
