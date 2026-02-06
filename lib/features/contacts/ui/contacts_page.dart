import 'package:flutter/material.dart';
import 'contacts_grouped_view.dart';

class ContactsPage extends StatelessWidget {
  const ContactsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: ContactsGroupedView(),
      ),
    );
  }
}
