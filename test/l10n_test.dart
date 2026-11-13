import 'package:essen/game/game.dart';
import 'package:essen/game/world.dart';
import 'package:essen/l10n/l10n.dart';
import 'package:essen/l10n/ui_strings.dart';
import 'package:essen/story/story.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(() => L10n.lang = Lang.en);

  test('every language has the same UI keys', () {
    final en = uiStrings[Lang.en]!.keys.toSet();
    for (final l in Lang.values) {
      expect(uiStrings[l]!.keys.toSet(), en, reason: l.name);
      expect(uiStrings[l]!['compass']!.split(',').length, 8, reason: l.name);
    }
  });

  test('every language has the same story keys', () {
    final en = L10n.storyFor(Lang.en);
    for (final l in Lang.values) {
      final s = L10n.storyFor(l);
      expect(s.s.keys.toSet(), en.s.keys.toSet(), reason: '${l.name} strings');
      expect(s.p.keys.toSet(), en.p.keys.toSet(), reason: '${l.name} paragraphs');
      expect(s.d.keys.toSet(), en.d.keys.toSet(), reason: '${l.name} dialogs');
      for (final k in en.d.keys) {
        final a = en.d[k]!, b = s.d[k]!;
        expect(b.where((d) => d.choices != null).length, a.where((d) => d.choices != null).length,
            reason: '${l.name} $k choice line');
        expect(b.last.choices?.length, a.last.choices?.length, reason: '${l.name} $k choices');
      }
    }
  });

  test('story structure resolves to text in every language', () {
    for (final l in Lang.values) {
      L10n.lang = l;
      for (final ch in Story.chapters) {
        expect(ch.title, isNot('ch${ch.number}.title'));
        expect(ch.intro, isNotEmpty);
        for (final o in ch.objectives) {
          expect(o.text, isNot(o.id), reason: '${l.name} ${o.id}');
        }
      }
      for (final c in Story.codex) {
        expect(c.title, isNot(startsWith('codex.')), reason: '${l.name} ${c.id}');
        expect(c.text.length, greaterThan(20));
      }
      expect(Story.endingMercy, isNotEmpty);
      expect(Story.endingVengeance, isNotEmpty);
      expect(upper('yeni'), l == Lang.az ? 'YENİ' : 'YENI');
    }
  });

  test('a chapter plays in Japanese and Azerbaijani', () {
    final world = World();
    for (final l in [Lang.ja, Lang.az]) {
      L10n.lang = l;
      final g = Game(world, 0);
      expect(g.currentLine!.text, isNotEmpty);
      while (g.phase == Phase.dialog) {
        g.advanceDialog();
      }
      expect(g.objectiveText, L10n.storyFor(l).s['c1.o1']);
    }
  });
}
