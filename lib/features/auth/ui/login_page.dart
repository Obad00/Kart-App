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

class _LoginPageState extends State<LoginPage> {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  bool _isFormValid() =>
      _emailCtrl.text.contains('@') &&
      _passwordCtrl.text.length >= 6;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
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

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                /// HEADER
                const Text(
                  'KART',
                  style: TextStyle(
                    fontSize: 44,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 3.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Connexion',
                  style: TextStyle(
                    color: Colors.grey[400],
                    letterSpacing: 1,
                  ),
                ),

                const SizedBox(height: 64),

                AuthTextField(
                  label: 'Email',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                   onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 32),

                AuthTextField(
                  label: 'Mot de passe',
                  controller: _passwordCtrl,
                  obscureText: true,
                   onChanged: (_) => setState(() {}),
                ),

                const SizedBox(height: 48),

                AuthPrimaryButton(
                  label: 'Connexion',
                  loading: auth.isLoading,
                  onTap: _isFormValid()
                      ? () => _submit(auth)
                      : null,
                ),

                const SizedBox(height: 32),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Pas encore de compte ? ',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    GestureDetector(
                      onTap: () =>
                          Navigator.pushNamed(context, '/register'),
                      child: const Text(
                        'Créer un compte',
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
      ),
    );
  }
}
