import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_endpoints.dart';
import '../../public_card/ui/public_card_page.dart';
import '../models/explore_user.dart';
import '../providers/explore_provider.dart';
import 'connect_action_button.dart';

const _accentAmber = Color(0xFFF59E0B);
const _cardWidth = 156.0;

/// Carte "portrait" d'un profil — photo en tête, nom (+ badge "profil
/// complet"), poste, entreprise (ou ville pour "Professionnels près de
/// vous"), bouton "Se connecter" pleine largeur. Utilisée par tous les
/// carrousels horizontaux de la page Explorer (refonte) : Recommandés,
/// Certifiés, Votre secteur, Nouveaux profils, Près de vous, Cette
/// semaine — cf. maquette fournie. Distincte de [ExploreUserRow] (rangée
/// compacte de la liste "Voir tout"/AllProfilesPage).
class ExploreProfileCard extends StatelessWidget {
  final ExploreUser user;
  final ExploreProvider? removeFrom;

  /// Remplace la ligne "entreprise" par la ville (avec une icône de
  /// localisation) — utilisé par "Professionnels près de vous", où le
  /// poste reste affiché normalement (2e ligne) mais la ville partagée
  /// prend la place de l'entreprise (3e ligne), plus pertinente ici.
  final bool showCityInsteadOfCompany;

  const ExploreProfileCard({
    super.key,
    required this.user,
    this.removeFrom,
    this.showCityInsteadOfCompany = false,
  });

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
            fontSize: 26,
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
    final subtitle = user.jobTitle ?? '';
    final thirdLine = showCityInsteadOfCompany
        ? (user.city ?? '')
        : (user.company ?? '');

    return SizedBox(
      width: _cardWidth,
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _openCard(context),
          child: Container(
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
                Stack(
                  children: [
                    ClipRRect(
                      borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(20)),
                      child: SizedBox(
                        height: 110,
                        width: double.infinity,
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
                    if (user.isNew)
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF7C3AED),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: const Text(
                            'Nouveau',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              user.name,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w700,
                                color: colors.onSurface,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user.hasCompleteProfile) ...[
                            const SizedBox(width: 3),
                            const Icon(Icons.verified_rounded,
                                size: 13, color: _accentAmber),
                          ],
                        ],
                      ),
                      if (subtitle.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _accentAmber,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      if (thirdLine.isNotEmpty) ...[
                        const SizedBox(height: 1),
                        Row(
                          children: [
                            if (showCityInsteadOfCompany) ...[
                              Icon(Icons.location_on_rounded,
                                  size: 11,
                                  color:
                                      colors.onSurface.withValues(alpha: 0.4)),
                              const SizedBox(width: 2),
                            ],
                            Flexible(
                              child: Text(
                                thirdLine,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: colors.onSurface.withValues(alpha: 0.55),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 8),
                      // width: double.infinity — sans lui, le bouton
                      // compact (SizedBox sans largeur imposée) ne prend
                      // que la largeur de son texte au lieu de remplir la
                      // carte, comme sur la maquette.
                      SizedBox(
                        width: double.infinity,
                        child: ConnectActionButton(
                          userId: user.id,
                          userName: user.name,
                          initialStatus: user.connectionStatus,
                          initialRequestId: user.connectionRequestId,
                          compact: true,
                          onResolved: removeFrom == null
                              ? null
                              : () => removeFrom!.removeUserLocally(user.id),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
