import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../../../core/theme/kart_tokens.dart';
import '../models/nfc_card_status.dart';

/// Visuel de la carte NFC physique : noire dans les deux thèmes, comme la
/// carte de visite de l'app. [dimmed] pour une carte désactivée.
class NfcCardVisual extends StatelessWidget {
  final bool dimmed;

  const NfcCardVisual({super.key, this.dimmed = false});

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);

    return Center(
      child: Opacity(
        opacity: dimmed ? 0.45 : 1,
        child: Container(
          width: 220,
          height: 138,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [t.cardSheen, t.cardBlack, t.cardDeep],
            ),
            border: Border.all(color: t.softBorder),
            boxShadow: [
              BoxShadow(
                color: t.cardShadow,
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'KART',
                    style: TextStyle(
                      color: t.onCard,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const Spacer(),
                  Icon(Icons.contactless_outlined, color: t.onCard, size: 26),
                ],
              ),
              const Spacer(),
              Text(
                'Carte NFC',
                style: TextStyle(color: t.onCardMuted, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bouton principal du design system : blanc plein en thème sombre, bleu
/// KART plein en thème clair.
class NfcPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool busy;

  const NfcPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: busy ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: t.textPrimary,
          foregroundColor: t.pageBackground,
          disabledBackgroundColor: t.textPrimary.withValues(alpha: 0.5),
          disabledForegroundColor: t.pageBackground,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: busy
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: t.pageBackground,
                ),
              )
            : Text(
                label,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}

/// Bouton secondaire : contour fin. [danger] pour une action à confirmer
/// (désactiver la carte).
class NfcSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final bool danger;

  const NfcSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.danger = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);
    final color = danger ? t.negative : t.textPrimary;

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(
            color: danger ? t.negative.withValues(alpha: 0.5) : t.softBorder,
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[icon!, const SizedBox(width: 10)],
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// « Contacter le support » : ouvre WhatsApp. À n'afficher que si le
/// serveur a renvoyé un numéro.
class NfcSupportButton extends StatelessWidget {
  final VoidCallback onPressed;

  const NfcSupportButton({super.key, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return NfcSecondaryButton(
      label: 'Contacter le support',
      icon: const FaIcon(FontAwesomeIcons.whatsapp, size: 18),
      onPressed: onPressed,
    );
  }
}

/// Rappel affiché quand l'utilisateur n'a pas de carte NFC utilisable : le
/// partage par QR code ou par lien ne dépend jamais de l'état NFC.
class NfcQrReminder extends StatelessWidget {
  final VoidCallback onShowQr;

  const NfcQrReminder({super.key, required this.onShowQr});

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Divider(height: 1, thickness: 1, color: t.softBorder),
        const SizedBox(height: 16),
        Text(
          'Vous pouvez toujours partager votre carte avec votre QR code '
          'ou votre lien.',
          style: TextStyle(color: t.textSecondary, fontSize: 13, height: 1.4),
        ),
        const SizedBox(height: 12),
        NfcSecondaryButton(
          label: 'Afficher mon QR code',
          icon: const Icon(Icons.qr_code_2_rounded, size: 20),
          onPressed: onShowQr,
        ),
      ],
    );
  }
}

/// Frise d'une commande : Reçue → En fabrication → Prête → Livrée. Étapes
/// passées en vert, étape en cours en ambre, suivantes en gris.
class NfcOrderTimeline extends StatelessWidget {
  final NfcOrderInfo order;

  const NfcOrderTimeline({super.key, required this.order});

  static const _steps = [
    (NfcOrderStatus.pending, 'Reçue'),
    (NfcOrderStatus.inProduction, 'En fabrication'),
    (NfcOrderStatus.ready, 'Prête'),
    (NfcOrderStatus.delivered, 'Livrée'),
  ];

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);
    final current = _steps.indexWhere((step) => step.$1 == order.status);

    return Column(
      children: [
        for (var i = 0; i < _steps.length; i++)
          _TimelineStep(
            label: _steps[i].$2,
            // La date de la commande accompagne sa première étape.
            trailing: i == 0 ? formatNfcDate(order.createdAt) : null,
            color: i < current
                ? t.positive
                : (i == current ? t.attention : t.softBorder),
            done: i < current,
            current: i == current,
            isLast: i == _steps.length - 1,
          ),
      ],
    );
  }
}

class _TimelineStep extends StatelessWidget {
  final String label;
  final String? trailing;
  final Color color;
  final bool done;
  final bool current;
  final bool isLast;

  const _TimelineStep({
    required this.label,
    required this.color,
    required this.done,
    required this.current,
    required this.isLast,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);
    final reached = done || current;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: reached ? color : Colors.transparent,
                  border: Border.all(color: color, width: 2),
                ),
                child: done
                    ? Icon(Icons.check, size: 10, color: t.pageBackground)
                    : null,
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: done ? t.positive : t.softBorder,
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 22),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        color: reached ? t.textPrimary : t.textSecondary,
                        fontSize: 15,
                        fontWeight:
                            current ? FontWeight.w700 : FontWeight.w500,
                        height: 1.1,
                      ),
                    ),
                  ),
                  if (trailing != null)
                    Text(
                      trailing!,
                      style: TextStyle(color: t.textSecondary, fontSize: 12),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// « 5 oct. » — date courte en français, sans dépendre de la langue du
/// téléphone.
String? formatNfcDate(DateTime? date) {
  if (date == null) return null;
  const months = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];
  return '${date.day} ${months[date.month - 1]}';
}
