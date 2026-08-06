import 'package:dio/dio.dart';

/// Extrait un message d'erreur lisible et en français à partir d'une
/// exception d'appel API, plutôt que d'afficher `e.toString()` (technique,
/// en anglais) ou un message générique qui masque la vraie cause.
///
/// Priorité :
/// 1. Le premier message de validation renvoyé par le backend
///    (`errors: { champ: ["message"] }`, désormais en français grâce à
///    `lang/fr/validation.php`).
/// 2. Le `message` renvoyé par le backend, s'il est explicite (on ignore le
///    message générique Laravel "The given data was invalid.").
/// 3. Un message générique en français selon le type d'erreur réseau/HTTP.
String getErrorMessage(
  Object error, {
  String fallback = 'Une erreur est survenue. Réessayez.',
}) {
  if (error is! DioException) return fallback;

  final data = error.response?.data;

  if (data is Map) {
    final errors = data['errors'];
    if (errors is Map && errors.isNotEmpty) {
      final firstField = errors.values.first;
      if (firstField is List && firstField.isNotEmpty) {
        return firstField.first.toString();
      }
      if (firstField is String && firstField.isNotEmpty) {
        return firstField;
      }
    }

    final message = data['message'];
    if (message is String &&
        message.isNotEmpty &&
        message != 'The given data was invalid.') {
      return message;
    }
  }

  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
      return 'La connexion a expiré. Vérifiez votre connexion internet et réessayez.';
    case DioExceptionType.connectionError:
      return 'Impossible de se connecter. Vérifiez votre connexion internet.';
    case DioExceptionType.badCertificate:
      return 'Connexion sécurisée impossible. Réessayez plus tard.';
    case DioExceptionType.cancel:
      return 'Requête annulée.';
    case DioExceptionType.badResponse:
      final status = error.response?.statusCode;
      switch (status) {
        case 401:
          return 'Session expirée, reconnectez-vous.';
        case 403:
          return 'Action non autorisée.';
        case 404:
          return 'Ressource introuvable.';
        case 422:
          return 'Certaines informations sont invalides.';
        default:
          if (status != null && status >= 500) {
            return 'Erreur du serveur. Réessayez plus tard.';
          }
          return fallback;
      }
    case DioExceptionType.unknown:
      return fallback;
  }
}
