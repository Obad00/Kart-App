import 'package:flutter/material.dart';
import '../services/plan_service.dart';

class PlanProvider extends ChangeNotifier {
  final PlanService _service;

  PlanProvider({required PlanService service}) : _service = service;

  List<Map<String, dynamic>> _plans = [];
  String? error;
  bool loading = false;

  int? currentSubscriptionId;

  List<Map<String, dynamic>> get plans => _plans;

  Future<void> loadPlans() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      _plans = await _service.fetchPlans();
    } catch (e) {
      error = e.toString();
    }

    loading = false;
    notifyListeners();
  }

  Future<void> subscribePlan(int planId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      currentSubscriptionId = await _service.subscribePlan(planId);
    } catch (e) {
      error = e.toString();
    }

    loading = false;
    notifyListeners();
  }
}
