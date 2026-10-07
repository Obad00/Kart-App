import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/kart_tokens.dart';
import '../utils/nfc_code.dart';
import 'nfc_card_widgets.dart';

/// Saisie manuelle du code imprimé sur la carte NFC — pour un téléphone
/// sans NFC, ou quand la lecture de la puce échoue.
///
/// [onSubmit] envoie le code et renvoie un message d'erreur à afficher sous
/// le champ, ou null en cas de succès (la feuille se ferme alors en
/// renvoyant true).
class NfcCodeSheet extends StatefulWidget {
  final String title;
  final String submitLabel;

  /// Texte sous le titre, à la place de l'explication par défaut (ex. NFC
  /// coupé sur le téléphone).
  final String? hint;
  final Future<String?> Function(String code) onSubmit;

  const NfcCodeSheet({
    super.key,
    required this.onSubmit,
    this.title = 'Saisir le code',
    this.submitLabel = 'Activer',
    this.hint,
  });

  static Future<bool?> show(
    BuildContext context, {
    required Future<String?> Function(String code) onSubmit,
    String title = 'Saisir le code',
    String submitLabel = 'Activer',
    String? hint,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KartTokens.of(context).sheetBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NfcCodeSheet(
        onSubmit: onSubmit,
        title: title,
        submitLabel: submitLabel,
        hint: hint,
      ),
    );
  }

  @override
  State<NfcCodeSheet> createState() => _NfcCodeSheetState();
}

class _NfcCodeSheetState extends State<NfcCodeSheet> {
  final _controller = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final code = extractNfcCode(_controller.text);
    if (code == null || code.length != nfcCodeLength) {
      setState(() => _error = 'Le code fait $nfcCodeLength caractères.');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.onSubmit(code);
    if (!mounted) return;

    if (error == null) {
      Navigator.pop(context, true);
    } else {
      setState(() {
        _busy = false;
        _error = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.title,
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              widget.hint ?? 'Le code est imprimé sur votre carte NFC.',
              style: TextStyle(
                color: t.textSecondary,
                fontSize: 13,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              autocorrect: false,
              enableSuggestions: false,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9 ]')),
                // Quelques espaces tolérés (« ABCD 2345 »).
                LengthLimitingTextInputFormatter(nfcCodeLength + 3),
              ],
              style: TextStyle(
                color: t.textPrimary,
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: 3,
              ),
              decoration: InputDecoration(
                hintText: 'ABCD2345',
                hintStyle: TextStyle(
                  color: t.textSecondary.withValues(alpha: 0.5),
                  letterSpacing: 3,
                ),
                prefixIcon:
                    Icon(Icons.pin_outlined, color: t.textSecondary),
                filled: true,
                fillColor: t.softFill,
                errorText: _error,
                errorMaxLines: 3,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.softBorder),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: t.softBorder),
                ),
              ),
            ),
            const SizedBox(height: 16),
            NfcPrimaryButton(
              label: widget.submitLabel,
              busy: _busy,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}
