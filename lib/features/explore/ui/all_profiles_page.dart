import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/explore_provider.dart';
import '../widgets/explore_user_row.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/bottom_nav_metrics.dart';

/// "Voir tout" de la section "Profils suggérés pour vous" d'ExplorePage —
/// celle-ci n'en montre que les 5 premiers ; cette page affiche la liste
/// complète, paginée (défilement infini, cf. ExploreProvider.loadMore).
///
/// Attend un [ExploreProvider] déjà fourni par un ancêtre (même instance
/// qu'Explorer, passée via `ChangeNotifierProvider.value` au moment du
/// push) — déjà chargé, pas de fetch initial propre ici.
class AllProfilesPage extends StatefulWidget {
  const AllProfilesPage({super.key});

  @override
  State<AllProfilesPage> createState() => _AllProfilesPageState();
}

class _AllProfilesPageState extends State<AllProfilesPage> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200) {
      context.read<ExploreProvider>().loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final glassAppBar = GlassAppBar(
      title: const Text('Tous les profils'),
    );
    final topPadding =
        glassAppBar.preferredSize.height + MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          SafeArea(
            top: false,
            bottom: false,
            child: Consumer<ExploreProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return Padding(
                    padding: EdgeInsets.only(top: topPadding),
                    child: const Center(child: CircularProgressIndicator()),
                  );
                }

                if (provider.users.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.only(top: topPadding),
                    child: Center(
                      child: Text(
                        'Aucun profil à découvrir pour le moment',
                        style: TextStyle(
                          color: colors.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: EdgeInsets.only(
                    top: topPadding + 8,
                    bottom: 24 +
                        BottomNavMetrics.bottomInset(
                            MediaQuery.of(context).padding.bottom),
                  ),
                  itemCount: provider.users.length + (provider.hasMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index >= provider.users.length) {
                      return const Padding(
                        padding: EdgeInsets.all(16),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    return ExploreUserRow(user: provider.users[index]);
                  },
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SizedBox(height: topPadding, child: glassAppBar),
          ),
        ],
      ),
    );
  }
}
