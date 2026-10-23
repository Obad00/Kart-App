import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/ui/feedback/feedback_overlay.dart';
import '../../../shared/widgets/glass_dialog.dart';
import '../models/event_invitation.dart';
import '../services/event_invitations_service.dart';

/// Les deux envois d'une invitation. Le lien wa.me et le message viennent
/// du backend ; /send ne fait que suivre le statut : s'il échoue, l'envoi
/// n'est jamais bloqué, seul le statut prend du retard.
class InvitationSender {
  final EventInvitationsService service;
  final int eventId;

  /// Ouverture d'un lien dans l'application externe (WhatsApp).
  final Future<bool> Function(Uri uri) openExternal;

  /// Feuille de partage du système (image + texte).
  final Future<ShareResultStatus> Function(ShareParams params) share;

  /// Dossier où l'image est enregistrée avant le partage.
  final Future<Directory> Function() tempDir;

  InvitationSender({
    required this.service,
    required this.eventId,
    Future<bool> Function(Uri uri)? openExternal,
    Future<ShareResultStatus> Function(ShareParams params)? share,
    Future<Directory> Function()? tempDir,
  })  : openExternal = openExternal ??
            ((uri) => launchUrl(uri, mode: LaunchMode.externalApplication)),
        share = share ??
            ((params) async => (await SharePlus.instance.share(params)).status),
        tempDir = tempDir ?? getTemporaryDirectory;

  /// « Envoyer sur WhatsApp » (et « Relancer », « Envoyer au suivant »).
  /// Renvoie true si WhatsApp a été ouvert.
  Future<bool> sendWhatsApp(BuildContext context, EventInvitation invitation) async {
    final opened = await _openWhatsApp(context, invitation);
    if (!opened) return false;
    if (context.mounted) await _markSent(context, invitation);
    return true;
  }

  /// « Partager l'invitation » : l'image portrait, avec le message.
  Future<void> shareInvitation(BuildContext context, EventInvitation invitation) async {
    final File file;
    try {
      final bytes = await service.image(eventId, invitation.id);
      final dir = await tempDir();
      file = File('${dir.path}/invitation-${invitation.id}.png');
      await file.writeAsBytes(bytes, flush: true);
    } catch (e) {
      if (context.mounted) {
        FeedbackOverlay.showError(
          context,
          title: 'Invitation indisponible',
          subtitle: EventInvitationsService.errorMessage(e,
              fallback: "L'image n'a pas pu être téléchargée. Réessayez."),
        );
      }
      return;
    }

    ShareResultStatus status;
    try {
      status = await share(ShareParams(
        files: [XFile(file.path, mimeType: 'image/png')],
        text: invitation.message,
      ));
    } catch (e) {
      if (context.mounted) {
        FeedbackOverlay.showError(
          context,
          title: 'Erreur',
          subtitle: "Impossible d'ouvrir le partage.",
        );
      }
      return;
    }
    // Annulé : rien n'est parti, le statut ne bouge pas.
    if (status == ShareResultStatus.dismissed || !context.mounted) return;
    await _markSent(context, invitation);

    // Sur iPhone, WhatsApp ignore souvent le texte joint à une image : le
    // lien de confirmation risque de ne jamais arriver sans ce second envoi.
    if (defaultTargetPlatform != TargetPlatform.iOS ||
        invitation.whatsappUrl == null ||
        !context.mounted) {
      return;
    }
    final again = await GlassDialog.confirm(
      context,
      title: 'Envoyer aussi le message ?',
      message:
          "Sur iPhone, WhatsApp n'envoie souvent que l'image. Envoyez le message pour que ${invitation.firstName.isEmpty ? "l'invité" : invitation.firstName} reçoive son lien de confirmation.",
      cancelLabel: 'Plus tard',
      confirmLabel: 'Envoyer le message',
      isDestructive: false,
    );
    if (again && context.mounted) await _openWhatsApp(context, invitation);
  }

  Future<bool> _openWhatsApp(BuildContext context, EventInvitation invitation) async {
    final url = invitation.whatsappUrl;
    var opened = false;
    if (url != null && url.isNotEmpty) {
      try {
        opened = await openExternal(Uri.parse(url));
      } catch (_) {
        opened = false;
      }
    }
    if (!opened && context.mounted) {
      FeedbackOverlay.showError(
        context,
        title: 'WhatsApp indisponible',
        subtitle: url == null
            ? "Le lien de cet invité n'est pas encore prêt : actualisez la liste."
            : "WhatsApp n'a pas pu être ouvert sur ce téléphone.",
      );
    }
    return opened;
  }

  Future<void> _markSent(BuildContext context, EventInvitation invitation) async {
    try {
      await service.markSent(eventId, invitation.id);
    } catch (_) {
      if (!context.mounted) return;
      FeedbackOverlay.showInfo(
        context,
        title: 'Statut non mis à jour',
        subtitle:
            "L'invitation est partie, mais son statut n'a pas pu être mis à jour.",
      );
    }
  }
}
