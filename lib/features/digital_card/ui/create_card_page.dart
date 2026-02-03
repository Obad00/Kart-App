import 'package:flutter/material.dart';
import '../widgets/create_card_form.dart';

class CreateCardPage extends StatelessWidget {
  const CreateCardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Créer ma carte')),
      body: const Padding(
        padding: EdgeInsets.all(24),
        child: CreateCardForm(),
      ),
    );
  }
}
