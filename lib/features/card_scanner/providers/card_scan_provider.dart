import 'dart:io';
import 'package:flutter/material.dart';
import '../models/scanned_contact.dart';
import '../services/card_scan_service.dart';

enum ScanState {
  idle,
  scanning,
  success,
  error,
  saving,
}

class CardScanProvider extends ChangeNotifier {
  final CardScanService _service = CardScanService();

  ScanState state = ScanState.idle;
  String? error;
  File? selectedImage;
  ScannedContact? scannedContact;
  String? rawText;

  void setSelectedImage(File image) {
    selectedImage = image;
    error = null;
    state = ScanState.idle;
    notifyListeners();
  }

  void clearImage() {
    selectedImage = null;
    scannedContact = null;
    rawText = null;
    error = null;
    state = ScanState.idle;
    notifyListeners();
  }

  Future<bool> scanCard() async {
    if (selectedImage == null) {
      error = 'Aucune image sélectionnée';
      notifyListeners();
      return false;
    }

    state = ScanState.scanning;
    error = null;
    notifyListeners();

    final result = await _service.scanCard(selectedImage!);

    if (result.success && result.contact != null) {
      scannedContact = result.contact;
      rawText = result.rawText;
      state = ScanState.success;
      notifyListeners();
      return true;
    } else {
      error = result.error;
      state = ScanState.error;
      notifyListeners();
      return false;
    }
  }

  void updateContactField(String field, String value) {
    if (scannedContact == null) return;

    switch (field) {
      case 'firstName':
        scannedContact!.firstName = value;
        break;
      case 'lastName':
        scannedContact!.lastName = value;
        break;
      case 'jobTitle':
        scannedContact!.jobTitle = value;
        break;
      case 'company':
        scannedContact!.company = value;
        break;
      case 'email':
        scannedContact!.email = value;
        break;
      case 'phone':
        scannedContact!.phone = value;
        break;
      case 'address':
        scannedContact!.address = value;
        break;
      case 'website':
        scannedContact!.website = value;
        break;
    }
    notifyListeners();
  }

  Future<bool> saveContact() async {
    if (scannedContact == null) {
      error = 'Aucun contact à enregistrer';
      notifyListeners();
      return false;
    }

    state = ScanState.saving;
    error = null;
    notifyListeners();

    final success = await _service.saveContact(scannedContact!);

    if (success) {
      state = ScanState.idle;
      notifyListeners();
      return true;
    } else {
      error = 'Impossible d\'enregistrer le contact';
      state = ScanState.error;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    selectedImage = null;
    scannedContact = null;
    rawText = null;
    error = null;
    state = ScanState.idle;
    notifyListeners();
  }
}
