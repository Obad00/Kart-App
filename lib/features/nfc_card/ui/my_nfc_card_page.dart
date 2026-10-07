import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/kart_tokens.dart';
import '../../../shared/utils/relative_time.dart';
import '../data/nfc_card_service.dart';
import '../data/nfc_tag_reader.dart';
import '../models/nfc_card_status.dart';
import '../providers/nfc_card_provider.dart';
import '../widgets/nfc_card_widgets.dart';
import '../widgets/nfc_code_sheet.dart';
import '../widgets/nfc_order_sheet.dart';
import '../widgets/nfc_scan_sheet.dart';

/// « Ma carte NFC » : ouvert par l'icône NFC de l'écran Carte. L'écran
/// s'adapte à l'état calculé par le serveur (GET /me/nfc) : aucune carte,
/// commande en cours, carte à activer, carte active, carte désactivée.
///
/// Aucun prix ni paiement ici : la carte se paie à la livraison, hors app.
class MyNfcCardPage extends StatelessWidget {
  /// Téléphone du compte, pour préremplir le formulaire de commande.
  final String? initialPhone;

  /// Ouvre le QR code en plein écran. Le partage par QR ou par lien ne
  /// dépend jamais de l'état NFC.
  final void Function(BuildContext context) onShowQr;

  final NfcCardService service;

  /// Lecture de la puce — remplaçable dans les tests.
  final NfcTagReader reader;

  /// Ouvre un lien externe (WhatsApp) — remplaçable dans les tests.
  final Future<void> Function(Uri uri)? openUrl;

  const MyNfcCardPage({
    super.key,
    required this.onShowQr,
    this.initialPhone,
    this.service = const NfcCardService(),
    this.reader = const DeviceNfcTagReader(),
    this.openUrl,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => NfcCardProvider(service)..load(),
      child: _NfcCardView(
        initialPhone: initialPhone,
        onShowQr: onShowQr,
        reader: reader,
        openUrl: openUrl,
      ),
    );
  }
}

class _NfcCardView extends StatelessWidget {
  final String? initialPhone;
  final void Function(BuildContext context) onShowQr;
  final NfcTagReader reader;
  final Future<void> Function(Uri uri)? openUrl;

