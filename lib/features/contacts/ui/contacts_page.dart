import 'package:flutter/material.dart';
import 'contacts_grouped_view.dart';

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: colors.surface,
      body: const SafeArea(
        child: ContactsGroupedView(),
      ),
    );
  }
}
