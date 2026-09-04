import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/explore_discovery_provider.dart';
import '../widgets/company_discover_card.dart';
import 'company_detail_page.dart';
import '../../../shared/widgets/glass_app_bar.dart';
import '../../../shared/widgets/bottom_nav_metrics.dart';

/// "Voir tout" de "Entreprises à découvrir" — même [ExploreDiscoveryProvider]
/// que la page Explorer (déjà chargé), affiché en grille plutôt qu'en
/// scroll horizontal.
class CompaniesDiscoverPage extends StatelessWidget {
  const CompaniesDiscoverPage({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final glassAppBar = GlassAppBar(title: const Text('Entreprises à découvrir'));
    final topPadding =
        glassAppBar.preferredSize.height + MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: colors.surface,
      body: Stack(
        children: [
          SafeArea(
            top: false,
            bottom: false,
            child: Consumer<ExploreDiscoveryProvider>(
              builder: (context, provider, _) {
                if (provider.companies.isEmpty) {
                  return Padding(
                    padding: EdgeInsets.only(top: topPadding),
                    child: Center(
                      child: Text(
                        'Aucune entreprise à découvrir pour le moment',
                        style: TextStyle(
                          color: colors.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  padding: EdgeInsets.fromLTRB(
                    16,
                    topPadding + 16,
                    16,
                    24 +
                        BottomNavMetrics.bottomInset(
                            MediaQuery.of(context).padding.bottom),
                  ),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 168,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: provider.companies.length,
                  itemBuilder: (context, index) {
                    final company = provider.companies[index];
                    return CompanyDiscoverCard(
                      company: company,
                      onToggleFollow: () =>
                          provider.toggleFollowCompany(company),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CompanyDetailPage(
                            companyId: company.id,
                            companyName: company.name,
                          ),
                        ),
                      ),
                    );
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
