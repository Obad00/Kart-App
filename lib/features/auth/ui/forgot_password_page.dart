import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../../shared/widgets/auth_primary_button.dart';

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _emailCtrl = TextEditingController();
  bool _sent = false;

  bool _isFormValid() => _emailCtrl.text.contains('@');

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    final success = await auth.forgotPassword(_emailCtrl.text.trim());

    if (!mounted) return;

    // Comportement neutre : on affiche le même message de confirmation
    // qu'un compte existe ou non avec cet email (anti-énumération).
    if (success || auth.error == null) {
      setState(() => _sent = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Mot de passe oublié',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Indiquez votre adresse email, nous vous enverrons un lien pour le réinitialiser.',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 40),
              if (_sent) ...[
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.check_circle_outline_rounded,
                          color: Colors.green[300], size: 22),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          "Si un compte existe avec cet email, un lien de réinitialisation vient d'être envoyé. Vérifiez votre boîte de réception (et vos spams).",
                          style: TextStyle(color: Colors.green[100], fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                AuthPrimaryButton(
                  label: 'Retour à la connexion',
                  onTap: () => Navigator.pop(context),
                ),
              ] else ...[
                AuthTextField(
                  label: 'Email',
                  hint: 'votre@email.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.mail_outline_rounded,
                  onChanged: (_) => setState(() {}),
                ),
                if (auth.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            color: Colors.red[300],
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              auth.error!,
                              style: TextStyle(
                                color: Colors.red[300],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                const SizedBox(height: 32),
                AuthPrimaryButton(
                  label: 'Envoyer le lien',
                  icon: Icons.arrow_forward_rounded,
                  loading: auth.isLoading,
                  onTap: _isFormValid() ? () => _submit(auth) : null,
                ),
              ],
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
