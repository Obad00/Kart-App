import 'package:flutter/material.dart';
import '../../../shared/services/card_service.dart';

// ───────────────── DESIGN TOKENS ─────────────────

class AppColors {
  static const background = Color(0xFF0B0B0F);
  static const surface = Color(0xFF111318);
  static const stroke = Color(0xFF2A2D34);
  static const strokeFocus = Color(0xFF4A4F5A);

  static const textPrimary = Color(0xFFEDEDED);
  static const textSecondary = Color(0xFF9AA0A6);
}

// ───────────────── FORM ─────────────────

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

  @override
  void dispose() {
    _jobCtrl.dispose();
    _companyCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _linkedinCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final activatedFields = _activeFields.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();

      await CardService.createCard(
        jobTitle: _jobCtrl.text.trim(),
        company: _companyCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim(),
        linkedin: _linkedinCtrl.text.trim(),
        activatedFields: activatedFields,
        isPublic: _isPublic,
      );

      if (!mounted) return;
      Navigator.pop(context, true);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Créer ma carte',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _header(),
              const SizedBox(height: 36),

              _section(
                title: 'Profil professionnel',
                children: [
                  _field(
                    controller: _jobCtrl,
                    label: 'Poste',
                    required: true,
                  ),
                  _field(
                    controller: _companyCtrl,
                    label: 'Entreprise',
                    required: true,
                  ),
                ],
              ),

              const SizedBox(height: 32),

              _section(
                title: 'Contacts visibles',
                subtitle: 'Choisissez ce que vous partagez',
                children: [
                  _contactField(
                    label: 'Téléphone',
                    controller: _phoneCtrl,
                    fieldKey: 'phone',
                  ),
                  _contactField(
                    label: 'Email',
                    controller: _emailCtrl,
                    fieldKey: 'email',
                  ),
                  _contactField(
                    label: 'LinkedIn',
                    controller: _linkedinCtrl,
                    fieldKey: 'linkedin',
                  ),
                ],
              ),

              const SizedBox(height: 28),

              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text(
                  'Carte publique',
                  style: TextStyle(color: AppColors.textPrimary),
                ),
                subtitle: const Text(
                  'Visible via lien ou QR code',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                value: _isPublic,
                onChanged: (v) => setState(() => _isPublic = v),
              ),

              const SizedBox(height: 40),
              _submitButton(),
            ],
          ),
        ),
      ),
    );
  }

  // ───────────────── UI ─────────────────

  Widget _header() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Créer votre carte',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
        SizedBox(height: 6),
        Text(
          'Simple. Élégant. Professionnel.',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _section({
    required String title,
    String? subtitle,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        if (subtitle != null)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    bool required = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        validator: required
            ? (v) => v == null || v.isEmpty ? 'Champ requis' : null
            : null,
        style: const TextStyle(
          fontSize: 15,
          color: AppColors.textPrimary,
        ),
        cursorColor: AppColors.textPrimary,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(
            color: AppColors.textSecondary,
          ),
          floatingLabelStyle: const TextStyle(
            color: AppColors.textPrimary,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

          filled: true,
          fillColor: AppColors.surface,

          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.stroke,
              width: 0.9,
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: AppColors.strokeFocus,
              width: 1.2,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(
              color: Colors.redAccent,
              width: 1,
            ),
          ),
        ),
      ),
    );
  }

  Widget _contactField({
    required String label,
    required TextEditingController controller,
    required String fieldKey,
  }) {
    return Column(
      children: [
        _field(controller: controller, label: label),
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          title: Text(
            'Afficher $label',
            style: const TextStyle(color: AppColors.textPrimary),
          ),
          value: _activeFields[fieldKey]!,
          onChanged: (v) =>
              setState(() => _activeFields[fieldKey] = v),
        ),
      ],
    );
  }

  Widget _submitButton() {
    return GestureDetector(
      onTap: _isSubmitting ? null : _submit,
      child: Container(
        height: 56,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: AppColors.textPrimary,
        ),
        child: _isSubmitting
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.black,
                ),
              )
            : const Text(
                'Créer ma carte',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
      ),
    );
  }
}
