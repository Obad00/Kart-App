import 'package:flutter/foundation.dart';
import '../../../core/network/api_error.dart';
import '../models/professional_document.dart';
import '../services/professional_document_service.dart';

class ProfessionalDocumentProvider extends ChangeNotifier {
  final ProfessionalDocumentService _service;

  ProfessionalDocumentProvider(this._service);

  List<ProfessionalDocument> documents = [];
  bool isLoading = false;
  String? error;

  Future<void> load() async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      documents = await _service.fetch();
    } catch (e) {
      debugPrint('❌ Erreur load ProfessionalDocuments: $e');
      error = 'Impossible de charger vos documents.';
    }

    isLoading = false;
    notifyListeners();
  }

  /// Retourne un message d'erreur en cas d'échec (à afficher par
  /// l'appelant), ou `null` en cas de succès.
  Future<String?> upload({
    required String title,
    String? institution,
    int? year,
    required String category,
    required Uint8List fileBytes,
    required String fileName,
  }) async {
    try {
      final doc = await _service.upload(
        title: title,
        institution: institution,
        year: year,
        category: category,
        fileBytes: fileBytes,
        fileName: fileName,
      );
      documents = [doc, ...documents];
      notifyListeners();
      return null;
    } catch (e) {
      debugPrint('❌ Erreur upload ProfessionalDocument: $e');
      return getErrorMessage(e, fallback: "Impossible d'ajouter ce document.");
    }
  }

  /// Retrait optimiste — remis en place si la suppression échoue côté
  /// serveur (cf. removeUserLocally dans ExploreProvider pour le même
  /// principe).
  Future<void> remove(int id) async {
    final backup = documents;
    documents = documents.where((d) => d.id != id).toList();
    notifyListeners();

    try {
      await _service.delete(id);
    } catch (e) {
      debugPrint('❌ Erreur delete ProfessionalDocument: $e');
      documents = backup;
      notifyListeners();
    }
  }

  void reset() {
    documents = [];
    isLoading = false;
    error = null;
    notifyListeners();
  }
}
