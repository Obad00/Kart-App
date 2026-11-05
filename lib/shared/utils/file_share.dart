import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/ui/feedback/feedback_overlay.dart';

/// Écrit [bytes] dans un fichier temporaire, ouvre la feuille de partage
/// (Enregistrer, WhatsApp, Imprimer…) puis confirme par le message de
/// succès habituel, sauf si la personne a fermé la feuille sans rien faire.
Future<void> shareDownloadedFile(
  BuildContext context, {
  required Uint8List bytes,
  required String fileName,
  required String format,
  required String subject,
  required String successTitle,
  required String successSubtitle,
}) async {
  final directory = await getTemporaryDirectory();
  final file = File('${directory.path}/$fileName.$format');
  await file.writeAsBytes(bytes);
  final result = await SharePlus.instance.share(ShareParams(
    files: [XFile(file.path, mimeType: format == 'pdf' ? 'application/pdf' : 'image/png')],
    subject: subject,
  ));
  if (result.status == ShareResultStatus.dismissed || !context.mounted) return;
  FeedbackOverlay.showSuccess(context, title: successTitle, subtitle: successSubtitle);
}
