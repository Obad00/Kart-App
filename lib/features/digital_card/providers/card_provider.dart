import 'package:flutter/material.dart';
import '../../../shared/services/card_service.dart';
import '../../../core/network/api_client.dart';

/// Provider de gestion d'état pour la carte digitale KART.
///
/// Responsabilités:
/// - Charger le QR code SVG de la carte personnelle
/// - Gérer les états (loading, success, error)
/// - Exposer les données à la UI via ChangeNotifier
class CardProvider extends ChangeNotifier {
  // États
  String? _qrSvg;
  String? _error;

  // Getters
  String? get qrSvg => _qrSvg;
  String? get error => _error;

bool _isQrLoading = false;
bool _isSummaryLoading = false;

bool get isLoading => _isQrLoading || _isSummaryLoading;


  String? jobTitle;
  String? company;

Future<void> loadCardSummary() async {
  _isSummaryLoading = true;
  notifyListeners();

  try {
    final res = await ApiClient.dio.get('/me/card-summary');

    // debugPrint('SUMMARY RESPONSE => ${res.data}');

    jobTitle = res.data['job_title'];
    company  = res.data['company'];
  } catch (e) {
    _error = 'Impossible de charger le résumé de la carte';
  } finally {
    _isSummaryLoading = false;
    notifyListeners();
  }
}




  /// Charge le QR code SVG de la carte personnelle de l'utilisateur.
  ///
  /// Effectue les étapes suivantes:
  /// 1. Réinitialise l'état d'erreur
  /// 2. Active l'état de chargement
  /// 3. Appelle [CardService.getCardQrCode()]
  /// 4. Stocke le SVG si succès, ou l'erreur si échec
  /// 5. Notifie les écouteurs
  ///
  /// Gestion d'erreurs:
  /// - 401: Token invalide/expiré → redirection login recommandée
  /// - 403: Accès refusé
  /// - 500: Erreur serveur
  /// - Autres: Erreurs réseau/timeout
Future<void> loadMyCardQr() async {
  _error = null;
  _isQrLoading = true;
  notifyListeners();

  try {
    _qrSvg = await CardService.getCardQrCode();
  } catch (e) {
    _qrSvg = null;
    _error = 'Erreur lors du chargement du QR code';
  } finally {
    _isQrLoading = false;
    notifyListeners();
  }
}


  /// Réinitialise les données de la carte.
  ///
  /// Utile lors de la déconnexion ou pour rafraîchir manuellement.
 void clearCard() {
  _qrSvg = null;
  _error = null;
  _isQrLoading = false;
  _isSummaryLoading = false;
  jobTitle = null;
  company = null;
  notifyListeners();
}


  /// Vérifie si le QR code a été chargé avec succès.
  bool get hasQrCode => _qrSvg != null && _qrSvg!.isNotEmpty;

  /// Vérifie s'il y a une erreur en attente.
  bool get hasError => _error != null;
}
