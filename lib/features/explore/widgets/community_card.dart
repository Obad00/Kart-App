import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/community.dart';

/// Carte d'une communauté dans le carrousel "Réseaux populaires" — icône
/// colorée, nom, nombre de membres, pile d'avatars des derniers membres et
/// bouton rejoindre/quitter pleine largeur. Cf. maquette fournie.
class CommunityCard extends StatelessWidget {
  final Community community;
  final VoidCallback onToggleJoin;
  final VoidCallback? onTap;

  const CommunityCard({
    super.key,
    required this.community,
    required this.onToggleJoin,
    this.onTap,
  });

  String _avatarUrl(String avatar) {
    return avatar.startsWith('http')
        ? avatar
        : '${ApiEndpoints.storageUrl}/$avatar';
  }

  String _membersLabel(int count) {
    if (count >= 1000) {
      final k = count / 1000;
      final formatted =
          k == k.roundToDouble() ? k.toStringAsFixed(0) : k.toStringAsFixed(1);
      return '$formatted k membres';
    }
    return '$count ${count > 1 ? 'membres' : 'membre'}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
      padding: const EdgeInsets.only(top: 14, left: 14, right: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.onSurface.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.12 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: community.color.withValues(alpha: 0.16),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.groups_rounded, color: community.color, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            community.name,
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 14.5,
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
              height: 1.15,
            ),
            // 1 ligne (pas 2) : garde une hauteur de carte prévisible, sans
            // quoi il faudrait réserver la place du pire cas (nom sur 2
            // lignes) pour CHAQUE carte — d'où l'espace vide visible sous
            // les noms courts.
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            _membersLabel(community.membersCount),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.onSurface.withValues(alpha: 0.55),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          if (community.previewAvatars.isNotEmpty) ...[
            _AvatarStack(
              avatarUrls: community.previewAvatars.map(_avatarUrl).toList(),
              borderColor: colors.surface,
            ),
            const SizedBox(height: 10),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                onToggleJoin();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: community.isJoined
                    ? colors.onSurface.withValues(alpha: 0.06)
                    : community.color.withValues(alpha: 0.16),
                foregroundColor: community.isJoined
                    ? colors.onSurface.withValues(alpha: 0.7)
                    : community.color,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                community.isJoined ? 'Membre' : 'Rejoindre',
                style: const TextStyle(
                    fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
      ),
      ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final List<String> avatarUrls;
  final Color borderColor;

  const _AvatarStack({required this.avatarUrls, required this.borderColor});

  static const double _size = 24;
  static const double _overlap = 8;

  @override
  Widget build(BuildContext context) {
    final count = avatarUrls.length;
    return SizedBox(
      height: _size,
      width: _size + (count - 1) * (_size - _overlap),
      child: Stack(
        children: List.generate(count, (i) {
          return Positioned(
            left: i * (_size - _overlap),
            child: Container(
              width: _size,
              height: _size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: borderColor, width: 2),
              ),
              child: ClipOval(
                child: CachedNetworkImage(
                  imageUrl: avatarUrls[i],
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.high,
                  placeholder: (context, url) =>
                      Container(color: Colors.grey.withValues(alpha: 0.2)),
                  errorWidget: (context, url, error) =>
                      Container(color: Colors.grey.withValues(alpha: 0.2)),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
