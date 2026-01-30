import 'package:flutter/material.dart';
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
  late AnimationController _buttonAnimController;
  late Animation<double> _buttonScale;
  late Animation<Color?> _buttonColorAnimation;

  int _currentPage = 0;
  bool _emailFocused = false;
  bool _passwordFocused = false;

  final List<String> _fieldLabels = ['Email', 'Mot de passe'];

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
    if (_currentPage < _fieldLabels.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  void _handleButtonPress(AuthProvider auth) async {
    _buttonAnimController.forward();
    await Future.delayed(const Duration(milliseconds: 200));
    _buttonAnimController.reverse();

    if (mounted) {
      await auth.login(
        _emailCtrl.text.trim(),
        _passwordCtrl.text.trim(),
      );
      if (mounted && auth.isAuthenticated) {
        Navigator.of(context).pushReplacementNamed('/home');
      }
    }
  }

  bool _isEmailValid() {
    return _emailCtrl.text.isNotEmpty && _emailCtrl.text.contains('@');
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
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                // Header
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
                    const SizedBox(height: 8),
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

                // Progress Indicator
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    _fieldLabels.length,
                    (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // PageView with Fields
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    onPageChanged: (page) {
                      setState(() => _currentPage = page);
                    },
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Email
                      _buildFieldPage(
                        label: 'Email',
                        controller: _emailCtrl,
                        isFocused: _emailFocused,
                        onFocusChange: (focused) =>
                            setState(() => _emailFocused = focused),
                        keyboardType: TextInputType.emailAddress,
                      ),

                      // Password
                      _buildFieldPage(
                        label: 'Mot de passe',
                        controller: _passwordCtrl,
                        isFocused: _passwordFocused,
                        onFocusChange: (focused) =>
                            setState(() => _passwordFocused = focused),
                        obscureText: true,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Error Message
                if (auth.error != null) ...[
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      border: Border.all(
                        color: Colors.red.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      auth.error!,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Navigation Buttons
                Row(
                  children: [
                    // Previous Button
                    if (_currentPage > 0)
                      Expanded(
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _previousPage,
                            borderRadius: BorderRadius.circular(16),
                            splashColor: Colors.white.withValues(alpha: 0.08),
                            highlightColor:
                                Colors.white.withValues(alpha: 0.05),
                            child: Container(
                              height: 56,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Center(
                                child: Text(
                                  'Retour',
                                  style: TextStyle(
                                    color: Colors.grey[300],
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )
                    else
                      Expanded(child: SizedBox.shrink()),
                    const SizedBox(width: 12),

                    // Next or Submit Button
                    Expanded(
                      child: ScaleTransition(
                        scale: _buttonScale,
                        child: AnimatedBuilder(
                          animation: _buttonColorAnimation,
                          builder: (context, child) {
                            return Container(
                              height: 56,
                              decoration: BoxDecoration(
                                color:
                                    _buttonColorAnimation.value ?? Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(
                                        alpha:
                                            _buttonAnimController.value * 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _currentPage < _fieldLabels.length - 1
                                      ? (_isEmailValid() ? _nextPage : null)
                                      : (auth.isLoading
                                          ? null
                                          : () => _handleButtonPress(auth)),
                                  borderRadius: BorderRadius.circular(16),
                                  splashColor:
                                      Colors.white.withValues(alpha: 0.15),
                                  highlightColor:
                                      Colors.white.withValues(alpha: 0.1),
                                  child: Center(
                                    child: auth.isLoading &&
                                            _currentPage ==
                                                _fieldLabels.length - 1
                                        ? SizedBox(
                                            width: 24,
                                            height: 24,
                                            child: _buildMinimalLoader(),
                                          )
                                        : Text(
                                            _currentPage <
                                                    _fieldLabels.length - 1
                                                ? 'Suivant'
                                                : 'Connexion',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 0.5,
                                              color:
                                                  _buttonAnimController.value <
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

                const SizedBox(height: 24),

                // Signup Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Pas encore de compte ? ',
                      style: TextStyle(
                        color: Colors.grey[400],
                        fontSize: 14,
                      ),
                    ),
                    Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => Navigator.pushNamed(context, '/register'),
                        borderRadius: BorderRadius.circular(8),
                        splashColor: Colors.white.withValues(alpha: 0.08),
                        highlightColor: Colors.white.withValues(alpha: 0.05),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          child: Text(
                            'S\'inscrire',
                            style: TextStyle(
                              color: Colors.grey[100],
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5,
                            ),
                          ),
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

  Widget _buildFieldPage({
    required String label,
    required TextEditingController controller,
    required bool isFocused,
    required Function(bool) onFocusChange,
    bool obscureText = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Center(
      child: _buildFloatingLabelField(
        label: label,
        controller: controller,
        isFocused: isFocused,
        onFocusChange: onFocusChange,
        obscureText: obscureText,
        keyboardType: keyboardType,
      ),
    );
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
      width: 300,
      child: Focus(
        onFocusChange: onFocusChange,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
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
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isFocused
                        ? Colors.white.withValues(alpha: 0.8)
                        : Colors.white.withValues(alpha: 0.1),
                    width: isFocused ? 2 : 1,
                  ),
                ),
              ),
              child: TextField(
                controller: controller,
                obscureText: obscureText,
                keyboardType: keyboardType,
                onChanged: (_) => setState(() {}),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                  hintText: 'Entrez votre ${label.toLowerCase()}',
                  hintStyle: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMinimalLoader() {
    return CustomPaint(
      painter: MinimalLoaderPainter(),
    );
  }
}

class MinimalLoaderPainter extends CustomPainter {
  final DateTime startTime = DateTime.now();

  @override
  void paint(Canvas canvas, Size size) {
    final elapsed = DateTime.now().difference(startTime).inMilliseconds % 1500;
    final progress = elapsed / 1500;

    final paint = Paint()
      ..color = Colors.black.withValues(alpha: 0.7)
      ..strokeWidth = 2
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final center = Offset(size.width / 2, size.height / 2);

    // Draw rotating arc
    canvas.drawArc(
      Rect.fromCenter(center: center, width: size.width, height: size.height),
      progress * 2 * 3.14159,
      1.5,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(MinimalLoaderPainter oldDelegate) => true;
}
