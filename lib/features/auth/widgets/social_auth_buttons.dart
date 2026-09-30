import 'package:flutter/material.dart';
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
        // Apple en premier sur iOS (recommandation des guidelines Apple :
        // au moins aussi visible que les autres options).
        if (showApple) ...[
          const SizedBox(height: 20),
          _SocialButton(
            label: 'Continuer avec Apple',
            icon: FontAwesomeIcons.apple,
            // Noir sur fond clair, blanc sur fond sombre (Apple HIG).
            background: isDark ? Colors.white : Colors.black,
            foreground: isDark ? Colors.black : Colors.white,
            loading: auth.isAppleLoading,
            onTap: busy ? null : () => _handle(context, auth.loginWithApple),
          ),
        ],
        if (showGoogle) ...[
          SizedBox(height: showApple ? 12 : 20),
          _SocialButton(
            label: 'Continuer avec Google',
            icon: FontAwesomeIcons.google,
            background: Colors.white,
            foreground: Colors.black87,
            bordered: !isDark,
            loading: auth.isGoogleLoading,
            onTap: busy ? null : () => _handle(context, auth.loginWithGoogle),
          ),
        ],
      ],
    );
  }
}

class _SocialButton extends StatelessWidget {
  final String label;
  final FaIconData icon;
  final Color background;
  final Color foreground;
  final bool bordered;
  final bool loading;
  final VoidCallback? onTap;

  const _SocialButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    this.bordered = false,
    this.loading = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 150),
        opacity: onTap == null && !loading ? 0.6 : 1,
        child: Container(
          width: double.infinity,
          height: 54,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(14),
            border: bordered ? Border.all(color: Colors.black12) : null,
          ),
          child: Center(
            child: loading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: foreground.withValues(alpha: 0.6),
                    ),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      FaIcon(icon, color: foreground, size: 20),
                      const SizedBox(width: 12),
                      Text(
                        label,
                        style: TextStyle(
                          color: foreground,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
