import 'dart:async';
import 'package:flutter/material.dart';
import '../models/plan.dart';
import '../models/payment_method.dart';
import '../models/payment.dart';
import '../services/payment_service.dart';

enum PaymentState {
  idle,
  loading,
  success,
  error,
}

class PaymentProvider extends ChangeNotifier {
  final PaymentService _service = PaymentService();

  PaymentState state = PaymentState.idle;
  String? error;

  List<Plan> plans = [];
  List<PaymentMethod> paymentMethods = [];
  Plan? selectedPlan;
  PaymentMethod? selectedPaymentMethod;

  String? currentReference;
  String? paymentUrl;
  Payment? currentPayment;

  Timer? _pollingTimer;
  int _pollingAttempts = 0;
  static const int _maxPollingAttempts = 40; // 2 minutes at 3s intervals

  Future<void> loadPlans() async {
    state = PaymentState.loading;
    error = null;
    notifyListeners();

    try {
      plans = await _service.fetchPlans();
      state = PaymentState.success;
    } catch (e) {
      error = 'Impossible de charger les plans';
      state = PaymentState.error;
    }
    notifyListeners();
  }

  Future<void> loadPaymentMethods() async {
    state = PaymentState.loading;
    error = null;
    notifyListeners();

    try {
      paymentMethods = await _service.fetchPaymentMethods();
      state = PaymentState.success;
    } catch (e) {
      error = 'Impossible de charger les méthodes de paiement';
      state = PaymentState.error;
    }
    notifyListeners();
  }

  void selectPlan(Plan plan) {
    selectedPlan = plan;
    notifyListeners();
  }

  void selectPaymentMethod(PaymentMethod method) {
    selectedPaymentMethod = method;
    notifyListeners();
  }

  Future<bool> initializePayment() async {
    if (selectedPlan == null || selectedPaymentMethod == null) {
      error = 'Veuillez sélectionner un plan et une méthode de paiement';
      notifyListeners();
      return false;
    }

    state = PaymentState.loading;
    error = null;
    notifyListeners();

    try {
      final result = await _service.initializePayment(
        planId: selectedPlan!.id,
        paymentMethod: selectedPaymentMethod!.id,
      );

      if (result.success) {
        currentReference = result.reference;
        paymentUrl = result.paymentUrl;
        state = PaymentState.success;
        notifyListeners();
        return true;
      } else {
        error = result.message;
        state = PaymentState.error;
        notifyListeners();
        return false;
      }
    } catch (e) {
      error = 'Erreur lors de l\'initialisation du paiement';
      state = PaymentState.error;
      notifyListeners();
      return false;
    }
  }

  void startPollingPaymentStatus(Function(Payment) onComplete) {
    if (currentReference == null) return;

    _pollingAttempts = 0;
    _pollingTimer?.cancel();

    _pollingTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      _pollingAttempts++;

      try {
        currentPayment = await _service.checkPaymentStatus(currentReference!);
        notifyListeners();

        if (currentPayment!.isSuccessful || currentPayment!.isFailed) {
          timer.cancel();
          onComplete(currentPayment!);
        } else if (_pollingAttempts >= _maxPollingAttempts) {
          timer.cancel();
          error = 'Délai d\'attente dépassé. Vérifiez votre paiement.';
          state = PaymentState.error;
          notifyListeners();
        }
      } catch (e) {
        // Continue polling on network errors
      }
    });
  }

  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  void reset() {
    stopPolling();
    selectedPlan = null;
    selectedPaymentMethod = null;
    currentReference = null;
    paymentUrl = null;
    currentPayment = null;
    error = null;
    state = PaymentState.idle;
    notifyListeners();
  }

  @override
  void dispose() {
    stopPolling();
    super.dispose();
  }
}
