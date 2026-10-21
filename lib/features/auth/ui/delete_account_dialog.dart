import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/feedback/feedback_overlay.dart';
import '../../../shared/utils/session_reset.dart';
import '../../../shared/widgets/glass_dialog.dart';
import '../providers/auth_provider.dart';

/// « Supprimer le compte » (obligation Apple 5.1.1) : depuis le Profil, et
/// depuis l'écran « Compte suspendu » où c'est l'une des seules actions
/// encore possibles. [pageContext] : contexte de la page appelante, encore
/// monté après la fermeture d'une feuille éventuelle.
void showDeleteAccountDialog(BuildContext pageContext) {
  final passwordController = TextEditingController();
  bool isLoading = false;
  String? passwordError;
  bool obscurePassword = true;
  // Compte Google/Apple sans mot de passe : la session suffit (le backend
  // n'exige alors aucun mot de passe, cf. AuthService côté API).
  final requiresPassword =
      pageContext.read<AuthProvider>().user?.hasPassword ?? true;

  showDialog(
    context: pageContext,
    barrierDismissible: false,
    builder: (dialogContext) {
      return StatefulBuilder(
        builder: (context, setStateDialog) {
          Future<void> handleDelete() async {
            final password = passwordController.text.trim();
            if (requiresPassword && password.isEmpty) {
              setStateDialog(() {
                passwordError = 'Entrez votre mot de passe';
              });
              return;
            }

            setStateDialog(() {
              isLoading = true;
              passwordError = null;
            });

            final auth = pageContext.read<AuthProvider>();
            final result =
                await auth.deleteAccount(requiresPassword ? password : null);

            if (!dialogContext.mounted) return;

            if (result.status == DeleteAccountStatus.success) {
              Navigator.of(dialogContext).pop();
              if (!pageContext.mounted) return;
              // deleteAccount() appelle déjà logout() en interne, mais pas
              // le reset des autres providers (cf. session_reset.dart) —
              // sans ça, un compte connecté juste après sur le même
              // appareil verrait les données de celui qui vient d'être
              // supprimé.
              resetSessionProviders(pageContext);
              FeedbackOverlay.showSuccess(
                pageContext,
                title: 'Succès',
                subtitle: 'Votre compte a été supprimé avec succès',
              );
              Navigator.of(pageContext)
                  .pushNamedAndRemoveUntil('/login', (_) => false);
              return;
            }

            if (result.status == DeleteAccountStatus.invalidPassword) {
              setStateDialog(() {
                isLoading = false;
                passwordError = result.message ?? 'Mot de passe incorrect';
              });
              return;
            }

            if (result.status == DeleteAccountStatus.sessionExpired) {
              Navigator.of(dialogContext).pop();
              if (!pageContext.mounted) return;
              FeedbackOverlay.showError(
                pageContext,
                title: 'Erreur',
                subtitle: 'Session expirée',
              );
              Navigator.of(pageContext)
                  .pushNamedAndRemoveUntil('/login', (_) => false);
              return;
            }

            setStateDialog(() {
              isLoading = false;
            });
            if (!pageContext.mounted) return;
            FeedbackOverlay.showError(
              pageContext,
              title: 'Erreur',
              subtitle: 'Une erreur est survenue. Veuillez réessayer.',
            );
          }

          final colors = Theme.of(context).colorScheme;

          return GlassDialog(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.delete_forever_outlined,
                        color: Colors.red.shade400,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Supprimer le compte',
                        style: TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w700,
                          color: colors.onSurface,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  'Cette action est irréversible. Toutes vos données seront supprimées.',
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.45,
                    color: colors.onSurface.withValues(alpha: 0.75),
                  ),
                ),
                if (requiresPassword) ...[
                  const SizedBox(height: 16),
                  TextField(
                    controller: passwordController,
                    obscureText: obscurePassword,
                    enabled: !isLoading,
                    decoration: InputDecoration(
                      hintText: 'Entrez votre mot de passe',
                      errorText: passwordError,
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        onPressed: isLoading
                            ? null
                            : () {
                                setStateDialog(() {
                                  obscurePassword = !obscurePassword;
                                });
                              },
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colors.onSurface.withValues(alpha: 0.15),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: colors.primary,
                          width: 1.3,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 14,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: isLoading
                            ? null
                            : () => Navigator.of(dialogContext).pop(),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Annuler'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: isLoading ? null : handleDelete,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 13),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: isLoading
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white),
                                ),
                              )
                            : const Text('Confirmer'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      );
    },
  ).then((_) {
    passwordController.dispose();
  });
}
