import 'package:flutter/material.dart';
import '../../../shared/services/card_service.dart';

/// Bottom sheet pour capturer les coordonnees d'un visiteur
class LeadCaptureSheet extends StatefulWidget {
  final String slug;
  final String ownerName;

  const LeadCaptureSheet({
    super.key,
    required this.slug,
    required this.ownerName,
  });

  /// Affiche le bottom sheet
  static Future<bool?> show(
    BuildContext context, {
    required String slug,
    required String ownerName,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => LeadCaptureSheet(
        slug: slug,
        ownerName: ownerName,
      ),
    );
  }

  @override
  State<LeadCaptureSheet> createState() => _LeadCaptureSheetState();
}

class _LeadCaptureSheetState extends State<LeadCaptureSheet> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Au moins un champ doit etre rempli
    if (_nameController.text.trim().isEmpty &&
        _emailController.text.trim().isEmpty &&
        _phoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez remplir au moins un champ'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await CardService.registerCardView(
        slug: widget.slug,
        name: _nameController.text.trim().isNotEmpty ? _nameController.text.trim() : null,
        email: _emailController.text.trim().isNotEmpty ? _emailController.text.trim() : null,
        phone: _phoneController.text.trim().isNotEmpty ? _phoneController.text.trim() : null,
        source: 'contact_form',
      );

      if (mounted) {
        // Fermer le bottom sheet
        Navigator.of(context).pop(true);

        // Afficher le dialog de succès au centre
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => _SuccessDialog(ownerName: widget.ownerName),
        );
      }
    } catch (e) {
      if (mounted) {
        // Extract more detailed error message
        String errorMessage = 'Erreur lors de l\'envoi';

        if (e.toString().contains('422')) {
          errorMessage = 'Erreur de validation. Vérifiez vos informations.';
        } else if (e.toString().contains('401')) {
          errorMessage = 'Session expirée. Veuillez vous reconnecter.';
        } else if (e.toString().contains('500')) {
          errorMessage = 'Erreur serveur. Réessayez plus tard.';
        } else if (e.toString().contains('DioException')) {
          errorMessage = 'Erreur de connexion. Vérifiez votre réseau.';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red[700],
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;
    final bgColor = isLightMode ? Colors.white : const Color(0xFF1A1A1A);
    final textColor = isLightMode ? Colors.black87 : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 12,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: _buildForm(textColor, isLightMode),
        ),
      ),
    );
  }

  Widget _buildForm(Color textColor, bool isLightMode) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: textColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Titre
          Text(
            'Restons en contact',
            style: TextStyle(
              color: textColor,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Partagez vos coordonnees avec ${widget.ownerName}',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),

          // Champ Nom
          _buildTextField(
            controller: _nameController,
            label: 'Votre nom',
            icon: Icons.person_outline,
            textColor: textColor,
            isLightMode: isLightMode,
          ),
          const SizedBox(height: 16),

          // Champ Email
          _buildTextField(
            controller: _emailController,
            label: 'Votre email',
            icon: Icons.email_outlined,
            keyboardType: TextInputType.emailAddress,
            textColor: textColor,
            isLightMode: isLightMode,
          ),
          const SizedBox(height: 16),

          // Champ Telephone
          _buildTextField(
            controller: _phoneController,
            label: 'Votre telephone',
            icon: Icons.phone_outlined,
            keyboardType: TextInputType.phone,
            textColor: textColor,
            isLightMode: isLightMode,
          ),
          const SizedBox(height: 24),

          // Bouton envoyer
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text(
                      'Envoyer mes coordonnees',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 12),

          // Note de confidentialite
          Center(
            child: Text(
              'Vos informations sont partagees uniquement avec ${widget.ownerName}',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.5),
                fontSize: 11,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color textColor,
    required bool isLightMode,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: textColor.withValues(alpha: 0.1),
        ),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(color: textColor, fontSize: 14),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: textColor.withValues(alpha: 0.5),
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: textColor.withValues(alpha: 0.5),
            size: 20,
          ),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      ),
    );
  }
}

/// Dialog de succès affiché au centre de l'écran
class _SuccessDialog extends StatefulWidget {
  final String ownerName;

  const _SuccessDialog({required this.ownerName});

  @override
  State<_SuccessDialog> createState() => _SuccessDialogState();
}

class _SuccessDialogState extends State<_SuccessDialog> {
  @override
  void initState() {
    super.initState();
    // Fermer automatiquement après 2 secondes
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) Navigator.of(context).pop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLightMode = theme.brightness == Brightness.light;
    final bgColor = isLightMode ? Colors.white : const Color(0xFF1A1A1A);
    final textColor = isLightMode ? Colors.black87 : Colors.white;

    return Dialog(
      backgroundColor: bgColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.check_circle,
                color: Color(0xFF22C55E),
                size: 48,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Merci !',
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${widget.ownerName} a recu vos coordonnees',
              style: TextStyle(
                color: textColor.withValues(alpha: 0.7),
                fontSize: 14,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
