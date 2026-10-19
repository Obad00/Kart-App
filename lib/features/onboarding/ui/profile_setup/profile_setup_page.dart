import 'dart:typed_data';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:image_cropper/image_cropper.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../../../core/network/api_endpoints.dart';
import '../../../../core/theme/kart_tokens.dart';
import '../../../../shared/utils/crop_image.dart';
import '../../../../shared/utils/initials.dart';
import '../../../../shared/utils/placeholder_email.dart';
import '../../../../shared/widgets/auth_primary_button.dart';
import '../../../../shared/widgets/auth_text_field.dart';
import '../../../auth/providers/auth_provider.dart';
import '../../data/profile_setup_api.dart';

/// Onboarding d'un nouveau compte, après l'inscription et le consentement :
/// photo, poste et entreprise, un moyen de contact, visibilité. Chaque
/// étape se passe avec « Plus tard » ; « Passer » termine tout de suite.
/// Dans tous les cas, la fin est notée côté serveur (onboarding_completed_at)
/// et l'écran ne revient plus.
///
/// Avec [singleStep], une seule étape s'affiche (ouverte depuis la carte
/// « Complétez votre profil ») : « Continuer » ou « Plus tard » referment
/// l'écran, sans toucher à l'onboarding.
class ProfileSetupPage extends StatefulWidget {
  const ProfileSetupPage({
    super.key,
    this.api = const ProfileSetupApi(),
    this.pickAvatar,
    this.singleStep,
  });

  final ProfileSetupApi api;

  /// Étape seule à afficher : 0 photo, 1 poste et entreprise, 2 contact,
  /// 3 visibilité. null : le parcours complet.
  final int? singleStep;

  /// Choix et recadrage de la photo ; remplaçable dans les tests.
  /// Renvoie les octets et le nom du fichier, ou null si annulé.
  final Future<(Uint8List, String)?> Function(BuildContext context)? pickAvatar;

  @override
  State<ProfileSetupPage> createState() => _ProfileSetupPageState();
}

class _ProfileSetupPageState extends State<ProfileSetupPage> {
  static const _steps = 4;

  late int _step = widget.singleStep ?? 0;

  bool get _single => widget.singleStep != null;
  bool _loading = true;
  bool _saving = false;

  final _jobCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();

  /// Champs affichés sur la carte (activated_fields), complétés étape c.
  List<String> _activated = [];
  bool _showPhone = true;
  bool _whatsapp = false;
  bool _showEmail = false;

  /// E-mail du compte à proposer ; jamais l'adresse interne.
  String? _email;

  bool _isPublic = true;
  bool _listed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _jobCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final user = context.read<AuthProvider>().user;
    Map<String, dynamic> card = {};
    try {
      card = await widget.api.fetchCard();
    } catch (_) {
      // Carte pas encore lisible : les étapes partent de champs vides.
    }
    if (!mounted) return;

    final activated = (card['activated_fields'] as List?)?.map((e) => e.toString()).toList() ?? <String>[];
    final phone = (card['phone'] as String?)?.trim().isNotEmpty == true
        ? card['phone'] as String
        : (user?.phone ?? '');

