import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../shared/widgets/qr_fullscreen_view.dart';
import '../auth/providers/auth_provider.dart';
import '../digital_card/providers/card_provider.dart';
import 'ui/my_nfc_card_page.dart';

/// Route vers « Ma carte NFC », depuis l'icône NFC de l'écran Carte ou
/// depuis une notification (carte prête, commande mise à jour).
Route<void> myNfcCardRoute() {
  return MaterialPageRoute(
    builder: (context) => MyNfcCardPage(
      // Téléphone du compte, pour préremplir le formulaire de commande.
      initialPhone: context.read<AuthProvider>().user?.phone,
      onShowQr: showMyCardQr,
    ),
  );
}

/// QR code de la carte de visite en plein écran — le même que sur l'écran
/// Carte. Le partage par QR ne dépend pas de la carte NFC.
Future<void> showMyCardQr(BuildContext context) async {
  final card = context.read<CardProvider>();
  if (!card.hasQrCode) await card.loadMyCardQr();
  if (!context.mounted) return;

  final svg = card.qrSvg;
  if (svg == null || svg.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('QR code indisponible pour le moment.')),
    );
    return;
  }
  await QrFullscreenView.show(context, SvgPicture.string(svg));
}
