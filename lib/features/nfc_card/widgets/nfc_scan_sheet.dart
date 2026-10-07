import 'package:flutter/material.dart';

import '../../../core/theme/kart_tokens.dart';
import '../data/nfc_tag_reader.dart';
import '../utils/nfc_code.dart';

/// Résultat de la feuille « Approchez votre carte ».
enum NfcScanResult {
  /// La carte a été lue et acceptée par le serveur.
  done,

  /// L'utilisateur préfère saisir le code, ou la lecture est impossible.
  manual,
}

/// « Approchez votre carte du téléphone » : lit le lien gravé sur la puce
/// et en tire le code. Taper la carte prouve qu'on l'a en main.
///
/// [onCode] envoie le code au serveur et renvoie un message d'erreur à
/// afficher, ou null en cas de succès.
class NfcScanSheet extends StatefulWidget {
  final NfcTagReader reader;
  final String title;
  final Future<String?> Function(String code) onCode;

  const NfcScanSheet({
    super.key,
    required this.reader,
    required this.onCode,
    this.title = 'Activer ma carte',
  });

  static Future<NfcScanResult?> show(
    BuildContext context, {
    required NfcTagReader reader,
    required Future<String?> Function(String code) onCode,
    String title = 'Activer ma carte',
  }) {
    return showModalBottomSheet<NfcScanResult>(
      context: context,
      backgroundColor: KartTokens.of(context).sheetBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NfcScanSheet(reader: reader, onCode: onCode, title: title),
    );
  }

  @override
  State<NfcScanSheet> createState() => _NfcScanSheetState();
}

class _NfcScanSheetState extends State<NfcScanSheet> {
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    widget.reader.start(onRead: _onRead, onError: _onReaderError);
  }

  @override
  void dispose() {
    widget.reader.stop();
    super.dispose();
  }

  Future<void> _onRead(String? link) async {
    if (!mounted || _busy) return;

    final code = extractNfcCode(link);
    if (code == null || code.length != nfcCodeLength) {
      setState(() => _error = "Cette carte n'est pas une carte NFC KART.");
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.onCode(code);
    if (!mounted) return;

    if (error == null) {
      await widget.reader.stop(message: 'Carte reconnue');
      if (mounted) Navigator.pop(context, NfcScanResult.done);
    } else {
      // On reste à l'écoute : l'utilisateur peut présenter une autre carte.
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  /// La lecture s'est arrêtée (refusée, ou fermée par le téléphone) : la
  /// saisie du code prend le relais.
  void _onReaderError() {
    if (mounted) Navigator.pop(context, NfcScanResult.manual);
  }

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: t.softFill,
                shape: BoxShape.circle,
                border: Border.all(color: t.softBorder),
              ),
              child: _busy
                  ? Padding(
                      padding: const EdgeInsets.all(30),
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: t.textPrimary,
                      ),
                    )
                  : Icon(
                      Icons.contactless_outlined,
                      size: 44,
                      color: t.textPrimary,
                    ),
            ),
            const SizedBox(height: 20),
            Text(
              'Approchez votre carte du téléphone',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Posez-la contre le dos du téléphone et attendez un instant.",
              textAlign: TextAlign.center,
              style: TextStyle(color: t.textSecondary, fontSize: 13),
            ),
            if (_error != null) ...[
              const SizedBox(height: 14),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(color: t.negative, fontSize: 13, height: 1.3),
              ),
            ],
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => Navigator.pop(context, NfcScanResult.manual),
              style: TextButton.styleFrom(foregroundColor: t.textPrimary),
              child: const Text(
                'Saisir le code',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
