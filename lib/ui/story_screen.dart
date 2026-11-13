import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import 'backdrop.dart';
import 'theme.dart';

/// Chapter title card + narrative paragraphs revealed one tap at a time.
class StoryScreen extends StatefulWidget {
  final String heading;
  final String title;
  final String kanji;
  final List<String> paragraphs;
  final List<Color> sky;
  final String buttonLabel;
  final String? stats;
  final void Function(BuildContext context) onDone;

  const StoryScreen({
    super.key,
    required this.heading,
    required this.title,
    required this.kanji,
    required this.paragraphs,
    required this.sky,
    required this.buttonLabel,
    required this.onDone,
    this.stats,
  });

  @override
  State<StoryScreen> createState() => _StoryScreenState();
}

class _StoryScreenState extends State<StoryScreen> {
  int _shown = 1;

  bool get _all => _shown >= widget.paragraphs.length;

  void _next() {
    if (_all) {
      widget.onDone(context);
    } else {
      setState(() => _shown++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final paragraphs = widget.paragraphs.take(_shown).toList();
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _next,
        child: Backdrop(
          sky: widget.sky,
          sun: const Color(0xFFC8402A),
          child: Container(
            color: Colors.black.withValues(alpha: 0.45),
            child: SafeArea(
              child: Row(
                children: [
                  // Title column.
                  Expanded(
                    flex: 4,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(36, 24, 16, 24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(upper(widget.heading),
                              style: const TextStyle(color: Hue.gold, letterSpacing: 4, fontSize: 13)),
                          const SizedBox(height: 10),
                          Text(widget.title,
                              style: const TextStyle(
                                  fontSize: 34, fontWeight: FontWeight.w700, height: 1.1, color: Hue.paper)),
                          const SizedBox(height: 8),
                          Text(widget.kanji,
                              style: TextStyle(fontSize: 26, color: Hue.crimson.withValues(alpha: 0.9))),
                          if (widget.stats != null) ...[
                            const SizedBox(height: 18),
                            Text(widget.stats!, style: const TextStyle(color: Hue.dim, fontSize: 12)),
                          ],
                        ],
                      ),
                    ),
                  ),
                  // Narrative column.
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(8, 24, 36, 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ListView(
                              reverse: false,
                              children: [
                                const SizedBox(height: 12),
                                for (var i = 0; i < paragraphs.length; i++)
                                  TweenAnimationBuilder<double>(
                                    key: ValueKey(i),
                                    tween: Tween(begin: 0, end: 1),
                                    duration: const Duration(milliseconds: 700),
                                    builder: (_, v, child) => Opacity(
                                      opacity: v,
                                      child: Transform.translate(offset: Offset(0, 8 * (1 - v)), child: child),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.only(bottom: 14),
                                      child: Text(
                                        paragraphs[i],
                                        style: TextStyle(
                                          fontSize: paragraphs[i].length < 12 ? 26 : 16,
                                          height: 1.5,
                                          letterSpacing: paragraphs[i].length < 12 ? 8 : 0.2,
                                          fontWeight: paragraphs[i].length < 12 ? FontWeight.w700 : FontWeight.w400,
                                          color: Hue.paper,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (!_all)
                                TextButton(
                                  onPressed: () => widget.onDone(context),
                                  child: Text(tr('story.skip'), style: const TextStyle(color: Hue.dim, letterSpacing: 2)),
                                ),
                              const SizedBox(width: 8),
                              Text(_all ? '' : tr('story.tap'),
                                  style: const TextStyle(color: Hue.dim, fontSize: 12)),
                              if (_all) InkButton(widget.buttonLabel, primary: true, onTap: _next),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
