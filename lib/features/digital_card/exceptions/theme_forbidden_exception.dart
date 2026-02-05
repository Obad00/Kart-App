/// Exception levée quand un utilisateur FREE
/// tente d'accéder à une fonctionnalité PRO
class ThemeForbiddenException implements Exception {
  final String message;

  ThemeForbiddenException(this.message);

  @override
  String toString() => message;
}