  const _NfcCardView({
    required this.onShowQr,
    required this.reader,
    this.initialPhone,
    this.openUrl,
  });

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);
    final provider = context.watch<NfcCardProvider>();
    final status = provider.status;

    return Scaffold(
      backgroundColor: t.pageBackground,
      appBar: AppBar(title: const Text('Ma carte NFC')),
      body: SafeArea(
        child: status == null
            ? (provider.loading
                ? const Center(child: CircularProgressIndicator())
                : _LoadError(
                    message: provider.error ??
                        'Impossible de charger votre carte NFC.',
                    onRetry: provider.load,
                  ))
            : RefreshIndicator(
                onRefresh: provider.load,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: _content(context, status),
                ),
              ),
      ),
    );
  }

  // ───────────── Actions ─────────────

  void _snack(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  /// Ouvre WhatsApp sur le numéro du support renvoyé par le serveur.
  Future<void> _contactSupport(BuildContext context, String number) async {
    final uri = Uri.parse(
      'https://wa.me/$number'
      '?text=${Uri.encodeComponent('Bonjour, j\'ai une question sur ma carte NFC KART.')}',
    );
    try {
      if (openUrl != null) {
        await openUrl!(uri);
      } else {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      if (context.mounted) _snack(context, "WhatsApp n'a pas pu s'ouvrir.");
    }
  }

  Future<void> _order(BuildContext context, NfcCardStatus status) async {
    final provider = context.read<NfcCardProvider>();
    final support = status.supportWhatsapp;

    final ordered = await NfcOrderSheet.show(
      context,
      initialPhone: initialPhone,
      onSubmit: provider.order,
      onContactSupport:
          support == null ? null : () => _contactSupport(context, support),
    );
    if (ordered == true && context.mounted) {
      _snack(context, 'Commande reçue, nous vous contacterons.');
    }
  }

  /// Activation ou réactivation : il faut le code de la carte, preuve qu'on
  /// l'a en main. On propose de taper la carte quand le téléphone le peut ;
  /// sinon (pas de NFC, NFC coupé, lecture impossible), ou si l'utilisateur
  /// le préfère, on passe à la saisie du code imprimé dessus.
  Future<void> _enterCode(
    BuildContext context, {
    String title = 'Activer ma carte',
    String submitLabel = 'Activer',
    String success = 'Votre carte NFC est activée.',
  }) async {
    final provider = context.read<NfcCardProvider>();

    // Toujours la disponibilité D'ABORD : la feuille de lecture (et donc
    // la session NFC) n'est ouverte que si le téléphone peut lire.
    final availability = await reader.availability();
    if (!context.mounted) return;

    if (availability == NfcReaderAvailability.enabled) {
      final result = await NfcScanSheet.show(
        context,
        reader: reader,
        title: title,
        onCode: provider.activate,
      );
      if (!context.mounted) return;
      if (result == NfcScanResult.done) {
        _snack(context, success);
        return;
      }
      // Feuille fermée sans choisir : on n'insiste pas.
      if (result != NfcScanResult.manual) return;
    }

    final done = await NfcCodeSheet.show(
      context,
      title: title,
      submitLabel: submitLabel,
      // Le téléphone a le NFC mais il est coupé : on le dit, la saisie
      // reste possible.
      hint: availability == NfcReaderAvailability.disabled
          ? 'Le NFC est désactivé sur ce téléphone. Activez-le dans les '
              'réglages, ou saisissez le code imprimé sur votre carte.'
          : null,
      onSubmit: provider.activate,
    );
    if (done == true && context.mounted) _snack(context, success);
  }

  Future<void> _disable(BuildContext context) async {
    final t = KartTokens.of(context);
    final provider = context.read<NfcCardProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Désactiver la carte ?'),
        content: const Text(
          "Son lien n'ouvrira plus votre carte de visite. Vous pourrez la "
          'réactiver si vous la retrouvez.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: TextButton.styleFrom(foregroundColor: t.negative),
            child: const Text('Désactiver'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    final error = await provider.disable();
    if (context.mounted) {
      _snack(context, error ?? 'Carte NFC désactivée.');
    }
  }

  // ───────────── Contenu par état ─────────────

  List<Widget> _content(BuildContext context, NfcCardStatus status) {
    final support = status.supportWhatsapp;
    final supportButton = support == null
        ? const <Widget>[]
        : <Widget>[
            const SizedBox(height: 12),
            NfcSupportButton(
              onPressed: () => _contactSupport(context, support),
            ),
          ];

    return switch (status.state) {
      NfcCardState.none => _none(context, status, supportButton),
      NfcCardState.ordered => _ordered(context, status, supportButton),
      NfcCardState.ready => _ready(context, supportButton),
      NfcCardState.active => _active(context, status, supportButton),
      NfcCardState.disabled => _disabled(context, status, supportButton),
    };
  }

  List<Widget> _none(
    BuildContext context,
    NfcCardStatus status,
    List<Widget> supportButton,
  ) {
    final t = KartTokens.of(context);

    return [
      const NfcCardVisual(),
      const SizedBox(height: 24),
      const _Title("Vous n'avez pas encore de carte NFC KART"),
      const SizedBox(height: 16),
      const _Benefit('Un tap suffit'),
      const _Benefit("Pas besoin de l'application pour vous lire"),
      const _Benefit(
        'Toujours à jour : vos changements apparaissent sans changer de carte',
      ),
      if (status.cancelledOrder != null) ...[
        const SizedBox(height: 16),
        _Notice(
          icon: Icons.info_outline_rounded,
          color: t.attention,
          text: 'Votre dernière commande a été annulée.',
        ),
      ],
      const SizedBox(height: 24),
      if (status.hasCard)
        NfcPrimaryButton(
          label: 'Commander ma carte',
          onPressed: () => _order(context, status),
        )
      else
        // La carte NFC pointe vers une carte digitale : il en faut une.
        _Notice(
          icon: Icons.info_outline_rounded,
          color: t.attention,
          text: "Créez d'abord votre carte digitale pour commander une "
              'carte NFC.',
        ),
      if (status.hasCard) ...[
        const SizedBox(height: 4),
        Center(
          child: TextButton(
            onPressed: () => _enterCode(context),
            style: TextButton.styleFrom(foregroundColor: t.textPrimary),
            child: const Text(
              "J'ai déjà une carte",
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
      const SizedBox(height: 16),
      NfcQrReminder(onShowQr: () => onShowQr(context)),
      ...supportButton,
    ];
  }

  List<Widget> _ordered(
    BuildContext context,
    NfcCardStatus status,
    List<Widget> supportButton,
  ) {
    final t = KartTokens.of(context);
    final order = status.order;

    return [
      const _Title('Votre commande est en préparation'),
      const SizedBox(height: 24),
      if (order != null) ...[
        NfcOrderTimeline(order: order),
        const SizedBox(height: 24),
        _Panel(
          children: [
            Text(
              'Livraison',
              style: TextStyle(color: t.textSecondary, fontSize: 12),
            ),
            const SizedBox(height: 6),
            Text(
              order.deliveryPhone,
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              order.deliveryAddress,
              style: TextStyle(color: t.textPrimary, fontSize: 14, height: 1.3),
            ),
          ],
        ),
      ],
      ...supportButton,
    ];
  }

  List<Widget> _ready(BuildContext context, List<Widget> supportButton) {
    final t = KartTokens.of(context);

    return [
      const NfcCardVisual(),
      const SizedBox(height: 24),
      const _Title('Votre carte NFC est arrivée !'),
      const SizedBox(height: 8),
      Text(
        "Voulez-vous l'activer maintenant ? Approchez-la du téléphone, ou "
        "saisissez le code imprimé dessus, pour confirmer que vous l'avez "
        'en main.',
        style: TextStyle(color: t.textSecondary, fontSize: 14, height: 1.4),
      ),
      const SizedBox(height: 24),
      NfcPrimaryButton(
        label: 'Activer',
        onPressed: () => _enterCode(context),
      ),
      const SizedBox(height: 4),
      Center(
        child: TextButton(
          onPressed: () => Navigator.maybePop(context),
          style: TextButton.styleFrom(foregroundColor: t.textSecondary),
          child: const Text('Plus tard', style: TextStyle(fontSize: 14)),
        ),
      ),
      ...supportButton,
    ];
  }

  List<Widget> _active(
    BuildContext context,
    NfcCardStatus status,
    List<Widget> supportButton,
  ) {
    final t = KartTokens.of(context);
    final tag = status.tag;
    final lastTap = tag?.lastTappedAt;

    return [
      const NfcCardVisual(),
      const SizedBox(height: 16),
      Center(child: _StatusPill(label: 'Active', color: t.positive)),
      const SizedBox(height: 24),
      _Panel(
        children: [
          IntrinsicHeight(
            child: Row(
              children: [
                Expanded(
                  child: _Stat(
                    value: '${tag?.tapCount ?? 0}',
                    label: (tag?.tapCount ?? 0) > 1 ? 'taps' : 'tap',
                  ),
                ),
                VerticalDivider(width: 24, thickness: 1, color: t.softBorder),
                Expanded(
                  child: _Stat(
                    value: lastTap == null ? '—' : relativeTimeLabel(lastTap),
                    label: 'dernier tap',
                    small: true,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      if (tag?.code != null) ...[
        const SizedBox(height: 12),
        Text(
          'Code : ${tag!.code}',
          style: TextStyle(
            color: t.textSecondary,
            fontSize: 13,
            letterSpacing: 1,
          ),
        ),
      ],
      const SizedBox(height: 24),
      NfcSecondaryButton(
        label: 'Désactiver (carte perdue)',
        danger: true,
        onPressed: () => _disable(context),
      ),
      ...supportButton,
    ];
  }

  List<Widget> _disabled(
    BuildContext context,
    NfcCardStatus status,
    List<Widget> supportButton,
  ) {
    final t = KartTokens.of(context);
    final canReactivate = status.tag?.canReactivate ?? false;

    return [
      const NfcCardVisual(dimmed: true),
      const SizedBox(height: 16),
      Center(child: _StatusPill(label: 'Carte désactivée', color: t.negative)),
      const SizedBox(height: 12),
      Text(
        "Son lien n'ouvre plus votre carte de visite.",
        textAlign: TextAlign.center,
        style: TextStyle(color: t.textSecondary, fontSize: 14),
      ),
      const SizedBox(height: 24),
      if (canReactivate)
        // Réactiver demande le code de la carte : la preuve qu'on l'a
        // retrouvée.
        NfcPrimaryButton(
          label: 'Réactiver',
          onPressed: () => _enterCode(
            context,
            title: 'Réactiver ma carte',
            submitLabel: 'Réactiver',
            success: 'Votre carte NFC est réactivée.',
          ),
        )
      else
        _Notice(
          icon: Icons.info_outline_rounded,
          color: t.attention,
          text: 'Cette carte a été désactivée par KART. Contactez le '
              'support pour la réactiver.',
        ),
      if (status.hasCard) ...[
        const SizedBox(height: 12),
        NfcSecondaryButton(
          label: 'Commander une nouvelle carte',
          onPressed: () => _order(context, status),
        ),
      ],
      const SizedBox(height: 20),
      NfcQrReminder(onShowQr: () => onShowQr(context)),
      ...supportButton,
    ];
  }
}

// ───────────── Petits éléments de l'écran ─────────────

class _Title extends StatelessWidget {
  final String text;

  const _Title(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: KartTokens.of(context).textPrimary,
        fontSize: 22,
        fontWeight: FontWeight.w700,
        height: 1.2,
      ),
    );
  }
}

class _Benefit extends StatelessWidget {
  final String text;

  const _Benefit(this.text);

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.check_circle_rounded, size: 18, color: t.positive),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(color: t.textPrimary, fontSize: 14, height: 1.3),
            ),
          ),
        ],
      ),
    );
  }
}

/// Encart du design system : fond léger, bordure fine, rayon de 12.
class _Panel extends StatelessWidget {
  final List<Widget> children;

  const _Panel({required this.children});

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: t.softFill,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: t.softBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Notice({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                color: KartTokens.of(context).textPrimary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final String value;
  final String label;
  final bool small;

  const _Stat({required this.value, required this.label, this.small = false});

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          value,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: t.textPrimary,
            fontSize: small ? 15 : 24,
            fontWeight: FontWeight.w700,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: t.textSecondary, fontSize: 12)),
      ],
    );
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 40, color: t.textSecondary),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: t.textPrimary, fontSize: 15, height: 1.4),
            ),
            const SizedBox(height: 20),
            NfcSecondaryButton(label: 'Réessayer', onPressed: onRetry),
          ],
        ),
      ),
    );
  }
}
