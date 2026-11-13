import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Painted ukiyo-e style landscape used behind menus and story pages.
class Backdrop extends StatefulWidget {
  final List<Color> sky;
  final Color sun;
  final bool petals;
  final Widget? child;

  const Backdrop({
    super.key,
    this.sky = const [Color(0xFF1B1430), Color(0xFF6B2238), Color(0xFFE0743E)],
    this.sun = const Color(0xFFE8452C),
    this.petals = true,
    this.child,
  });

  @override
  State<Backdrop> createState() => _BackdropState();
}

class _BackdropState extends State<Backdrop> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(seconds: 60))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        RepaintBoundary(
          child: CustomPaint(
            painter: _BackdropPainter(widget.sky, widget.sun, widget.petals, _c),
          ),
        ),
        if (widget.child != null) widget.child!,
      ],
    );
  }
}

class _BackdropPainter extends CustomPainter {
  final List<Color> sky;
  final Color sun;
  final bool petals;
  final Animation<double> anim;

  _BackdropPainter(this.sky, this.sun, this.petals, this.anim) : super(repaint: anim);

  double _ridge(double x, double seed, double amp) =>
      math.sin(x * 2.1 + seed) * amp * 0.5 +
      math.sin(x * 5.3 + seed * 2) * amp * 0.3 +
      math.sin(x * 13.7 + seed * 3) * amp * 0.12;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;
    final t = anim.value * 60;
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: sky,
        ).createShader(Offset.zero & size),
    );
    // Sun with halo.
    final sc = Offset(w * 0.68, h * 0.42);
    canvas.drawCircle(sc, h * 0.3, Paint()
      ..color = sun.withValues(alpha: 0.18)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 40));
    canvas.drawCircle(sc, h * 0.17, Paint()..color = sun);
    // Mist bands.
    final mist = Paint()..color = Colors.white.withValues(alpha: 0.05);
    for (var i = 0; i < 3; i++) {
      final y = h * (0.5 + i * 0.07);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(-w * 0.2 + math.sin(t * 0.05 + i) * 40, y, w * 1.4, h * 0.035),
              const Radius.circular(20)),
          mist);
    }
    // Mountain layers.
    final layers = [
      (0.55, 0.20, 1.0, const Color(0xFF3A2440)),
      (0.65, 0.14, 2.5, const Color(0xFF26182E)),
      (0.76, 0.10, 4.0, const Color(0xFF160E1C)),
    ];
    for (final (base, amp, seed, color) in layers) {
      final path = Path()..moveTo(0, h);
      for (var x = 0.0; x <= w; x += 6) {
        path.lineTo(x, h * (base - _ridge(x / w * 3, seed, amp)));
      }
      path
        ..lineTo(w, h)
        ..close();
      canvas.drawPath(path, Paint()..color = color);
    }
    _pagoda(canvas, Offset(w * 0.18, h * 0.66), h * 0.36);
    _cliffNinja(canvas, Offset(w * 0.86, h * 0.80), h);
    if (petals) {
      final r = math.Random(4);
      final pp = Paint()..color = const Color(0xFFF6C3D3).withValues(alpha: 0.85);
      for (var i = 0; i < 46; i++) {
        final speed = 0.02 + r.nextDouble() * 0.03;
        final px = (r.nextDouble() * w + t * speed * w * 0.6 + math.sin(t * 0.6 + i) * 20) % w;
        final py = (r.nextDouble() * h + t * speed * h) % h;
        canvas.save();
        canvas.translate(px, py);
        canvas.rotate(t * 0.8 + i);
        canvas.drawOval(const Rect.fromLTWH(-4, -2, 8, 4), pp);
        canvas.restore();
      }
    }
  }

  void _pagoda(Canvas c, Offset base, double height) {
    final p = Paint()..color = const Color(0xFF0E0910);
    var y = base.dy;
    var w = height * 0.26;
    for (var i = 0; i < 5; i++) {
      final th = height * 0.13;
      c.drawRect(Rect.fromCenter(center: Offset(base.dx, y - th * 0.4), width: w * 0.55, height: th * 0.8), p);
      final roof = Path()
        ..moveTo(base.dx - w * 0.75, y - th * 0.75)
        ..quadraticBezierTo(base.dx - w * 0.3, y - th * 0.85, base.dx - w * 0.2, y - th * 1.05)
        ..lineTo(base.dx + w * 0.2, y - th * 1.05)
        ..quadraticBezierTo(base.dx + w * 0.3, y - th * 0.85, base.dx + w * 0.75, y - th * 0.75)
        ..close();
      c.drawPath(roof, p);
      y -= th;
      w *= 0.85;
    }
    c.drawRect(Rect.fromLTWH(base.dx - 1.5, y - height * 0.14, 3, height * 0.14), p);
  }

  void _cliffNinja(Canvas c, Offset at, double h) {
    final p = Paint()..color = const Color(0xFF07050A);
    final cliff = Path()
      ..moveTo(at.dx - h * 0.5, h)
      ..lineTo(at.dx - h * 0.18, at.dy + h * 0.02)
      ..lineTo(at.dx + h * 0.05, at.dy)
      ..lineTo(at.dx + h * 0.4, at.dy + h * 0.06)
      ..lineTo(at.dx + h * 0.6, h)
      ..close();
    c.drawPath(cliff, p);
    // Crouching shinobi silhouette with a sword across the back.
    final s = h * 0.0016;
    final o = Offset(at.dx - h * 0.02, at.dy);
    c.drawCircle(o + Offset(0, -46 * s), 8 * s, p);
    final body = Path()
      ..moveTo(o.dx - 10 * s, o.dy - 38 * s)
      ..lineTo(o.dx + 12 * s, o.dy - 36 * s)
      ..lineTo(o.dx + 16 * s, o.dy - 14 * s)
      ..lineTo(o.dx + 22 * s, o.dy)
      ..lineTo(o.dx - 20 * s, o.dy)
      ..lineTo(o.dx - 12 * s, o.dy - 16 * s)
      ..close();
    c.drawPath(body, p);
    c.drawLine(o + Offset(-22 * s, -58 * s), o + Offset(18 * s, -22 * s),
        Paint()
          ..color = p.color
          ..strokeWidth = 3 * s);
    // Scarf trailing in the wind.
    final scarf = Path()
      ..moveTo(o.dx - 4 * s, o.dy - 40 * s)
      ..quadraticBezierTo(o.dx - 30 * s, o.dy - 50 * s, o.dx - 60 * s, o.dy - 38 * s)
      ..quadraticBezierTo(o.dx - 32 * s, o.dy - 42 * s, o.dx - 4 * s, o.dy - 36 * s)
      ..close();
    c.drawPath(scarf, Paint()..color = const Color(0xFF9E1B1B));
  }

  @override
  bool shouldRepaint(covariant _BackdropPainter old) => old.sky != sky || old.sun != sun;
}
