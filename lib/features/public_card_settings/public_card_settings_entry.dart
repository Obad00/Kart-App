import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../auth/providers/auth_provider.dart';
import '../digital_card/providers/card_provider.dart';
import '../profile/ui/profile_page.dart' show showBrandingEditor;
import '../profile_completion/ui/completion_form_page.dart';
import '../../shared/widgets/color_picker_field.dart' show showKartColorPicker;
import 'ui/public_card_settings_page.dart';
import 'widgets/public_card_thumbnail.dart' show PreviewIdentity;

/// Route vers « Personnaliser ma carte publique », depuis le bouton de la
/// face infos de l'écran Carte.
Route<void> publicCardSettingsRoute() {
  return MaterialPageRoute(
    builder: (context) {
      final user = context.read<AuthProvider>().user;
      final card = context.read<CardProvider>();

      return PublicCardSettingsPage(
        identity: PreviewIdentity(
          fullName: '${user?.firstname ?? ''} ${user?.lastname ?? ''}'.trim(),
          jobTitle: card.jobTitle ?? '',
          company: card.company ?? '',
          city: card.city ?? '',
        ),
        fallbackActivatedFields: card.activatedFields ?? const [],
        onOpenUrl: (url) =>
            launchUrl(url, mode: LaunchMode.externalApplication),
        // Formulaire existant (le même que depuis le Profil).
        onEditInfo: (context) => showModalBottomSheet<void>(
          context: context,
          backgroundColor: Colors.transparent,
          isScrollControlled: true,
          builder: (_) => const CompletionFormPage(),
        ),
        // Feuille « Couleur et logo » existante.
        onEditLogo: showBrandingEditor,
        // Sélecteur de couleur libre existant.
        onPickColor: showKartColorPicker,
        // L'écran Carte relit la carte : sa face infos suit la visibilité
        // qui vient d'être enregistrée.
        onSaved: card.loadCardSummary,
      );
    },
  );
}
