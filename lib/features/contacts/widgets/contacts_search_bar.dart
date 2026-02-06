import 'package:flutter/material.dart';

class ContactsSearchBar extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const ContactsSearchBar({
    super.key,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: 'Rechercher',
          prefixIcon: const Icon(Icons.search),
          filled: true,
          fillColor: Colors.grey.withValues(alpha: 0.15),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }
}
