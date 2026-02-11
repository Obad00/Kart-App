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

  bool _loading = false;

  // données venant du workflow (PlanSelectionPage)
  int? _subscriptionId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    if (args != null) {
      _subscriptionId = args['subscriptionId'];
    }
  }

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
    if (_subscriptionId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Subscription ID manquant")),
      );
      return;
    }

    setState(() => _loading = true);

    final companyProvider = context.read<CompanyProvider>();

    await companyProvider.createCompany(
      name: _nameCtrl.text.trim(),
      maxUsers: int.parse(_maxUsersCtrl.text.trim()),
      logo: _logoCtrl.text.trim().isEmpty ? null : _logoCtrl.text.trim(),
      primaryColor: _colorCtrl.text.trim(),
      subscriptionId: _subscriptionId!,
    );

    if (!mounted) return;

    setState(() => _loading = false);

    if (companyProvider.error == null) {
      // Redirection après création entreprise
      Navigator.pushReplacementNamed(context, '/home');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(companyProvider.error!)),
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.pushReplacementNamed(context, '/plans');
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 12),
            const Text(
              'Configuration entreprise',
              style: TextStyle(
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

            AuthTextField(
              label: 'Nom de l’entreprise',
              controller: _nameCtrl,
            ),
            const SizedBox(height: 24),

            AuthTextField(
              label: 'Nombre de membres',
              controller: _maxUsersCtrl,
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 24),

            AuthTextField(
              label: 'Couleur principale (hex)',
              controller: _colorCtrl,
            ),
            const SizedBox(height: 24),

            AuthTextField(
              label: 'Logo (URL)',
              controller: _logoCtrl,
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
}
