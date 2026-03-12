import 'package:flutter/material.dart';

class CardHeader extends StatelessWidget {
  final String initials;
  final String fullName;
  final String subtitle;
  final VoidCallback? onLeadsTap;

  const CardHeader({
    super.key,
    required this.initials,
    required this.fullName,
    required this.subtitle,
    this.onLeadsTap,
  });
  
  

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              initials,
              style: const TextStyle(
                color: Color(0xFF0A0A0A),
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                fullName,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: colors.onSurface.withAlpha(180),
                ),
              ),
            ],
          ),
        ),
        // Bouton pour voir les leads/contacts
        if (onLeadsTap != null)
          IconButton(
            icon: const Icon(Icons.people_outline),
            tooltip: 'Mes contacts',
            onPressed: onLeadsTap,
          ),
        IconButton(
          icon: const Icon(Icons.more_vert),
          onPressed: () {},
        ),
      ],
    );
  }
}
