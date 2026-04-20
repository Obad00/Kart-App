import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../../shared/widgets/auth_primary_button.dart';

class CompleteProfilePage extends StatefulWidget {
  const CompleteProfilePage({super.key});

  @override
  State<CompleteProfilePage> createState() => _CompleteProfilePageState();
}

class _CompleteProfilePageState extends State<CompleteProfilePage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _firstnameCtrl = TextEditingController();
  final _lastnameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  bool _isLoading = false;

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

    _initializeFields();
  }

  void _initializeFields() {
    final auth = context.read<AuthProvider>();
    final user = auth.user;
    if (user != null) {
      _firstnameCtrl.text = user.firstname;
      _lastnameCtrl.text = user.lastname;
      _emailCtrl.text = user.email;
      _phoneCtrl.text = user.phone ?? '';
    }
  }

  bool _isFormValid() {
    return _firstnameCtrl.text.trim().isNotEmpty &&
        _lastnameCtrl.text.trim().isNotEmpty &&
        _emailCtrl.text.contains('@') &&
        _phoneCtrl.text.length >= 8;
  }

  @override
  void dispose() {
    _firstnameCtrl.dispose();
    _lastnameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _animController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_isFormValid()) return;

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final success = await auth.updateProfile(
      firstname: _firstnameCtrl.text.trim(),
      lastname: _lastnameCtrl.text.trim(),
      phone: _phoneCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
    );

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      // Nouveau user Google -> rediriger vers le choix de plan
      Navigator.pushReplacementNamed(context, '/plans');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Une erreur est survenue'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _skip() {
    // Meme en skippant, on va vers les plans
    Navigator.pushReplacementNamed(context, '/plans');
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              horizontal: 28,
              vertical: 32,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  // Welcome icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.green.withValues(alpha: 0.3),
                          Colors.green.withValues(alpha: 0.1),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: Colors.green.withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.check_circle_outline_rounded,
                        color: Colors.green,
                        size: 36,
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  Text(
                    'Bienvenue ${auth.user?.firstname ?? ''} !',
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),

                  const SizedBox(height: 8),

                  Text(
                    'Votre compte a été créé avec succès.\nComplétez vos informations pour continuer.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 15,
                      height: 1.4,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Stepper indicator
                  Row(
                    children: [
                      _buildStep(1, 'Profil', true),
                      _buildStepLine(),
                      _buildStep(2, 'Plan', false),
                    ],
                  ),

                  const SizedBox(height: 32),

                  // Form Card
                  Container(
                    padding: const EdgeInsets.all(24),
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
                        const Text(
                          'Informations personnelles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),

                        const SizedBox(height: 6),

                        Text(
                          'Ces informations seront visibles sur votre carte digitale',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 13,
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Prénom
                        AuthTextField(
                          label: 'Prénom',
                          hint: 'Votre prénom',
                          controller: _firstnameCtrl,
                          prefixIcon: Icons.person_outline_rounded,
                          onChanged: (_) => setState(() {}),
                        ),

                        const SizedBox(height: 20),

                        // Nom
                        AuthTextField(
                          label: 'Nom',
                          hint: 'Votre nom',
                          controller: _lastnameCtrl,
                          prefixIcon: Icons.person_outline_rounded,
                          onChanged: (_) => setState(() {}),
                        ),

                        const SizedBox(height: 20),

                        // Email
                        AuthTextField(
                          label: 'Email',
                          hint: 'votre@email.com',
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          prefixIcon: Icons.mail_outline_rounded,
                          onChanged: (_) => setState(() {}),
                        ),

                        const SizedBox(height: 20),

                        // Téléphone
                        AuthTextField(
                          label: 'Téléphone',
                          hint: '+221 7* *** ** **',
                          controller: _phoneCtrl,
                          keyboardType: TextInputType.phone,
                          prefixIcon: Icons.phone_outlined,
                          onChanged: (_) => setState(() {}),
                        ),

                        const SizedBox(height: 32),

                        // Submit
                        AuthPrimaryButton(
                          label: 'Continuer',
                          icon: Icons.arrow_forward_rounded,
                          loading: _isLoading,
                          onTap: _isFormValid() ? _submit : null,
                        ),

                        const SizedBox(height: 16),

                        Center(
                          child: TextButton(
                            onPressed: _skip,
                            child: Text(
                              'Passer cette étape',
                              style: TextStyle(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStep(int number, String label, bool isActive) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isActive
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.1),
              border: Border.all(
                color: isActive
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                '$number',
                style: TextStyle(
                  color: isActive ? Colors.black : Colors.grey[500],
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.white : Colors.grey[600],
              fontSize: 12,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine() {
    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.4),
              Colors.white.withValues(alpha: 0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
