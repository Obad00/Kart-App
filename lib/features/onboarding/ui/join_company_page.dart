import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../onboarding/providers/company_provider.dart';

class JoinCompanyPage extends StatefulWidget {
  const JoinCompanyPage({super.key});

  @override
  State<JoinCompanyPage> createState() => _JoinCompanyPageState();
}

class _JoinCompanyPageState extends State<JoinCompanyPage> {
  final _codeCtrl = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CompanyProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Rejoindre une entreprise')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _codeCtrl,
              decoration: const InputDecoration(
                labelText: 'Code licence',
              ),
            ),
            const Spacer(),
            ElevatedButton(
              onPressed: provider.isLoading
                  ? null
                  : () async {
                      await provider.joinCompany(_codeCtrl.text);
                      if (context.mounted) {
                        Navigator.pushReplacementNamed(context, '/home');
                      }
                    },
              child: provider.isLoading
                  ? const CircularProgressIndicator()
                  : const Text('Rejoindre'),
            ),
          ],
        ),
      ),
    );
  }
}
