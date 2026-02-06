import 'package:flutter/material.dart';
import '../models/contact_model.dart';

class ContactRow extends StatelessWidget {
  final ContactModel contact;
  final VoidCallback? onTap;

  const ContactRow({super.key, required this.contact, this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              child: Text(contact.fullname.isNotEmpty
                  ? contact.fullname[0]
                  : '?'),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                contact.fullname,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.message),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}
