import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/contacts_provider.dart';

/// Formulaire de création manuelle d'un contact (prénom, nom, email,
/// téléphone) — utile quand on n'a pas pu scanner la carte de quelqu'un.
/// Si un email est renseigné, ce contact reçoit un mail KART l'invitant à
/// créer sa propre carte (géré côté serveur).
void showAddContactSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const _AddContactSheet(),
  );
}

class _AddContactSheet extends StatefulWidget {
  const _AddContactSheet();

  @override
  State<_AddContactSheet> createState() => _AddContactSheetState();
}

class _AddContactSheetState extends State<_AddContactSheet> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  bool get _canSubmit =>
      _firstNameController.text.trim().isNotEmpty ||
      _lastNameController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    final fullname = [
      _firstNameController.text.trim(),
      _lastNameController.text.trim(),
    ].where((s) => s.isNotEmpty).join(' ');

    if (fullname.isEmpty || _isLoading) return;

    setState(() => _isLoading = true);

    final provider = context.read<ContactsProvider>();
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    try {
      await provider.createManualContact(
        fullname: fullname,
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
      );
      if (navigator.mounted) navigator.pop();
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            _emailController.text.trim().isNotEmpty
                ? '$fullname ajouté — un mail l\'invitant à créer sa carte KART lui a été envoyé.'
                : '$fullname ajouté à vos contacts.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
              'Erreur : ${e.toString().replaceAll('DioException [bad response]: ', '')}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1A1A) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 24,
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colors.onSurface.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Text(
              'Ajouter un contact',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Pratique quand vous n\'avez pas pu scanner sa carte.',
              style: TextStyle(
                fontSize: 13,
                color: colors.onSurface.withValues(alpha: 0.55),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildField(
                    controller: _firstNameController,
                    label: 'Prénom',
                    colors: colors,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildField(
                    controller: _lastNameController,
                    label: 'Nom',
                    colors: colors,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _emailController,
              label: 'Email',
              colors: colors,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            _buildField(
              controller: _phoneController,
              label: 'Téléphone',
              colors: colors,
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  disabledBackgroundColor:
                      const Color(0xFF3B82F6).withValues(alpha: 0.4),
                ),
                onPressed: (_canSubmit && !_isLoading) ? _submit : null,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Ajouter',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required ColorScheme colors,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      onChanged: (_) => setState(() {}),
      style: TextStyle(color: colors.onSurface, fontSize: 15),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.5)),
        filled: true,
        fillColor: colors.onSurface.withValues(alpha: 0.05),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
        ),
      ),
    );
  }
}
