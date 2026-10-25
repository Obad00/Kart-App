import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'glass_sheet.dart';

const _themeBlue = Color(0xFF3B82F6);

/// Une entrée du menu verre : icône bleue, titre, sous-titre facultatif.
/// [destructive] l'affiche en rouge ; [dividerBefore] trace un séparateur.
class GlassMenuItem<T> {
  final T value;
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool destructive;
  final bool dividerBefore;

  const GlassMenuItem({
    required this.value,
    required this.icon,
    required this.title,
    this.subtitle,
    this.destructive = false,
    this.dividerBefore = false,
  });
}

/// Menu contextuel en verre dépoli (même verre que GlassSheet / GlassDialog),
/// ancré sous [child]. Remplace les PopupMenuButton opaques (initiales de la
/// page Carte, « ⋯ » des contacts…) sans changer leurs actions.
class GlassMenuButton<T> extends StatelessWidget {
  final Widget child;
  final List<GlassMenuItem<T>> Function(BuildContext context) itemBuilder;
  final ValueChanged<T> onSelected;
  final String? tooltip;

  const GlassMenuButton({
    super.key,
    required this.child,
    required this.itemBuilder,
    required this.onSelected,
    this.tooltip,
  });

  Future<void> _open(BuildContext context) async {
    final box = context.findRenderObject()! as RenderBox;
    final anchor = box.localToGlobal(Offset.zero) & box.size;
    HapticFeedback.selectionClick();
    final value = await Navigator.of(context).push<T>(
      _GlassMenuRoute<T>(anchor: anchor, items: itemBuilder(context)),
    );
    if (value != null) onSelected(value);
  }

  @override
  Widget build(BuildContext context) {
    final button = InkResponse(
      onTap: () => _open(context),
      radius: 28,
      child: child,
    );
    return tooltip == null ? button : Tooltip(message: tooltip!, child: button);
  }
}

class _GlassMenuRoute<T> extends PopupRoute<T> {
  final Rect anchor;
  final List<GlassMenuItem<T>> items;

  _GlassMenuRoute({required this.anchor, required this.items});

  @override
  Color? get barrierColor => Colors.black.withValues(alpha: 0.08);

  @override
  bool get barrierDismissible => true;

  @override
  String? get barrierLabel => 'Fermer le menu';

  @override
  Duration get transitionDuration => const Duration(milliseconds: 160);

  @override
  Widget buildPage(BuildContext context, Animation<double> animation, Animation<double> secondaryAnimation) {
    final media = MediaQuery.of(context);
    return CustomSingleChildLayout(
      delegate: _MenuLayout(anchor: anchor, padding: media.padding),
      child: FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
        child: ScaleTransition(
          alignment: Alignment.topRight,
          scale: Tween(begin: 0.94, end: 1.0)
              .animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
          child: _GlassMenu<T>(items: items),
        ),
      ),
    );
  }
}

/// Sous l'ancre, aligné sur son bord droit, toujours dans l'écran.
class _MenuLayout extends SingleChildLayoutDelegate {
  final Rect anchor;
  final EdgeInsets padding;

  _MenuLayout({required this.anchor, required this.padding});

  @override
  BoxConstraints getConstraintsForChild(BoxConstraints constraints) =>
      BoxConstraints(maxWidth: math.min(300, constraints.maxWidth - 24), maxHeight: constraints.maxHeight - 48);

  @override
  Offset getPositionForChild(Size size, Size childSize) {
    var x = anchor.right - childSize.width;
    x = x.clamp(12.0, size.width - childSize.width - 12);
    var y = anchor.bottom + 8;
    // Pas la place en dessous : au-dessus de l'ancre.
    if (y + childSize.height > size.height - padding.bottom - 12) {
      y = math.max(padding.top + 12, anchor.top - childSize.height - 8);
    }
    return Offset(x, y);
  }

  @override
  bool shouldRelayout(_MenuLayout old) => old.anchor != anchor || old.padding != padding;
}

class _GlassMenu<T> extends StatelessWidget {
  final List<GlassMenuItem<T>> items;

  const _GlassMenu({required this.items});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      type: MaterialType.transparency,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 24, offset: const Offset(0, 8)),
          ],
        ),
        child: GlassSheet(
          borderRadius: BorderRadius.circular(16),
          child: IntrinsicWidth(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (final item in items) ...[
                    if (item.dividerBefore)
                      Divider(height: 9, thickness: 0.5, color: colors.onSurface.withValues(alpha: 0.12)),
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        Navigator.of(context).pop(item.value);
                      },
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(minWidth: 200, minHeight: 46),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          child: Row(
                            children: [
                              Icon(item.icon, size: 20, color: item.destructive ? Colors.redAccent : _themeBlue),
                              const SizedBox(width: 12),
                              Flexible(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.title,
                                      style: TextStyle(
                                        fontSize: 14.5,
                                        fontWeight: FontWeight.w600,
                                        color: item.destructive ? Colors.redAccent : colors.onSurface,
                                      ),
                                    ),
                                    if (item.subtitle != null && item.subtitle!.isNotEmpty)
                                      Text(
                                        item.subtitle!,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(fontSize: 12, color: colors.onSurface.withValues(alpha: 0.55)),
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
