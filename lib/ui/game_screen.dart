import 'dart:async';
import 'dart:isolate';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';

import '../game/fx.dart';
import '../game/game.dart';
import '../game/world.dart';
import '../l10n/l10n.dart';
import '../story/story.dart';
import 'codex_screen.dart';
import 'flow.dart';
import 'game_icons.dart';
import 'hud.dart';
import 'progress.dart';
import 'theme.dart';

/// Builds the static world once and shares it between chapters.
class WorldCache {
  static Future<World>? _pending;

  static Future<World> get() => _pending ??= _build();

  static Future<World> _build() async {
    if (!kIsWeb) {
      try {
        return await Isolate.run(World.new);
      } catch (_) {
        // Fall back to building on the UI isolate.
      }
    }
    await Future<void>.delayed(const Duration(milliseconds: 30));
    return World();
  }
}

class GameScreen extends StatefulWidget {
  final int chapterIndex;

  const GameScreen({super.key, required this.chapterIndex});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> with SingleTickerProviderStateMixin {
  Game? _game;
  late final Ticker _ticker = createTicker(_tick);
  final ValueNotifier<int> _frame = ValueNotifier(0);
  final Controls _controls = Controls();
  final FocusNode _focus = FocusNode();
  Duration _last = Duration.zero;
  bool _paused = false;
  bool _completed = false;
  double _typed = 0; // typewriter progress for the current dialog line
  DialogLine? _typedLine;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    // Only the world is required; icons and effect models are cosmetic and
    // must never block the game (each reports its own problems).
    final cosmetics = Future.wait([GameIcons.load(), Fx.load()]).catchError((Object e) {
      debugPrint('Optional assets failed to load: $e');
      return <void>[];
    });
    final world = await WorldCache.get();
    await cosmetics;
    if (!mounted) return;
    final g = Game(world, widget.chapterIndex,
        codex: Set.of(Progress.instance.codex), onUnlock: Progress.instance.addCodex);
    g.addListener(_onGameChanged);
    setState(() => _game = g);
    _ticker.start();
  }

  @override
  void dispose() {
    _ticker.dispose();
    _game?.removeListener(_onGameChanged);
    _frame.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _onGameChanged() {
    final g = _game!;
    if (g.phase == Phase.chapterComplete && !_completed) {
      _completed = true;
      _ticker.stop();
      Future<void>.delayed(const Duration(milliseconds: 400), () {
        if (mounted) Journey.chapterComplete(context, g);
      });
    }
    if (mounted) setState(() {});
  }

  void _tick(Duration elapsed) {
    final g = _game;
    if (g == null) return;
    var dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt > 0.05) dt = 0.05;
    if (dt <= 0) return;
    if (_paused) return;
    _applyKeyboard(g.input);
    if (_controls.isDown(Btn.attack)) g.input.attack = true;
    g.update(dt);
    final line = g.currentLine;
    if (line != _typedLine) {
      _typedLine = line;
      _typed = 0;
      if (mounted) setState(() {});
    }
    if (line != null && _typed < line.text.length) {
      _typed += dt * 55;
      if (mounted) setState(() {});
    }
    _frame.value++;
  }

  // ------------------------------------------------------------------ input

  void _applyKeyboard(GameInput inp) {
    final keys = HardwareKeyboard.instance.logicalKeysPressed;
    if (_controls.joyPointer == null) {
      var mx = 0.0, my = 0.0;
      if (keys.contains(LogicalKeyboardKey.keyW)) my += 1;
      if (keys.contains(LogicalKeyboardKey.keyS)) my -= 1;
      if (keys.contains(LogicalKeyboardKey.keyD)) mx += 1;
      if (keys.contains(LogicalKeyboardKey.keyA)) mx -= 1;
      final run = keys.contains(LogicalKeyboardKey.shiftLeft) || keys.contains(LogicalKeyboardKey.shiftRight);
      final scale = run ? 1.0 : 0.75;
      inp.moveX = mx * scale;
      inp.moveY = my * scale;
    }
    if (keys.contains(LogicalKeyboardKey.arrowLeft)) inp.lookDX -= 7;
    if (keys.contains(LogicalKeyboardKey.arrowRight)) inp.lookDX += 7;
    if (keys.contains(LogicalKeyboardKey.arrowUp)) inp.lookDY -= 5;
    if (keys.contains(LogicalKeyboardKey.arrowDown)) inp.lookDY += 5;
  }

