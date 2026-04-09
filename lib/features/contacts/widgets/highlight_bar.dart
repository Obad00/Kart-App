import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/highlight_provider.dart';
import '../models/highlight_model.dart';
import '../../digital_card/providers/card_provider.dart';
import '../../auth/providers/auth_provider.dart';

class HighlightBar extends StatelessWidget {
  const HighlightBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<HighlightProvider>();
    final cardProvider = context.watch<CardProvider>();
    final authProvider = context.watch<AuthProvider>();

    // Récupérer la couleur de l'entreprise
    final bool isCompanyUser = authProvider.user?.hasCompany == true ||
        (cardProvider.companyPrimaryColor != null &&
            cardProvider.companyPrimaryColor!.isNotEmpty);

    final Color companyColor = _parseColor(cardProvider.companyPrimaryColor);

    if (provider.isLoading) {
      return const SizedBox(
        height: 96,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return SizedBox(
      height: 96,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: provider.highlights.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (_, index) {
          if (index == 0) {
            return _AddHighlightButton(
              accentColor: companyColor,
              isCompanyUser: isCompanyUser,
            );
          }

          final highlight = provider.highlights[index - 1];
          return _HighlightItem(
            highlight: highlight,
            accentColor: companyColor,
            isCompanyUser: isCompanyUser,
          );
        },

      ),
    );
  }

  Color _parseColor(String? hexColor) {
    if (hexColor == null || hexColor.isEmpty) return const Color(0xFF3B82F6);
    try {
      String hex = hexColor.replaceFirst('#', '');
      if (hex.length == 6) hex = 'FF$hex';
      return Color(int.parse(hex, radix: 16));
    } catch (_) {
      return const Color(0xFF3B82F6);
    }
  }
}

class _HighlightItem extends StatelessWidget {
  final HighlightModel highlight;
  final Color accentColor;
  final bool isCompanyUser;

  const _HighlightItem({
    required this.highlight,
    required this.accentColor,
    required this.isCompanyUser,
  });

