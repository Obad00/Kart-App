import 'package:flutter/material.dart';

import '../../../core/theme/kart_tokens.dart';

/// Une action rapide sous la carte (Partager, Télécharger...).
class CardQuickAction {
  final IconData icon;
  final String label;
  final Future<void> Function() onTap;

  const CardQuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });
}

/// Rangée de boutons ronds avec libellé sous la carte. Un bouton affiche
/// un indicateur de chargement tant que son action n'est pas terminée
/// (évite les doubles taps pendant un export ou un téléchargement).
class CardQuickActions extends StatefulWidget {
  final List<CardQuickAction> actions;

  const CardQuickActions({super.key, required this.actions});

  @override
  State<CardQuickActions> createState() => _CardQuickActionsState();
}

class _CardQuickActionsState extends State<CardQuickActions> {
  final Set<int> _busy = {};

  Future<void> _run(int index) async {
    if (_busy.contains(index)) return;
    setState(() => _busy.add(index));
    try {
      await widget.actions[index].onTap();
    } finally {
      if (mounted) setState(() => _busy.remove(index));
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < widget.actions.length; i++)
          Expanded(
            child: Semantics(
              button: true,
              label: widget.actions[i].label,
              excludeSemantics: true,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => _run(i),
                child: Column(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: t.softFill,
                        shape: BoxShape.circle,
                        border: Border.all(color: t.softBorder),
                      ),
                      alignment: Alignment.center,
                      child: _busy.contains(i)
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: t.activeBlue,
                              ),
                            )
                          : Icon(
                              widget.actions[i].icon,
                              size: 26,
                              color: t.activeBlue,
                            ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.actions[i].label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: t.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
