import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../story/story.dart';
import 'progress.dart';
import 'theme.dart';

/// Lore collected on the journey.
class CodexScreen extends StatefulWidget {
  const CodexScreen({super.key});

  @override
  State<CodexScreen> createState() => _CodexScreenState();
}

class _CodexScreenState extends State<CodexScreen> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final unlocked = Progress.instance.codex;
    final entries = Story.codex;
    final sel = Story.codexById(_selected ?? 'essen');
    return Scaffold(
      backgroundColor: const Color(0xFF14110F),
      body: SafeArea(
        child: Row(
          children: [
            SizedBox(
              width: 280,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
                    child: Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back, color: Hue.paper),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                        Text(tr('codex.title'), style: const TextStyle(letterSpacing: 5, fontSize: 18, color: Hue.gold)),
                        const Spacer(),
                        Text('${entries.where((e) => unlocked.contains(e.id)).length}/${entries.length}',
                            style: const TextStyle(color: Hue.dim)),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ListView(
                      children: [
                        for (final cat in ['Characters', 'Places', 'Lore']) ...[
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 12, 4),
                            child: Text(tr('cat.$cat'),
                                style: const TextStyle(color: Hue.crimson, fontSize: 11, letterSpacing: 3)),
                          ),
                          for (final e in entries.where((e) => e.category == cat))
                            ListTile(
                              dense: true,
                              selected: e.id == sel?.id,
                              selectedTileColor: Colors.white10,
                              enabled: unlocked.contains(e.id),
                              title: Text(unlocked.contains(e.id) ? e.title : '? ? ?',
                                  style: TextStyle(color: unlocked.contains(e.id) ? Hue.paper : Hue.dim)),
                              onTap: () => setState(() => _selected = e.id),
                            ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1, color: Colors.white12),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: sel == null || !unlocked.contains(sel.id)
                    ? Center(child: Text(tr('codex.undiscovered'), style: const TextStyle(color: Hue.dim)))
                    : ListView(
                        children: [
                          Text(tr('cat.${sel.category}'),
                              style: const TextStyle(color: Hue.gold, letterSpacing: 4, fontSize: 12)),
                          const SizedBox(height: 8),
                          Text(sel.title, style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 18),
                          Text(sel.text, style: const TextStyle(fontSize: 16, height: 1.6)),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
