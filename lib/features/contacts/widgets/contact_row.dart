import 'package:flutter/material.dart';
import '../../../shared/utils/company_color_helper.dart';
import '../models/contact_model.dart';

class ContactRow extends StatelessWidget {
  final ContactModel contact;
  final VoidCallback? onTap;

  const ContactRow({
    super.key,
    required this.contact,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final companyColor = context.companyColor;
    
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: companyColor.withValues(alpha: 0.15),
              child: Text(
                contact.fullname.isNotEmpty
                    ? contact.fullname[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: companyColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                contact.fullname,
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: colors.onSurface,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.message, color: companyColor),
              onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Messagerie avec ${contact.fullname} à venir'),
                ),
              );
            },

            ),
          ],
        ),
      ),
    );
  }
}
