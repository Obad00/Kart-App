import 'package:flutter/material.dart';

class ContactsSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;
  final TextEditingController? controller; // ← ajouté

  const ContactsSearchBar({
    super.key,
    required this.onChanged,
    this.controller, // ← ajouté
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: controller, // ← assigné ici
        onChanged: onChanged,
        style: TextStyle(color: colors.onSurface),
        decoration: InputDecoration(
          hintText: 'Rechercher',
          hintStyle: TextStyle(color: colors.onSurface.withValues(alpha: 0.5)),
          prefixIcon: Icon(Icons.search, color: colors.onSurface.withValues(alpha: 0.5)),
          filled: true,
          fillColor: colors.onSurface.withValues(alpha: 0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
