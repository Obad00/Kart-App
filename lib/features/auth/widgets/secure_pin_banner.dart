import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';

/// Nudge non bloquant affiché tant que le compte utilise encore le code
/// PIN à 4 chiffres généré à l'inscription événement (has_temporary_pin,
/// cf. EventRegistrationService côté backend) — plus faible qu'un vrai mot
/// de passe. Contrairement à ForceChangePasswordPage (must_change_password),
/// rien n'empêche d'utiliser l'app sans agir dessus : juste une invitation,
/// même esprit visuel que CompletionBanner (Profil).
class SecurePinBanner extends StatelessWidget {
  const SecurePinBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null || !user.hasTemporaryPin) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;
    const accentColor = Color(0xFFF59E0B);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pushNamed(context, '/change-password');
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(top: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              accentColor.withValues(alpha: 0.12),
              accentColor.withValues(alpha: 0.04),
            ],
          ),
          border: Border.all(color: accentColor.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 18,
                color: accentColor,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Sécurisez votre compte',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Vous utilisez encore le code reçu à l\'inscription — définissez un vrai mot de passe.',
                    style: TextStyle(
                      fontSize: 12,
                      color: colors.onSurface.withValues(alpha: 0.55),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: colors.onSurface.withValues(alpha: 0.3),
              size: 22,
            ),
          ],
        ),
      ),
    );
  }
}
