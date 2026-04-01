import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../../shared/widgets/auth_primary_button.dart';
import '../../../shared/widgets/auth_outline_button.dart';
import '../../../shared/services/card_service.dart';
import '../../auth/providers/auth_provider.dart';

class CreateCardForm extends StatefulWidget {
  const CreateCardForm({super.key});

  @override
  State<CreateCardForm> createState() => _CreateCardFormState();
}

class _CreateCardFormState extends State<CreateCardForm> {
  final _formKey = GlobalKey<FormState>();

  final _jobCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();
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
  bool _companyInitialized = false; // ✅ Flag pour éviter la réinitialisation multiple

  final PageController _pageController = PageController();
  int _currentPage = 0;

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
        // Pre-remplir le nom de l'entreprise si disponible
        if (user.company != null && user.company!.name.isNotEmpty) {
          _companyCtrl.text = user.company!.name;
          debugPrint('✅ Company pre-filled: ${user.company!.name}');
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
    _jobCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _linkedinCtrl.dispose();
    _pageController.dispose();
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
        phone: data['phone'] as String?,
        email: data['email'] as String?,
        linkedin: data['linkedin'] as String?,
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

  void _nextPage() {
    if (_currentPage < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _submit();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOutCubic,
      );
    }
  }

  bool _isValidPage() {
    switch (_currentPage) {
      case 0:
        return _jobCtrl.text.isNotEmpty && _companyCtrl.text.isNotEmpty;
      case 1:
      case 2:
        return true; // tous champs facultatifs
      default:
        return false;
    }
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Column(
              children: [
                // HEADER avec gradient
                ShaderMask(
                  shaderCallback: (bounds) => LinearGradient(
                    colors: isDark
                        ? [Colors.white, const Color(0xFFB0B0B0)]
                        : [colors.onSurface, colors.onSurface.withValues(alpha: 0.7)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ).createShader(bounds),
                  child: Text(
                    'Créer ma carte',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.white : colors.onSurface,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Étape ${_currentPage + 1} sur 3',
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurface.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const SizedBox(height: 24),

                // INDICATOR Premium
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: colors.onSurface.withValues(alpha: 0.04),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: colors.onSurface.withValues(alpha: 0.06),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (i) {
                      final isActive = _currentPage == i;
                      final isCompleted = _currentPage > i;
                      return Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            width: isActive ? 32 : 10,
                            height: 10,
                            decoration: BoxDecoration(
                              gradient: isActive || isCompleted
                                  ? const LinearGradient(
                                      colors: [
                                        Color(0xFF3B82F6),
                                        Color(0xFF2563EB)
                                      ],
                                    )
                                  : null,
                              color: isActive || isCompleted
                                  ? null
                                  : colors.onSurface.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(5),
                              boxShadow: isActive
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFF3B82F6)
                                            .withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      ),
                                    ]
                                  : null,
                            ),
                          ),
                          if (i < 2) const SizedBox(width: 8),
                        ],
                      );
                    }),
                  ),
                ),

                const SizedBox(height: 32),

                // PAGES
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: [
                      _buildProfessionalInfoPage(),
                      _buildContactInfoPage(),
                      _buildSocialAndVisibilityPage(),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // BUTTONS
                Row(
                  children: [
                    if (_currentPage > 0)
                      Expanded(
                        child: AuthOutlineButton(
                          label: 'Retour',
                          onTap: _previousPage,
                        ),
                      )
                    else
                      const Expanded(child: SizedBox()),
                    const SizedBox(width: 12),
                    Expanded(
                      child: AuthPrimaryButton(
                        label: _currentPage == 2 ? 'Créer ma carte' : 'Suivant',
                        loading: _isSubmitting,
                        onTap: _isValidPage() ? _nextPage : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- PAGES ----------------

  Widget _buildProfessionalInfoPage() {
    final auth = context.read<AuthProvider>();
    final isCompanyLinked = auth.user?.hasCompany == true;

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSectionHeader(
            icon: Icons.badge_outlined,
            title: 'Informations professionnelles',
            subtitle: 'Ces informations apparaitront sur votre carte digitale',
          ),
          _buildFieldCard(
            child: Column(
              children: [
                AuthTextField(
                  label: 'Votre poste',
                  controller: _jobCtrl,
                  onChanged: (_) => setState(() {}),
                  prefixIcon: Icons.work_outline,
                  hint: 'Ex: Directeur Marketing, Developpeur...',
                ),
                const SizedBox(height: 24),
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
                          'Entreprise liee a votre licence',
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
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactInfoPage() {
    final auth = context.read<AuthProvider>();
    final hasPhonePrefilled = auth.user?.phone != null && auth.user!.phone!.isNotEmpty;
    final hasEmailPrefilled = auth.user?.email != null && auth.user!.email.isNotEmpty;

    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSectionHeader(
            icon: Icons.contact_phone_outlined,
            title: 'Coordonnees de contact',
            subtitle: 'Ces informations seront visibles sur votre carte',
          ),
          _buildFieldCard(
            child: Column(
              children: [
                AuthTextField(
                  label: 'Numero de telephone',
                  controller: _phoneCtrl,
                  onChanged: (_) => setState(() {}),
                  prefixIcon: Icons.phone_outlined,
                  keyboardType: TextInputType.phone,
                  hint: 'Ex: +221 77 123 45 67',
                ),
                if (hasPhonePrefilled) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey[500],
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Pre-rempli depuis votre profil',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                _buildPremiumSwitch(
                  title: 'Afficher le telephone sur ma carte',
                  value: _activeFields['phone'] ?? false,
                  onChanged: (v) =>
                      setState(() => _activeFields['phone'] = v),
                  icon: Icons.visibility_outlined,
                ),
                const SizedBox(height: 28),
                AuthTextField(
                  label: 'Adresse email professionnelle',
                  controller: _emailCtrl,
                  onChanged: (_) => setState(() {}),
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  hint: 'Ex: nom@entreprise.com',
                ),
                if (hasEmailPrefilled) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Colors.grey[500],
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Pre-rempli depuis votre profil',
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                _buildPremiumSwitch(
                  title: 'Afficher l\'email sur ma carte',
                  value: _activeFields['email'] ?? false,
                  onChanged: (v) =>
                      setState(() => _activeFields['email'] = v),
                  icon: Icons.visibility_outlined,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialAndVisibilityPage() {
    return SingleChildScrollView(
      child: Column(
        children: [
          _buildSectionHeader(
            icon: Icons.link_outlined,
            title: 'Reseaux sociaux et visibilite',
            subtitle: 'Ajoutez vos liens professionnels',
          ),
          _buildFieldCard(
            child: Column(
              children: [
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
              ],
            ),
          ),
          const SizedBox(height: 20),
          _buildFieldCard(
            child: _buildPremiumSwitch(
              title: 'Rendre ma carte publique',
              subtitle: 'Accessible via un lien ou QR code',
              value: _isPublic,
              onChanged: (v) => setState(() => _isPublic = v),
              icon: Icons.public_outlined,
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- HELPERS ----------------

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                colors.onSurface.withValues(alpha: 0.15),
                colors.onSurface.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: colors.onSurface.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Icon(icon, color: colors.onSurface, size: 26),
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.onSurface,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: colors.onSurface.withValues(alpha: 0.5),
            height: 1.4,
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildFieldCard({required Widget child}) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colors.onSurface.withValues(alpha: 0.06),
            colors.onSurface.withValues(alpha: 0.02),
          ],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: colors.onSurface.withValues(alpha: 0.08),
          width: 1,
        ),
      ),
      child: child,
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
                color: value ? colors.onSurface : colors.onSurface.withValues(alpha: 0.5),
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
                    color: value ? colors.onSurface : colors.onSurface.withValues(alpha: 0.7),
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
              activeTrackColor: isDark ? const Color(0xFF3B82F6) : const Color(0xFF3B82F6).withValues(alpha: 0.5),
              inactiveThumbColor: colors.onSurface.withValues(alpha: 0.4),
              inactiveTrackColor: colors.onSurface.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }

}