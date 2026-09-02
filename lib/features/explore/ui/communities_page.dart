import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/community_provider.dart';
import '../widgets/community_card.dart';

/// "Voir tout" — grille de toutes les communautés actives, ouverte depuis
/// le carrousel "Réseaux populaires" de l'onglet Découvrir. Réutilise le
/// [CommunityProvider] déjà chargé par ExplorePage (passé via
/// ChangeNotifierProvider.value par l'appelant), donc pas de rechargement
/// ici — les actions rejoindre/quitter restent synchronisées entre les deux
/// écrans.
class CommunitiesPage extends StatelessWidget {
  const CommunitiesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Réseaux populaires')),
      body: SafeArea(
        child: Consumer<CommunityProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading && provider.communities.isEmpty) {
              return const Center(child: CircularProgressIndicator());
            }

            if (provider.communities.isEmpty) {
              return Center(
                child: Text(
                  'Aucune communauté pour le moment',
                  style: TextStyle(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5),
                  ),
                ),
              );
            }

            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.88,
              ),
              itemCount: provider.communities.length,
              itemBuilder: (context, index) {
                final community = provider.communities[index];
                return SizedBox(
                  width: double.infinity,
                  child: CommunityCard(
                    community: community,
                    onToggleJoin: () => provider.toggleJoin(community),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
