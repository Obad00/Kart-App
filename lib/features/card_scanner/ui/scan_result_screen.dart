import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/card_scan_provider.dart';
import '../../contacts/providers/contacts_provider.dart';
import '../../navigation/home_shell.dart';

class ScanResultScreen extends StatefulWidget {
  const ScanResultScreen({super.key});

  @override
  State<ScanResultScreen> createState() => _ScanResultScreenState();
}

class _ScanResultScreenState extends State<ScanResultScreen> {
  late TextEditingController _firstNameCtrl;
  late TextEditingController _lastNameCtrl;
  late TextEditingController _jobTitleCtrl;
  late TextEditingController _companyCtrl;
  late TextEditingController _emailCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _addressCtrl;
  late TextEditingController _websiteCtrl;

  bool _showRawText = false;

  @override
  void initState() {
    super.initState();
    final contact = context.read<CardScanProvider>().scannedContact;
    _firstNameCtrl = TextEditingController(text: contact?.firstName ?? '');
    _lastNameCtrl = TextEditingController(text: contact?.lastName ?? '');
    _jobTitleCtrl = TextEditingController(text: contact?.jobTitle ?? '');
    _companyCtrl = TextEditingController(text: contact?.company ?? '');
    _emailCtrl = TextEditingController(text: contact?.email ?? '');
    _phoneCtrl = TextEditingController(text: contact?.phone ?? '');
    _addressCtrl = TextEditingController(text: contact?.address ?? '');
    _websiteCtrl = TextEditingController(text: contact?.website ?? '');
  }

  @override
  void dispose() {
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _jobTitleCtrl.dispose();
    _companyCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    _websiteCtrl.dispose();
    super.dispose();
  }

  void _updateProvider() {
    final provider = context.read<CardScanProvider>();
    provider.updateContactField('firstName', _firstNameCtrl.text);
    provider.updateContactField('lastName', _lastNameCtrl.text);
    provider.updateContactField('jobTitle', _jobTitleCtrl.text);
    provider.updateContactField('company', _companyCtrl.text);
    provider.updateContactField('email', _emailCtrl.text);
    provider.updateContactField('phone', _phoneCtrl.text);
    provider.updateContactField('address', _addressCtrl.text);
    provider.updateContactField('website', _websiteCtrl.text);
  }

  Future<void> _saveContact() async {
    _updateProvider();
    final provider = context.read<CardScanProvider>();
    final success = await provider.saveContact();

    if (!mounted) return;

    if (success) {
      // Refresh contacts list
      context.read<ContactsProvider>().fetchGroupedContacts();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact enregistr\u00e9 avec succ\u00e8s'),
          backgroundColor: Colors.green,
        ),
      );
      provider.reset();
      // Navigate to contacts tab
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const HomeShell(initialIndex: 2),
        ),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.error ?? 'Erreur lors de l\'enregistrement'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CardScanProvider>();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0A0A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_rounded, color: textColor),
          onPressed: () {
            provider.reset();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'R\u00e9sultat du scan',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          if (provider.rawText != null)
            IconButton(
              icon: Icon(
                _showRawText ? Icons.text_fields : Icons.raw_on_rounded,
                color: textColor,
              ),
              onPressed: () => setState(() => _showRawText = !_showRawText),
              tooltip: 'Voir le texte brut',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSuccessBanner(isDark),
            const SizedBox(height: 24),
            if (_showRawText && provider.rawText != null) ...[
              _buildRawTextSection(provider.rawText!, isDark),
              const SizedBox(height: 24),
            ],
            _buildFormSection(isDark),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(provider, isDark),
    );
  }

  Widget _buildSuccessBanner(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: isDark ? 0.1 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.green.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.check_circle_rounded,
              color: Colors.green,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Carte analys\u00e9e avec succ\u00e8s',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'V\u00e9rifiez et corrigez les informations si n\u00e9cessaire',
                  style: TextStyle(
                    color: Colors.green[200],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRawTextSection(String rawText, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.text_snippet_rounded,
                color: Colors.grey,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'Texte d\u00e9tect\u00e9',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            rawText,
            style: TextStyle(
              color: isDark ? Colors.grey[300] : Colors.grey[700],
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations du contact',
          style: TextStyle(
            color: Colors.grey[isDark ? 400 : 600],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Pr\u00e9nom', _firstNameCtrl, Icons.person_outline_rounded, isDark)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField('Nom', _lastNameCtrl, Icons.person_outline_rounded, isDark)),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField('Poste', _jobTitleCtrl, Icons.work_outline_rounded, isDark),
        const SizedBox(height: 16),
        _buildTextField('Entreprise', _companyCtrl, Icons.business_rounded, isDark),
        const SizedBox(height: 16),
        _buildTextField('Email', _emailCtrl, Icons.email_outlined, isDark, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _buildTextField('T\u00e9l\u00e9phone', _phoneCtrl, Icons.phone_outlined, isDark, keyboardType: TextInputType.phone),
        const SizedBox(height: 16),
        _buildTextField('Adresse', _addressCtrl, Icons.location_on_outlined, isDark),
        const SizedBox(height: 16),
        _buildTextField('Site web', _websiteCtrl, Icons.language_rounded, isDark, keyboardType: TextInputType.url),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon,
    bool isDark, {
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.08),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 15,
        ),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            color: Colors.grey[500],
            fontSize: 14,
          ),
          prefixIcon: Icon(
            icon,
            color: Colors.grey[isDark ? 600 : 400],
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

  Widget _buildBottomActions(CardScanProvider provider, bool isDark) {
    final isSaving = provider.state == ScanState.saving;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: isSaving ? null : _saveContact,
                icon: isSaving
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? Colors.black54 : Colors.white54,
                          ),
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(isSaving ? 'Enregistrement...' : 'Enregistrer le contact'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white : Colors.black,
                  foregroundColor: isDark ? Colors.black : Colors.white,
                  disabledBackgroundColor: (isDark ? Colors.white : Colors.black).withValues(alpha: 0.5),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: isSaving
                  ? null
                  : () {
                      provider.reset();
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
              child: Text(
                'Annuler',
                style: TextStyle(
                  color: Colors.grey[500],
                  fontSize: 14,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
