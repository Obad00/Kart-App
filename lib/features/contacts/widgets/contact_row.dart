import 'package:flutter/material.dart';
import '../../../shared/utils/company_color_helper.dart';
import '../models/contact_model.dart';
import '../../public_card/ui/public_card_page.dart'; // <-- import manquant

class ContactRow extends StatelessWidget {
  final ContactModel contact;
  final VoidCallback? onMailTap;
  final bool isSelected;

  const ContactRow({
    super.key,
    required this.contact,
    this.onMailTap,
    this.isSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final companyColor = context.companyColor;

    return InkWell(
      onTap: () {
        // Ouvre la carte publique seulement si elle existe
        if (contact.cardSlug != null && contact.cardSlug!.isNotEmpty) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => PublicCardPage(
                slug: contact.cardSlug!,
              ),
            ),
          );
        }
      },
      child: Container(
        color: isSelected
            ? companyColor.withValues(alpha: 0.1)
            : Colors.transparent,
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
                icon: const Icon(Icons.mail_outline, color: Colors.green),
                onPressed: onMailTap,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
