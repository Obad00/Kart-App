import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../../shared/widgets/auth_primary_button.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  bool _isFormValid() =>
      _emailCtrl.text.contains('@') && _passwordCtrl.text.length >= 6;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    ));

    _animController.forward();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit(AuthProvider auth) async {
    await auth.login(
      _emailCtrl.text.trim(),
      _passwordCtrl.text.trim(),
    );

    if (!mounted) return;

    if (auth.isAuthenticated) {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 28,
                right: 28,
                top: 32,
                bottom: bottomPadding > 0 ? bottomPadding + 32 : 32,
              ),
              child: Column(
                children: [
                  // Logo / Brand
                  _buildLogo(),

                  const SizedBox(height: 56),

                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.03),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.08),
                        width: 1,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        const Text(
                          'Connexion',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                            letterSpacing: -0.5,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          'Accédez à votre carte digitale',
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 15,
                          ),
                        ),

                        const SizedBox(height: 32),

                        // Email
                        AuthTextField(
                          label: 'Email',
                          hint: 'votre@email.com',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.mail_outline_rounded,
                          onChanged: (_) => setState(() {}),
                        ),

                        const SizedBox(height: 24),

                        // Password
                        AuthTextField(
                          label: 'Mot de passe',
                          hint: '••••••••',
                          controller: _passwordCtrl,
                          obscureText: true,
                          prefixIcon: Icons.lock_outline_rounded,
                          onChanged: (_) => setState(() {}),
                        ),

                        // Error message
                        if (auth.error != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 20),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: auth.error == 'Compte inactif'
                                    ? Colors.orange.withValues(alpha: 0.1)
                                    : Colors.red.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: auth.error == 'Compte inactif'
                                      ? Colors.orange.withValues(alpha: 0.3)
                                      : Colors.red.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        auth.error == 'Compte inactif'
                                            ? Icons.warning_amber_rounded
                                            : Icons.error_outline_rounded,
                                        color: auth.error == 'Compte inactif'
                                            ? Colors.orange[300]
                                            : Colors.red[300],
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          auth.error == 'Compte inactif'
                                              ? 'Votre compte n\'est pas encore actif. Veuillez vérifier votre adresse e-mail ou renvoyer le lien de confirmation.'
                                              : auth.error!,
                                          style: TextStyle(
                                            color:
                                                auth.error == 'Compte inactif'
                                                    ? Colors.orange[300]
                                                    : Colors.red[300],
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  if (auth.error == 'Compte inactif') ...[
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: () async {
                                        if (_emailCtrl.text.trim().isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                              content: Text(
                                                  'Veuillez saisir votre adresse e-mail'),
                                            ),
                                          );
                                          return;
                                        }
                                        final sent =
                                            await auth.resendVerificationEmail(
                                                _emailCtrl.text.trim());
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                sent
                                                    ? 'Email de vérification renvoyé !'
                                                    : 'Erreur: ${auth.error ?? "Impossible de renvoyer l'email"}',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      style: TextButton.styleFrom(
                                        padding: EdgeInsets.zero,
                                        minimumSize: const Size(0, 30),
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: Text(
                                        'Renvoyer l\'email de validation',
                                        style: TextStyle(
                                          color: Colors.orange[300],
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                          decoration: TextDecoration.underline,
                                        ),
                                      ),
                                    ),
                                  ],
                                  if (auth.errorDetails != null &&
                                      auth.error != 'Compte inactif')
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8.0),
                                      child: Text(
                                        auth.errorDetails!,
                                        style: TextStyle(
                                          color: Colors.red[200],
                                          fontSize: 12,
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),

                        const SizedBox(height: 32),

                        // Submit Button
                        AuthPrimaryButton(
                          label: 'Se connecter',
                          icon: Icons.arrow_forward_rounded,
                          loading: auth.isLoading,
                          onTap: _isFormValid() ? () => _submit(auth) : null,
                        ),

                        const SizedBox(height: 16),
                        // Boutons de connexion sociale désactivés temporairement
                        // _buildAppleButton(auth),
                        // const SizedBox(height: 12),
                        // _buildGoogleButton(auth),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Register Link
                  _buildRegisterLink(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Column(
      children: [
        // Logo icon
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withValues(alpha: 0.15),
                Colors.white.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
            ),
          ),
          child: const Center(
            child: Icon(
              Icons.credit_card_rounded,
              color: Colors.white,
              size: 36,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Brand name
        const Text(
          'KART',
          style: TextStyle(
            fontSize: 36,
            fontWeight: FontWeight.w800,
            letterSpacing: 6,
            color: Colors.white,
          ),
        ),

        const SizedBox(height: 6),

        Text(
          'Votre carte de visite digitale',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            'Pas encore de compte ? ',
            style: TextStyle(
              color: Colors.grey[500],
              fontSize: 15,
            ),
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/register'),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Créer un compte',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
