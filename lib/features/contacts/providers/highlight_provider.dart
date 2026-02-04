import 'package:flutter/material.dart';
import '../models/highlight_model.dart';
import '../../../shared/services/card_service.dart';

class HighlightProvider extends ChangeNotifier {
  List<HighlightModel> highlights = [];
  bool isLoading = false;

  HighlightModel? get active {
    try {
      return highlights.firstWhere((h) => h.isActive);
    } catch (_) {
      return null;
    }
  }

  // ✅ Lister
  Future<void> loadHighlights() async {
    isLoading = true;
    notifyListeners();

    try {
      final data = await CardService.fetchHighlights();
      highlights =
          data.map((e) => HighlightModel.fromJson(e)).toList();
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  // ✅ Créer
  Future<void> createHighlight(String name) async {
    await CardService.createHighlight(name);
    await loadHighlights();
  }

  // ✅ Activer / désactiver
  Future<void> toggleHighlight(HighlightModel highlight) async {
    if (highlight.isActive) {
      await CardService.deactivateHighlight(highlight.id);
    } else {
      await CardService.activateHighlight(highlight.id);
    }
    await loadHighlights();
  }
}
