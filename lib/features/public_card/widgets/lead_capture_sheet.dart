import 'package:flutter/material.dart';
import '../../../shared/services/card_service.dart';
import '../../../shared/services/user_service.dart';

class LeadCaptureSheet extends StatefulWidget {
  final String slug;
  final String ownerName;

  const LeadCaptureSheet({
    super.key,
    required this.slug,
    required this.ownerName,
  });

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

  final _userService = UserService();

  bool _isLoading = false;
  bool _loadingUser = true;
  bool _alreadySubmitted = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    try {
      final user = await _userService.getMe();

      if (!mounted) return;

      _nameController.text =
          '${user['firstname'] ?? ''} ${user['lastname'] ?? ''}'.trim();
      _emailController.text = (user['email'] ?? '').toString();
      _phoneController.text = (user['phone'] ?? '').toString();
    } catch (e) {
      debugPrint('Erreur _loadUser: $e');
    }

    if (!mounted) return;

    setState(() => _loadingUser = false);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_alreadySubmitted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vous avez déjà envoyé vos coordonnées'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    try {
      final response = await CardService.registerCardView(
        slug: widget.slug,
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        source: 'contact_form',
      );

      final alreadySent = response['already_sent'] == true;

      _alreadySubmitted = true;

      if (!mounted) return;

      Navigator.of(context).pop(true);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;

        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => _SuccessDialog(
            ownerName: widget.ownerName,
            isDuplicate: alreadySent,
          ),
        );
      });
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Erreur lors de l\'envoi'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = isDark ? const Color(0xFF111827) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

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
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            child: _loadingUser
                ? const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _buildForm(textColor),
          ),
        ),
      ),
    );
  }

  Widget _buildForm(Color textColor) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
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
            'Partagez vos coordonnées avec ${widget.ownerName}',
            style: TextStyle(
              color: textColor.withValues(alpha: 0.6),
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 24),
          _buildField(_nameController, 'Nom complet', Icons.person, textColor),
          const SizedBox(height: 12),
          _buildField(_emailController, 'Email', Icons.email, textColor),
          const SizedBox(height: 12),
          _buildField(_phoneController, 'Téléphone', Icons.phone, textColor),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF3B82F6),
                padding: const EdgeInsets.all(16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Envoyer',
                      style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(
    TextEditingController controller,
    String label,
    IconData icon,
    Color textColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: textColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          labelText: label,
          prefixIcon: Icon(icon, color: textColor.withValues(alpha: 0.5)),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }
}

class _SuccessDialog extends StatelessWidget {
  final String ownerName;
  final bool isDuplicate;

  const _SuccessDialog({
    required this.ownerName,
    this.isDuplicate = false,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: const Icon(Icons.close, size: 22),
                ),
              ],
            ),
            Icon(
              isDuplicate ? Icons.info_outline : Icons.check_circle,
              color: isDuplicate ? Colors.orange : const Color(0xFF2563EB),
              size: 60,
            ),
            const SizedBox(height: 12),
            Text(
              isDuplicate ? 'Déjà envoyé' : 'Merci !',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isDuplicate
                  ? 'Vous avez déjà partagé vos coordonnées avec $ownerName'
                  : '$ownerName a reçu vos coordonnées',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
