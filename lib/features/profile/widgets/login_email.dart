import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/feedback/feedback_overlay.dart';
import '../../../shared/utils/placeholder_email.dart';
import '../../../shared/widgets/auth_primary_button.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../../shared/widgets/glass_sheet.dart';
import '../../auth/providers/auth_provider.dart';

/// Email de connexion (users.email), distinct de l'email affiché sur la
/// carte. Visible et modifiable depuis Paramètres → Compte et depuis
/// « Modifier la carte » (cf. [LoginEmailNotice]) : les deux ouvrent
/// [showLoginEmailSheet].
Future<void> showLoginEmailSheet(BuildContext context) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: true,
    builder: (_) => GlassSheet(child: _LoginEmailSheet(hostContext: context)),
  );
}

class _LoginEmailSheet extends StatefulWidget {
  const _LoginEmailSheet({required this.hostContext});

  /// Écran qui a ouvert la fenêtre : il affiche le message de succès.
  final BuildContext hostContext;

  @override
  State<_LoginEmailSheet> createState() => _LoginEmailSheetState();
}

class _LoginEmailSheetState extends State<_LoginEmailSheet> {
  late final TextEditingController _emailCtrl;
  String? _error;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _emailCtrl = TextEditingController(
      text: displayableEmail(context.read<AuthProvider>().user?.email) ?? '',
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    final email = _emailCtrl.text.trim();
    if (email.toLowerCase() == (auth.user?.email ?? '').toLowerCase()) {
      Navigator.of(context).pop();
      return;
    }
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      setState(() => _error = 'Saisissez une adresse email valide.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });
    final error = await auth.changeLoginEmail(email);
    if (!mounted) return;
    if (error != null) {
      setState(() {
        _saving = false;
        _error = error;
      });
      return;
    }

    Navigator.of(context).pop();
    if (!widget.hostContext.mounted) return;
    FeedbackOverlay.showSuccess(
      widget.hostContext,
      title: 'Email de connexion modifié',
      subtitle: 'Un lien de vérification a été envoyé à $email.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 20),
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Text(
            'Email de connexion',
            style: TextStyle(fontFamily: 'Syne', fontSize: 22, fontWeight: FontWeight.w700, color: colors.onSurface),
          ),
          const SizedBox(height: 8),
          Text(
            'C\'est l\'adresse avec laquelle vous vous connectez. Elle n\'est pas affichée sur votre carte. '
            'Une nouvelle adresse doit être confirmée : un lien vous sera envoyé.',
            style: TextStyle(fontSize: 14, height: 1.4, color: colors.onSurface.withValues(alpha: 0.65)),
          ),
          const SizedBox(height: 20),
          AuthTextField(
            key: const Key('login-email-field'),
            label: 'Email de connexion',
            controller: _emailCtrl,
            prefixIcon: Icons.alternate_email,
            keyboardType: TextInputType.emailAddress,
            hint: 'votre@email.com',
            errorText: _error,
          ),
          const SizedBox(height: 20),
          AuthPrimaryButton(
            key: const Key('login-email-save'),
            label: 'Enregistrer',
            loading: _saving,
            onTap: _saving ? null : _save,
          ),
        ],
      ),
    );
  }
}

/// Sous « Email affiché sur la carte » : rappelle l'email de connexion,
/// permet de le modifier, et de le reprendre sur la carte s'il diffère.
class LoginEmailNotice extends StatelessWidget {
  const LoginEmailNotice({super.key, required this.cardEmail, required this.onUseOnCard});

  final TextEditingController cardEmail;
  final ValueChanged<String> onUseOnCard;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final loginEmail = displayableEmail(context.watch<AuthProvider>().user?.email);
    final muted = TextStyle(fontSize: 13, color: colors.onSurface.withValues(alpha: 0.6));

    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: cardEmail,
      builder: (context, value, _) {
        final differs = loginEmail != null && value.text.trim().toLowerCase() != loginEmail.toLowerCase();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text(loginEmail == null ? 'Aucun email de connexion' : 'Vous vous connectez avec ', style: muted),
                if (loginEmail != null)
                  Text(loginEmail,
                      key: const Key('login-email-value'),
                      style: muted.copyWith(fontWeight: FontWeight.w700, color: colors.onSurface.withValues(alpha: 0.8))),
                Text(' · ', style: muted),
                InkWell(
                  key: const Key('login-email-edit'),
                  onTap: () => showLoginEmailSheet(context),
                  child: Text(
                    loginEmail == null ? 'Ajouter' : 'Modifier',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: colors.primary),
                  ),
                ),
              ],
            ),
            if (differs)
              TextButton.icon(
                key: const Key('login-email-use-on-card'),
                style: TextButton.styleFrom(padding: EdgeInsets.zero, visualDensity: VisualDensity.compact),
                onPressed: () => onUseOnCard(loginEmail),
                icon: const Icon(Icons.content_copy_rounded, size: 16),
                label: const Text('Utiliser cet email sur ma carte'),
              ),
          ],
        );
      },
    );
  }
}
