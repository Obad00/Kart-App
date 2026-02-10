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
  bool _companyLocked = false;

  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    if (user?.hasCompany == true && !_companyLocked) {
      _companyCtrl.text = user!.company!.name;
      _companyLocked = true;
    }
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

      final data = {
        'jobTitle': _jobCtrl.text.trim(),
        'company': _companyCtrl.text.trim(),
        'phone': _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        'email': _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        'linkedin': _linkedinCtrl.text.trim().isEmpty ? null : _linkedinCtrl.text.trim(),
        'activatedFields': activatedFields,
        'isPublic': _isPublic,
      };

      // Affiche les données uniquement en mode debug
      if (kDebugMode) {
        debugPrint('Données envoyées : $data');
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
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
            child: Column(
              children: [
                const Text(
                  'Créer ma carte',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 32),

                // INDICATOR
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    3,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == i ? Colors.white : Colors.white24,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 40),

                // PAGES
                Expanded(
                  child: PageView(
                    controller: _pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    children: [
                      _twoFields(
                        'Poste',
                        _jobCtrl,
                        'Entreprise',
                        _companyCtrl,
                        companyLocked: _companyLocked,
                        onChanged1: (_) => setState(() {}),
                        onChanged2: (_) => setState(() {}),
                      ),
                      _twoFieldsWithSwitches(
                        'Téléphone',
                        _phoneCtrl,
                        'Email',
                        _emailCtrl,
                        activeFields: _activeFields,
                        onChanged1: (_) => setState(() {}),
                        onChanged2: (_) => setState(() {}),
                      ),
                      _oneFieldWithSwitch(
                        'LinkedIn',
                        _linkedinCtrl,
                        isPublic: _isPublic,
                        onPublicChanged: (v) => setState(() => _isPublic = v),
                        onChanged: (_) => setState(() {}),
                      ),
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

  // ---------------- HELPERS ----------------

  Widget _twoFields(
    String l1,
    TextEditingController c1,
    String l2,
    TextEditingController c2, {
    bool companyLocked = false,
    ValueChanged<String>? onChanged1,
    ValueChanged<String>? onChanged2,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AuthTextField(label: l1, controller: c1, onChanged: onChanged1),
          const SizedBox(height: 32),
          AuthTextField(
            label: l2,
            controller: c2,
            enabled: !companyLocked,
            onChanged: onChanged2,
          ),
          if (companyLocked)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                'Entreprise liée à votre licence',
                style: TextStyle(color: Colors.grey[400], fontSize: 12),
              ),
            ),
        ],
      ),
    );
  }

  Widget _twoFieldsWithSwitches(
    String l1,
    TextEditingController c1,
    String l2,
    TextEditingController c2, {
    required Map<String, bool> activeFields,
    ValueChanged<String>? onChanged1,
    ValueChanged<String>? onChanged2,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AuthTextField(label: l1, controller: c1, onChanged: onChanged1),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text('Afficher $l1', style: const TextStyle(color: Colors.white)),
            value: activeFields[l1.toLowerCase()] ?? false,
            onChanged: (v) => setState(() => activeFields[l1.toLowerCase()] = v),
          ),
          const SizedBox(height: 32),
          AuthTextField(label: l2, controller: c2, onChanged: onChanged2),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: Text('Afficher $l2', style: const TextStyle(color: Colors.white)),
            value: activeFields[l2.toLowerCase()] ?? false,
            onChanged: (v) => setState(() => activeFields[l2.toLowerCase()] = v),
          ),
        ],
      ),
    );
  }

  Widget _oneFieldWithSwitch(
    String label,
    TextEditingController ctrl, {
    required bool isPublic,
    required ValueChanged<bool> onPublicChanged,
    ValueChanged<String>? onChanged,
  }) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AuthTextField(label: label, controller: ctrl, onChanged: onChanged),
          const SizedBox(height: 32),
          SwitchListTile.adaptive(
            contentPadding: EdgeInsets.zero,
            title: const Text('Carte publique', style: TextStyle(color: Colors.white)),
            subtitle: const Text(
              'Visible via lien ou QR code',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
            value: isPublic,
            onChanged: onPublicChanged,
          ),
        ],
      ),
    );
  }
}
