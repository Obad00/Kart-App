import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/explore_provider.dart';
import '../services/explore_service.dart';
import '../widgets/explore_user_row.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/bottom_nav_metrics.dart';

/// "Voir tout" générique pour n'importe quel carrousel de la page Explorer
/// (refonte) — Certifiés, Votre secteur, Nouveaux profils, Près de vous,
/// Cette semaine. Instancie son propre [ExploreProvider] (section dédiée,
/// paginé) plutôt que de partager celui de la page Explorer : contrairement
/// à "Profils recommandés pour vous" (cf. AllProfilesPage), ces listes ne
/// sont jamais déjà chargées avant l'ouverture de cette page.
class SectionProfilesPage extends StatefulWidget {
  final String section;
  final String title;
  // Nom d'un secteur JobSectors ("Tech & Digital"...) — "Explorer par
  // catégorie" (tap sur une case), indépendant de section.
  final String category;

  const SectionProfilesPage({
    super.key,
    this.section = 'recommended',
    required this.title,
    this.category = '',
  });

  @override
  State<SectionProfilesPage> createState() => _SectionProfilesPageState();
}

class _SectionProfilesPageState extends State<SectionProfilesPage> {
  late final ExploreProvider _provider;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _provider = ExploreProvider(
      ExploreService(),
      section: widget.section,
      category: widget.category,
    );
    _provider.loadUsers();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >
        _scrollController.position.maxScrollExtent - 200) {
      _provider.loadMore();
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _provider.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final glassAppBar = GlassAppBar(title: Text(widget.title));
    final topPadding =
        glassAppBar.preferredSize.height + MediaQuery.of(context).padding.top;

    return ChangeNotifierProvider.value(
      value: _provider,
      child: Scaffold(
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
                          'Aucun profil à afficher pour le moment',
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
                    itemCount:
                        provider.users.length + (provider.hasMore ? 1 : 0),
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
      ),
    );
  }
}
