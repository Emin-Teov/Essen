# Localization (EN / AZ / JA)

## Rules
- **No player-facing string literals outside `lib/l10n/`.**
- The only exceptions are the game title `Essen`, the katakana `エッセン`, chapter kanji subtitles, and debug output.
- Every key must exist in **all** languages. `test/l10n_test.dart` enforces identical key sets, and identical choice lines and counts in dialogs.
- When adding text, write the English version first, then add natural Azerbaijani and Japanese translations. Don't leave English placeholders in other languages.

## Lookup API (lib/l10n/l10n.dart)
| Call | Use for |
|---|---|
| `tr('key', {'n': 3})` | UI strings from `ui_strings.dart`; `{name}` placeholders are replaced |
| `L10n.s('key')` | single story strings: chapter titles, objectives, codex, ending titles |
| `L10n.paragraphs('key')` | story paragraph lists |
| `L10n.dialog('key')` | `List<DialogLine>` |
| `L10n.speaker(Spk.x)` | speaker display name (UI key `spk.<x>`) |
| `upper(s)` | **always use instead of `toUpperCase()`** in UI; it handles Azerbaijani `i → İ` |
| `L10n.lang` / `Progress.instance.setLang(l)` | current language; `setLang` saves it and rebuilds the app |

Fallback order: current language → English → the key itself.

## Key naming
| Area | Keys |
|---|---|
| UI | `menu.*`, `story.*`, `pause.*`, `death.*`, `hud.*`, `btn.*`, `toast.*`, `cat.*`, `howto.*`, `codex.title`, `chapters.title`, `loading`, `compass` (8 comma-separated labels starting at N), `spk.*`, `lang.name` |
| Story strings | `tagline`, `ch<N>.title`, `c<N>.o<M>`, `ending.<mercy\|vengeance>.title`, `codex.<id>.title`, `codex.<id>.text` |
| Story paragraphs | `ch<N>.intro`, `ch<N>.outro`, `ending.mercy`, `ending.vengeance` |
| Dialogs | `c<N>.o<M>.before`, `.after`, `.mid`; pickup dialogs use their own key (`note1`…) |

## Dialog lines
`DialogLine(Spk.essen, 'text')`. Speakers are keys (`Spk.essen`, `soun`, `tsuru`, `hotaru`, `rendo`, `masakage`, `hint`, `unknown`).
The final ending line carries `choices: [...]` with exactly 2 items, in the same order in every language (0 = mercy, 1 = vengeance).

## Names reference
| EN | AZ | JA |
|---|---|---|
| Essen | Essen | エッセン |
| Master Kiriya Sōun | Usta Kiriya Soun | 桐谷宗雲 師匠 |
| Hotaru | Hotaru | 蛍 |
| Obaa Tsuru | Tsuru nənə | ツル婆 |
| Lord Tetsuryū Masakage | Hökmdar Tetsuryu Masakage | 鉄竜政景 公 |
| General Takeshi Rendō | General Takeşi Rendo | 蓮堂武 将軍 |
| Kasumi-gakure (Village Hidden in Mist) | Kasumi-gakure (Dumanda gizlənən kənd) | 霞隠れの里 |
| Iron Dragon clan | Dəmir Əjdaha klanı | 鉄竜家 |
| Hanamura | Hanamura | 花村 |
| the Morgenrot | Morgenrot | モルゲンロート号 |
| Shadow Strike | Kölgə zərbəsi | 影討ち |

## Adding a language
See recipes.md → "Add a language".
