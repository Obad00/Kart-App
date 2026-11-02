import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../data/email_verification_service.dart';
import '../providers/auth_provider.dart';
import '../ui/email_verification_page.dart';

/// Bandeau non bloquant pour un compte non vérifié qui n'est pas soumis à la
/// vérification obligatoire (ancien compte, ancien build, visiteur
/// d'événement qui a ajouté une vraie adresse) : renvoi du code avec compte
/// à rebours du serveur, et saisie du code.
class EmailVerificationBanner extends StatefulWidget {
  final EmailVerificationService? service;

  const EmailVerificationBanner({super.key, this.service});

  @override
  State<EmailVerificationBanner> createState() => _EmailVerificationBannerState();
}

class _EmailVerificationBannerState extends State<EmailVerificationBanner> {
  late final EmailVerificationService _service = widget.service ?? EmailVerificationService();
  Timer? _timer;
  int _cooldown = 0;
  bool _sending = false;
  String? _notice;

  @override
  void initState() {
    super.initState();
    _start(context.read<AuthProvider>().user?.emailVerificationRetryAfter ?? 0);
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start(int seconds) {
    _timer?.cancel();
    _cooldown = seconds;
    if (seconds <= 0) return;
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _cooldown--);
      if (_cooldown <= 0) timer.cancel();
    });
  }

  Future<void> _resend() async {
    setState(() => _sending = true);
    final result = await _service.resend();
    if (!mounted) return;
    setState(() {
      _sending = false;
      _notice = result.sent ? 'Email envoyé : saisissez le code ou ouvrez le lien.' : result.message;
      _start(result.retryAfter);
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user;
    if (user == null || !user.emailVerificationBanner || user.emailVerified) {
      return const SizedBox.shrink();
    }

    final colors = Theme.of(context).colorScheme;
    const accent = Color(0xFFF59E0B);
    final cooldown = _cooldown > 0 ? ' (${_cooldown ~/ 60}:${(_cooldown % 60).toString().padLeft(2, '0')})' : '';

    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [accent.withValues(alpha: 0.12), accent.withValues(alpha: 0.04)],
        ),
        border: Border.all(color: accent.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.mark_email_unread_outlined, size: 18, color: accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirmez votre adresse email',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: colors.onSurface),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _notice ?? user.email,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurface.withValues(alpha: 0.55),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _cooldown > 0 || _sending ? null : _resend,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.onSurface,
                    side: BorderSide(color: colors.onSurface.withValues(alpha: 0.2)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(
                    'Renvoyer$cooldown',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      // Fixé ici : le thème clair impose sinon sa propre couleur.
                      color: colors.onSurface.withValues(alpha: _cooldown > 0 || _sending ? 0.4 : 1),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => EmailVerificationPage(blocking: false, service: widget.service)),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: colors.onSurface,
                    foregroundColor: colors.surface,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Saisir le code', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
