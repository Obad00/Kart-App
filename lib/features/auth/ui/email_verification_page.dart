import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../../core/ui/feedback/feedback_overlay.dart';
import '../../../shared/services/card_service.dart';
import '../../../shared/widgets/auth_primary_button.dart';
import '../../digital_card/providers/card_provider.dart';
import '../data/email_verification_service.dart';
import '../providers/auth_provider.dart';

/// Vérification de l'email : code à 6 chiffres reçu par email (ou lien du
/// même email). Le compte à rebours du renvoi vient du serveur (1 renvoi par
/// minute, 5 par heure).
///
/// [blocking] (inscription, ou HomeShell pour un compte à vérification
/// obligatoire) : une fois l'email vérifié, la carte digitale est créée en
/// arrière-plan puis l'accueil s'ouvre (onboarding). Sinon (ouvert depuis le
/// bandeau) : retour à l'écran précédent.
class EmailVerificationPage extends StatefulWidget {
  final bool blocking;
  final EmailVerificationService? service;

  const EmailVerificationPage({super.key, this.blocking = true, this.service});

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  static const _codeLength = 6;

  late final EmailVerificationService _service =
      widget.service ?? EmailVerificationService();
  final _codeCtrl = TextEditingController();
  final _codeFocus = FocusNode();

