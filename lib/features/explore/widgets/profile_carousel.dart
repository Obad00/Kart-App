import 'package:flutter/material.dart';
import '../models/explore_user.dart';
import 'explore_profile_card.dart';
import 'explore_section_header.dart';

/// Un carrousel horizontal de [ExploreProfileCard] avec son en-tête — même
/// structure pour Recommandés, Certifiés, Votre secteur, Nouveaux profils,
/// Près de vous, Cette semaine (cf. ExplorePage). Ne s'affiche pas du tout
/// si [users] est vide : ces carrousels "annexes" (contrairement à
/// Recommandés, toujours affiché) n'ont pas d'état vide à montrer, ils
/// disparaissent simplement (ex: personne d'autre dans la même ville).
class ProfileCarousel extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<ExploreUser> users;
  final VoidCallback? onSeeAll;
  final bool showCityInsteadOfJobTitle;

  const ProfileCarousel({
    super.key,
    required this.title,
    required this.subtitle,
    required this.users,
    this.onSeeAll,
    this.showCityInsteadOfJobTitle = false,
  });

  @override
  Widget build(BuildContext context) {
    if (users.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExploreSectionHeader(
            title: title,
            subtitle: subtitle,
            onSeeAll: onSeeAll,
          ),
          SizedBox(
            height: 214,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              scrollDirection: Axis.horizontal,
              itemCount: users.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) => ExploreProfileCard(
                user: users[index],
                showCityInsteadOfJobTitle: showCityInsteadOfJobTitle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
