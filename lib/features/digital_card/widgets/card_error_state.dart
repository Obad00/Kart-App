import 'package:flutter/material.dart';

class CardErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const CardErrorState({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.error_outline, size: 48, color: Colors.red),
        const SizedBox(height: 16),
        Text(message, textAlign: TextAlign.center),
        const SizedBox(height: 24),
        ElevatedButton(
          onPressed: onRetry,
          child: const Text('Réessayer'),
        ),
      ],
    );
  }
}
