import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../l10n/l10n.dart';

/// Saved story progress: unlocked chapters, codex entries, ending and language.
class Progress {
  static final Progress instance = Progress._();
  Progress._();

  int unlockedChapters = 1;
  final Set<String> codex = {'essen'};
  int? ending;

  /// Current language; the app rebuilds when it changes.
  final ValueNotifier<Lang> lang = ValueNotifier(Lang.en);
  SharedPreferences? _prefs;

  Future<void> load() async {
    L10n.lang = lang.value = L10n.fromCode(PlatformDispatcher.instance.locale.languageCode);
    try {
      final p = _prefs = await SharedPreferences.getInstance();
      unlockedChapters = p.getInt('unlocked') ?? 1;
      codex.addAll(p.getStringList('codex') ?? const []);
      ending = p.getInt('ending');
      final saved = p.getString('lang');
      if (saved != null) L10n.lang = lang.value = L10n.fromCode(saved);
    } catch (_) {
      // Storage unavailable (tests, unsupported platform): keep defaults.
    }
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setInt('unlocked', unlockedChapters);
    await p.setStringList('codex', codex.toList());
    await p.setString('lang', lang.value.name);
    if (ending != null) await p.setInt('ending', ending!);
  }

  void unlockChapter(int count) {
    if (count > unlockedChapters) {
      unlockedChapters = count;
      _save();
    }
  }

  void addCodex(String id) {
    if (codex.add(id)) _save();
  }

  void setEnding(int e) {
    ending = e;
    _save();
  }

  void setLang(Lang l) {
    L10n.lang = l;
    lang.value = l;
    _save();
  }
}
