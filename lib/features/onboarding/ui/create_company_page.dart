import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/company_provider.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../../shared/widgets/auth_primary_button.dart';

class CreateCompanyPage extends StatefulWidget {
  const CreateCompanyPage({super.key});

  @override
  State<CreateCompanyPage> createState() => _CreateCompanyPageState();
}

class _CreateCompanyPageState extends State<CreateCompanyPage> {
  final _nameCtrl = TextEditingController();
  final _maxUsersCtrl = TextEditingController();
  final _logoCtrl = TextEditingController();
  final _colorCtrl = TextEditingController(text: '#000000');

  String _plan = 'enterprise';
  bool _loading = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _maxUsersCtrl.dispose();
    _logoCtrl.dispose();
    _colorCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.isEmpty || _maxUsersCtrl.text.isEmpty) return;

    setState(() => _loading = true);

    final provider = context.read<CompanyProvider>();

    await provider.createCompany(
      name: _nameCtrl.text.trim(),
      maxUsers: int.parse(_maxUsersCtrl.text.trim()),
      logo: _logoCtrl.text.trim().isEmpty ? null : _logoCtrl.text.trim(),
      primaryColor: _colorCtrl.text.trim(),
      plan: _plan,
    );

    setState(() => _loading = false);

    if (!mounted) return;

    if (provider.error == null) {
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Créer une entreprise'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            Text(
              'Configuration entreprise',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 32,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Branding et paramètres',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),

            // Champs
            AuthTextField(
              label: 'Nom de l’entreprise',
              controller: _nameCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            AuthTextField(
              label: 'Nombre de membres',
              controller: _maxUsersCtrl,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            _planDropdown(),
            const SizedBox(height: 24),
            AuthTextField(
              label: 'Couleur principale (hex)',
              controller: _colorCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 24),
            AuthTextField(
              label: 'Logo (URL)',
              controller: _logoCtrl,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 36),

            AuthPrimaryButton(
              label: 'Créer l’entreprise',
              loading: _loading,
              onTap: _submit,
            ),
          ],
        ),
      ),
    );
  }

 Widget _planDropdown() {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      border: Border(
        bottom: BorderSide(color: Colors.grey[600]!, width: 1),
      ),
    ),
    child: DropdownButtonFormField<String>(
      initialValue: _plan, // <-- ici
      items: const [
        DropdownMenuItem(value: 'free', child: Text('Free')),
        DropdownMenuItem(value: 'pro', child: Text('Pro')),
        DropdownMenuItem(value: 'enterprise', child: Text('Enterprise')),
      ],
      onChanged: (v) => setState(() => _plan = v!),
      dropdownColor: const Color(0xFF0A0A0A),
      style: const TextStyle(color: Colors.white),
      decoration: const InputDecoration(
        labelText: 'Plan',
        labelStyle: TextStyle(color: Colors.grey),
        border: InputBorder.none,
      ),
    ),
  );
}

}
