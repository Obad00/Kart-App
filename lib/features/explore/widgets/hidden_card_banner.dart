import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/ui/feedback/feedback_overlay.dart';
import '../../digital_card/providers/card_provider.dart';

/// Bannière « Votre carte est invisible dans Explorer » : carte privée ou
/// retirée de l'annuaire. Même règle que la notification push
/// (cards:remind-hidden) : au plus une fois par semaine, trois fois en tout.
class HiddenCardBanner extends StatefulWidget {
  const HiddenCardBanner({super.key});

  static const shownCountKey = 'hidden_card_banner_shown_count';
  static const lastShownKey = 'hidden_card_banner_last_shown_at';
  static const maxShows = 3;
  static const minGap = Duration(days: 7);

  /// La bannière peut-elle s'afficher maintenant (et compte-t-elle un affichage) ?
  static Future<bool> claimDisplay(SharedPreferences prefs, DateTime now) async {
    final count = prefs.getInt(shownCountKey) ?? 0;
    final last = prefs.getInt(lastShownKey);
    if (count >= maxShows) return false;
    if (last != null && now.difference(DateTime.fromMillisecondsSinceEpoch(last)) < minGap) return false;
    await prefs.setInt(shownCountKey, count + 1);
    await prefs.setInt(lastShownKey, now.millisecondsSinceEpoch);
    return true;
  }

  @override
  State<HiddenCardBanner> createState() => _HiddenCardBannerState();
}

class _HiddenCardBannerState extends State<HiddenCardBanner> {
  // Décidé une fois par ouverture de l'écran.
  bool? _allowed;
  bool _dismissed = false;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_allowed == null && context.read<CardProvider>().isHiddenFromExplore) {
      _allowed = false;
      SharedPreferences.getInstance()
          .then((prefs) => HiddenCardBanner.claimDisplay(prefs, DateTime.now()))
          .then((ok) => mounted ? setState(() => _allowed = ok) : null);
    }
  }

  Future<void> _makeVisible() async {
    setState(() => _busy = true);
    final ok = await context.read<CardProvider>().makeVisibleInExplore();
    if (!mounted) return;
    setState(() => _busy = false);
    if (ok) {
      FeedbackOverlay.showSuccess(context,
          title: 'Carte visible', subtitle: 'Les membres de KART peuvent maintenant vous trouver dans Explorer.');
    } else {
      FeedbackOverlay.showError(context, title: 'Erreur', subtitle: 'La carte n\'a pas pu être rendue visible. Réessayez.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final hidden = context.watch<CardProvider>().isHiddenFromExplore;
    if (!hidden || _allowed != true || _dismissed) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.amber.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.visibility_off_outlined, color: Colors.amber.shade700, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Votre carte est invisible dans Explorer',
                    style: TextStyle(fontWeight: FontWeight.w700, color: colors.onSurface)),
                const SizedBox(height: 4),
                Text('Les autres membres ne peuvent pas vous trouver ni vous proposer de vous connecter.',
                    style: TextStyle(fontSize: 13, color: colors.onSurface.withValues(alpha: 0.7))),
                const SizedBox(height: 10),
                ElevatedButton(
                  onPressed: _busy ? null : _makeVisible,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF3B82F6),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  child: Text(_busy ? 'Un instant…' : 'Rendre ma carte visible'),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Fermer',
            icon: Icon(Icons.close_rounded, color: colors.onSurface.withValues(alpha: 0.5)),
            onPressed: () => setState(() => _dismissed = true),
          ),
        ],
      ),
    );
  }
}
