import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/network/api_error.dart';
import '../services/plan_service.dart';

class PlanProvider extends ChangeNotifier {
  final PlanService _service;
  static const _pendingPlanKey = 'pending_plan_slug';

  PlanProvider({required PlanService service}) : _service = service;

  List<Map<String, dynamic>> _plans = [];
  String? error;
  bool loading = false;

  int? currentSubscriptionId;
  String? pendingPlanSlug;

  List<Map<String, dynamic>> get plans => _plans;

  Future<void> loadPendingPlanSlug() async {
    final prefs = await SharedPreferences.getInstance();
    pendingPlanSlug = prefs.getString(_pendingPlanKey);
    notifyListeners();
  }

  Future<void> setPendingPlanSlug(String? planSlug) async {
    final prefs = await SharedPreferences.getInstance();
    if (planSlug == null || planSlug.isEmpty) {
      await prefs.remove(_pendingPlanKey);
      pendingPlanSlug = null;
    } else {
      await prefs.setString(_pendingPlanKey, planSlug);
      pendingPlanSlug = planSlug;
    }
    notifyListeners();
  }

  Future<void> loadPlans() async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      _plans = await _service.fetchPlans();
    } catch (e) {
      error = getErrorMessage(e,
          fallback: 'Impossible de charger les plans. Réessayez.');
    }

    loading = false;
    notifyListeners();
  }

  Future<int?> subscribePlan(int planId) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      currentSubscriptionId = await _service.subscribePlan(planId);
      loading = false;
      notifyListeners();
      return currentSubscriptionId;
    } catch (e) {
      error = getErrorMessage(e,
          fallback: 'Impossible de souscrire à ce plan. Réessayez.');
      loading = false;
      notifyListeners();
      return null;
    }
  }

  Future<FreePlanActivationResponse?> activateFreePlan(String planSlug) async {
    loading = true;
    error = null;
    notifyListeners();

    try {
      final result = await _service.activateFreePlan(planSlug);
      loading = false;
      notifyListeners();
      return result;
    } catch (e) {
      error = getErrorMessage(e,
          fallback: 'Impossible d\'activer ce plan. Réessayez.');
      loading = false;
      notifyListeners();
      return null;
    }
  }
}
