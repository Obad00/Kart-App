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

class _RegisterPageState extends State<RegisterPage> {
  final _firstnameCtrl = TextEditingController();
  final _lastnameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _passwordConfirmCtrl = TextEditingController();

  final _pageController = PageController();
  int _currentPage = 0;

  @override
  void dispose() {
    _firstnameCtrl.dispose();
    _lastnameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _passwordConfirmCtrl.dispose();
    _pageController.dispose();
    super.dispose();
  }

  // ---------------- VALIDATION ----------------

  bool _isPasswordValid() =>
      _passwordCtrl.text.isNotEmpty &&
      _passwordCtrl.text == _passwordConfirmCtrl.text;

  bool _isValidPage() {
    switch (_currentPage) {
      case 0:
        return _firstnameCtrl.text.isNotEmpty &&
            _lastnameCtrl.text.isNotEmpty;
      case 1:
        return _emailCtrl.text.contains('@');
      case 2:
        return _isPasswordValid();
      default:
        return false;
    }
  }

  // ---------------- ACTIONS ----------------

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOutCubic,
    );
  }

  Future<void> _submit(AuthProvider auth) async {
    await auth.register(
      firstname: _firstnameCtrl.text.trim(),
      lastname: _lastnameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      passwordConfirmation: _passwordConfirmCtrl.text,
    );

    if (!mounted) return;

    if (auth.isAuthenticated) {
      Navigator.pushReplacementNamed(
        context,
        '/plans',
        arguments: {
          'successMessage': 'Compte créé avec succès 🎉',
        },
      );
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            children: [
              /// HEADER
              const Text(
                'Créer un compte',
                style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 32),

              /// INDICATOR
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  3,
                  (i) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == i ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == i
                          ? Colors.white
                          : Colors.white24,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 40),

              /// PAGES
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const BouncingScrollPhysics(),
                  onPageChanged: (i) =>
                      setState(() => _currentPage = i),
                  children: [
                    _twoFields(
                      'Prénom',
                      _firstnameCtrl,
                      'Nom',
                      _lastnameCtrl,
                      onChanged1: (_) => setState(() {}),
                      onChanged2: (_) => setState(() {}),
                    ),
                    _oneField(
                      'Email',
                      _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      onChanged: (_) => setState(() {}),
                    ),
                    _twoFields(
                      'Mot de passe',
                      _passwordCtrl,
                      'Confirmation',
                      _passwordConfirmCtrl,
                      onChanged1: (_) => setState(() {}),
                      onChanged2: (_) => setState(() {}),
                      obscure: true,
                    ),
                  ],

                ),
              ),

              const SizedBox(height: 24),

              /// BUTTONS
              Row(
                children: [
                  if (_currentPage > 0)
                    Expanded(
                      child: AuthOutlineButton(
                        label: 'Retour',
                        onTap: _previousPage,
                      ),
                    )
                  else
                    const Expanded(child: SizedBox()),

                  const SizedBox(width: 12),

                  Expanded(
                    child: AuthPrimaryButton(
                      label: _currentPage == 2
                          ? 'Créer mon compte'
                          : 'Suivant',
                      loading: auth.isLoading,
                      onTap: _isValidPage()
                          ? () => _currentPage == 2
                              ? _submit(auth)
                              : _nextPage()
                          : null,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Déjà un compte ? ',
                    style: TextStyle(color: Colors.grey[400]),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Text(
                      'Se connecter',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- HELPERS ----------------

Widget _twoFields(
  String l1,
  TextEditingController c1,
  String l2,
  TextEditingController c2, {
  bool obscure = false,
  ValueChanged<String>? onChanged1,
  ValueChanged<String>? onChanged2,
}) {
  return Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      AuthTextField(
        label: l1,
        controller: c1,
        obscureText: obscure,
        onChanged: onChanged1,
      ),
      const SizedBox(height: 32),
      AuthTextField(
        label: l2,
        controller: c2,
        obscureText: obscure,
        onChanged: onChanged2,
        matchController: obscure ? c1 : null, // ✅ check seulement si c'est un password
      ),
    ],
  );
}


Widget _oneField(
  String label,
  TextEditingController ctrl, {
  TextInputType keyboardType = TextInputType.text,
  ValueChanged<String>? onChanged, // ajout ici
}) {
  return Center(
    child: AuthTextField(
      label: label,
      controller: ctrl,
      keyboardType: keyboardType,
      onChanged: onChanged,
    ),
  );
}

}
