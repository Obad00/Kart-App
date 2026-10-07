import 'package:flutter/foundation.dart';

import '../../../core/network/api_error.dart';
import '../data/nfc_card_service.dart';
import '../models/nfc_card_status.dart';

/// État de l'écran « Ma carte NFC ». Propre à l'écran (créé à son
/// ouverture) : rien à garder en mémoire le reste du temps.
class NfcCardProvider extends ChangeNotifier {
  NfcCardProvider([this._service = const NfcCardService()]);

  final NfcCardService _service;
  bool _disposed = false;

  NfcCardStatus? _status;
  bool _loading = false;
  String? _error;

  NfcCardStatus? get status => _status;
  bool get loading => _loading;

  /// Message d'erreur du dernier chargement, null s'il a réussi.
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    _notify();

    try {
      _status = await _service.fetch();
    } catch (e) {
      _error = getErrorMessage(
        e,
        fallback: 'Impossible de charger votre carte NFC. Réessayez.',
      );
    } finally {
      _loading = false;
      _notify();
    }
  }

  /// Renvoie un message d'erreur à afficher, ou null si la commande est
  /// passée.
  Future<String?> order({
    required String phone,
    required String address,
    String? notes,
  }) =>
      _run(
        () => _service.order(phone: phone, address: address, notes: notes),
        fallback: "La commande n'a pas pu être envoyée. Réessayez.",
      );

  Future<String?> activate(String code) => _run(
        () => _service.activate(code),
        fallback: "La carte n'a pas pu être activée. Réessayez.",
      );

  Future<String?> disable() {
    final tag = _status?.tag;
    if (tag == null) return Future.value('Aucune carte à désactiver.');
    return _run(
      () => _service.disable(tag.id),
      fallback: "La carte n'a pas pu être désactivée. Réessayez.",
    );
  }

  Future<String?> _run(
    Future<NfcCardStatus> Function() action, {
    required String fallback,
  }) async {
    try {
      _status = await action();
      _notify();
      return null;
    } catch (e) {
      return getErrorMessage(e, fallback: fallback);
    }
  }

  void _notify() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
