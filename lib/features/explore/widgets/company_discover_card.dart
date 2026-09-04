import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/network/api_endpoints.dart';
import '../models/discoverable_company.dart';

const _themeBlue = Color(0xFF3B82F6);

/// Carte d'une entreprise dans "Entreprises à découvrir" — logo, nom,
/// secteur, nombre d'opportunités publiées, bouton suivre/suivi. cf.
/// maquette fournie (même esprit que CommunityCard pour les réseaux).
class CompanyDiscoverCard extends StatelessWidget {
  final DiscoverableCompany company;
  final VoidCallback onToggleFollow;
  final VoidCallback? onTap;

  const CompanyDiscoverCard({
    super.key,
    required this.company,
    required this.onToggleFollow,
    this.onTap,
  });

  String get _logoUrl {
    final logo = company.logo;
    if (logo == null || logo.isEmpty) return '';
    return logo.startsWith('http') ? logo : '${ApiEndpoints.storageUrl}/$logo';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final logoUrl = _logoUrl;

    return Material(
      color: colors.surface,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
      width: 168,
      padding: const EdgeInsets.all(14),
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
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 40,
              height: 40,
              color: _themeBlue.withValues(alpha: 0.1),
              child: logoUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: logoUrl,
                      fit: BoxFit.cover,
                      errorWidget: (context, url, error) => _initial(),
                    )
                  : _initial(),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            company.name,
            style: TextStyle(
              fontFamily: 'Syne',
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: colors.onSurface,
              height: 1.15,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 3),
          Text(
            company.industry?.isNotEmpty == true
                ? company.industry!
                : 'Entreprise',
            style: TextStyle(
              fontSize: 11.5,
              color: colors.onSurface.withValues(alpha: 0.55),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Text(
            company.opportunitiesCount > 0
                ? '${company.opportunitiesCount} opportunité${company.opportunitiesCount > 1 ? 's' : ''}'
                : 'Aucune opportunité pour le moment',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: company.opportunitiesCount > 0
                  ? _themeBlue
                  : colors.onSurface.withValues(alpha: 0.4),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {
                HapticFeedback.selectionClick();
                onToggleFollow();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor:
                    company.isFollowing ? colors.onSurface.withValues(alpha: 0.6) : _themeBlue,
                side: BorderSide(
                  color: company.isFollowing
                      ? colors.onSurface.withValues(alpha: 0.15)
                      : _themeBlue.withValues(alpha: 0.3),
                ),
                padding: const EdgeInsets.symmetric(vertical: 9),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              child: Text(
                company.isFollowing ? 'Suivi' : 'Suivre',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
        ),
      ),
    );
  }

  Widget _initial() {
    return Center(
      child: Text(
        company.name.isNotEmpty ? company.name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontFamily: 'Syne',
          fontWeight: FontWeight.w800,
          color: _themeBlue,
        ),
      ),
    );
  }
}
