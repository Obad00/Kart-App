import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/contact_model.dart';

/// Rangée d'accès rapide aux contacts marqués favoris (étoile ⭐ sur la
/// carte) — façon "à la une" : les visages en premier, un tap ouvre
/// directement les actions de ce contact.
class FavoritesStrip extends StatelessWidget {
  final List<ContactModel> favorites;
  final ValueChanged<ContactModel> onTapFavorite;

  const FavoritesStrip({
    super.key,
    required this.favorites,
    required this.onTapFavorite,
  });

  @override
  Widget build(BuildContext context) {
    if (favorites.isEmpty) return const SizedBox.shrink();

    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
          child: Text(
            'FAVORIS',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: colors.onSurface.withValues(alpha: 0.4),
            ),
          ),
        ),
        SizedBox(
          height: 88,
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: favorites.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (_, index) {
              final contact = favorites[index];
              final avatar = contact.avatar;
              final avatarUrl = (avatar == null || avatar.isEmpty)
                  ? null
                  : (avatar.startsWith('http')
                      ? avatar
                      : '${ApiEndpoints.storageUrl}/$avatar');

              return GestureDetector(
                onTap: () => onTapFavorite(contact),
                child: SizedBox(
                  width: 62,
                  child: Column(
                    children: [
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: avatarUrl == null
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF2563EB),
                                    Color(0xFF1D4ED8)
                                  ],
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
                          border: Border.all(
                            color: const Color(0xFF3B82F6),
                            width: 2,
                          ),
                        ),
                        child: avatarUrl == null
                            ? Center(
                                child: Text(
                                  _initials(contact.fullname),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              )
                            : null,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        contact.fullname.split(' ').first,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          color: colors.onSurface.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
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
}
