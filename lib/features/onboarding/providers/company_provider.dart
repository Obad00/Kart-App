import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';

class CompanyProvider extends ChangeNotifier {
  bool isLoading = false;
  String? error;

  // --- Lecture seule ("Mon entreprise") ---
  bool isLoadingCompany = false;
  Map<String, dynamic>? myCompany;
  List<Map<String, dynamic>> members = [];

  /// Charge les infos de l'entreprise de l'utilisateur connecté (lecture seule).
  Future<void> loadMyCompany() async {
    isLoadingCompany = true;
    error = null;
    notifyListeners();

    try {
      final response = await ApiClient.dio.get('/companies/me');
      if (response.data is Map) {
        myCompany = Map<String, dynamic>.from(response.data as Map);
      }
    } catch (e) {
      error = 'Impossible de charger les informations de l\'entreprise';
    }

    isLoadingCompany = false;
    notifyListeners();
  }

  /// Charge la liste des collègues (réservé owner/admin côté backend).
  Future<void> loadMembers() async {
    try {
      final response = await ApiClient.dio.get('/company/employees');
      final data = response.data;
      if (data is Map && data['data'] is List) {
        members = List<Map<String, dynamic>>.from(
          (data['data'] as List).map((e) => Map<String, dynamic>.from(e)),
        );
        notifyListeners();
      }
    } catch (e) {
      // Non-bloquant : un membre simple n'a pas accès à cette liste (403)
      debugPrint('⚠️ Impossible de charger les collègues: $e');
    }
  }

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
