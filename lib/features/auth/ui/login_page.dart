import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../../shared/widgets/auth_primary_button.dart';
import '../widgets/social_auth_buttons.dart';

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

  // Email OU téléphone (cf. AuthService::login() côté backend, qui détecte
  // lequel des deux a été tapé) — un compte créé depuis l'inscription
  // événement sans email (visiteur qui n'en avait pas) se connecte
  // uniquement avec son téléphone. >= 4 et pas >= 6 : le mot de passe peut
  // être un code PIN à 4 chiffres (EventRegistrationService), pas
  // seulement un mot de passe classique.
  bool _isFormValid() =>
      _emailCtrl.text.trim().isNotEmpty && _passwordCtrl.text.length >= 4;

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
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.surface,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            // Tout tient sur un écran sans défiler : espacements resserrés
            // selon la hauteur disponible (compact < 900, serré < 700, ex:
            // iPhone SE), et les Spacer répartissent le reste. Le défilement
            // ne sert plus que clavier ouvert (hauteur réduite).
            child: LayoutBuilder(builder: (context, constraints) {
              final h = constraints.maxHeight;
              final compact = h < 900;
              final tight = h < 700;
              final vPad = tight ? 8.0 : (compact ? 10.0 : 16.0);
              final gapLarge = tight ? 16.0 : (compact ? 20.0 : 32.0);
              final gapField = tight ? 12.0 : (compact ? 14.0 : 24.0);

              return SingleChildScrollView(
                padding: EdgeInsets.only(
                  left: 24,
                  right: 24,
                  top: vPad,
                  bottom: bottomPadding > 0 ? bottomPadding + vPad : vPad,
                ),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: (h - vPad * 2 - bottomPadding).clamp(0, h),
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        // Logo / Brand
                        _buildLogo(colors, isDark,
                            compact: compact, tight: tight),

                        const Spacer(),
                        SizedBox(height: tight ? 12 : 20),

                        // Form Card
                        Container(
                          padding:
                              EdgeInsets.all(tight ? 18 : (compact ? 22 : 28)),
                          decoration: BoxDecoration(
                            color: colors.onSurface
                                .withValues(alpha: isDark ? 0.03 : 0.035),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: colors.onSurface
                                  .withValues(alpha: isDark ? 0.08 : 0.1),
                              width: 1,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Title
                              Text(
                                'Connexion',
                                style: TextStyle(
                                  fontSize: tight ? 24 : 28,
                                  fontWeight: FontWeight.w700,
                                  color: colors.onSurface,
                                  letterSpacing: -0.5,
                                ),
                              ),

                              if (!tight) ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Accédez à votre carte digitale',
                                  style: TextStyle(
                                    color:
                                        colors.onSurface.withValues(alpha: 0.6),
                                    fontSize: 15,
                                  ),
                                ),
                              ],

                              SizedBox(height: gapLarge),

                              // Email ou téléphone (cf. _isFormValid) — un
                              // clavier neutre plutôt qu'emailAddress, qui
                              // masquerait les touches utiles pour taper un
                              // numéro.
                              AuthTextField(
                                label: 'Email ou téléphone',
                                hint: 'votre@email.com ou +221 77 123 45 67',
                                controller: _emailCtrl,
                                keyboardType: TextInputType.text,
                                prefixIcon: Icons.person_outline_rounded,
                                onChanged: (_) => setState(() {}),
                              ),

                              SizedBox(height: gapField),

                              // Password
                              AuthTextField(
                                label: 'Mot de passe',
                                hint: '••••••••',
                                controller: _passwordCtrl,
                                obscureText: true,
                                prefixIcon: Icons.lock_outline_rounded,
                                onChanged: (_) => setState(() {}),
                              ),

                              const SizedBox(height: 12),

                              Align(
                                alignment: Alignment.centerRight,
                                child: GestureDetector(
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/forgot-password',
                                    arguments: _emailCtrl.text.trim(),
                                  ),
                                  child: Text(
                                    'Mot de passe oublié ?',
                                    style: TextStyle(
                                      color: colors.onSurface
                                          .withValues(alpha: 0.6),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
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
                                      color: Colors.red.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color:
                                            Colors.red.withValues(alpha: 0.3),
                                      ),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Icon(
                                              Icons.error_outline_rounded,
                                              color: Colors
                                                  .red[isDark ? 300 : 700],
                                              size: 20,
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: Text(
                                                auth.error!,
                                                style: TextStyle(
                                                  color: Colors
                                                      .red[isDark ? 300 : 700],
                                                  fontSize: 14,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (auth.errorDetails != null)
                                          Padding(
                                            padding:
                                                const EdgeInsets.only(top: 8.0),
                                            child: Text(
                                              auth.errorDetails!,
                                              style: TextStyle(
                                                color: Colors
                                                    .red[isDark ? 200 : 800],
                                                fontSize: 12,
                                                fontFamily: 'monospace',
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ),

                              SizedBox(height: gapLarge),

                              // Submit Button
                              AuthPrimaryButton(
                                label: 'Se connecter',
                                icon: Icons.arrow_forward_rounded,
                                loading: auth.isLoading,
                                onTap:
                                    _isFormValid() ? () => _submit(auth) : null,
                              ),

                              SizedBox(height: gapField),
                              const SocialAuthButtons(),
                            ],
                          ),
                        ),

                        const Spacer(),
                        SizedBox(height: tight ? 8 : 16),

                        // Register Link
                        _buildRegisterLink(context),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildLogo(ColorScheme colors, bool isDark,
      {bool compact = false, bool tight = false}) {
    final iconBox = compact ? 44.0 : 72.0;
    return Column(
      children: [
        // Logo icon (masqué sur petit écran : la marque suffit)
        if (!tight) ...[
          Container(
            width: iconBox,
            height: iconBox,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  colors.onSurface.withValues(alpha: isDark ? 0.15 : 0.08),
                  colors.onSurface.withValues(alpha: isDark ? 0.05 : 0.03),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: colors.onSurface.withValues(alpha: isDark ? 0.1 : 0.12),
              ),
            ),
            child: Center(
              child: Icon(
                Icons.credit_card_rounded,
                color: colors.onSurface,
                size: iconBox / 2,
              ),
            ),
          ),
          SizedBox(height: compact ? 8 : 20),
        ],

        // Brand name
        Text(
          'KART',
          style: TextStyle(
            fontSize: compact ? 28 : 36,
            fontWeight: FontWeight.w800,
            letterSpacing: 6,
            color: colors.onSurface,
          ),
        ),

        SizedBox(height: tight ? 2 : 6),

        Text(
          'Votre carte de visite digitale',
          style: TextStyle(
            color: colors.onSurface.withValues(alpha: 0.5),
            fontSize: 14,
            letterSpacing: 0.5,
          ),
        ),
      ],
    );
  }

  Widget _buildRegisterLink(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Text(
            'Pas encore de compte ? ',
            style: TextStyle(
              color: colors.onSurface.withValues(alpha: 0.5),
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
              color: colors.onSurface.withValues(alpha: 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              'Créer un compte',
              style: TextStyle(
                color: colors.onSurface,
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
