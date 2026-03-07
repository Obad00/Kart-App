import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/card_scan_provider.dart';

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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact enregistré avec succès'),
          backgroundColor: Colors.green,
        ),
      );
      provider.reset();
      Navigator.popUntil(context, (route) => route.isFirst);
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

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, color: Colors.white),
          onPressed: () {
            provider.reset();
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Résultat du scan',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(
              _showRawText ? Icons.text_fields : Icons.raw_on_rounded,
              color: Colors.white,
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
            // Success banner
            _buildSuccessBanner(),

            const SizedBox(height: 24),

            // Raw text toggle
            if (_showRawText && provider.rawText != null) ...[
              _buildRawTextSection(provider.rawText!),
              const SizedBox(height: 24),
            ],

            // Form fields
            _buildFormSection(),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomActions(provider),
    );
  }

  Widget _buildSuccessBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.1),
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
                  'Carte analysée avec succès',
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Vérifiez et corrigez les informations si nécessaire',
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

  Widget _buildRawTextSection(String rawText) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
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
                'Texte détecté',
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
              color: Colors.grey[300],
              fontSize: 13,
              fontFamily: 'monospace',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Informations du contact',
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: _buildTextField('Prénom', _firstNameCtrl, Icons.person_outline_rounded)),
            const SizedBox(width: 12),
            Expanded(child: _buildTextField('Nom', _lastNameCtrl, Icons.person_outline_rounded)),
          ],
        ),
        const SizedBox(height: 16),
        _buildTextField('Poste', _jobTitleCtrl, Icons.work_outline_rounded),
        const SizedBox(height: 16),
        _buildTextField('Entreprise', _companyCtrl, Icons.business_rounded),
        const SizedBox(height: 16),
        _buildTextField('Email', _emailCtrl, Icons.email_outlined, keyboardType: TextInputType.emailAddress),
        const SizedBox(height: 16),
        _buildTextField('Téléphone', _phoneCtrl, Icons.phone_outlined, keyboardType: TextInputType.phone),
        const SizedBox(height: 16),
        _buildTextField('Adresse', _addressCtrl, Icons.location_on_outlined),
        const SizedBox(height: 16),
        _buildTextField('Site web', _websiteCtrl, Icons.language_rounded, keyboardType: TextInputType.url),
      ],
    );
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller,
    IconData icon, {
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.08),
        ),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(
          color: Colors.white,
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
            color: Colors.grey[600],
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

  Widget _buildBottomActions(CardScanProvider provider) {
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
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor:
                              AlwaysStoppedAnimation<Color>(Colors.black54),
                        ),
                      )
                    : const Icon(Icons.save_rounded),
                label: Text(isSaving ? 'Enregistrement...' : 'Enregistrer le contact'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                  disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
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
