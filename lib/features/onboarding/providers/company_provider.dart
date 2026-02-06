import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

class CompanyProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;

 Future<void> createCompany({
  required String name,
  required int maxUsers,
  String? logo,
  String? primaryColor,
  String plan = 'enterprise',
})
 async {
    isLoading = true;
    notifyListeners();

    try {
      await ApiClient.dio.post('/companies', data: {
        'name': name,
        'max_users': maxUsers,
      });
    } catch (e) {
      error = 'Erreur création entreprise';
    }

    isLoading = false;
    notifyListeners();
  }

  Future<void> joinCompany(String code) async {
    isLoading = true;
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
