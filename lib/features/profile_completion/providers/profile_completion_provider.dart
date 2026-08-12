import 'package:flutter/material.dart';
import '../model/profile_completion_model.dart';
import '../services/profile_completion_service.dart';

class ProfileCompletionProvider extends ChangeNotifier {
  final ProfileCompletionService service;

  ProfileCompletionProvider(this.service);

  ProfileCompletionModel model = ProfileCompletionModel();

  bool loading = false;

  /// Remet le provider à zéro à la déconnexion (cf. CardProvider.reset).
  void reset() {
    model = ProfileCompletionModel();
    loading = false;
    notifyListeners();
  }

  Future<void> load() async {
    loading = true;
    notifyListeners();

    model = await service.fetch();

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
