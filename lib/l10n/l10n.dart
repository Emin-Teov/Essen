import '../story/story.dart';
import 'story_az.dart';
import 'story_en.dart';
import 'story_ja.dart';
import 'ui_strings.dart';

enum Lang { en, az, ja }

/// Localized story content for one language.
class StoryText {
  /// Single strings: chapter titles, objective texts, codex titles/texts.
  final Map<String, String> s;

  /// Paragraph lists: chapter intros/outros, endings.
  final Map<String, List<String>> p;

  /// Conversations.
  final Map<String, List<DialogLine>> d;

  const StoryText({required this.s, required this.p, required this.d});
}

/// Global localization lookup. Falls back to English, then to the key itself.
class L10n {
  static Lang lang = Lang.en;

  static StoryText storyFor(Lang l) => switch (l) {
        Lang.en => storyEn,
        Lang.az => storyAz,
        Lang.ja => storyJa,
      };

  static StoryText get _story => storyFor(lang);

  /// UI string with optional `{name}` placeholders.
  static String t(String key, [Map<String, Object> args = const {}]) {
    var s = uiStrings[lang]![key] ?? uiStrings[Lang.en]![key] ?? key;
    args.forEach((k, v) => s = s.replaceAll('{$k}', '$v'));
    return s;
  }

  static String s(String key) => _story.s[key] ?? storyEn.s[key] ?? key;

  static List<String> paragraphs(String key) => _story.p[key] ?? storyEn.p[key] ?? const [];

  static List<DialogLine> dialog(String key) => _story.d[key] ?? storyEn.d[key] ?? const [];

  static String speaker(String key) => t('spk.$key');

  static String nameOf(Lang l) => uiStrings[l]!['lang.name']!;

  static Lang fromCode(String? code) => switch (code) {
        'az' => Lang.az,
        'ja' => Lang.ja,
        _ => Lang.en,
      };
}

/// Shorthand for [L10n.t].
String tr(String key, [Map<String, Object> args = const {}]) => L10n.t(key, args);

/// Upper-cases [s] respecting Azerbaijani dotted/dotless i (i→İ, ı→I).
String upper(String s) =>
    L10n.lang == Lang.az ? s.replaceAll('i', 'İ').toUpperCase() : s.toUpperCase();
