import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../../shared/widgets/auth_primary_button.dart';
import '../../../shared/services/card_service.dart';
import '../../../core/network/api_endpoints.dart';
import '../../auth/providers/auth_provider.dart';

class CreateCardForm extends StatefulWidget {
  const CreateCardForm({super.key});

  @override
  State<CreateCardForm> createState() => _CreateCardFormState();
}

class _CreateCardFormState extends State<CreateCardForm> {
  final _formKey = GlobalKey<FormState>();

  final _firstnameCtrl = TextEditingController();
  final _lastnameCtrl = TextEditingController();
  final _jobCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();

  final Map<String, bool> _activeFields = {
    'phone': false,
    'email': false,
  };

  // Suggestions "Poste" — statuts spéciaux en tête, puis intitulés courants.
  // Tapées comme des puces sous le champ plutôt qu'un vrai menu déroulant :
  // AuthTextField gère son propre FocusNode en interne, incompatible avec
  // le fieldViewBuilder qu'exige Autocomplete/RawAutocomplete.
  static const _jobSuggestions = [
    'Étudiant',
    'Entrepreneur',
    'Développeur',
    'Designer',
    "Chef de projet",
    'Consultant',
    'Commercial',
    'Marketing Manager',
    'Comptable',
    'Avocat',
    'Médecin',
    'Enseignant',
    'Ingénieur',
    'Ressources Humaines',
  ];

  // Suggestions "Entreprise" par défaut (pas de vraie entreprise) — en plus
  // de celles-ci, propose "Étudiant"/"Auto-entrepreneur" quand le poste
  // choisi est "Étudiant"/"Entrepreneur" (cf. _companySuggestions).
  static const _noCompanySuggestions = ['Indépendant', 'Freelance', 'Aucune'];

  List<String> get _companySuggestions {
    final job = _jobCtrl.text.trim().toLowerCase();
    if (job == 'étudiant') return const ['Étudiant', 'Aucune'];
    if (job == 'entrepreneur') {
      return const ['Auto-entrepreneur', 'Indépendant', 'Freelance'];
    }
    return _noCompanySuggestions;
  }

  bool _isPublic = true;
  bool _isSubmitting = false;
  bool _companyInitialized =
      false; // ✅ Flag pour éviter la réinitialisation multiple

  bool _companyLocked = false;
  Map<String, dynamic>? _lockedCompany;

  @override
  void initState() {
    super.initState();
    // ✅ Initialiser après le premier build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeCompanyField();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _initializeCompanyField();
  }

  void _initializeCompanyField() {
    if (_companyInitialized) return;
    _companyInitialized = true;

    final auth = context.read<AuthProvider>();
    final user = auth.user;

    if (user == null) return;

    // Pre-remplir les infos utilisateur (synchrone, ne dépend pas du réseau)
    if (user.firstname.isNotEmpty) {
      _firstnameCtrl.text = user.firstname;
    }
    if (user.lastname.isNotEmpty) {
      _lastnameCtrl.text = user.lastname;
    }
    if (user.phone != null && user.phone!.isNotEmpty) {
      _phoneCtrl.text = user.phone!;
      _activeFields['phone'] = true;
    }
    if (user.email.isNotEmpty) {
      _emailCtrl.text = user.email;
      _activeFields['email'] = true;
    }

    // Meilleure estimation immédiate (évite un flash de champ déverrouillé)
    // avant la réponse de /cards/create-context.
    setState(() => _companyLocked = user.hasCompany);

    _loadCompanyContext();
  }

  Future<void> _loadCompanyContext() async {
    final createContext = await CardService.getCreateContext();
    if (!mounted) return;

    final locked = createContext['company_locked'] == true;
    final company = createContext['company'] as Map<String, dynamic>?;

    setState(() {
      _companyLocked = locked;
      _lockedCompany = company;
    });

    if (locked && company != null) {
      _companyCtrl.text = company['name']?.toString() ?? '';
    }
  }

