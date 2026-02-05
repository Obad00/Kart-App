import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/card_themes.dart';
import '../providers/card_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/pro_badge.dart';

class ThemeSelector extends StatelessWidget {
  const ThemeSelector({super.key});

  @override
  Widget build(BuildContext context) {
    final card = context.watch<CardProvider>();
    final auth = context.watch<AuthProvider>();

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: CardThemes.options.map((option) {
        final isSelected = card.theme == option.key;
        final locked = option.isProOnly && !auth.isPro;

        return GestureDetector(
          onTap: () {
            if (locked) {
              _showProDialog(context);
              return;
            }

            card.updateTheme(option.key);
          },
          child: Opacity(
            opacity: locked ? 0.45 : 1,
            child: Stack(
              children: [
                Container(
                  width: 140,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: option.theme.background,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isSelected
                          ? option.theme.foreground
                          : option.theme.border,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                  child: Text(
                    option.label,
                    style: TextStyle(
                      color: option.theme.foreground,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                if (locked)
                  const Positioned(
                    top: 8,
                    right: 8,
                    child: ProBadge(),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  void _showProDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Text(
              'Passe en PRO',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 12),
            Text(
              'Débloque les thèmes premium et personnalise ta carte.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
