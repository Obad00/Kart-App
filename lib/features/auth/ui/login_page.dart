import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  late PageController _pageController;
  int _currentPage = 0;

  late AnimationController _buttonAnimController;
  late Animation<double> _buttonScale;
  late Animation<Color?> _buttonColorAnimation;

  bool _emailFocused = false;
  bool _passwordFocused = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);

    _buttonAnimController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _buttonScale = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _buttonAnimController, curve: Curves.easeInOut),
    );

    _buttonColorAnimation = ColorTween(
      begin: Colors.white,
      end: Colors.black,
    ).animate(
      CurvedAnimation(parent: _buttonAnimController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _pageController.dispose();
    _buttonAnimController.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage < 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeInOut,
      );
    }
  }

  void _handleButtonPress() async {
    _buttonAnimController.forward();
    await Future.delayed(const Duration(milliseconds: 180));
    _buttonAnimController.reverse();

    if (mounted) {
      final auth = context.read<AuthProvider>();
      await auth.login(_emailCtrl.text.trim(), _passwordCtrl.text.trim());
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF0A0A0A),
              const Color(0xFF1A1A1A),
              const Color(0xFF0D0D0D),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: MediaQuery.of(context).size.height -
                    MediaQuery.of(context).padding.top -
                    MediaQuery.of(context).padding.bottom,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Logo Section
                    Column(
                      children: [
                        Text(
                          'KART',
                          style: TextStyle(
                            fontSize: 44,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 3.5,
                            color: Colors.white,
                            shadows: [
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.1),
                                blurRadius: 20,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Bienvenue',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1,
                            color: Colors.grey[400],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 48),

                    // Card with PageView (swipe)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.05),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.25),
                                blurRadius: 24,
                                offset: const Offset(0, 10),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SizedBox(
                                height: 140,
                                child: PageView(
                                  controller: _pageController,
                                  onPageChanged: (p) =>
                                      setState(() => _currentPage = p),
                                  physics: const BouncingScrollPhysics(),
                                  children: [
                                    _buildFloatingLabelField(
                                      label: 'Email',
                                      controller: _emailCtrl,
                                      isFocused: _emailFocused,
                                      onFocusChange: (f) =>
                                          setState(() => _emailFocused = f),
                                      keyboardType: TextInputType.emailAddress,
                                    ),
                                    _buildFloatingLabelField(
                                      label: 'Mot de passe',
                                      controller: _passwordCtrl,
                                      isFocused: _passwordFocused,
                                      onFocusChange: (f) =>
                                          setState(() => _passwordFocused = f),
                                      obscureText: true,
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 20),

                              // Progress dots
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: List.generate(2, (i) {
                                  return AnimatedContainer(
                                    duration: const Duration(milliseconds: 260),
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 6),
                                    width: _currentPage == i ? 28 : 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: _currentPage == i
                                          ? Colors.white
                                          : Colors.white
                                              .withValues(alpha: 0.25),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  );
                                }),
                              ),

                              const SizedBox(height: 20),

                              // Navigation row
                              Row(
                                children: [
                                  if (_currentPage > 0)
                                    Expanded(
                                      child: Material(
                                        color: Colors.transparent,
                                        child: InkWell(
                                          onTap: _previousPage,
                                          borderRadius:
                                              BorderRadius.circular(14),
                                          splashColor: Colors.white
                                              .withValues(alpha: 0.08),
                                          highlightColor: Colors.white
                                              .withValues(alpha: 0.04),
                                          child: Container(
                                            height: 52,
                                            decoration: BoxDecoration(
                                              border: Border.all(
                                                  color: Colors.white
                                                      .withValues(alpha: 0.12),
                                                  width: 1),
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: Center(
                                              child: Text(
                                                'Retour',
                                                style: TextStyle(
                                                    color: Colors.grey[300],
                                                    fontWeight:
                                                        FontWeight.w600),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                    )
                                  else
                                    const Expanded(child: SizedBox()),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: ScaleTransition(
                                      scale: _buttonScale,
                                      child: AnimatedBuilder(
                                        animation: _buttonColorAnimation,
                                        builder: (context, child) {
                                          final isLast = _currentPage == 1;
                                          return Container(
                                            height: 52,
                                            decoration: BoxDecoration(
                                              color:
                                                  _buttonColorAnimation.value ??
                                                      Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.white.withValues(
                                                      alpha:
                                                          _buttonAnimController
                                                                  .value *
                                                              0.22),
                                                  blurRadius: 18,
                                                  offset: const Offset(0, 8),
                                                ),
                                              ],
                                            ),
                                            child: Material(
                                              color: Colors.transparent,
                                              child: InkWell(
                                                onTap: isLast
                                                    ? (auth.isLoading
                                                        ? null
                                                        : _handleButtonPress)
                                                    : (_isEmailValid()
                                                        ? _nextPage
                                                        : null),
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                                splashColor: Colors.white
                                                    .withValues(alpha: 0.12),
                                                highlightColor: Colors.white
                                                    .withValues(alpha: 0.06),
                                                child: Center(
                                                  child: auth.isLoading &&
                                                          isLast
                                                      ? SizedBox(
                                                          width: 20,
                                                          height: 20,
                                                          child: CircularProgressIndicator(
                                                              strokeWidth: 2,
                                                              valueColor: AlwaysStoppedAnimation<
                                                                      Color>(
                                                                  Colors.black
                                                                      .withValues(
                                                                          alpha:
                                                                              0.7))))
                                                      : Text(
                                                          isLast
                                                              ? 'Connexion'
                                                              : 'Suivant',
                                                          style: TextStyle(
                                                            fontSize: 16,
                                                            fontWeight:
                                                                FontWeight.w600,
                                                            color: _buttonAnimController
                                                                        .value <
                                                                    0.5
                                                                ? Colors.black
                                                                : Colors.white,
                                                          ),
                                                        ),
                                                ),
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 12),

                              // Forgot / Signup row
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'Pas encore de compte ? ',
                                    style: TextStyle(color: Colors.grey[400]),
                                  ),
                                  TextButton(
                                    onPressed: () => Navigator.pushNamed(
                                        context, '/register'),
                                    style: TextButton.styleFrom(
                                      overlayColor:
                                          Colors.white.withValues(alpha: 0.08),
                                    ),
                                    child: Text(
                                      'S\'inscrire',
                                      style: TextStyle(
                                          color: Colors.grey[100],
                                          fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  bool _isEmailValid() {
    return _emailCtrl.text.isNotEmpty && _emailCtrl.text.contains('@');
  }

  Widget _buildFloatingLabelField({
    required String label,
    required TextEditingController controller,
    required bool isFocused,
    required Function(bool) onFocusChange,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return SizedBox(
      width: double.infinity,
      child: Focus(
        onFocusChange: onFocusChange,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: TextStyle(
                fontSize: isFocused || controller.text.isNotEmpty ? 12 : 14,
                color: isFocused ? Colors.white : Colors.grey[400],
                fontWeight: isFocused ? FontWeight.w500 : FontWeight.w400,
                letterSpacing: 0.3,
              ),
              child: Text(label),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isFocused
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.12),
                    width: isFocused ? 2 : 1,
                  ),
                ),
              ),
              child: TextField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                style: const TextStyle(color: Colors.white, fontSize: 15),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                  hintText: 'Entrez votre ${label.toLowerCase()}',
                  hintStyle: TextStyle(color: Colors.grey[600]),
                ),
                onChanged: (_) => setState(() {}),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
