import 'package:flutter/material.dart';
import '../../../shared/services/card_service.dart';

class CreateCardForm extends StatefulWidget {
  const CreateCardForm({super.key});

  @override
  State<CreateCardForm> createState() => _CreateCardFormState();
}

class _CreateCardFormState extends State<CreateCardForm> {
  final _formKey = GlobalKey<FormState>();
  final _jobCtrl = TextEditingController();
  final _companyCtrl = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _jobCtrl.dispose();
    _companyCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      await CardService.createCard(
        jobTitle: _jobCtrl.text.trim(),
        company: _companyCtrl.text.trim(),
      );

      if (!mounted) return;
      Navigator.pop(context, true); // succès
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de la création de la carte')),
      );
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextFormField(
            controller: _jobCtrl,
            decoration: const InputDecoration(labelText: 'Poste'),
            validator: (v) =>
                v == null || v.isEmpty ? 'Champ requis' : null,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _companyCtrl,
            decoration: const InputDecoration(labelText: 'Entreprise'),
            validator: (v) =>
                v == null || v.isEmpty ? 'Champ requis' : null,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submit,
            child: _isSubmitting
                ? const CircularProgressIndicator()
                : const Text('Créer ma carte'),
          ),
        ],
      ),
    );
  }
}
