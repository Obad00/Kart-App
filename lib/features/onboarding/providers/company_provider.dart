import 'dart:io';
import 'package:dio/dio.dart';
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
      // Preparer les donnees en FormData pour supporter l'upload d'image
      final formData = FormData.fromMap({
        'name': name,
        'max_users': maxUsers,
        'primary_color': primaryColor,
        'subscription_id': subscriptionId,
      });

      // Si un logo est fourni (chemin de fichier local uniquement)
      if (logo != null && logo.isNotEmpty && !logo.startsWith('http')) {
        final file = File(logo);
        if (await file.exists()) {
          final fileName = logo.split('/').last;
          formData.files.add(MapEntry(
            'logo',
            await MultipartFile.fromFile(
              logo,
              filename: fileName,
            ),
          ));
        }
      }

      await ApiClient.dio.post(
        '/companies',
        data: formData,
        options: Options(
          contentType: 'multipart/form-data',
        ),
      );
    } catch (e) {
      error = 'Erreur lors de la creation';
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
