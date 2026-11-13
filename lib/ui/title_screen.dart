import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../story/story.dart';
import 'backdrop.dart';
import 'codex_screen.dart';
import 'flow.dart';
import 'game_icons.dart';
import 'progress.dart';
import 'theme.dart';

class TitleScreen extends StatelessWidget {
  const TitleScreen({super.key});

  void _chapters(BuildContext context) {
    final unlocked = Progress.instance.unlockedChapters;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Hue.panel,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(tr('chapters.title'), style: const TextStyle(color: Hue.gold, letterSpacing: 4)),
                const SizedBox(height: 10),
                for (var i = 0; i < Story.chapters.length; i++)
                  ListTile(
                    enabled: i < unlocked,
                    leading: Text(Story.chapters[i].kanji,
                        style: TextStyle(color: i < unlocked ? Hue.crimson : Hue.dim)),
                    title: Text('${Story.chapters[i].number}. ${Story.chapters[i].title}'),
                    trailing: i < unlocked ? null : const Icon(Icons.lock, size: 16),
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Journey.startChapter(context, i);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _language(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Hue.panel,
        child: SizedBox(
          width: 320,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(upper(tr('menu.language')),
                    style: const TextStyle(color: Hue.gold, letterSpacing: 4)),
                const SizedBox(height: 8),
                for (final l in Lang.values)
                  ListTile(
                    selected: l == L10n.lang,
                    selectedTileColor: Colors.white10,
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(3),
                      child: Image.asset(GameIcons.flagAsset(l.name), width: 36, height: 24),
                    ),
                    title: Text(L10n.nameOf(l)),
                    trailing: l == L10n.lang ? const Icon(Icons.check, color: Hue.gold) : null,
                    onTap: () {
                      Navigator.of(ctx).pop();
                      Progress.instance.setLang(l);
                    },
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _howTo(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Hue.panel,
        title: Text(tr('howto.title'), style: const TextStyle(color: Hue.gold, letterSpacing: 3)),
        content: SingleChildScrollView(
          child: Text(tr('howto.body'), style: const TextStyle(height: 1.5)),
        ),
        actions: [TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(tr('howto.ok')))],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = Progress.instance;
    final next = (progress.unlockedChapters - 1).clamp(0, Story.chapters.length - 1);
    return Scaffold(
      body: Backdrop(
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(left: 48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('エッセン',
                          style: TextStyle(color: Hue.crimson, fontSize: 20, letterSpacing: 10)),
                      FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          Story.gameTitle,
                          style: TextStyle(
                            fontSize: 76,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 8,
                            color: Hue.paper,
                            shadows: [Shadow(color: Colors.black.withValues(alpha: 0.6), blurRadius: 18)],
                          ),
                        ),
                      ),
                      Text(upper(Story.tagline),
                          style: const TextStyle(color: Hue.gold, letterSpacing: 5, fontSize: 13)),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(right: 40),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (progress.unlockedChapters > 1)
                        InkButton(tr('menu.continue', {'n': next + 1}),
                            primary: true, onTap: () => Journey.startChapter(context, next)),
                      InkButton(tr('menu.new'),
                          primary: progress.unlockedChapters <= 1,
                          onTap: () => Journey.startChapter(context, 0)),
                      InkButton(tr('menu.chapters'), onTap: () => _chapters(context)),
                      InkButton(tr('menu.codex'),
                          onTap: () => Navigator.of(context)
                              .push(MaterialPageRoute<void>(builder: (_) => const CodexScreen()))),
                      InkButton(tr('menu.howto'), onTap: () => _howTo(context)),
                      InkButton('${tr('menu.language')}: ${L10n.nameOf(L10n.lang)}',
                          leading: GameIcons.flagAsset(L10n.lang.name), onTap: () => _language(context)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
