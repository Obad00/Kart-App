import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../shared/services/card_service.dart';

enum CardStatus {
  idle,
  loading,
  hasCard,
  noCard,
  error,
}

class CardProvider extends ChangeNotifier {
  // --- STATUS ---
  CardStatus _status = CardStatus.idle;
  CardStatus get status => _status;

  // --- DATA ---
  String? _qrSvg;
  String? _error;

  String? jobTitle;
  String? company;

  // --- LOADING ---
  bool _isQrLoading = false;
  bool _isSummaryLoading = false;

  // --- GETTERS ---
  String? get qrSvg => _qrSvg;
  String? get error => _error;

  bool get isLoading => _isQrLoading || _isSummaryLoading;
  bool get hasError => _error != null;
  bool get hasQrCode => _qrSvg != null && _qrSvg!.isNotEmpty;
  bool get isReady =>
    _status == CardStatus.hasCard && hasQrCode;

  // --- METHODS ---
  Future<void> loadCardSummary() async {
    _isSummaryLoading = true;
    _status = CardStatus.loading;
    notifyListeners();

    try {
      final res = await ApiClient.dio.get('/me/card-summary');

      if (res.data['job_title'] == null &&
          res.data['company'] == null) {
        _status = CardStatus.noCard;
        jobTitle = null;
        company = null;
      } else {
        jobTitle = res.data['job_title'];
        company  = res.data['company'];
        _status = CardStatus.hasCard;
      }
    } catch (e) {
      _status = CardStatus.error;
      _error = 'Impossible de charger le résumé de la carte';
    } finally {
      _isSummaryLoading = false;
      notifyListeners();
    }
  }

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

  void clearCard() {
    _qrSvg = null;
    _error = null;
    jobTitle = null;
    company = null;
    _status = CardStatus.idle;
    notifyListeners();
  }
}
