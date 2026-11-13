import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'l10n/l10n.dart';
import 'ui/progress.dart';
import 'ui/theme.dart';
import 'ui/title_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Progress.instance.load();
  runApp(const EssenApp());
}

class EssenApp extends StatelessWidget {
  const EssenApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Rebuild the whole app (back to the title screen) when the language changes.
    return ValueListenableBuilder<Lang>(
      valueListenable: Progress.instance.lang,
      builder: (_, lang, _) => MaterialApp(
        key: ValueKey(lang),
        title: 'Essen',
        debugShowCheckedModeBanner: false,
        theme: essenTheme(),
        home: const TitleScreen(),
      ),
    );
  }
}
