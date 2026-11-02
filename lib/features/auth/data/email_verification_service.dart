import 'auth_api.dart';

/// Réponse d'un renvoi de code : envoyé ou refusé par le serveur, avec le
/// délai avant le prochain renvoi (compte à rebours de l'écran et du bandeau).
class ResendResult {
  final bool sent;
  final int retryAfter;
  final String? message;

  const ResendResult({required this.sent, required this.retryAfter, this.message});
}

/// Réponse d'une saisie de code.
class CodeResult {
  final bool verified;
  final String status;
  final int attemptsLeft;
  final String message;

  const CodeResult({
    required this.verified,
    required this.status,
    required this.attemptsLeft,
    required this.message,
  });

  /// Plus d'essai possible avec ce code : il faut en demander un nouveau.
  bool get needsNewCode => const ['expired', 'too_many_attempts', 'no_code'].contains(status);
}

/// Appels de la vérification d'email (code à 6 chiffres, renvoi limité par
/// le serveur à 1 par minute et 5 par heure).
class EmailVerificationService {
  final AuthApi _api;

  EmailVerificationService({AuthApi? api}) : _api = api ?? AuthApi();

  Future<ResendResult> resend() async {
    try {
      final response = await _api.resendEmailVerification();
      final data = response.data is Map ? response.data as Map : const {};
      final retryAfter = int.tryParse('${data['retry_after'] ?? 0}') ?? 0;
      final code = response.statusCode ?? 0;
      if (code >= 200 && code < 300) {
        return ResendResult(sent: true, retryAfter: retryAfter > 0 ? retryAfter : 60);
      }
      return ResendResult(
        sent: false,
        retryAfter: retryAfter,
        message: data['message']?.toString() ?? "Impossible d'envoyer l'email pour le moment.",
      );
    } catch (_) {
      return const ResendResult(
        sent: false,
        retryAfter: 0,
        message: "Impossible d'envoyer l'email pour le moment.",
      );
    }
  }

  Future<CodeResult> verifyCode(String code) async {
    try {
      final response = await _api.verifyEmailCode(code);
      final data = response.data is Map ? response.data as Map : const {};
      final status = data['status']?.toString() ?? 'error';
      return CodeResult(
        verified: response.statusCode == 200,
        status: status,
        attemptsLeft: int.tryParse('${data['attempts_left'] ?? 0}') ?? 0,
        message: data['message']?.toString() ?? 'Vérification impossible pour le moment.',
      );
    } catch (_) {
      return const CodeResult(
        verified: false,
        status: 'error',
        attemptsLeft: 0,
        message: 'Vérification impossible pour le moment. Vérifiez votre connexion.',
      );
    }
  }
}
