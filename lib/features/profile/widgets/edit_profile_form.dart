import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../auth/providers/auth_provider.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../../shared/widgets/auth_primary_button.dart';

class EditProfileForm extends StatefulWidget {
  const EditProfileForm({super.key});

  @override
  State<EditProfileForm> createState() => _EditProfileFormState();
}

class _EditProfileFormState extends State<EditProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _firstnameCtrl = TextEditingController();
  final _lastnameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordConfirmCtrl = TextEditingController();

  bool _isLoading = false;
  bool _showPassword = false;
  String? _successMessage;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _initializeFields();
  }

  void _initializeFields() {
    final auth = context.read<AuthProvider>();
    final user = auth.user;

    if (user != null) {
      _firstnameCtrl.text = user.firstname;
      _lastnameCtrl.text = user.lastname;
      _phoneCtrl.text = user.phone ?? '';
      _emailCtrl.text = user.email;
    }
  }

  @override
  void dispose() {
    _firstnameCtrl.dispose();
    _lastnameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _successMessage = null;
      _errorMessage = null;
    });

    final auth = context.read<AuthProvider>();

    // Verifier que les mots de passe correspondent
    if (_passwordCtrl.text.isNotEmpty &&
        _passwordCtrl.text != _passwordConfirmCtrl.text) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Les mots de passe ne correspondent pas';
      });
      return;
    }

    final success = await auth.updateProfile(
      firstname: _firstnameCtrl.text.trim(),
      lastname: _lastnameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text.isNotEmpty ? _passwordCtrl.text : null,
      passwordConfirmation: _passwordConfirmCtrl.text.isNotEmpty
          ? _passwordConfirmCtrl.text
          : null,
    );

    if (!mounted) return;

    setState(() {
      _isLoading = false;
      if (success) {
        _successMessage = 'Les modifications ont ete enregistrees avec succes';
        // Effacer les champs de mot de passe apres la mise a jour
        _passwordCtrl.clear();
        _passwordConfirmCtrl.clear();
      } else {
        _errorMessage = auth.error ?? 'Une erreur est survenue';
      }
    });

    // Fermer apres 2 secondes si succes
    if (success) {
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: colors.onSurface.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: colors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.edit_outlined,
                      color: colors.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  const Text(
                    'Modifier mon profil',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                'Modifiez vos informations personnelles',
                style: TextStyle(
                  fontSize: 14,
                  color: colors.onSurface.withValues(alpha: 0.6),
                ),
              ),

              const SizedBox(height: 24),

              // Messages de succes/erreur
              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: Colors.green,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(
                            color: Colors.green,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Section Informations personnelles
              _buildSectionTitle('Informations personnelles'),
              const SizedBox(height: 12),

              AuthTextField(
                label: 'Prénom',
                controller: _firstnameCtrl,
                prefixIcon: Icons.person_outline,
                hint: 'Votre prénom',
              ),

              const SizedBox(height: 16),

              AuthTextField(
                label: 'Nom',
                controller: _lastnameCtrl,
                prefixIcon: Icons.person_outline,
                hint: 'Votre nom',
              ),

              const SizedBox(height: 16),

              AuthTextField(
                label: 'Numero de telephone',
                controller: _phoneCtrl,
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                hint: 'Ex: +221 77 123 45 67',
              ),

              const SizedBox(height: 16),

              AuthTextField(
                label: 'Adresse email',
                controller: _emailCtrl,
                prefixIcon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                hint: 'Ex: votre@email.com',
              ),

              const SizedBox(height: 24),

              // Section Mot de passe
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildSectionTitle('Modifier le mot de passe'),
                  TextButton.icon(
                    onPressed: () {
                      setState(() => _showPassword = !_showPassword);
                    },
                    icon: Icon(
                      _showPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      size: 18,
                    ),
                    label: Text(_showPassword ? 'Masquer' : 'Afficher'),
                    style: TextButton.styleFrom(
                      foregroundColor: colors.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Text(
                'Laissez vide si vous ne souhaitez pas changer le mot de passe',
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurface.withValues(alpha: 0.5),
                ),
              ),

              const SizedBox(height: 12),

              if (_showPassword) ...[
                AuthTextField(
                  label: 'Nouveau mot de passe',
                  controller: _passwordCtrl,
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  hint: 'Entrez un nouveau mot de passe',
                ),

                const SizedBox(height: 16),

                AuthTextField(
                  label: 'Confirmer le mot de passe',
                  controller: _passwordConfirmCtrl,
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  hint: 'Confirmez le nouveau mot de passe',
                ),

                const SizedBox(height: 24),
              ],

              // Bouton de soumission
              AuthPrimaryButton(
                label: 'Enregistrer les modifications',
                loading: _isLoading,
                onTap: _submit,
                icon: Icons.check_rounded,
              ),

              const SizedBox(height: 16),

              // Bouton annuler
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Annuler',
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ),
              ),

              // Padding pour le clavier
              SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.onSurface,
        letterSpacing: 0.3,
      ),
    );
  }
}
