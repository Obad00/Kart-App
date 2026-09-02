import 'package:flutter/foundation.dart';
import '../models/community.dart';
import '../services/community_service.dart';

class CommunityProvider extends ChangeNotifier {
  final CommunityService _service;

  CommunityProvider(this._service);

  List<Community> communities = [];
  bool isLoading = false;
  String? error;

  Future<void> loadCommunities() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      communities = await _service.fetchCommunities();
    } catch (e) {
      debugPrint('❌ Erreur loadCommunities: $e');
      error = 'Impossible de charger les communautés.';
    }

    isLoading = false;
    notifyListeners();
  }

  /// Bascule rejoindre/quitter — mise à jour optimiste (le compteur affiché
  /// change tout de suite), corrigée avec le vrai total renvoyé par le
  /// serveur une fois la requête terminée ; en cas d'échec, on revient à
  /// l'état d'avant.
  Future<void> toggleJoin(Community community) async {
    final index = communities.indexWhere((c) => c.id == community.id);
    if (index == -1) return;

    final wasJoined = community.isJoined;
    final optimisticCount =
        wasJoined ? community.membersCount - 1 : community.membersCount + 1;

    communities[index] = community.copyWith(
      isJoined: !wasJoined,
      membersCount: optimisticCount < 0 ? 0 : optimisticCount,
    );
    notifyListeners();

    try {
      final membersCount = wasJoined
          ? await _service.leave(community.id)
          : await _service.join(community.id);

      final freshIndex = communities.indexWhere((c) => c.id == community.id);
      if (freshIndex != -1) {
        communities[freshIndex] = communities[freshIndex].copyWith(
          membersCount: membersCount,
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('❌ Erreur toggleJoin (community ${community.id}): $e');
      final revertIndex = communities.indexWhere((c) => c.id == community.id);
      if (revertIndex != -1) {
        communities[revertIndex] = community;
        notifyListeners();
      }
    }
  }
}
