import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../onboarding/providers/company_provider.dart';
import '../../../shared/widgets/auth_text_field.dart';
import '../../../shared/widgets/auth_primary_button.dart';

class JoinCompanyPage extends StatefulWidget {
  const JoinCompanyPage({super.key});

  @override
  State<JoinCompanyPage> createState() => _JoinCompanyPageState();
}

class _JoinCompanyPageState extends State<JoinCompanyPage> {
  final _codeCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit(CompanyProvider provider) async {
    if (_codeCtrl.text.isEmpty) return;

    setState(() => _loading = true);

    await provider.joinCompany(_codeCtrl.text.trim());

    setState(() => _loading = false);

    if (!mounted) return;

    if (provider.error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(provider.error!)),
      );
    } else {
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CompanyProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFF0A0A0A),
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Rejoindre une entreprise'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 12),
              const Text(
                'Rejoindre une entreprise',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Entrez le code licence fourni par votre entreprise.',
                style: TextStyle(
                  color: Colors.grey[400],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),

              AuthTextField(
                label: 'Code licence',
                controller: _codeCtrl,
                onChanged: (_) => setState(() {}),
              ),

              const SizedBox(height: 36),

              AuthPrimaryButton(
                label: 'Rejoindre',
                loading: _loading || provider.isLoading,
                onTap: () => _submit(provider),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