  @override
  Widget build(BuildContext context) {
    final provider = context.read<HighlightProvider>();
    final colors = Theme.of(context).colorScheme;

    // Créer les couleurs du gradient basées sur la couleur de l'entreprise
    final Color gradientStart = isCompanyUser
        ? accentColor
        : const Color(0xFFE1306C); // Rose Instagram par défaut
    final Color gradientEnd = isCompanyUser
        ? HSLColor.fromColor(accentColor)
            .withLightness((HSLColor.fromColor(accentColor).lightness + 0.15)
                .clamp(0.0, 1.0))
            .toColor()
        : const Color(0xFFF77737); // Orange Instagram par défaut

    // Couleur de fond adaptée au thème
    final Color backgroundColor = colors.surface;

    // Couleur de bordure pour les highlights inactifs
    final Color inactiveBorderColor = isCompanyUser
        ? accentColor.withValues(alpha: 0.3)
        : colors.onSurface.withValues(alpha: 0.2);

    return GestureDetector(
onTap: () async {
  final bool isCurrentlyActive = highlight.isActive;

  final confirm = await showDialog<bool>(
    context: context,
    builder: (dialogContext) {
      final isDark = Theme.of(dialogContext).brightness == Brightness.dark;
      final dialogBgColor = isDark ? const Color(0xFF2A2A2A) : Colors.white;
      final textColor = isDark ? Colors.white : Colors.black87;
      final subtitleColor = isDark ? Colors.white70 : Colors.black54;

      return AlertDialog(
        backgroundColor: dialogBgColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.white.withValues(alpha: isDark ? 0.1 : 0.0),
            width: 1,
          ),
        ),
        elevation: isDark ? 12 : 24,
        title: Text(
          isCurrentlyActive
              ? 'Désactiver ce highlight ?'
              : 'Activer ce highlight ?',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        content: Text(
          isCurrentlyActive
              ? 'Voulez-vous désactiver "${highlight.name}" ?'
              : 'Voulez-vous activer "${highlight.name}" ?',
          style: TextStyle(
            color: subtitleColor,
            fontSize: 15,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            style: TextButton.styleFrom(
              foregroundColor: subtitleColor,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: isCompanyUser ? accentColor : const Color(0xFF3B82F6),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              isCurrentlyActive ? 'Désactiver' : 'Activer',
            ),
          ),
        ],
      );
    },
  );

  if (confirm == true) {
    provider.toggleHighlight(highlight);
  }
},
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: highlight.isActive
                  ? LinearGradient(
                      colors: [gradientStart, gradientEnd],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null,
              border: Border.all(
                color: highlight.isActive
                    ? Colors.transparent
                    : inactiveBorderColor,
                width: 2,
              ),
              boxShadow: highlight.isActive && isCompanyUser
                  ? [
                      BoxShadow(
                        color: accentColor.withValues(alpha: 0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.all(3),
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: backgroundColor,
              ),
              alignment: Alignment.center,
              child: Text(
                highlight.name[0].toUpperCase(),
                style: TextStyle(
                  color: highlight.isActive
                      ? (isCompanyUser ? accentColor : gradientStart)
                      : colors.onSurface.withValues(alpha: 0.7),
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(height: 6),
          SizedBox(
            width: 70,
            child: Text(
              highlight.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 11,
                color: highlight.isActive
                    ? (isCompanyUser ? accentColor : gradientStart)
                    : colors.onSurface.withValues(alpha: 0.6),
                fontWeight:
                    highlight.isActive ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddHighlightButton extends StatelessWidget {
  final Color accentColor;
  final bool isCompanyUser;

  const _AddHighlightButton({
    required this.accentColor,
    required this.isCompanyUser,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    // Couleur de bordure adaptée
    final borderColor = isCompanyUser
        ? accentColor.withValues(alpha: 0.5)
        : colors.onSurface.withValues(alpha: 0.2);

    // Couleur de fond
    final bgColor = isCompanyUser
        ? accentColor.withValues(alpha: 0.1)
        : colors.onSurface.withValues(alpha: 0.05);

    // Couleur de l'icône et du texte
    final contentColor =
        isCompanyUser ? accentColor : colors.onSurface.withValues(alpha: 0.6);

    return GestureDetector(
      onTap: () =>
          _openCreateHighlightModal(context, accentColor, isCompanyUser),
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: borderColor,
                width: 1.5,
              ),
              color: bgColor,
            ),
            child: Icon(
              Icons.add,
              color: contentColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Nouveau',
            style: TextStyle(
              fontSize: 11,
              color: contentColor,
            ),
          ),
        ],
      ),
    );
  }
}

void _openCreateHighlightModal(
    BuildContext context, Color accentColor, bool isCompanyUser) {
  final controller = TextEditingController();

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (modalContext) {
      return _CreateHighlightSheet(
        controller: controller,
        accentColor: accentColor,
        isCompanyUser: isCompanyUser,
        parentContext: context,
      );
    },
  );
}

class _CreateHighlightSheet extends StatefulWidget {
  final TextEditingController controller;
  final Color accentColor;
  final bool isCompanyUser;
  final BuildContext parentContext;

  const _CreateHighlightSheet({
    required this.controller,
    required this.accentColor,
    required this.isCompanyUser,
    required this.parentContext,
  });

  @override
  State<_CreateHighlightSheet> createState() => _CreateHighlightSheetState();
}

class _CreateHighlightSheetState extends State<_CreateHighlightSheet> {
  bool _isLoading = false;

  Future<void> _submit() async {
    final name = widget.controller.text.trim();
    if (name.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);

    final provider = widget.parentContext.read<HighlightProvider>();
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(widget.parentContext);

    try {
      await provider.createHighlight(name);
      if (navigator.mounted) {
        navigator.pop();
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(
              'Erreur: ${e.toString().replaceAll('DioException [bad response]: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Row(
              children: [
                if (widget.isCompanyUser)
                  Container(
                    width: 4,
                    height: 24,
                    margin: const EdgeInsets.only(right: 12),
                    decoration: BoxDecoration(
                      color: widget.accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                Text(
                  'Nouveau highlight',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.controller,
              maxLength: 20,
              autofocus: true,
              cursorColor: widget.isCompanyUser ? widget.accentColor : colors.primary,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Ex: Salon Dakar 2026',
                hintStyle: TextStyle(color: textColor.withValues(alpha: 0.4)),
                counterStyle: TextStyle(color: textColor.withValues(alpha: 0.5)),
                filled: true,
                fillColor: widget.isCompanyUser
                    ? widget.accentColor.withValues(alpha: isDark ? 0.15 : 0.1)
                    : colors.onSurface.withValues(alpha: 0.05),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: colors.onSurface.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: widget.isCompanyUser ? widget.accentColor : colors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isCompanyUser
                      ? widget.accentColor
                      : const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: (widget.isCompanyUser
                      ? widget.accentColor
                      : const Color(0xFF3B82F6)).withValues(alpha: 0.5),
                ),
                onPressed: _isLoading ? null : _submit,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Créer',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
