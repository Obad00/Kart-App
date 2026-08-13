import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/contact_model.dart';
import '../../public_card/ui/public_card_page.dart';

const _themeBlue = Color(0xFF3B82F6);

const _frenchMonths = [
  'janvier', 'février', 'mars', 'avril', 'mai', 'juin',
  'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre',
];

String _formatFrenchDate(DateTime date) =>
    '${date.day} ${_frenchMonths[date.month - 1]} ${date.year}';

/// Ligne de la liste de contacts (avatar, nom, poste, badge highlight +
/// date, favori, ouverture du détail) — remplace l'ancien rendu en grille
/// de cartes pour se rapprocher d'une vraie liste de contacts.
class ContactRow extends StatelessWidget {
  final ContactModel contact;
  final bool isSelected;
  final bool selectionModeActive;
  final ValueChanged<int>? onSelect;
  final VoidCallback? onToggleFavorite;
  final VoidCallback? onDelete;

  const ContactRow({
    super.key,
    required this.contact,
    this.isSelected = false,
    this.selectionModeActive = false,
    this.onSelect,
    this.onToggleFavorite,
    this.onDelete,
  });

  String? get _avatarUrl {
    final avatar = contact.avatar;
    if (avatar == null || avatar.isEmpty) return null;
    return avatar.startsWith('http')
        ? avatar
        : '${ApiEndpoints.storageUrl}/$avatar';
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '';
  }

  void _openPublicCard(BuildContext context) {
    final slug = contact.cardSlug;
    if (slug == null || slug.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ce contact n\'a pas de carte associée.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PublicCardPage(slug: slug, contactId: contact.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final avatarUrl = _avatarUrl;
    final selectable = isSelected || selectionModeActive;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          HapticFeedback.lightImpact();
          if (selectable) {
            onSelect?.call(contact.id);
          } else {
            _openPublicCard(context);
          }
        },
        onLongPress: () {
          HapticFeedback.mediumImpact();
          onSelect?.call(contact.id);
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected
                ? _themeBlue.withValues(alpha: 0.1)
                : colors.onSurface.withValues(alpha: 0.035),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: isSelected
                  ? _themeBlue.withValues(alpha: 0.4)
                  : colors.onSurface.withValues(alpha: 0.06),
            ),
          ),
          child: Row(
            children: [
              // Cercle de sélection — toujours visible (comme dans les
              // apps Apple), pas seulement en "mode sélection".
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onSelect?.call(contact.id);
                },
                child: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isSelected ? _themeBlue : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? _themeBlue
                          : colors.onSurface.withValues(alpha: 0.25),
                      width: 1.5,
                    ),
                  ),
                  child: isSelected
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 12),

              // Avatar
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: avatarUrl == null
                      ? const LinearGradient(
                          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  image: avatarUrl != null
                      ? DecorationImage(
                          image: CachedNetworkImageProvider(avatarUrl),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: avatarUrl == null
                    ? Center(
                        child: Text(
                          _initials(contact.fullname),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 14),

              // Nom / poste / badge highlight
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contact.fullname,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: colors.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if ((contact.job ?? contact.company ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        [contact.job, contact.company]
                            .where((v) => (v ?? '').isNotEmpty)
                            .join(' · '),
                        style: TextStyle(
                          fontSize: 12.5,
                          color: colors.onSurface.withValues(alpha: 0.55),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (contact.highlightName != null ||
                        contact.capturedAt != null) ...[
                      const SizedBox(height: 6),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (contact.highlightName != null)
                            Flexible(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: _themeBlue.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: _themeBlue.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.event_rounded,
                                        size: 11, color: _themeBlue),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        contact.highlightName!,
                                        style: const TextStyle(
                                          fontSize: 10.5,
                                          fontWeight: FontWeight.w600,
                                          color: _themeBlue,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (contact.highlightName != null &&
                              contact.capturedAt != null)
                            const SizedBox(width: 6),
                          if (contact.capturedAt != null)
                            Text(
                              _formatFrenchDate(contact.capturedAt!),
                              style: TextStyle(
                                fontSize: 11,
                                color: colors.onSurface.withValues(alpha: 0.4),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),

              // Favori
              if (onToggleFavorite != null && !selectionModeActive)
                IconButton(
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    onToggleFavorite!();
                  },
                  icon: Icon(
                    contact.isFavorite
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: contact.isFavorite
                        ? _themeBlue
                        : colors.onSurface.withValues(alpha: 0.35),
                  ),
                ),

              if (!selectionModeActive)
                Icon(
                  Icons.chevron_right_rounded,
                  color: colors.onSurface.withValues(alpha: 0.3),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
