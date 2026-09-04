import 'package:flutter/foundation.dart';

import '../models/discoverable_company.dart';
import '../models/explore_category.dart';
import '../models/explore_user.dart';
import '../services/company_discovery_service.dart';
import '../services/explore_service.dart';

/// Charge en une fois tous les carrousels "annexes" de la page Explorer
/// (refonte) — "Profils recommandés pour vous" reste porté par
/// [ExploreProvider] (pagination/recherche déjà en place) ; celui-ci ne
/// gère que les aperçus supplémentaires : certifiés, votre secteur,
/// nouveaux profils, près de vous, catégories, entreprises.
///
/// Chaque section échoue indépendamment (ex: pas de ville renseignée ->
/// "près de vous" vide) sans faire échouer les autres — Future.wait avec
/// des futures qui capturent déjà leurs erreurs.
class ExploreDiscoveryProvider extends ChangeNotifier {
  final ExploreService _exploreService;
  final CompanyDiscoveryService _companyService;

  ExploreDiscoveryProvider(this._exploreService, this._companyService);

  static const _previewCount = 8;

  List<ExploreUser> certified = [];
  List<ExploreUser> sector = [];
  List<ExploreUser> newProfiles = [];
  List<ExploreUser> nearYou = [];
  List<ExploreUser> weekly = [];
  List<ExploreCategory> categories = [];
  List<DiscoverableCompany> companies = [];

  bool isLoading = false;
  bool _loaded = false;

  Future<void> loadAll({bool force = false}) async {
    if (_loaded && !force) return;
    isLoading = true;
    notifyListeners();

    final results = await Future.wait([
      _safeUsers('certified'),
      _safeUsers('sector'),
      _safeUsers('new'),
      _safeUsers('near'),
      _safeUsers('weekly'),
      _safeCategories(),
      _safeCompanies(),
    ]);

    certified = results[0] as List<ExploreUser>;
    sector = results[1] as List<ExploreUser>;
    newProfiles = results[2] as List<ExploreUser>;
    nearYou = results[3] as List<ExploreUser>;
    weekly = results[4] as List<ExploreUser>;
    categories = results[5] as List<ExploreCategory>;
    companies = results[6] as List<DiscoverableCompany>;

    _loaded = true;
    isLoading = false;
    notifyListeners();
  }

  Future<List<ExploreUser>> _safeUsers(String section) async {
    try {
      final result =
          await _exploreService.fetchUsers(page: 1, section: section);
      return result.users.take(_previewCount).toList();
    } catch (e) {
      debugPrint('❌ Erreur chargement Explorer ($section): $e');
      return [];
    }
  }

  Future<List<ExploreCategory>> _safeCategories() async {
    try {
      return await _exploreService.fetchCategories();
    } catch (e) {
      debugPrint('❌ Erreur chargement des catégories Explorer: $e');
      return [];
    }
  }

  Future<List<DiscoverableCompany>> _safeCompanies() async {
    try {
      return await _companyService.fetchCompanies();
    } catch (e) {
      debugPrint('❌ Erreur chargement des entreprises Explorer: $e');
      return [];
    }
  }

  /// Bascule suivre/ne plus suivre — mise à jour optimiste comme
  /// CommunityProvider.toggleJoin, sans compteur de membres à corriger ici
  /// (opportunitiesCount ne dépend pas du suivi).
  Future<void> toggleFollowCompany(DiscoverableCompany company) async {
    final index = companies.indexWhere((c) => c.id == company.id);
    if (index == -1) return;

    final wasFollowing = company.isFollowing;
    companies[index] = company.copyWith(isFollowing: !wasFollowing);
    notifyListeners();

    try {
      if (wasFollowing) {
        await _companyService.unfollow(company.id);
      } else {
        await _companyService.follow(company.id);
      }
    } catch (e) {
      debugPrint('❌ Erreur toggleFollowCompany (${company.id}): $e');
      final revertIndex = companies.indexWhere((c) => c.id == company.id);
      if (revertIndex != -1) {
        companies[revertIndex] = company;
        notifyListeners();
      }
    }
  }
}