  @override
  void dispose() {
    _firstnameCtrl.dispose();
    _lastnameCtrl.dispose();
    _jobCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  // ---------------- ACTIONS ----------------

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final activatedFields = _activeFields.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      // Si verrouillé, le champ est déjà prérempli et non modifiable ;
      // le backend impose de toute façon le nom d'entreprise côté serveur.
      // Entreprise est désormais optionnelle (nullable côté backend) :
      // envoyée seulement si renseignée, jamais une chaîne vide forcée.
      final data = {
        'jobTitle': _jobCtrl.text.trim(),
        'company':
            _companyCtrl.text.trim().isEmpty ? null : _companyCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'activatedFields': activatedFields,
        'isPublic': _isPublic,
      };

      if (kDebugMode) {
        // debugPrint('📤 Données envoyées : $data');
      }

      await CardService.createCard(
        jobTitle: data['jobTitle']! as String,
        company: data['company'] as String?,
        firstname: _firstnameCtrl.text.trim(),
        lastname: _lastnameCtrl.text.trim(),
        phone: data['phone'] as String?,
        email: data['email'] as String?,
        activatedFields: activatedFields,
        isPublic: _isPublic,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } on DioException catch (e) {
      // Erreurs de validation du backend
      if (e.response?.statusCode == 422) {
        final errors = e.response?.data;
        String errorMsg = 'Erreur de validation :\n';

        if (errors is Map) {
          errors.forEach((key, value) {
            if (value is List) {
              errorMsg += '$key : ${value.join(", ")}\n';
            } else {
              errorMsg += '$key : $value\n';
            }
          });
        } else {
          errorMsg = e.response?.data.toString() ?? 'Erreur 422';
        }

        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Erreur de validation'),
              content: Text(errorMsg),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      } else {
        // Autres erreurs réseau ou serveur
        if (mounted) {
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Erreur'),
              content: Text('Une erreur est survenue : ${e.message}'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  String? get _lockedCompanyLogoUrl {
    final logo = _lockedCompany?['logo'] as String?;
    if (logo == null || logo.isEmpty) return null;
    if (logo.startsWith('http://') || logo.startsWith('https://')) {
      return logo;
    }
    return '${ApiEndpoints.storageUrl}/$logo';
  }

  // Entreprise n'est plus requise — utile sans société propre (étudiant,
  // entrepreneur individuel...), cf. suggestions de _companySuggestions.
  bool _isFormValid() {
    return _firstnameCtrl.text.isNotEmpty &&
        _lastnameCtrl.text.isNotEmpty &&
        _jobCtrl.text.isNotEmpty;
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final isCompanyLinked = _companyLocked;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              left: 28,
              right: 28,
              top: 32,
              bottom: bottomPadding > 0 ? bottomPadding + 32 : 32,
            ),
            child: Column(
              children: [
                // HEADER
                Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: colors.onSurface.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          color: colors.onSurface,
                          size: 22,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      'KART',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                        color: colors.onSurface,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(width: 42),
                  ],
                ),

                const SizedBox(height: 32),

                // Title
                Text(
                  'Créer ma carte',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: colors.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 8),

                Text(
                  'Remplissez vos informations professionnelles',
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.5),
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 32),

                // User Info
                Text(
                  'Informations personnelles',
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 16),

                AuthTextField(
                  label: 'Prénom',
                  controller: _firstnameCtrl,
                  onChanged: (_) => setState(() {}),
                  prefixIcon: Icons.person_outline,
                  hint: 'Ex: Adama',
                ),

                const SizedBox(height: 16),

                AuthTextField(
                  label: 'Nom',
                  controller: _lastnameCtrl,
                  onChanged: (_) => setState(() {}),
                  prefixIcon: Icons.person_outline,
                  hint: 'Ex: Dabo',
                ),

                const SizedBox(height: 16),

                // Professional Info
                AuthTextField(
                  label: 'Votre poste',
                  controller: _jobCtrl,
                  onChanged: (_) => setState(() {}),
                  prefixIcon: Icons.work_outline,
                  hint: 'Ex: Étudiant, Entrepreneur, Développeur...',
                ),
                _buildSuggestionChips(_jobSuggestions, _jobCtrl),

                const SizedBox(height: 32),

                // Company Info
                Row(
                  children: [
                    if (isCompanyLinked && _lockedCompanyLogoUrl != null) ...[
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          _lockedCompanyLogoUrl!,
                          width: 24,
                          height: 24,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(
                      'Informations de l\'entreprise',
                      style: TextStyle(
                        color: colors.onSurface.withValues(alpha: 0.7),
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),

                if (isCompanyLinked) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.lock_outline_rounded,
                          color: const Color(0xFF3B82F6),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Défini par votre entreprise',
                          style: TextStyle(
                            color: const Color(0xFF60A5FA),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                AuthTextField(
                  // (optionnel) : pas de vraie entreprise ? laisse vide ou
                  // choisis une suggestion ci-dessous (Indépendant, Étudiant...).
                  label: 'Nom de l\'entreprise (optionnel)',
                  controller: _companyCtrl,
                  enabled: !isCompanyLinked,
                  onChanged: (_) => setState(() {}),
                  prefixIcon: isCompanyLinked
                      ? Icons.lock_outline_rounded
                      : Icons.business_outlined,
                  hint: 'Ex: Kart Technologies, Indépendant...',
                ),
                if (!isCompanyLinked)
                  _buildSuggestionChips(_companySuggestions, _companyCtrl),

                const SizedBox(height: 32),

                // Contact Info
                Text(
                  'Coordonnées de contact',
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 16),

                AuthTextField(
                  label: 'Numero de telephone',
                  controller: _phoneCtrl,
                  onChanged: (_) => setState(() {}),
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  hint: 'Ex: +221 77 123 45 67',
                ),

                const SizedBox(height: 12),

                _buildPremiumSwitch(
                  title: 'Afficher le telephone sur ma carte',
                  value: _activeFields['phone'] ?? false,
                  onChanged: (v) => setState(() => _activeFields['phone'] = v),
                  icon: Icons.visibility_outlined,
                ),

                const SizedBox(height: 24),

                AuthTextField(
                  label: 'Adresse email professionnelle',
                  controller: _emailCtrl,
                  onChanged: (_) => setState(() {}),
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  hint: 'Ex: nom@entreprise.com',
                ),

                const SizedBox(height: 12),

                _buildPremiumSwitch(
                  title: 'Afficher l\'email sur ma carte',
                  value: _activeFields['email'] ?? false,
                  onChanged: (v) => setState(() => _activeFields['email'] = v),
                  icon: Icons.visibility_outlined,
                ),

                const SizedBox(height: 32),

                // Visibilité — réseaux sociaux (LinkedIn, Instagram,
                // GitHub, Facebook, site web) retirés de la création :
                // à compléter plus tard depuis le profil (section
                // "Réseaux sociaux"), pour ne pas surcharger cette
                // première étape.
                Text(
                  'Visibilité',
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 16),

                _buildPremiumSwitch(
                  title: 'Rendre ma carte publique',
                  subtitle: 'Accessible via un lien ou QR code',
                  value: _isPublic,
                  onChanged: (v) => setState(() => _isPublic = v),
                  icon: Icons.public_outlined,
                ),

                const SizedBox(height: 32),

                // Submit Button
                AuthPrimaryButton(
                  label: 'Créer ma carte',
                  icon: Icons.check_rounded,
                  loading: _isSubmitting,
                  onTap: _isFormValid() ? _submit : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- HELPERS ----------------

  /// Puces de suggestion sous un champ (Poste, Entreprise) — sert de "liste
  /// déroulante" sans les problèmes d'intégration d'un vrai Autocomplete
  /// (AuthTextField gère son propre FocusNode en interne). Un tap remplit
  /// le champ ; retaper à la main reste toujours possible.
  Widget _buildSuggestionChips(
      List<String> suggestions, TextEditingController controller) {
    final colors = Theme.of(context).colorScheme;
    final current = controller.text.trim().toLowerCase();

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: suggestions.map((s) {
          final selected = current == s.toLowerCase();
          return GestureDetector(
            onTap: () => setState(() => controller.text = s),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
              decoration: BoxDecoration(
                color: selected
                    ? const Color(0xFF3B82F6).withValues(alpha: 0.15)
                    : colors.onSurface.withValues(alpha: 0.04),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: selected
                      ? const Color(0xFF3B82F6).withValues(alpha: 0.4)
                      : colors.onSurface.withValues(alpha: 0.1),
                ),
              ),
              child: Text(
                s,
                style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: selected
                      ? const Color(0xFF3B82F6)
                      : colors.onSurface.withValues(alpha: 0.6),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPremiumSwitch({
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    IconData? icon,
  }) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: value
            ? colors.onSurface.withValues(alpha: 0.08)
            : colors.onSurface.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: value
              ? colors.onSurface.withValues(alpha: 0.15)
              : colors.onSurface.withValues(alpha: 0.06),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          if (icon != null) ...[
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: value
                    ? colors.onSurface.withValues(alpha: 0.12)
                    : colors.onSurface.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: value
                    ? colors.onSurface
                    : colors.onSurface.withValues(alpha: 0.5),
                size: 18,
              ),
            ),
            const SizedBox(width: 14),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: value
                        ? colors.onSurface
                        : colors.onSurface.withValues(alpha: 0.7),
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.onSurface.withValues(alpha: 0.5),
                      fontSize: 12,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Transform.scale(
            scale: 0.85,
            child: Switch.adaptive(
              value: value,
              onChanged: onChanged,
              activeThumbColor: isDark ? Colors.white : const Color(0xFF3B82F6),
              activeTrackColor: isDark
                  ? const Color(0xFF3B82F6)
                  : const Color(0xFF3B82F6).withValues(alpha: 0.5),
              inactiveThumbColor: colors.onSurface.withValues(alpha: 0.4),
              inactiveTrackColor: colors.onSurface.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}
