import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../../shared/widgets/auth_primary_button.dart';
import '../../../shared/services/card_service.dart';
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
  final _companyAddressCtrl = TextEditingController();
  final _companyPhoneCtrl = TextEditingController();
  final _companyEmailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _linkedinCtrl = TextEditingController();

  final Map<String, bool> _activeFields = {
    'phone': false,
    'email': false,
    'linkedin': false,
  };

  bool _isPublic = true;
  bool _isSubmitting = false;
  bool _companyInitialized =
      false; // ✅ Flag pour éviter la réinitialisation multiple

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

    final auth = context.read<AuthProvider>();
    final user = auth.user;

    debugPrint('📝 Initializing card form with user data:');
    debugPrint('   - User: ${user?.firstname} ${user?.lastname}');
    debugPrint('   - Phone: ${user?.phone}');
    debugPrint('   - Email: ${user?.email}');
    debugPrint('   - Company: ${user?.company?.name}');

    Future.microtask(() {
      if (mounted && user != null) {
        // Pre-remplir les infos utilisateur
        if (user.firstname.isNotEmpty) {
          _firstnameCtrl.text = user.firstname;
        }
        if (user.lastname.isNotEmpty) {
          _lastnameCtrl.text = user.lastname;
        }

        // Pre-remplir le nom de l'entreprise si disponible
        if (user.hasCompany &&
            user.company != null &&
            user.company!.name.isNotEmpty) {
          _companyCtrl.text = user.company!.name;
          debugPrint('✅ Company pre-filled: ${user.company!.name}');

          // Pre-remplir les infos entreprise (licence entreprise)
          final company = user.company!;
          if (company.address != null && company.address!.isNotEmpty) {
            _companyAddressCtrl.text = company.address!;
          }
          if (company.phone != null && company.phone!.isNotEmpty) {
            _companyPhoneCtrl.text = company.phone!;
          }
          if (company.email != null && company.email!.isNotEmpty) {
            _companyEmailCtrl.text = company.email!;
          }
        }

        // Pre-remplir le telephone si disponible
        if (user.phone != null && user.phone!.isNotEmpty) {
          _phoneCtrl.text = user.phone!;
          _activeFields['phone'] = true;
          debugPrint('✅ Phone pre-filled: ${user.phone}');
        }

        // Pre-remplir l'email si disponible
        if (user.email.isNotEmpty) {
          _emailCtrl.text = user.email;
          _activeFields['email'] = true;
          debugPrint('✅ Email pre-filled: ${user.email}');
        }

        _companyInitialized = true;
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _firstnameCtrl.dispose();
    _lastnameCtrl.dispose();
    _jobCtrl.dispose();
    _companyCtrl.dispose();
    _companyAddressCtrl.dispose();
    _companyPhoneCtrl.dispose();
    _companyEmailCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _linkedinCtrl.dispose();
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

      final auth = context.read<AuthProvider>();
      final user = auth.user;

      // ✅ Utiliser le nom de l'entreprise liée OU le texte saisi
      final companyName = user?.hasCompany == true
          ? user!.company!.name
          : _companyCtrl.text.trim();

      final data = {
        'jobTitle': _jobCtrl.text.trim(),
        'company': companyName,
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'linkedin': _linkedinCtrl.text.trim().isEmpty
            ? null
            : _linkedinCtrl.text.trim(),
        'activatedFields': activatedFields,
        'isPublic': _isPublic,
      };

      if (kDebugMode) {
        // debugPrint('📤 Données envoyées : $data');
      }

      await CardService.createCard(
        jobTitle: data['jobTitle']! as String,
        company: data['company']! as String,
        firstname: _firstnameCtrl.text.trim(),
        lastname: _lastnameCtrl.text.trim(),
        phone: data['phone'] as String?,
        email: data['email'] as String?,
        linkedin: data['linkedin'] as String?,
        companyAddress: _companyAddressCtrl.text.trim(),
        companyPhone: _companyPhoneCtrl.text.trim(),
        companyEmail: _companyEmailCtrl.text.trim(),
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

  bool _isFormValid() {
    return _firstnameCtrl.text.isNotEmpty &&
        _lastnameCtrl.text.isNotEmpty &&
        _jobCtrl.text.isNotEmpty &&
        _companyCtrl.text.isNotEmpty;
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isCompanyLinked = auth.user?.hasCompany == true;
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
                  hint: 'Ex: Directeur Marketing, Developpeur...',
                ),

                const SizedBox(height: 32),

                // Company Info
                Text(
                  'Informations de l\'entreprise',
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 16),

                AuthTextField(
                  label: 'Nom de l\'entreprise',
                  controller: _companyCtrl,
                  enabled: !isCompanyLinked,
                  onChanged: (_) => setState(() {}),
                  prefixIcon: Icons.business_outlined,
                  hint: 'Ex: Kart Technologies, Ma Societe...',
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
                          Icons.verified_outlined,
                          color: const Color(0xFF3B82F6),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Entreprise liée à votre licence',
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
                  label: 'Adresse de l\'entreprise',
                  controller: _companyAddressCtrl,
                  enabled: !isCompanyLinked,
                  onChanged: (_) => setState(() {}),
                  prefixIcon: Icons.location_on_outlined,
                  hint: 'Ex: 123 Rue de la Paix, Dakar',
                ),

                const SizedBox(height: 16),

                AuthTextField(
                  label: 'Téléphone de l\'entreprise',
                  controller: _companyPhoneCtrl,
                  enabled: !isCompanyLinked,
                  onChanged: (_) => setState(() {}),
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  hint: 'Ex: +221 33 123 45 67',
                ),

                const SizedBox(height: 16),

                AuthTextField(
                  label: 'Email de l\'entreprise',
                  controller: _companyEmailCtrl,
                  enabled: !isCompanyLinked,
                  onChanged: (_) => setState(() {}),
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  hint: 'Ex: contact@entreprise.com',
                ),

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

                // Social & Visibility
                Text(
                  'Reseaux sociaux et visibilite',
                  style: TextStyle(
                    color: colors.onSurface.withValues(alpha: 0.7),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 16),

                AuthTextField(
                  label: 'Profil LinkedIn',
                  controller: _linkedinCtrl,
                  onChanged: (_) => setState(() {}),
                  prefixIcon: Icons.link,
                  hint: 'Ex: linkedin.com/in/votrenom',
                ),

                const SizedBox(height: 12),

                _buildPremiumSwitch(
                  title: 'Afficher LinkedIn sur ma carte',
                  value: _activeFields['linkedin'] ?? false,
                  onChanged: (v) =>
                      setState(() => _activeFields['linkedin'] = v),
                  icon: Icons.visibility_outlined,
                ),

                const SizedBox(height: 20),

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
