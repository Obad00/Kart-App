import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/network/api_endpoints.dart';
import '../../public_card/ui/public_card_page.dart';
import '../models/explore_user.dart';
import '../providers/explore_provider.dart';
import 'connect_action_button.dart';

const _accentAmber = Color(0xFFF59E0B);

/// Rangée compacte d'un profil dans l'annuaire — avatar rond, nom (+
/// badge "profil complet"), poste, entreprise, bouton "Se connecter"
/// compact. Utilisée à la fois par l'aperçu "Profils suggérés pour vous"
/// d'ExplorePage et par la liste complète d'AllProfilesPage ("Voir tout"),
/// pour garantir un rendu identique entre les deux. Pas de note/tags/
/// ville/pastille "en ligne" affichés : ces données n'existent pas dans
/// [ExploreUser] ni côté backend.
class ExploreUserRow extends StatelessWidget {
  final ExploreUser user;

  const ExploreUserRow({super.key, required this.user});

  String? get _avatarUrl {
    final avatar = user.avatar;
    if (avatar == null || avatar.isEmpty) return null;
    return avatar.startsWith('http')
        ? avatar
        : '${ApiEndpoints.storageUrl}/$avatar';
  }

  String _initials(String name) {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return '';
  }

  void _openCard(BuildContext context) {
    final slug = user.cardSlug;
    if (slug == null || slug.isEmpty) return;
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => PublicCardPage(slug: slug)),
    );
  }

  Widget _avatarFallback() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1D4ED8), Color(0xFF6D28D9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          _initials(user.name),
          style: const TextStyle(
            fontFamily: 'Syne',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final avatarUrl = _avatarUrl;
    final jobTitle = user.jobTitle ?? '';
    final company = user.company ?? '';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openCard(context),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: colors.onSurface.withValues(alpha: 0.06)),
              // Ombre discrète — juste de quoi détacher la carte du fond.
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                ClipOval(
                  child: SizedBox(
                    width: 52,
                    height: 52,
                    child: avatarUrl != null
                        ? CachedNetworkImage(
                            imageUrl: avatarUrl,
                            fit: BoxFit.cover,
                            filterQuality: FilterQuality.high,
                            fadeInDuration: const Duration(milliseconds: 200),
                            placeholder: (context, url) => _avatarFallback(),
                            errorWidget: (context, url, error) =>
                                _avatarFallback(),
                          )
                        : _avatarFallback(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          // Le backend trie déjà l'annuaire par complétion
                          // décroissante — ce badge la rend visible ici.
                          if (user.hasCompleteProfile) ...[
                            const SizedBox(width: 4),
                            const Icon(Icons.verified_rounded,
                                size: 15, color: _accentAmber),
                          ],
                        ],
                      ),
                      if (jobTitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          jobTitle,
                          style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: _accentAmber,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (company.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Text(
                          company,
                          style: TextStyle(
                            fontSize: 12,
                            color: colors.onSurface.withValues(alpha: 0.55),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                // compact:true — un simple bouton tap, le geste "glisser
                // pour se connecter" n'a pas la place de fonctionner dans
                // une rangée aussi étroite (cf. ConnectActionButton).
                ConnectActionButton(
                  userId: user.id,
                  userName: user.name,
                  initialStatus: user.connectionStatus,
                  initialRequestId: user.connectionRequestId,
                  compact: true,
                  onResolved: () =>
                      context.read<ExploreProvider>().removeUserLocally(user.id),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
