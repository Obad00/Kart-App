import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/company_provider.dart';

class CreateCompanyPage extends StatefulWidget {
  const CreateCompanyPage({super.key});

  @override
  State<CreateCompanyPage> createState() => _CreateCompanyPageState();
}

class _CreateCompanyPageState extends State<CreateCompanyPage> {
  final _formKey = GlobalKey<FormState>();

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
    if (!_formKey.currentState!.validate()) return;

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
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une entreprise'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Configuration entreprise',
                style: theme.textTheme.headlineLarge,
              ),
              const SizedBox(height: 6),
              Text(
                'Branding et paramètres',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.6),

                ),
              ),

              const SizedBox(height: 32),

              _field(
                controller: _nameCtrl,
                label: 'Nom de l’entreprise',
                required: true,
              ),
              _field(
                controller: _maxUsersCtrl,
                label: 'Nombre de membres',
                keyboardType: TextInputType.number,
                required: true,
              ),
              _planDropdown(context),
              _field(
                controller: _colorCtrl,
                label: 'Couleur principale (hex)',
              ),
              _field(
                controller: _logoCtrl,
                label: 'Logo (URL)',
              ),

              const SizedBox(height: 36),

              ElevatedButton(
                onPressed: _loading ? null : _submit,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Créer l’entreprise'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    bool required = false,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: required
            ? (v) => v == null || v.isEmpty ? 'Champ requis' : null
            : null,
        decoration: InputDecoration(labelText: label),
      ),
    );
  }

  Widget _planDropdown(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: DropdownButtonFormField<String>(
        initialValue: _plan,
        items: const [
          DropdownMenuItem(value: 'free', child: Text('Free')),
          DropdownMenuItem(value: 'pro', child: Text('Pro')),
          DropdownMenuItem(value: 'enterprise', child: Text('Enterprise')),
        ],
        onChanged: (v) => setState(() => _plan = v!),
        decoration: const InputDecoration(labelText: 'Plan'),
      ),
    );
  }
}
