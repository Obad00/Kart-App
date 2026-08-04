import 'package:flutter/material.dart';
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
      error = e.toString();
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
      error = e.toString();
      loading = false;
      notifyListeners();
      return false;
    }
  }
}
