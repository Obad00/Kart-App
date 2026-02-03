import 'package:flutter/material.dart';

class NoCardCta extends StatelessWidget {
  final VoidCallback onCreate;

  const NoCardCta({super.key, required this.onCreate});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.qr_code_2, size: 48),
        const SizedBox(height: 24),
        const Text(
          'Aucune carte créée',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        ElevatedButton(
          onPressed: onCreate,
          child: const Text('Créer ma carte'),
        ),
      ],
    );
  }
}
