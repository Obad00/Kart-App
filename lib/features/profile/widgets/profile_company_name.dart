import 'package:flutter/material.dart';

/// Nom de l'entreprise sous le poste, dans l'en-tête du profil. Sur 2
/// lignes : sur une seule, un nom long (« Cabinet Médical Ahmadina Saliou
/// (CMAS) ») était coupé.
class ProfileCompanyName extends StatelessWidget {
  final String name;

  const ProfileCompanyName(this.name, {super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Text(
      name,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: colors.onSurface.withValues(alpha: 0.6),
      ),
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
    );
  }
}
