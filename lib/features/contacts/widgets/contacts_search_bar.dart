import 'package:flutter/material.dart';

class ContactsSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const ContactsSearchBar({
    super.key,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        onChanged: onChanged,
        style: TextStyle(color: colors.onSurface),
        decoration: InputDecoration(
          hintText: 'Rechercher',
          hintStyle: TextStyle(color: colors.onSurface.withOpacity(0.5)),
          prefixIcon: Icon(Icons.search, color: colors.onSurface.withOpacity(0.5)),
          filled: true,
          fillColor: colors.onSurface.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
