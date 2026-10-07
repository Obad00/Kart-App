import 'package:flutter/material.dart';

import '../../../core/theme/kart_tokens.dart';
import 'nfc_card_widgets.dart';

/// Formulaire de commande d'une carte NFC : téléphone, adresse de
/// livraison, notes. Aucun prix ni paiement dans l'app — KART recontacte
/// l'utilisateur. Une carte par commande ; pour en vouloir plusieurs, on
/// passe par le support.
///
/// [onSubmit] renvoie un message d'erreur à afficher, ou null en cas de
/// succès (la feuille se ferme alors en renvoyant true).
class NfcOrderSheet extends StatefulWidget {
  final String? initialPhone;
  final Future<String?> Function({
    required String phone,
    required String address,
    String? notes,
  }) onSubmit;

  /// Ouvre le support WhatsApp ; null si aucun numéro n'est configuré (le
  /// lien « Besoin de plusieurs cartes ? » est alors masqué).
  final VoidCallback? onContactSupport;

  const NfcOrderSheet({
    super.key,
    required this.onSubmit,
    this.initialPhone,
    this.onContactSupport,
  });

  static Future<bool?> show(
    BuildContext context, {
    required Future<String?> Function({
      required String phone,
      required String address,
      String? notes,
    }) onSubmit,
    String? initialPhone,
    VoidCallback? onContactSupport,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: KartTokens.of(context).sheetBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => NfcOrderSheet(
        onSubmit: onSubmit,
        initialPhone: initialPhone,
        onContactSupport: onContactSupport,
      ),
    );
  }

  @override
  State<NfcOrderSheet> createState() => _NfcOrderSheetState();
}

class _NfcOrderSheetState extends State<NfcOrderSheet> {
  final _formKey = GlobalKey<FormState>();
  late final _phone = TextEditingController(text: widget.initialPhone ?? '');
  final _address = TextEditingController();
  final _notes = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _phone.dispose();
    _address.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    final error = await widget.onSubmit(
      phone: _phone.text.trim(),
      address: _address.text.trim(),
      notes: _notes.text.trim(),
    );
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

  InputDecoration _decoration(KartTokens t, String label, IconData icon) {
    OutlineInputBorder border(Color color) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: color),
        );

    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: t.textSecondary),
      prefixIcon: Icon(icon, color: t.textSecondary),
      filled: true,
      fillColor: t.softFill,
      border: border(t.softBorder),
      enabledBorder: border(t.softBorder),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);
    final fieldStyle = TextStyle(color: t.textPrimary, fontSize: 15);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          20,
          20,
          MediaQuery.of(context).viewInsets.bottom + 20,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Commander ma carte',
                  style: TextStyle(
                    color: t.textPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Nous vous contacterons pour la livraison.',
                  style: TextStyle(color: t.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phone,
                  keyboardType: TextInputType.phone,
                  maxLength: 30,
                  style: fieldStyle,
                  decoration: _decoration(t, 'Téléphone', Icons.phone_outlined)
                      .copyWith(counterText: ''),
                  validator: (value) =>
                      (value == null || value.trim().length < 6)
                          ? 'Indiquez un numéro où vous joindre.'
                          : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _address,
                  maxLength: 500,
                  minLines: 2,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  style: fieldStyle,
                  decoration: _decoration(
                    t,
                    'Adresse de livraison',
                    Icons.location_on_outlined,
                  ).copyWith(counterText: ''),
                  validator: (value) => (value == null || value.trim().isEmpty)
                      ? "Indiquez l'adresse de livraison."
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _notes,
                  maxLength: 1000,
                  minLines: 1,
                  maxLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  style: fieldStyle,
                  decoration: _decoration(
                    t,
                    'Notes (facultatif)',
                    Icons.notes_rounded,
                  ).copyWith(counterText: ''),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _error!,
                    style: TextStyle(color: t.negative, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 16),
                NfcPrimaryButton(
                  label: 'Envoyer ma commande',
                  busy: _busy,
                  onPressed: _submit,
                ),
                if (widget.onContactSupport != null) ...[
                  const SizedBox(height: 8),
                  Center(
                    child: TextButton(
                      onPressed: widget.onContactSupport,
                      style: TextButton.styleFrom(
                        foregroundColor: t.textSecondary,
                      ),
                      child: const Text(
                        'Besoin de plusieurs cartes ? Contactez-nous',
                        style: TextStyle(fontSize: 13),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
