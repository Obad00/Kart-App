import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:provider/provider.dart';

import '../../../config/auth_config.dart';
import '../providers/auth_provider.dart';

/// Boutons "Continuer avec Google / Apple", partagés entre la connexion et
/// l'inscription — le backend crée le compte s'il n'existe pas, donc les
/// deux écrans ont exactement le même comportement. Un nouveau compte passe
/// par /complete-profile (téléphone, nom si Apple ne l'a pas transmis),
/// un compte existant va directement sur /home.
class SocialAuthButtons extends StatelessWidget {
  const SocialAuthButtons({super.key});

  Future<void> _handle(
    BuildContext context,
    Future<void> Function() signIn,
  ) async {
    final auth = context.read<AuthProvider>();
    await signIn();
    if (!context.mounted || !auth.isAuthenticated) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      auth.isNewUser ? '/complete-profile' : '/home',
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final showGoogle = AuthConfig.enableGoogleSignIn;
    final showApple =
        AuthConfig.enableAppleSignIn && auth.isAppleSignInAvailable;

    if (!showGoogle && !showApple) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final busy = auth.isGoogleLoading || auth.isAppleLoading || auth.isLoading;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Divider(color: colors.onSurface.withValues(alpha: 0.12)),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Text(
                'ou',
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.5),
                  fontSize: 13,
                ),
              ),
            ),
            Expanded(
              child: Divider(color: colors.onSurface.withValues(alpha: 0.12)),
            ),
          ],
        ),
        const SizedBox(height: 20),
        // Logos seuls, côte à côte : plus sobre que deux grands boutons
        // texte. Les guidelines Apple autorisent le bouton "logo only" à
        // condition qu'il ait la même taille que ceux des autres
        // fournisseurs — c'est le cas ici (même _SocialButton).
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Apple en premier sur iOS (recommandation des guidelines Apple :
            // au moins aussi visible que les autres options).
            if (showApple)
              _SocialButton(
                semanticLabel: 'Continuer avec Apple',
                logo: FaIcon(
                  FontAwesomeIcons.apple,
                  // Noir sur fond clair, blanc sur fond sombre (Apple HIG).
                  color: isDark ? Colors.black : Colors.white,
                  size: 24,
                ),
                background: isDark ? Colors.white : Colors.black,
                spinnerColor: isDark ? Colors.black54 : Colors.white70,
                loading: auth.isAppleLoading,
                onTap:
                    busy ? null : () => _handle(context, auth.loginWithApple),
              ),
            if (showApple && showGoogle) const SizedBox(width: 20),
            if (showGoogle)
              _SocialButton(
                semanticLabel: 'Continuer avec Google',
                // Logo "G" officiel en couleurs (Google Branding Guidelines),
                // toujours sur fond blanc.
                logo: SvgPicture.string(_googleLogoSvg, width: 22, height: 22),
                background: Colors.white,
                spinnerColor: Colors.black54,
                bordered: !isDark,
                loading: auth.isGoogleLoading,
                onTap:
                    busy ? null : () => _handle(context, auth.loginWithGoogle),
              ),
          ],
        ),
      ],
    );
  }
}

/// "G" officiel de Google, 4 couleurs (tracés du kit de marque Google).
const String _googleLogoSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 48 48">
<path fill="#EA4335" d="M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z"/>
<path fill="#4285F4" d="M46.98 24.55c0-1.57-.15-3.09-.38-4.55H24v9.02h12.94c-.58 2.96-2.26 5.48-4.78 7.18l7.73 6c4.51-4.18 7.09-10.36 7.09-17.65z"/>
<path fill="#FBBC05" d="M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z"/>
<path fill="#34A853" d="M24 48c6.48 0 11.93-2.13 15.89-5.81l-7.73-6c-2.15 1.45-4.92 2.3-8.16 2.3-6.26 0-11.57-4.22-13.47-9.91l-7.98 6.19C6.51 42.62 14.62 48 24 48z"/>
</svg>
''';

/// Bouton rond avec le seul logo du fournisseur. Le libellé reste exposé
/// aux lecteurs d'écran (VoiceOver/TalkBack) via [semanticLabel].
class _SocialButton extends StatelessWidget {
  final String semanticLabel;
  final Widget logo;
  final Color background;
  final Color spinnerColor;
  final bool bordered;
  final bool loading;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.semanticLabel,
    required this.logo,
    required this.background,
    required this.spinnerColor,
    this.bordered = false,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      enabled: onTap != null,
      label: semanticLabel,
      excludeSemantics: true,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 150),
          opacity: onTap == null && !loading ? 0.6 : 1,
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: background,
              shape: BoxShape.circle,
              border: bordered ? Border.all(color: Colors.black12) : null,
            ),
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: spinnerColor,
                      ),
                    )
                  : logo,
            ),
          ),
        ),
      ),
    );
  }
}