  KeyEventResult _onKey(FocusNode node, KeyEvent e) {
    final g = _game;
    if (g == null || e is! KeyDownEvent) return KeyEventResult.ignored;
    final k = e.logicalKey;
    if (g.phase == Phase.dialog) {
      if (k == LogicalKeyboardKey.space || k == LogicalKeyboardKey.enter) _advanceDialog();
      return KeyEventResult.handled;
    }
    if (k == LogicalKeyboardKey.escape) {
      setState(() => _paused = !_paused);
    } else if (k == LogicalKeyboardKey.space) {
      g.input.jump = true;
    } else if (k == LogicalKeyboardKey.keyJ || k == LogicalKeyboardKey.keyF) {
      g.input.attack = true;
    } else if (k == LogicalKeyboardKey.keyK || k == LogicalKeyboardKey.keyE) {
      g.input.shuriken = true;
    } else if (k == LogicalKeyboardKey.keyC) {
      g.input.crouch = true;
    } else if (k == LogicalKeyboardKey.keyQ) {
      g.input.smoke = true;
    } else {
      return KeyEventResult.ignored;
    }
    return KeyEventResult.handled;
  }

  void _pointerDown(PointerDownEvent e) {
    final g = _game;
    if (g == null || g.phase != Phase.playing || _paused) return;
    final c = _controls;
    final btn = c.hit(e.localPosition);
    if (btn != null) {
      c.pressed[e.pointer] = btn;
      switch (btn) {
        case Btn.attack:
          g.input.attack = true;
        case Btn.shuriken:
          g.input.shuriken = true;
        case Btn.jump:
          g.input.jump = true;
        case Btn.smoke:
          g.input.smoke = true;
        case Btn.crouch:
          g.input.crouch = true;
        case Btn.pause:
          setState(() => _paused = true);
      }
      return;
    }
    if (e.localPosition.dx < c.size.width * 0.42 && c.joyPointer == null) {
      c.joyPointer = e.pointer;
      c.joyOrigin = e.localPosition;
      c.joyPos = e.localPosition;
    } else if (c.lookPointer == null) {
      c.lookPointer = e.pointer;
      c.lookLast = e.localPosition;
    }
  }

  void _pointerMove(PointerMoveEvent e) {
    final g = _game;
    if (g == null) return;
    final c = _controls;
    if (e.pointer == c.joyPointer) {
      c.joyPos = e.localPosition;
      final d = (c.joyPos - c.joyOrigin) / c.joyRadius;
      final len = d.distance;
      final v = len > 1 ? d / len : d;
      g.input.moveX = v.dx;
      g.input.moveY = -v.dy;
    } else if (e.pointer == c.lookPointer) {
      final d = e.localPosition - c.lookLast;
      c.lookLast = e.localPosition;
      g.input.lookDX += d.dx * 1.15;
      g.input.lookDY += d.dy * 1.15;
    }
  }

  void _pointerUp(PointerEvent e) {
    final c = _controls;
    c.pressed.remove(e.pointer);
    if (e.pointer == c.joyPointer) {
      c.joyPointer = null;
      _game?.input.moveX = 0;
      _game?.input.moveY = 0;
    }
    if (e.pointer == c.lookPointer) c.lookPointer = null;
  }

  void _advanceDialog() {
    final g = _game!;
    final line = g.currentLine;
    if (line == null) return;
    if (_typed < line.text.length) {
      setState(() => _typed = line.text.length.toDouble());
      return;
    }
    g.advanceDialog();
  }

  // ------------------------------------------------------------------ build

