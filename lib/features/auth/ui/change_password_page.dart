import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../../shared/widgets/auth_primary_button.dart';

/// Écran de changement de mot de passe volontaire, accessible depuis
/// Profil > Réglages. Contrairement à [ForceChangePasswordPage], l'utilisateur
/// peut revenir en arrière et n'est pas redirigé après succès.
class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _currentPasswordCtrl.text.isNotEmpty &&
      _newPasswordCtrl.text.length >= 8 &&
      _newPasswordCtrl.text == _confirmPasswordCtrl.text;

  Future<void> _submit() async {
    if (!_isValid) return;
    setState(() => _isSubmitting = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.changePassword(
      currentPassword: _currentPasswordCtrl.text,
      newPassword: _newPasswordCtrl.text,
      newPasswordConfirmation: _confirmPasswordCtrl.text,
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Mot de passe mis à jour avec succès.')),
      );
      Navigator.pop(context);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Une erreur est survenue'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              const Text(
                'Changer le mot de passe',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Saisissez votre mot de passe actuel puis choisissez-en un nouveau.',
                style: TextStyle(color: Colors.grey[400], fontSize: 15),
              ),
              const SizedBox(height: 32),
              AuthTextField(
                label: 'Mot de passe actuel',
                controller: _currentPasswordCtrl,
                obscureText: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: 'Nouveau mot de passe',
                controller: _newPasswordCtrl,
                obscureText: true,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),
              AuthTextField(
                label: 'Confirmer le nouveau mot de passe',
                controller: _confirmPasswordCtrl,
                obscureText: true,
                matchController: _newPasswordCtrl,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 32),
              AuthPrimaryButton(
                label: 'Mettre à jour',
                icon: Icons.check_rounded,
                loading: _isSubmitting,
                onTap: _isValid ? _submit : null,
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
