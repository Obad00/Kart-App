import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../../shared/services/card_service.dart';

/// Provider de gestion d'état pour la carte digitale KART.
///
/// Responsabilités:
/// - Charger le QR code SVG de la carte personnelle
/// - Gérer les états (loading, success, error)
/// - Exposer les données à la UI via ChangeNotifier
class CardProvider extends ChangeNotifier {
  // États
  String? _qrSvg;
  bool _isLoading = false;
  String? _error;

  // Getters
  String? get qrSvg => _qrSvg;
  bool get isLoading => _isLoading;
  String? get error => _error;

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
    _isLoading = true;
    notifyListeners();

    try {
      final svgData = await CardService.getCardQrCode();

      _qrSvg = svgData;
      _error = null;
    } on DioException catch (e) {
      _qrSvg = null;
      _error = e.error is String
          ? e.error as String
          : 'Erreur lors du chargement du QR code';

      // Log ou analyse additionnelle si nécessaire
      debugPrint(
          'CardProvider Error - Status: ${e.response?.statusCode}, Message: $_error');
    } catch (e) {
      _qrSvg = null;
      _error = 'Erreur inattendue: $e';
      debugPrint('CardProvider Unexpected Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Réinitialise les données de la carte.
  ///
  /// Utile lors de la déconnexion ou pour rafraîchir manuellement.
  void clearCard() {
    _qrSvg = null;
    _error = null;
    _isLoading = false;
    notifyListeners();
  }

  /// Vérifie si le QR code a été chargé avec succès.
  bool get hasQrCode => _qrSvg != null && _qrSvg!.isNotEmpty;

  /// Vérifie s'il y a une erreur en attente.
  bool get hasError => _error != null;
}
