import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/highlight_provider.dart';
import '../models/highlight_icons.dart';
import '../models/highlight_model.dart';
import '../ui/event_highlight_detail_page.dart';
import '../../digital_card/providers/card_provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../core/ui/feedback/feedback_overlay.dart';
import '../../../shared/widgets/glass_dialog.dart';
import '../../../core/theme/kart_tokens.dart';

/// Diamètre des cercles de la barre (catégories) et hauteur de la barre.
const double _circleSize = 64;
const double _barHeight = 100;

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

    // Pas de spinner ici — remonté côté produit : "Ma carte" en montrait
    // déjà un pour son propre chargement (QR/résumé), et celui-ci
    // apparaissait EN MÊME TEMPS un peu plus haut sur le même écran (deux
    // loaders visibles simultanément au lieu d'un seul pour toute la
    // page). Un espace vide de même hauteur le temps du chargement évite
    // ce doublon sans décaler le reste de la mise en page.
    if (provider.isLoading) {
      return const SizedBox(height: _barHeight);
    }

    return SizedBox(
      height: _barHeight,
      child: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
        scrollDirection: Axis.horizontal,
        itemCount: provider.highlights.length + 1,
        separatorBuilder: (_, __) => const SizedBox(width: 18),
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
    final t = KartTokens.of(context);

    // Créer les couleurs du gradient basées sur la couleur de l'entreprise
    final Color gradientStart =
        isCompanyUser ? accentColor : t.categoryGradientStart;
    final Color gradientEnd = isCompanyUser
        ? HSLColor.fromColor(accentColor)
            .withLightness((HSLColor.fromColor(accentColor).lightness + 0.15)
                .clamp(0.0, 1.0))
            .toColor()
        : t.categoryGradientEnd;

    // Libellé et contenu du cercle actif
    final Color activeColor =
        isCompanyUser ? accentColor : t.categoryActiveLabel;

    // Couleur de bordure pour les highlights inactifs
    final Color inactiveBorderColor =
        isCompanyUser ? accentColor.withValues(alpha: 0.3) : t.softBorder;

    final IconData? icon = HighlightIcons.of(highlight.icon);

    return GestureDetector(
      onLongPress: () {
        // Un highlight d'événement KART n'appartient pas à l'utilisateur
        // (il est auto-créé quand il s'inscrit à l'événement d'un autre) —
        // il ne doit donc pas pouvoir en changer le nom, seul l'organisateur
        // le peut.
        if (highlight.isCompanyEvent) return;
        _openCreateHighlightModal(context, accentColor, isCompanyUser,
            existing: highlight);
      },
      onTap: () async {
        // Un highlight d'événement KART (créé automatiquement lors d'une
        // inscription via le formulaire public) ouvre la fiche de l'événement
        // avec ses autres participants — le toggle actif/inactif classique n'a
        // pas de sens ici, ce n'est pas un highlight qu'on gère soi-même.
        if (highlight.isCompanyEvent && highlight.eventId != null) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EventHighlightDetailPage(
                eventId: highlight.eventId!,
                fallbackName: highlight.name,
              ),
            ),
          );
          return;
        }

        // Highlight d'événement sans event_id (créé avant l'ajout de cette
        // colonne) : pas de fiche à ouvrir, mais son activation reste du
        // ressort de l'entreprise organisatrice (HighlightController::
        // activate() renvoie 403 pour is_company_event) — on l'explique au
        // lieu de laisser la bascule échouer silencieusement.
        if (highlight.isCompanyEvent) {
          FeedbackOverlay.showInfo(
            context,
            title: 'Mise en avant gérée par l\'organisateur',
            subtitle:
                "L'entreprise qui organise cet événement décide de son affichage.",
          );
          return;
        }

        final bool isCurrentlyActive = highlight.isActive;

        final confirm = await GlassDialog.confirm(
          context,
          title: isCurrentlyActive
              ? 'Désactiver ce highlight ?'
              : 'Activer ce highlight ?',
          message: isCurrentlyActive
              ? 'Voulez-vous désactiver "${highlight.name}" ?'
              : 'Voulez-vous activer "${highlight.name}" ?',
          confirmLabel: isCurrentlyActive ? 'Désactiver' : 'Activer',
          isDestructive: isCurrentlyActive,
        );

        if (confirm == true) {
          provider.toggleHighlight(highlight);
        }
      },
      child: Column(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: _circleSize,
                height: _circleSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: highlight.isActive
                      ? LinearGradient(
                          colors: [gradientStart, gradientEnd],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  border: highlight.isActive
                      ? null
                      : Border.all(color: inactiveBorderColor, width: 1.5),
                  // Alpha/rayon réduits en thème clair — remonté côté
                  // produit une seconde fois ("vraiment le diminuer") :
                  // même à 0.2, l'ombre restait bien plus lourde qu'en
                  // thème sombre (où elle se fond davantage dans
                  // l'arrière-plan déjà foncé).
                  boxShadow: highlight.isActive && isCompanyUser
                      ? [
                          BoxShadow(
                            color: accentColor.withValues(
                                alpha: colors.brightness == Brightness.dark
                                    ? 0.4
                                    : 0.1),
                            blurRadius: colors.brightness == Brightness.dark
                                ? 12
                                : 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                // Anneau dégradé + fin liseré couleur de page entre
                // l'anneau et le cercle (style "stories").
                padding: EdgeInsets.all(highlight.isActive ? 2.5 : 0),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: t.pageBackground,
                  ),
                  padding: EdgeInsets.all(highlight.isActive ? 2.5 : 0),
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: t.softFill,
                    ),
                    alignment: Alignment.center,
                    child: icon != null
                        ? Icon(
                            icon,
                            size: 26,
                            color: highlight.isActive
                                ? activeColor
                                : t.textSecondary,
                          )
                        : Text(
                            highlight.name.isNotEmpty
                                ? highlight.name[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: highlight.isActive
                                  ? activeColor
                                  : t.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 20,
                            ),
                          ),
                  ),
                ),
              ),
              // Icône crayon visible pour renommer ce highlight — évite de
              // ne compter que sur l'appui long (non découvrable). Affichée
              // seulement sur le highlight actif : sur les autres, l'appui
              // long reste disponible mais on n'encombre pas visuellement
              // toute la rangée.
              // Le crayon de renommage n'a de sens que sur un highlight
              // qu'on gère soi-même — pas sur un highlight d'événement où
              // l'on n'est que participant.
              if (highlight.isActive && !highlight.isCompanyEvent)
                Positioned(
                  top: -4,
                  right: -4,
                  child: Semantics(
                    button: true,
                    label: 'Modifier ${highlight.name}',
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        _openCreateHighlightModal(
                            context, accentColor, isCompanyUser,
                            existing: highlight);
                      },
                      child: Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: t.sheetBackground,
                          shape: BoxShape.circle,
                          border:
                              Border.all(color: t.pageBackground, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: t.cardShadow,
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          size: 13,
                          color: t.textPrimary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: _circleSize + 16,
            child: Text(
              highlight.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: highlight.isActive ? activeColor : t.textSecondary,
                fontWeight:
                    highlight.isActive ? FontWeight.w600 : FontWeight.w500,
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
    final t = KartTokens.of(context);

    // Couleur de bordure adaptée
    final borderColor =
        isCompanyUser ? accentColor.withValues(alpha: 0.5) : t.softBorder;

    // Couleur de fond
    final bgColor =
        isCompanyUser ? accentColor.withValues(alpha: 0.1) : t.softFill;

    // Couleur de l'icône et du texte
    final contentColor = isCompanyUser ? accentColor : t.textSecondary;

    return Semantics(
      button: true,
      label: 'Nouveau highlight',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () =>
            _openCreateHighlightModal(context, accentColor, isCompanyUser),
        child: Column(
          children: [
            Container(
              width: _circleSize,
              height: _circleSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                  width: 1.5,
                ),
                color: bgColor,
              ),
              child: Icon(
                Icons.add_rounded,
                size: 30,
                color: contentColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Nouveau',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: contentColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

void _openCreateHighlightModal(
    BuildContext context, Color accentColor, bool isCompanyUser,
    {HighlightModel? existing}) {
  final controller = TextEditingController(text: existing?.name ?? '');

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
        existing: existing,
      );
    },
  );
}

class _CreateHighlightSheet extends StatefulWidget {
  final TextEditingController controller;
  final Color accentColor;
  final bool isCompanyUser;
  final BuildContext parentContext;
  final HighlightModel? existing;

  const _CreateHighlightSheet({
    required this.controller,
    required this.accentColor,
    required this.isCompanyUser,
    required this.parentContext,
    this.existing,
  });

  @override
  State<_CreateHighlightSheet> createState() => _CreateHighlightSheetState();
}

class _CreateHighlightSheetState extends State<_CreateHighlightSheet> {
  bool _isLoading = false;

  // Icône choisie (clé HighlightIcons) ; null = initiale du nom.
  late String? _icon = widget.existing?.icon;

  Future<void> _submit() async {
    final name = widget.controller.text.trim();
    if (name.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);

    final provider = widget.parentContext.read<HighlightProvider>();
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(widget.parentContext);

    try {
      if (widget.existing != null) {
        await provider.updateHighlight(widget.existing!, name, icon: _icon);
      } else {
        await provider.createHighlight(name, icon: _icon);
      }
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
    final t = KartTokens.of(context);
    final bgColor = t.sheetBackground;
    final textColor = t.textPrimary;
    final choiceColor = widget.isCompanyUser ? widget.accentColor : t.activeBlue;

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
                  widget.existing != null
                      ? 'Modifier le highlight'
                      : 'Nouveau highlight',
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
              cursorColor:
                  widget.isCompanyUser ? widget.accentColor : colors.primary,
              style: TextStyle(
                color: textColor,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
              decoration: InputDecoration(
                hintText: 'Ex: Salon Dakar 2026',
                hintStyle: TextStyle(color: textColor.withValues(alpha: 0.4)),
                counterStyle:
                    TextStyle(color: textColor.withValues(alpha: 0.5)),
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
                    color: widget.isCompanyUser
                        ? widget.accentColor
                        : colors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Icône (facultatif)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "Sans icône, l'initiale du nom est affichée.",
              style: TextStyle(fontSize: 12, color: t.textSecondary),
            ),
            const SizedBox(height: 12),
            ValueListenableBuilder<TextEditingValue>(
              valueListenable: widget.controller,
              builder: (context, value, _) {
                final name = value.text.trim();
                return Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _IconChoice(
                      selected: _icon == null,
                      color: choiceColor,
                      semanticLabel: 'Aucune icône (initiale)',
                      onTap: () => setState(() => _icon = null),
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : 'A',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    for (final entry in HighlightIcons.all.entries)
                      _IconChoice(
                        selected: _icon == entry.key,
                        color: choiceColor,
                        semanticLabel: 'Icône ${entry.key}',
                        onTap: () => setState(() => _icon = entry.key),
                        child: Icon(entry.value, size: 22),
                      ),
                  ],
                );
              },
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: widget.isCompanyUser
                      ? widget.accentColor
                      : t.activeBlue,
                  foregroundColor:
                      widget.isCompanyUser ? Colors.white : t.onActiveBlue,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor: (widget.isCompanyUser
                          ? widget.accentColor
                          : t.activeBlue)
                      .withValues(alpha: 0.5),
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
                    : Text(
                        widget.existing != null ? 'Enregistrer' : 'Créer',
                        style: const TextStyle(
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

/// Pastille de choix d'icône dans la feuille de création/modification.
class _IconChoice extends StatelessWidget {
  final bool selected;
  final Color color;
  final String semanticLabel;
  final VoidCallback onTap;
  final Widget child;

  const _IconChoice({
    required this.selected,
    required this.color,
    required this.semanticLabel,
    required this.onTap,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);

    return Semantics(
      button: true,
      selected: selected,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? color.withValues(alpha: 0.14) : t.softFill,
            border: Border.all(
              color: selected ? color : t.softBorder,
              width: selected ? 2 : 1,
            ),
          ),
          alignment: Alignment.center,
          child: IconTheme(
            data: IconThemeData(color: selected ? color : t.textSecondary),
            child: DefaultTextStyle.merge(
              style: TextStyle(color: selected ? color : t.textSecondary),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
