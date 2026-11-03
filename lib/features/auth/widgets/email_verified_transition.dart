import 'package:flutter/material.dart';

/// Écran de transition après la vérification de l'email, pendant la
/// création de la carte digitale. Tout est centré et rien n'est coupé :
/// les textes passent à la ligne (grande police, petit écran) et la page
/// défile si elle ne tient pas en hauteur.
class EmailVerifiedTransition extends StatelessWidget {
  /// Durée minimale d'affichage, même si la carte est créée plus vite.
  static const minimumDuration = Duration(seconds: 2);

  final String subtitle;

  const EmailVerifiedTransition({
    super.key,
    this.subtitle = 'Création de votre carte digitale…',
  });

  /// Attend le reste de [minimumDuration] depuis [shown].
  static Future<void> waitRemaining(Stopwatch shown, {Future<void> Function(Duration)? delay}) async {
    final remaining = minimumDuration - shown.elapsed;
    if (remaining > Duration.zero) await (delay ?? Future<void>.delayed)(remaining);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        key: const Key('email-verified-transition'),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: (constraints.maxHeight - 64).clamp(0, double.infinity)),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Container(
                    width: 88,
                    height: 88,
                    decoration: BoxDecoration(
                      color: Colors.green.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.mark_email_read_rounded, color: Colors.green.shade500, size: 42),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Email vérifié',
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: TextStyle(
                      fontFamily: 'Syne',
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: colors.onSurface,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    subtitle,
                    textAlign: TextAlign.center,
                    softWrap: true,
                    style: TextStyle(color: colors.onSurface.withValues(alpha: 0.65), fontSize: 15, height: 1.45),
                  ),
                  const SizedBox(height: 28),
                  const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
