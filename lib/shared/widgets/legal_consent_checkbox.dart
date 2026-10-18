import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/kart_tokens.dart';

/// Pages de la politique de confidentialité et des CGU sur le site. Le
/// contenu et la version vivent côté serveur (legal_documents) : un
/// nouveau texte ne demande pas de nouvelle version de l'app.
const kPrivacyUrl = 'https://kart.business/privacy';
const kTermsUrl = 'https://kart.business/terms';

/// Case « J'accepte la politique de confidentialité et les CGU », jamais
/// pré-cochée, avec les deux liens qui s'ouvrent dans le navigateur.
class LegalConsentCheckbox extends StatefulWidget {
  const LegalConsentCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    this.privacyUrl = kPrivacyUrl,
    this.termsUrl = kTermsUrl,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final String privacyUrl;
  final String termsUrl;

  @override
  State<LegalConsentCheckbox> createState() => _LegalConsentCheckboxState();
}

class _LegalConsentCheckboxState extends State<LegalConsentCheckbox> {
  late final _privacy = TapGestureRecognizer()..onTap = () => _open(widget.privacyUrl);
  late final _terms = TapGestureRecognizer()..onTap = () => _open(widget.termsUrl);

  Future<void> _open(String url) =>
      launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

  @override
  void dispose() {
    _privacy.dispose();
    _terms.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);
    final link = TextStyle(
      color: t.textPrimary,
      fontWeight: FontWeight.w600,
      decoration: TextDecoration.underline,
    );

    return InkWell(
      key: const Key('legal-consent'),
      borderRadius: BorderRadius.circular(8),
      onTap: () => widget.onChanged(!widget.value),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 24,
              height: 24,
              child: Checkbox(
                value: widget.value,
                onChanged: (v) => widget.onChanged(v ?? false),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text.rich(
                TextSpan(
                  style: TextStyle(color: t.textSecondary, fontSize: 13, height: 1.45),
                  children: [
                    const TextSpan(text: "J'accepte la "),
                    TextSpan(text: 'politique de confidentialité', style: link, recognizer: _privacy),
                    const TextSpan(text: ' et les '),
                    TextSpan(text: "conditions d'utilisation", style: link, recognizer: _terms),
                    const TextSpan(text: ' de KART.'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