  Timer? _pollTimer;
  Timer? _cooldownTimer;
  int _resendCooldown = 0;
  bool _submitting = false;
  bool _resending = false;
  bool _proceeding = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;
    if (user != null && !user.emailVerificationCodeSupported) {
      // Serveur d'avant le code : il n'envoie rien à l'inscription.
      unawaited(_service.resend());
    } else {
      _startCooldown(user?.emailVerificationRetryAfter ?? 0);
    }
    // Le lien de l'email ouvre le navigateur, pas l'app : on regarde
    // régulièrement si l'adresse a été confirmée par ce biais.
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) => _checkLink());
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _cooldownTimer?.cancel();
    _codeCtrl.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  void _startCooldown(int seconds) {
    _cooldownTimer?.cancel();
    setState(() => _resendCooldown = seconds);
    if (seconds <= 0) return;
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() => _resendCooldown--);
      if (_resendCooldown <= 0) timer.cancel();
    });
  }

  Future<void> _resend() async {
    if (_resending || _resendCooldown > 0) return;
    setState(() => _resending = true);
    final result = await _service.resend();
    if (!mounted) return;
    setState(() => _resending = false);
    _startCooldown(result.retryAfter);
    if (result.sent) {
      _codeCtrl.clear();
      setState(() => _error = null);
      FeedbackOverlay.showSuccess(context, title: 'Code envoyé', subtitle: 'Un nouveau code vient de partir.');
    } else {
      setState(() => _error = result.message);
    }
  }

  Future<void> _submit() async {
    final code = _codeCtrl.text.trim();
    if (code.length != _codeLength || _submitting) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    final result = await _service.verifyCode(code);
    if (!mounted) return;
    if (result.verified) {
      await _onVerified();
      return;
    }
    setState(() {
      _submitting = false;
      _error = result.message;
    });
    _codeCtrl.clear();
    _codeFocus.requestFocus();
  }

  Future<void> _checkLink() async {
    if (_submitting || _proceeding) return;
    final auth = context.read<AuthProvider>();
    await auth.loadMe();
    if (!mounted) return;
    if (auth.user?.emailVerified == true) await _onVerified();
  }

  Future<void> _onVerified() async {
    if (_proceeding) return;
    _pollTimer?.cancel();
    setState(() => _proceeding = true);
    final auth = context.read<AuthProvider>();
    await auth.loadMe();
    if (!mounted) return;

    if (!widget.blocking) {
      FeedbackOverlay.showSuccess(context, title: 'Email vérifié', subtitle: 'Votre adresse est confirmée.');
      Navigator.of(context).pop(true);
      return;
    }

    try {
      await CardService.createDefaultCard();
    } catch (e) {
      // Non bloquant : déjà créée (inscription sur le site) ou souci
      // réseau ponctuel ; MyDigitalCardPage propose alors « Créer ma carte ».
      debugPrint('⚠️ Création auto de la carte échouée (non bloquant): $e');
    }
    if (!mounted) return;
    await context.read<CardProvider>().loadCardSummary();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/home', (_) => false);
  }

  Future<void> _changeEmail(AuthProvider auth) async {
    final user = auth.user;
    if (user == null) return;
    final ctrl = TextEditingController(text: user.email);
    final email = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Corriger mon adresse'),
        content: TextField(
          controller: ctrl,
          keyboardType: TextInputType.emailAddress,
          autofocus: true,
          decoration: const InputDecoration(prefixIcon: Icon(Icons.alternate_email_rounded)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(dialogContext, ctrl.text.trim()), child: const Text('Envoyer le code')),
        ],
      ),
    );
    ctrl.dispose();
    if (email == null || email.isEmpty || email == user.email || !mounted) return;

    // Un nouveau code part à la nouvelle adresse (PUT /me, autorisé avant
    // la vérification).
    final error = await auth.changeLoginEmail(email);
    if (!mounted) return;
    _codeCtrl.clear();
    setState(() => _error = error);
    if (error == null) _startCooldown(auth.user?.emailVerificationRetryAfter ?? 60);
  }

  String _formatCooldown(int seconds) {
    final m = seconds ~/ 60;
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final email = auth.user?.email ?? '';

    return PopScope(
      canPop: !widget.blocking,
      child: Scaffold(
        backgroundColor: colors.surface,
        appBar: widget.blocking
            ? null
            : AppBar(backgroundColor: colors.surface, elevation: 0, foregroundColor: colors.onSurface),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
            child: Column(
              children: [
                const SizedBox(height: 16),
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
                          child: SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 2.5)),
                        )
                      : Icon(Icons.mark_email_unread_outlined, color: colors.onSurface, size: 40),
                ),
                const SizedBox(height: 28),
                Text(
                  _proceeding ? 'Email vérifié !' : 'Vérifiez votre email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Syne',
                    fontSize: 26,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _proceeding
                      ? (widget.blocking ? 'Création de votre carte digitale...' : '')
                      : 'Saisissez le code à 6 chiffres envoyé à\n$email\n\nVous pouvez aussi ouvrir le lien du même email.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: colors.onSurface.withValues(alpha: 0.6), fontSize: 15, height: 1.45),
                ),
                if (!_proceeding) ...[
                  const SizedBox(height: 28),
                  _CodeBoxes(
                    controller: _codeCtrl,
                    focusNode: _codeFocus,
                    length: _codeLength,
                    enabled: !_submitting,
                    hasError: _error != null,
                    onCompleted: _submit,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Color(0xFFEF4444), fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ],
                  const SizedBox(height: 28),
                  ValueListenableBuilder<TextEditingValue>(
                    valueListenable: _codeCtrl,
                    builder: (context, value, _) => AuthPrimaryButton(
                      label: 'Valider le code',
                      icon: Icons.check_rounded,
                      loading: _submitting,
                      onTap: value.text.length == _codeLength ? _submit : null,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _resendCooldown > 0 || _resending ? null : _resend,
                    child: Text(
                      _resendCooldown > 0
                          ? 'Renvoyer le code dans ${_formatCooldown(_resendCooldown)}'
                          : 'Renvoyer le code',
                      style: TextStyle(
                        color: _resendCooldown > 0
                            ? colors.onSurface.withValues(alpha: 0.35)
                            : colors.onSurface.withValues(alpha: 0.8),
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => _changeEmail(auth),
                    child: Text(
                      'Ce n\'est pas la bonne adresse ? La corriger',
                      style: TextStyle(color: colors.onSurface.withValues(alpha: 0.55), fontSize: 13),
                    ),
                  ),
                  if (widget.blocking)
                    TextButton(
                      onPressed: () async {
                        await auth.logout();
                        if (!context.mounted) return;
                        Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
                      },
                      child: Text(
                        'Se déconnecter',
                        style: TextStyle(color: colors.onSurface.withValues(alpha: 0.4), fontSize: 13),
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Six cases ; un seul champ invisible par-dessus reçoit la saisie (et le
/// remplissage automatique du code par le clavier).
class _CodeBoxes extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final int length;
  final bool enabled;
  final bool hasError;
  final VoidCallback onCompleted;

  const _CodeBoxes({
    required this.controller,
    required this.focusNode,
    required this.length,
    required this.enabled,
    required this.hasError,
    required this.onCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      alignment: Alignment.center,
      children: [
        ValueListenableBuilder<TextEditingValue>(
          valueListenable: controller,
          builder: (context, value, _) => Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(length, (i) {
              final char = i < value.text.length ? value.text[i] : '';
              final active = i == value.text.length && focusNode.hasFocus;
              return Container(
                width: 46,
                height: 56,
                margin: EdgeInsets.only(right: i == length - 1 ? 0 : 8),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.onSurface.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    width: active ? 1.6 : 1,
                    color: hasError
                        ? const Color(0xFFEF4444).withValues(alpha: 0.7)
                        : active
                            ? colors.onSurface.withValues(alpha: 0.7)
                            : colors.onSurface.withValues(alpha: 0.14),
                  ),
                ),
                child: Text(
                  char,
                  style: TextStyle(fontFamily: 'Syne', fontSize: 24, fontWeight: FontWeight.w700, color: colors.onSurface),
                ),
              );
            }),
          ),
        ),
        Positioned.fill(
          child: Opacity(
            opacity: 0,
            child: TextField(
              key: const Key('email-code-field'),
              controller: controller,
              focusNode: focusNode,
              enabled: enabled,
              autofocus: true,
              keyboardType: TextInputType.number,
              autofillHints: const [AutofillHints.oneTimeCode],
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(length)],
              showCursor: false,
              enableInteractiveSelection: false,
              onChanged: (text) {
                if (text.length == length) onCompleted();
              },
            ),
          ),
        ),
      ],
    );
  }
}
