import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../../shared/widgets/auth_primary_button.dart';
import '../../../shared/widgets/auth_outline_button.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final _firstnameCtrl = TextEditingController();
  final _lastnameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordConfirmCtrl = TextEditingController();

  int _currentPage = 0;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutCubic,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _firstnameCtrl.dispose();
    _lastnameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordConfirmCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  // ---------------- VALIDATION ----------------

  bool _isPasswordValid() =>
      _passwordCtrl.text.length >= 6 &&
      _passwordCtrl.text == _passwordConfirmCtrl.text;

  bool _isValidPage() {
    switch (_currentPage) {
      case 0:
        return _firstnameCtrl.text.isNotEmpty && _lastnameCtrl.text.isNotEmpty;
      case 1:
        return _emailCtrl.text.contains('@') && _phoneCtrl.text.length >= 8;
      case 2:
        return _isPasswordValid();
      default:
        return false;
    }
  }

  // ---------------- ACTIONS ----------------

  void _nextPage() {
    if (_currentPage < 2) {
      setState(() => _currentPage++);
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      setState(() => _currentPage--);
    }
  }

  Future<void> _submit(AuthProvider auth) async {
    final success = await auth.register(
      firstname: _firstnameCtrl.text.trim(),
      lastname: _lastnameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      passwordConfirmation: _passwordConfirmCtrl.text,
    );

    if (!mounted) return;

    if (success) {
      if (auth.error == 'verification_required') {
        _showVerificationRequiredDialog(context, _emailCtrl.text.trim());
      } else if (auth.isAuthenticated) {
        Navigator.pushReplacementNamed(
          context,
          '/plans',
          arguments: {
            'successMessage': 'Compte créé avec succès 🎉',
          },
        );
      }
    }
  }

  // ---------------- UI ----------------

  String _getStepTitle() {
    switch (_currentPage) {
      case 0:
        return 'Qui êtes-vous ?';
      case 1:
        return 'Vos coordonnées';
      case 2:
        return 'Sécurisez votre compte';
      default:
        return '';
    }
  }

  String _getStepSubtitle() {
    switch (_currentPage) {
      case 0:
        return 'Commençons par votre identité';
      case 1:
        return 'Pour vous contacter et accéder à votre carte';
      case 2:
        return 'Choisissez un mot de passe sécurisé';
      default:
        return '';
    }
  }

  IconData _getStepIcon() {
    switch (_currentPage) {
      case 0:
        return Icons.person_outline_rounded;
      case 1:
        return Icons.mail_outline_rounded;
      case 2:
        return Icons.lock_outline_rounded;
      default:
        return Icons.circle;
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
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 20,
              bottom: bottomPadding > 0 ? bottomPadding + 20 : 20,
            ),
            child: Column(
              children: [
                // Header with back button
                _buildHeader(),

                const SizedBox(height: 24),

                // Progress indicator
                _buildProgressIndicator(),

                const SizedBox(height: 32),

                // Step info
                _buildStepInfo(),

                const SizedBox(height: 32),

                // Form pages - using AnimatedSwitcher instead of PageView
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _currentPage == 0
                      ? _buildNameStep()
                      : _currentPage == 1
                          ? _buildEmailStep()
                          : _buildPasswordStep(),
                ),

                const SizedBox(height: 32),

                // Error message
                if (auth.error != null && auth.error != 'verification_required')
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
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

                // Buttons
                _buildButtons(auth),

                const SizedBox(height: 20),

                // Login link
                _buildLoginLink(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        if (_currentPage > 0)
          GestureDetector(
            onTap: _previousPage,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          )
        else
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.close_rounded,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
        const Spacer(),
        const Text(
          'KART',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            letterSpacing: 3,
            color: Colors.white,
          ),
        ),
        const Spacer(),
        const SizedBox(width: 42),
      ],
    );
  }

  Widget _buildProgressIndicator() {
    return Row(
      children: List.generate(3, (i) {
        final isActive = i <= _currentPage;
        final isCurrent = i == _currentPage;

        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 4,
            margin: EdgeInsets.only(right: i < 2 ? 8 : 0),
            decoration: BoxDecoration(
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(2),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: Colors.white.withValues(alpha: 0.3),
                        blurRadius: 8,
                      ),
                    ]
                  : [],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildStepInfo() {
    return Column(
      children: [
        // Icon
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Container(
            key: ValueKey(_currentPage),
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withValues(alpha: 0.12),
                  Colors.white.withValues(alpha: 0.04),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              _getStepIcon(),
              color: Colors.white,
              size: 28,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Title
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _getStepTitle(),
            key: ValueKey('title$_currentPage'),
            style: const TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
        ),

        const SizedBox(height: 8),

        // Subtitle
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: Text(
            _getStepSubtitle(),
            key: ValueKey('sub$_currentPage'),
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 15,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNameStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          AuthTextField(
            label: 'Prénom',
            hint: 'Prénom',
            controller: _firstnameCtrl,
            prefixIcon: Icons.person_outline_rounded,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          AuthTextField(
            label: 'Nom',
            hint: 'Nom de famille',
            controller: _lastnameCtrl,
            prefixIcon: Icons.badge_outlined,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildEmailStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          AuthTextField(
            label: 'Numéro de téléphone',
            hint: '+221 77 123 45 67',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          AuthTextField(
            label: 'Adresse email',
            hint: 'text@email.com',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.mail_outline_rounded,
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordStep() {
    return SingleChildScrollView(
      child: Column(
        children: [
          AuthTextField(
            label: 'Mot de passe',
            hint: 'Minimum 6 caractères',
            controller: _passwordCtrl,
            obscureText: true,
            prefixIcon: Icons.lock_outline_rounded,
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 24),
          AuthTextField(
            label: 'Confirmer le mot de passe',
            hint: 'Retapez votre mot de passe',
            controller: _passwordConfirmCtrl,
            obscureText: true,
            prefixIcon: Icons.lock_outline_rounded,
            matchController: _passwordCtrl,
            onChanged: (_) => setState(() {}),
          ),

          // Password strength indicator
          if (_passwordCtrl.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: _buildPasswordStrength(),
            ),
        ],
      ),
    );
  }

  Widget _buildPasswordStrength() {
    final password = _passwordCtrl.text;
    int strength = 0;

    if (password.length >= 6) strength++;
    if (password.length >= 8) strength++;
    if (password.contains(RegExp(r'[A-Z]'))) strength++;
    if (password.contains(RegExp(r'[0-9]'))) strength++;
    if (password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'))) strength++;

    String label;
    Color color;

    if (strength <= 2) {
      label = 'Faible';
      color = Colors.red;
    } else if (strength <= 3) {
      label = 'Moyen';
      color = Colors.orange;
    } else {
      label = 'Fort';
      color = Colors.green;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(5, (i) {
            return Expanded(
              child: Container(
                height: 4,
                margin: EdgeInsets.only(right: i < 4 ? 4 : 0),
                decoration: BoxDecoration(
                  color: i < strength
                      ? color.withValues(alpha: 0.8)
                      : Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 8),
        Text(
          'Force du mot de passe : $label',
          style: TextStyle(
            color: color.withValues(alpha: 0.8),
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildButtons(AuthProvider auth) {
    return Row(
      children: [
        if (_currentPage > 0)
          Expanded(
            child: AuthOutlineButton(
              label: 'Retour',
              icon: Icons.arrow_back_rounded,
              onTap: _previousPage,
            ),
          )
        else
          const Expanded(child: SizedBox()),
        const SizedBox(width: 12),
        Expanded(
          flex: 2,
          child: AuthPrimaryButton(
            label: _currentPage == 2 ? 'Créer mon compte' : 'Continuer',
            icon: _currentPage == 2
                ? Icons.check_rounded
                : Icons.arrow_forward_rounded,
            loading: auth.isLoading,
            onTap: _isValidPage()
                ? () => _currentPage == 2 ? _submit(auth) : _nextPage()
                : null,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Déjà un compte ? ',
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 15,
          ),
        ),
        GestureDetector(
          onTap: () => Navigator.pop(context),
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
              'Se connecter',
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

  void _showVerificationRequiredDialog(BuildContext context, String email) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: Row(
          children: const [
            Icon(Icons.mark_email_unread_outlined, color: Colors.white, size: 28),
            SizedBox(width: 12),
            Text('Vérification requise', style: TextStyle(color: Colors.white)),
          ],
        ),
        content: Text(
          'Votre compte a été créé. Un e-mail de validation a été envoyé à :\n\n$email\n\nVeuillez valider votre e-mail pour activer votre compte. Une fois activé, vous recevrez un lien pour ouvrir l\'application.',
          style: const TextStyle(color: Colors.white70, height: 1.5),
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              Navigator.of(context).pushReplacementNamed('/login');
            },
            child: const Text('Aller à la connexion', style: TextStyle(color: Colors.white)),
          ),
          TextButton(
            onPressed: () async {
              final auth = context.read<AuthProvider>();
              final sent = await auth.resendVerificationEmail(email);
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(
                    content: Text(
                      sent
                          ? 'Email de vérification renvoyé !'
                          : 'Erreur: ${auth.error ?? "Impossible de renvoyer l\'email"}',
                    ),
                  ),
                );
              }
            },
            child: const Text('Renvoyer l\'email', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