    setState(() {
      _jobCtrl.text = (card['job_title'] as String?) ?? '';
      _companyCtrl.text = (card['company'] as String?) ?? '';
      _phoneCtrl.text = phone;
      _activated = activated;
      _showPhone = activated.contains('phone') || phone.isNotEmpty;
      _whatsapp = activated.contains('whatsapp');
      _email = displayableEmail(card['email'] as String?) ?? displayableEmail(user?.email);
      _showEmail = _email != null && activated.contains('email');
      _isPublic = card['is_public'] as bool? ?? true;
      // Jamais activé d'office : seulement si l'utilisateur l'a déjà choisi.
      _listed = card['listed_in_directory'] == true;
      _loading = false;
    });
  }

  // ── Navigation ─────────────────────────────────────────────────────────

  Future<void> _next() async {
    if (_single) {
      Navigator.of(context).pop(true);
      return;
    }
    if (_step < _steps - 1) {
      setState(() => _step++);
    } else {
      await _finish();
    }
  }

  Future<void> _finish() async {
    setState(() => _saving = true);
    final ok = await context.read<AuthProvider>().completeOnboarding();
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      Navigator.of(context).pushNamedAndRemoveUntil('/home', (_) => false);
    } else {
      _error();
    }
  }

  /// Enregistre l'étape, puis passe à la suivante. Reste sur place en cas
  /// d'échec.
  Future<void> _saveAndNext(Map<String, dynamic> fields) async {
    setState(() => _saving = true);
    try {
      await widget.api.saveCard(fields);
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      _error();
      return;
    }
    if (!mounted) return;
    setState(() => _saving = false);
    await _next();
  }

  void _error() {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text("Impossible d'enregistrer pour le moment. Réessayez."),
    ));
  }

  // ── Étapes ─────────────────────────────────────────────────────────────

  Future<void> _pickPhoto() async {
    final picked = await (widget.pickAvatar ?? _defaultPickAvatar)(context);
    if (picked == null || !mounted) return;
    setState(() => _saving = true);
    try {
      await context.read<AuthProvider>().updateAvatar(picked.$1, picked.$2);
    } catch (_) {
      if (mounted) _error();
    }
    if (mounted) setState(() => _saving = false);
  }

  static Future<(Uint8List, String)?> _defaultPickAvatar(BuildContext context) async {
    final picked = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (picked == null || !context.mounted) return null;
    final cropped = await cropPickedImage(context, picked.path, cropStyle: CropStyle.circle);
    if (cropped == null) return null;
    return (await cropped.readAsBytes(), picked.name);
  }

  void _saveJob() {
    final job = _jobCtrl.text.trim();
    final company = _companyCtrl.text.trim();
    _saveAndNext({
      if (job.isNotEmpty) 'job_title': job,
      if (company.isNotEmpty) 'company': company,
    });
  }

  bool get _contactChosen =>
      (_phoneCtrl.text.trim().isNotEmpty && (_showPhone || _whatsapp)) || (_email != null && _showEmail);

  void _saveContact() {
    final hasPhone = _phoneCtrl.text.trim().isNotEmpty;
    final activated = {..._activated}
      ..remove('phone')
      ..remove('whatsapp')
      ..remove('email');
    if (hasPhone && _showPhone) activated.add('phone');
    if (hasPhone && _whatsapp) activated.add('whatsapp');
    if (_email != null && _showEmail) activated.add('email');
    _saveAndNext({
      if (hasPhone) 'phone': _phoneCtrl.text.trim(),
      'activated_fields': activated.toList(),
    });
  }

  void _saveVisibility() {
    _saveAndNext({
      'is_public': _isPublic,
      // Une carte non publique n'est jamais dans l'annuaire.
      'listed_in_directory': _isPublic && _listed,
    });
  }

  // ── Affichage ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final t = KartTokens.of(context);
    final colors = Theme.of(context).colorScheme;

    return PopScope(
      canPop: _single,
      child: Scaffold(
        backgroundColor: colors.surface,
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (_single)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            key: const Key('onboarding-close'),
                            icon: Icon(Icons.close_rounded, color: t.textPrimary),
                            onPressed: _saving ? null : () => Navigator.of(context).pop(false),
                          ),
                        )
                      else
                        Row(
                          children: [
                            Expanded(child: _progress(t)),
                            const SizedBox(width: 12),
                            TextButton(
                              key: const Key('onboarding-skip-all'),
                              onPressed: _saving ? null : _finish,
                              child: Text('Passer', style: TextStyle(color: t.textSecondary)),
                            ),
                          ],
                        ),
                      const SizedBox(height: 24),
                      Expanded(
                        child: SingleChildScrollView(
                          child: KeyedSubtree(key: ValueKey(_step), child: _stepBody(t)),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _actions(t),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Widget _progress(KartTokens t) => Row(
        children: [
          for (var i = 0; i < _steps; i++) ...[
            if (i > 0) const SizedBox(width: 6),
            Expanded(
              child: Container(
                height: 4,
                decoration: BoxDecoration(
                  color: i <= _step ? t.textPrimary : t.softBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
          ],
        ],
      );

  Widget _title(KartTokens t, String title, String subtitle) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontFamily: 'Syne', fontSize: 26, fontWeight: FontWeight.w700, color: t.textPrimary)),
          const SizedBox(height: 8),
          Text(subtitle, style: TextStyle(fontSize: 15, height: 1.45, color: t.textSecondary)),
          const SizedBox(height: 28),
        ],
      );

  Widget _stepBody(KartTokens t) {
    switch (_step) {
      case 0:
        return _photoStep(t);
      case 1:
        return Column(
          children: [
            _title(t, 'Poste et entreprise', 'Ce qui apparaît sous votre nom sur votre carte.'),
            AuthTextField(label: 'Poste', hint: 'Ex : Directrice commerciale', controller: _jobCtrl, prefixIcon: Icons.work_outline),
            const SizedBox(height: 16),
            AuthTextField(label: 'Entreprise', hint: 'Ex : Entreprise Exemple', controller: _companyCtrl, prefixIcon: Icons.apartment_outlined),
          ],
        );
      case 2:
        return _contactStep(t);
      default:
        return _visibilityStep(t);
    }
  }

  Widget _photoStep(KartTokens t) {
    final user = context.watch<AuthProvider>().user;
    final avatar = (user?.avatar ?? '').trim();
    final url = avatar.isEmpty ? null : (avatar.startsWith('http') ? avatar : '${ApiEndpoints.storageUrl}/$avatar');
    final name = '${user?.firstname ?? ''} ${user?.lastname ?? ''}'.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _title(t, 'Votre photo', 'Une photo aide vos contacts à vous reconnaître.'),
        Center(
          child: Container(
            key: const Key('onboarding-avatar'),
            width: 132,
            height: 132,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF002842),
              image: url == null ? null : DecorationImage(image: CachedNetworkImageProvider(url), fit: BoxFit.cover),
            ),
            alignment: Alignment.center,
            child: url == null
                ? Text(getInitials(name, fallback: '?'),
                    style: const TextStyle(fontFamily: 'Syne', fontSize: 40, fontWeight: FontWeight.w700, color: Colors.white))
                : null,
          ),
        ),
      ],
    );
  }

  Widget _contactStep(KartTokens t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(t, 'Comment vous joindre', 'Au moins un moyen de contact, affiché sur votre carte.'),
          AuthTextField(
            label: 'Téléphone',
            hint: '+221 77 000 00 00',
            controller: _phoneCtrl,
            keyboardType: TextInputType.phone,
            prefixIcon: Icons.phone_outlined,
            // Premier numéro saisi : affiché par défaut (c'est le but de
            // l'étape) ; l'utilisateur peut toujours décocher.
            onChanged: (value) => setState(() {
              if (value.trim().isNotEmpty && !_showPhone && !_whatsapp) _showPhone = true;
            }),
          ),
          const SizedBox(height: 16),
          _toggle(t, key: 'onboarding-show-phone', title: 'Afficher mon numéro', value: _showPhone,
              onChanged: _phoneCtrl.text.trim().isEmpty ? null : (v) => setState(() => _showPhone = v)),
          const SizedBox(height: 10),
          _toggle(t, key: 'onboarding-whatsapp', title: 'Joignable sur WhatsApp', value: _whatsapp,
              onChanged: _phoneCtrl.text.trim().isEmpty ? null : (v) => setState(() => _whatsapp = v)),
          // L'e-mail du compte, s'il en a un vrai (jamais l'adresse interne).
          if (_email != null) ...[
            const SizedBox(height: 10),
            _toggle(t, key: 'onboarding-show-email', title: 'Afficher mon e-mail', subtitle: _email, value: _showEmail,
                onChanged: (v) => setState(() => _showEmail = v)),
          ],
        ],
      );

  Widget _visibilityStep(KartTokens t) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title(t, 'Qui peut voir votre carte', 'Vous pourrez changer ces réglages à tout moment dans « Modifier mes infos ».'),
          _toggle(t, key: 'onboarding-public', title: 'Rendre ma carte publique',
              subtitle: 'Votre lien, votre QR et votre carte NFC ouvrent votre carte.', value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v)),
          const SizedBox(height: 10),
          // Même texte que « Modifier mes infos ».
          _toggle(t, key: 'onboarding-listed', title: 'Apparaître dans Explorer',
              subtitle: _isPublic
                  ? 'Les membres KART peuvent vous trouver. Votre lien, votre QR et votre carte NFC fonctionnent dans tous les cas.'
                  : "Rendez d'abord votre carte publique.",
              value: _isPublic && _listed,
              onChanged: _isPublic ? (v) => setState(() => _listed = v) : null),
        ],
      );

  Widget _toggle(KartTokens t,
      {required String key, required String title, String? subtitle, required bool value, required ValueChanged<bool>? onChanged}) {
    return Opacity(
      opacity: onChanged == null ? 0.5 : 1,
      child: Container(
        key: Key(key),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: t.softFill,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: t.softBorder),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: t.textPrimary)),
                  if (subtitle != null) ...[
                    const SizedBox(height: 3),
                    Text(subtitle, style: TextStyle(fontSize: 12, height: 1.35, color: t.textSecondary)),
                  ],
                ],
              ),
            ),
            Switch.adaptive(value: value, onChanged: onChanged),
          ],
        ),
      ),
    );
  }

  Widget _actions(KartTokens t) {
    final user = context.watch<AuthProvider>().user;
    final hasPhoto = (user?.avatar ?? '').trim().isNotEmpty;

    final (String label, VoidCallback? onTap) = switch (_step) {
      0 => hasPhoto ? ('Continuer', _next) : ('Ajouter une photo', _pickPhoto),
      1 => ('Continuer', _saveJob),
      2 => ('Continuer', _contactChosen ? _saveContact : null),
      _ => (_single ? 'Enregistrer' : 'Terminer', _saveVisibility),
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthPrimaryButton(key: const Key('onboarding-primary'), label: label, loading: _saving, onTap: _saving ? null : onTap),
        const SizedBox(height: 4),
        TextButton(
          key: const Key('onboarding-later'),
          onPressed: _saving ? null : _next,
          child: Text('Plus tard', style: TextStyle(color: t.textSecondary)),
        ),
      ],
    );
  }
}
