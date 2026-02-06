import 'package:flutter/material.dart';
import '../models/highlight_model.dart';

class HighlightHeader extends StatelessWidget {
  final HighlightModel highlight;

  const HighlightHeader({super.key, required this.highlight});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 24, 16, 8),
      child: Text(
        highlight.name,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
