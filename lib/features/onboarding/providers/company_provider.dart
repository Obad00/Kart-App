import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

class CompanyProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;

  /// Créer une entreprise
  Future<void> createCompany({
    required String name,
    required int maxUsers,
    String? logo,
    String? primaryColor,
    required int subscriptionId, // obligatoire pour ton backend
  }) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await ApiClient.dio.post('/companies', data: {
        'name': name,
        'max_users': maxUsers,
        'logo': logo,
        'primary_color': primaryColor,
        'subscription_id': subscriptionId,
      });
    } catch (e) {
      error = 'Erreur lors de la création de l’entreprise';
    }

    isLoading = false;
    notifyListeners();
  }

  /// Rejoindre une entreprise via code
  Future<void> joinCompany(String code) async {
    isLoading = true;
    error = null;
    notifyListeners();

    try {
      await ApiClient.dio.post('/companies/join', data: {
        'license_code': code,
      });
    } catch (e) {
      error = 'Code invalide';
    }

    isLoading = false;
    notifyListeners();
  }
}
