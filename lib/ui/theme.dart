import 'package:flutter/material.dart';

import '../l10n/l10n.dart';

class Hue {
  static const paper = Color(0xFFF1E6CF);
  static const crimson = Color(0xFFC0392B);
  static const gold = Color(0xFFD8A940);
  static const night = Color(0xFF0D0F16);
  static const panel = Color(0xE6121219);
  static const dim = Color(0xFF9A9286);
}

ThemeData essenTheme() {
  final base = ThemeData.dark(useMaterial3: true);
  return base.copyWith(
    scaffoldBackgroundColor: Hue.night,
    colorScheme: base.colorScheme.copyWith(primary: Hue.crimson, secondary: Hue.gold),
    textTheme: base.textTheme.apply(bodyColor: Hue.paper, displayColor: Hue.paper),
  );
}

/// Brush-stroke style menu button.
class InkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool primary;
  final String? leading; // optional image asset shown before the label

  const InkButton(this.label, {super.key, this.onTap, this.primary = false, this.leading});

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(4),
          child: Container(
            width: 250,
            padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 18),
            decoration: BoxDecoration(
              color: primary ? Hue.crimson.withValues(alpha: 0.85) : Colors.black.withValues(alpha: 0.35),
              border: Border(
                left: BorderSide(color: enabled ? Hue.gold : Hue.dim, width: 3),
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                if (leading != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: Image.asset(leading!, width: 27, height: 18),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: Text(
                    upper(label),
                    style: TextStyle(
                      color: enabled ? Hue.paper : Hue.dim,
                      fontSize: 14,
                      letterSpacing: 2.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
