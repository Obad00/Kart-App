import 'package:flutter/material.dart';
import '../../../core/network/api_error.dart';
import '../model/skill_model.dart';
import '../services/candidate_skills_service.dart';

class CandidateSkillsProvider extends ChangeNotifier {
  final CandidateSkillsService service;

  CandidateSkillsProvider(this.service);

  List<CandidateSkillModel> skills = [];
  bool loading = false;
  String? error;

  Future<void> load() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      skills = await service.fetch();
    } catch (e) {
      error = getErrorMessage(e,
          fallback: 'Impossible de charger les compétences. Réessayez.');
    }

    loading = false;
    notifyListeners();
  }

  Future<bool> save(List<CandidateSkillModel> newSkills) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      skills = await service.update(newSkills);
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = getErrorMessage(e,
          fallback: 'Impossible d\'enregistrer vos compétences. Réessayez.');
      loading = false;
      notifyListeners();
      return false;
    }
  }
}