  @override
  Widget build(BuildContext context) {
    final g = _game;
    if (g == null) return _loading();
    return Scaffold(
      backgroundColor: Colors.black,
      body: Focus(
        focusNode: _focus,
        autofocus: true,
        onKeyEvent: _onKey,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Listener(
              behavior: HitTestBehavior.opaque,
              onPointerDown: _pointerDown,
              onPointerMove: _pointerMove,
              onPointerUp: _pointerUp,
              onPointerCancel: _pointerUp,
              child: RepaintBoundary(
                child: CustomPaint(
                  painter: _WorldPainter(g, _frame),
                  foregroundPainter: HudPainter(g, _controls, _frame),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            if (g.phase == Phase.dialog && g.currentLine != null) _dialog(g),
            if (g.phase == Phase.dead) _deathOverlay(g),
            if (_paused) _pauseOverlay(g),
          ],
        ),
      ),
    );
  }

  Widget _loading() {
    final ch = Story.chapters[widget.chapterIndex];
    return Scaffold(
      backgroundColor: Hue.night,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ch.kanji, style: const TextStyle(fontSize: 34, color: Hue.crimson)),
            const SizedBox(height: 10),
            Text(upper(ch.title), style: const TextStyle(letterSpacing: 5, color: Hue.paper)),
            const SizedBox(height: 22),
            const SizedBox(
              width: 160,
              child: LinearProgressIndicator(color: Hue.crimson, backgroundColor: Colors.white10),
            ),
            const SizedBox(height: 10),
            Text(tr('loading'), style: const TextStyle(color: Hue.dim, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _dialog(Game g) {
    final line = g.currentLine!;
    final shown = line.text.substring(0, _typed.clamp(0, line.text.length).toInt());
    final isHint = line.speaker == Spk.hint;
    final speakerColor = switch (line.speaker) {
      Spk.essen => Hue.paper,
      Spk.masakage => const Color(0xFFE05A4A),
      Spk.rendo => const Color(0xFF7FA8E8),
      Spk.hotaru => const Color(0xFFF08A9A),
      _ => isHint ? const Color(0xFF9EC8FF) : Hue.gold,
    };
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _advanceDialog,
      child: Container(
        alignment: Alignment.bottomCenter,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.transparent, Color(0xAA000000)],
            stops: [0.45, 1],
          ),
        ),
        child: SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(40, 0, 40, 18),
            padding: const EdgeInsets.fromLTRB(22, 14, 22, 12),
            constraints: const BoxConstraints(maxWidth: 820),
            decoration: BoxDecoration(
              color: Hue.panel,
              border: Border(top: BorderSide(color: speakerColor.withValues(alpha: 0.8), width: 2)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(upper(L10n.speaker(line.speaker)),
                    style: TextStyle(color: speakerColor, letterSpacing: 3, fontSize: 12, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(shown,
                    style: TextStyle(
                        fontSize: 16, height: 1.45, color: Hue.paper, fontStyle: isHint ? FontStyle.italic : null)),
                const SizedBox(height: 8),
                if (line.choices != null && _typed >= line.text.length)
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      for (var i = 0; i < line.choices!.length; i++)
                        InkButton(line.choices![i], primary: i == 0, onTap: () => g.choose(i)),
                    ],
                  )
                else
                  const Align(
                    alignment: Alignment.centerRight,
                    child: Text('▸', style: TextStyle(color: Hue.dim)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _deathOverlay(Game g) {
    return Container(
      color: Colors.black.withValues(alpha: 0.6),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('死', style: TextStyle(fontSize: 64, color: Hue.crimson)),
            Text(tr('death.title'), style: const TextStyle(letterSpacing: 6, fontSize: 20)),
            const SizedBox(height: 6),
            Text(tr('death.sub'), style: const TextStyle(color: Hue.dim)),
            const SizedBox(height: 20),
            InkButton(tr('death.rise'), primary: true, onTap: g.respawn),
            InkButton(tr('pause.quit'), onTap: () => Journey.toTitle(context)),
          ],
        ),
      ),
    );
  }

  Widget _pauseOverlay(Game g) {
    return Container(
      color: Colors.black.withValues(alpha: 0.7),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(tr('pause.title'), style: const TextStyle(letterSpacing: 8, fontSize: 22, color: Hue.gold)),
            const SizedBox(height: 6),
            Text('${tr('story.chapter', {'n': g.chapter.number})} — ${g.chapter.title}', style: const TextStyle(color: Hue.dim)),
            const SizedBox(height: 18),
            InkButton(tr('pause.resume'), primary: true, onTap: () => setState(() => _paused = false)),
            InkButton(tr('menu.codex'),
                onTap: () => Navigator.of(context)
                    .push(MaterialPageRoute<void>(builder: (_) => const CodexScreen()))),
            InkButton(tr('pause.restart'), onTap: () => Journey.startChapter(context, widget.chapterIndex)),
            InkButton(tr('pause.quit'), onTap: () => Journey.toTitle(context)),
          ],
        ),
      ),
    );
  }
}

class _WorldPainter extends CustomPainter {
  final Game game;
  _WorldPainter(this.game, Listenable repaint) : super(repaint: repaint);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.clipRect(Offset.zero & size);
    game.render(canvas, size);
  }

  @override
  bool shouldRepaint(covariant _WorldPainter old) => old.game != game;
}
