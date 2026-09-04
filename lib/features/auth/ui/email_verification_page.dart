import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/onboarding/onboarding_prefs.dart';
import '../../../shared/services/card_service.dart';
import '../../../shared/widgets/auth_primary_button.dart';
import '../../digital_card/providers/card_provider.dart';
import '../data/auth_api.dart';
import '../providers/auth_provider.dart';

/// Affiché juste après l'inscription (3e étape validée) : bloque le
/// parcours jusqu'à ce que l'email soit vérifié (lien reçu par mail), puis
/// enchaîne automatiquement — carte digitale créée en arrière-plan (sans
/// poste/entreprise, cf. CardService.createDefaultCard), et un drapeau posé
/// pour que MyDigitalCardPage propose de les compléter une fois la carte
/// affichée (cf. OnboardingPrefs) — avant de reprendre le parcours normal
/// vers /plans.
class EmailVerificationPage extends StatefulWidget {
  const EmailVerificationPage({super.key});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  final _authApi = AuthApi();

  Timer? _pollTimer;
  Timer? _cooldownTimer;
  int _resendCooldown = 0;
  bool _checkingNow = false;
  bool _proceeding = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _sendVerificationEmail(silent: true);
    // Vérifie périodiquement si le lien reçu par mail a été cliqué —
    // l'app n'a pas d'autre moyen de le savoir en direct (le lien ouvre le
    // navigateur, pas l'app).
    _pollTimer = Timer.periodic(
      const Duration(seconds: 4),
      (_) => _checkVerification(),
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendVerificationEmail({bool silent = false}) async {
    try {
      await _authApi.resendEmailVerification();
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email de vérification renvoyé.')),
        );
        _startResendCooldown();
      }
    } catch (e) {
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Impossible d'envoyer l'email pour le moment."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startResendCooldown() {
    setState(() => _resendCooldown = 30);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _resendCooldown--);
      if (_resendCooldown <= 0) timer.cancel();
    });
  }

  Future<void> _checkVerification({bool manual = false}) async {
    if (_checkingNow || _proceeding) return;
    setState(() {
      _checkingNow = true;
      if (manual) _error = null;
    });

    final auth = context.read<AuthProvider>();
    await auth.loadMe();
    if (!mounted) return;

    if (auth.user?.emailVerified == true) {
      await _onVerified();
      return;
    }

    setState(() {
      _checkingNow = false;
      if (manual) {
        _error = "Email pas encore vérifié — ouvrez le lien reçu par mail.";
      }
    });
  }

  /// Email confirmé : crée la carte digitale (vide, sans poste/entreprise)
  /// puis reprend le parcours d'inscription là où il s'arrêtait avant cet
  /// écran — vers le choix du plan.
  Future<void> _onVerified() async {
    _pollTimer?.cancel();
    setState(() => _proceeding = true);

    try {
      await CardService.createDefaultCard();
    } catch (e) {
      // Non bloquant : si la création échoue ici (déjà créée, ou souci
      // réseau ponctuel), MyDigitalCardPage retombe sur le CTA "Créer ma
      // carte" habituel plutôt que de bloquer toute l'inscription.
      debugPrint('⚠️ Création auto de la carte échouée (non bloquant): $e');
    }

    await OnboardingPrefs.markPendingJobCompanyPrompt();
    if (!mounted) return;

    // Rafraîchit tout de suite le CardProvider partagé (HomeShell le lira
    // sans nouvel appel réseau dès l'arrivée sur l'onglet Carte).
    await context.read<CardProvider>().loadCardSummary();
    if (!mounted) return;

    Navigator.pushReplacementNamed(
      context,
      '/plans',
      arguments: {'successMessage': 'Compte créé avec succès 🎉'},
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final email = auth.user?.email ?? '';

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
          child: Column(
            children: [
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      colors.onSurface.withValues(alpha: isDark ? 0.14 : 0.08),
                      colors.onSurface.withValues(alpha: isDark ? 0.05 : 0.03),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: _proceeding
                    ? const Center(
                        child: SizedBox(
                          width: 28,
                          height: 28,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        ),
                      )
                    : Icon(Icons.mark_email_unread_outlined,
                        color: colors.onSurface, size: 40),
              ),
              const SizedBox(height: 28),
              Text(
                _proceeding ? 'Email vérifié !' : 'Vérifiez votre email',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: colors.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                _proceeding
                    ? 'Création de votre carte digitale...'
                    : "Nous avons envoyé un lien de confirmation à\n$email\n\nOuvrez-le pour continuer — cet écran se met à jour automatiquement.",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colors.onSurface.withValues(alpha: 0.6),
                  fontSize: 15,
                  height: 1.45,
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Text(
                  _error!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
              const Spacer(),
              if (!_proceeding) ...[
                AuthPrimaryButton(
                  label: "J'ai vérifié, continuer",
                  icon: Icons.check_rounded,
                  loading: _checkingNow,
                  onTap: () => _checkVerification(manual: true),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _resendCooldown > 0
                      ? null
                      : () => _sendVerificationEmail(),
                  child: Text(
                    _resendCooldown > 0
                        ? 'Renvoyer l\'email (${_resendCooldown}s)'
                        : "Renvoyer l'email",
                    style: TextStyle(
                      color: _resendCooldown > 0
                          ? colors.onSurface.withValues(alpha: 0.35)
                          : colors.onSurface.withValues(alpha: 0.7),
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () async {
                    await auth.logout();
                    if (!context.mounted) return;
                    Navigator.pushNamedAndRemoveUntil(
                        context, '/login', (_) => false);
                  },
                  child: Text(
                    'Ce n\'est pas la bonne adresse ? Se déconnecter',
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.4),
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
