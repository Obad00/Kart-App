import 'package:flutter/material.dart';
import '../../../shared/utils/company_color_helper.dart';
import '../models/contact_model.dart';

class ContactRow extends StatelessWidget {
  final ContactModel contact;
  final VoidCallback? onMessageTap;
  final VoidCallback? onMailTap;
  final bool isSelected;

  const ContactRow({
    super.key,
    required this.contact,
    this.onMessageTap,
    this.onMailTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final companyColor = context.companyColor;

    return Container(
      color: isSelected ? companyColor.withValues(alpha: 0.1) : Colors.transparent,
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
            Row(
              children: [
                IconButton(
                  icon: Icon(Icons.message, color: companyColor),
                  onPressed: onMessageTap ??
                      () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Messagerie avec ${contact.fullname} à venir'),
                          ),
                        );
                      },
                ),
                IconButton(
                  icon: const Icon(Icons.mail_outline, color: Colors.green),
                  onPressed: onMailTap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
