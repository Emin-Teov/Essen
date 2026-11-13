import 'package:flutter/material.dart';

import '../game/game.dart';
import '../l10n/l10n.dart';
import '../story/story.dart';
import 'game_screen.dart';
import 'progress.dart';
import 'story_screen.dart';
import 'title_screen.dart';

Route<void> fadeRoute(Widget page) => PageRouteBuilder<void>(
      pageBuilder: (_, _, _) => page,
      transitionDuration: const Duration(milliseconds: 600),
      transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
    );

/// Moves between story pages, chapters and the title screen.
class Journey {
  static const _moods = [
    [Color(0xFF05070F), Color(0xFF1B2440), Color(0xFF5A2A1E)],
    [Color(0xFF3D4A66), Color(0xFF9C8E9A), Color(0xFFE7C0A5)],
    [Color(0xFF3F6FA8), Color(0xFFB9CDE0), Color(0xFFF2D3DA)],
    [Color(0xFF1E1530), Color(0xFF7A2A30), Color(0xFFE07848)],
  ];

  static void startChapter(BuildContext context, int index) {
    final ch = Story.chapters[index];
    Navigator.of(context).pushReplacement(fadeRoute(StoryScreen(
      heading: tr('story.chapter', {'n': ch.number}),
      title: ch.title,
      kanji: ch.kanji,
      paragraphs: ch.intro,
      sky: _moods[index],
      buttonLabel: tr('story.begin'),
      onDone: (ctx) => Navigator.of(ctx)
          .pushReplacement(fadeRoute(GameScreen(chapterIndex: index))),
    )));
  }

  static void chapterComplete(BuildContext context, Game game) {
    final idx = game.chapterIndex;
    final ch = game.chapter;
    Progress.instance.unlockChapter(idx + 2);
    if (idx + 1 < Story.chapters.length) {
      Navigator.of(context).pushReplacement(fadeRoute(StoryScreen(
        heading: tr('story.complete', {'n': ch.number}),
        title: ch.title,
        kanji: ch.kanji,
        paragraphs: ch.outro,
        sky: _moods[idx],
        stats: tr('story.stats', {'k': game.kills, 's': game.shadowKills}),
        buttonLabel: tr('story.continue'),
        onDone: (ctx) => startChapter(ctx, idx + 1),
      )));
      return;
    }
    final mercy = game.endingChoice != 1;
    Progress.instance.setEnding(mercy ? 0 : 1);
    Navigator.of(context).pushReplacement(fadeRoute(StoryScreen(
      heading: tr('story.epilogue'),
      title: L10n.s(mercy ? 'ending.mercy.title' : 'ending.vengeance.title'),
      kanji: mercy ? '優しき手' : '影の裁き',
      paragraphs: mercy ? Story.endingMercy : Story.endingVengeance,
      sky: mercy ? _moods[1] : _moods[0],
      buttonLabel: tr('story.fin'),
      onDone: (ctx) => toTitle(ctx),
    )));
  }

  static void toTitle(BuildContext context) {
    Navigator.of(context).pushAndRemoveUntil(fadeRoute(const TitleScreen()), (_) => false);
  }
}
