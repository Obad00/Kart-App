import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../model/profile_completion_model.dart';
import '../services/profile_completion_service.dart';

class ProfileCompletionProvider extends ChangeNotifier {
  final ProfileCompletionService service;

  ProfileCompletionProvider(this.service);

  ProfileCompletionModel model = ProfileCompletionModel();

  bool loading = false;
  // Si le dernier fetch() a échoué (réseau, backend pas encore à jour...),
  // 'model' reste sur son état précédent (vide au tout premier chargement)
  // — sans ce champ, un échec était totalement silencieux : la page
  // Profil semblait juste "vide", sans aucune indication que la
  // récupération avait raté plutôt que de refléter un profil réellement
  // sans expériences/formations/etc.
  String? error;

  /// Remet le provider à zéro à la déconnexion (cf. CardProvider.reset).
  void reset() {
    model = ProfileCompletionModel();
    loading = false;
    error = null;
    notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      model = await service.fetch();
    } catch (e) {
      debugPrint('❌ Erreur ProfileCompletionProvider.load(): $e');
      error = 'Impossible de charger votre profil.';
    }

    loading = false;
    notifyListeners();
  }

  Future<bool> save() async {
    return await service.update(model);
  }

  void updateModel(ProfileCompletionModel newModel) {
    model = newModel;
    notifyListeners();
  }

  // getters shortcuts
  String? get jobTitle => model.jobTitle;
  String? get company => model.company;
  String? get phone => model.phone;
  String? get email => model.email;

  String? get linkedin => model.linkedin;
  String? get instagram => model.instagram;
  String? get github => model.github;
  String? get facebook => model.facebook;
  String? get website => model.website;
}
