import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/kart_tokens.dart';
import '../../../shared/widgets/auth_primary_button.dart';
import '../../../shared/widgets/legal_consent_checkbox.dart';
import '../providers/auth_provider.dart';

/// Affiché à la connexion quand /me renvoie consent_required : comptes
/// créés avant la case, par l'admin ou la commande NFC, par Google/Apple,
/// ou nouvelle version d'un texte. On peut accepter ou se déconnecter ;
/// le serveur, lui, ne bloque rien.
class ConsentPage extends StatefulWidget {
  const ConsentPage({super.key});

  @override
  State<ConsentPage> createState() => _ConsentPageState();
}

class _ConsentPageState extends State<ConsentPage> {
  bool _accepted = false;
  bool _sending = false;

  Future<void> _submit() async {
    setState(() => _sending = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.acceptConsents();
    if (!mounted) return;
    setState(() => _sending = false);

    if (ok) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Impossible d'enregistrer votre accord. Réessayez."),
      ));
    }
  }

  Future<void> _logout() async {
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Avant de continuer',
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: t.textPrimary,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Pour utiliser KART, merci de lire et d\'accepter notre '
                  'politique de confidentialité et nos conditions d\'utilisation.',
                  style: TextStyle(color: t.textSecondary, fontSize: 15, height: 1.5),
                ),
                const SizedBox(height: 28),
                LegalConsentCheckbox(
                  value: _accepted,
                  onChanged: (v) => setState(() => _accepted = v),
                ),
                const Spacer(),
                AuthPrimaryButton(
                  key: const Key('consent-submit'),
                  label: 'Continuer',
                  loading: _sending,
                  onTap: _accepted && !_sending ? _submit : null,
                ),
                const SizedBox(height: 8),
                Center(
                  child: TextButton(
                    onPressed: _sending ? null : _logout,
                    child: Text('Se déconnecter', style: TextStyle(color: t.textSecondary)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
