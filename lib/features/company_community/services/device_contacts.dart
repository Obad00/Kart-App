import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contacts/flutter_contacts.dart' as fc;
import 'package:flutter_native_contact_picker/flutter_native_contact_picker.dart'
    as picker;

/// Accès aux contacts du téléphone pour « Ajouter depuis mes contacts ».
///
/// - iOS : lecture de la liste avec permission (accès limité d'iOS 18 géré),
///   et sélecteur natif multiple (sans permission) en repli.
/// - Android : AUCUNE permission Contacts (règle Google Play « Contacts
///   Permissions ») : sélecteur système, un contact à la fois, via le canal
///   natif kart/contact_picker (cf. MainActivity.kt).
///
/// Rien n'est envoyé d'ici : seuls les contacts cochés partent ensuite vers
/// KART (route batch). Aucun format de numéro n'est calculé : le numéro est
/// transmis tel qu'il est enregistré, le backend le normalise.
abstract class DeviceContactsSource {
  Future<ContactsAccess> check();
  Future<ContactsAccess> request();
  Future<List<DeviceContact>> readAll();

  /// iOS : sélecteur natif multiple, sans permission.
  Future<List<DeviceContact>> pickMultipleNative();

  /// Android : sélecteur système, un numéro ; null si Retour.
  Future<DeviceContact?> pickOneNative();

  Future<void> openSettings();
}

enum ContactsAccess { full, limited, notDetermined, denied }

class DeviceContactPhone {
  final String number;
  final String label;
  final bool isMobile;

  const DeviceContactPhone({
    required this.number,
    required this.label,
    this.isMobile = false,
  });
}

class DeviceContact {
  final String id;
  final String name;
  final List<DeviceContactPhone> phones;

  const DeviceContact({
    required this.id,
    required this.name,
    required this.phones,
  });

  /// Le mobile par défaut, sinon le premier numéro.
  int get defaultPhoneIndex {
    final mobile = phones.indexWhere((p) => p.isMobile);
    return mobile >= 0 ? mobile : 0;
  }

  String get initials {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? '?' : letters;
  }
}

class PlatformDeviceContacts implements DeviceContactsSource {
  static const _androidPicker = MethodChannel('kart/contact_picker');

  bool get _isIos => defaultTargetPlatform == TargetPlatform.iOS;

  @override
  Future<ContactsAccess> check() async =>
      _isIos ? _map(await fc.FlutterContacts.permissions.check(fc.PermissionType.read)) : ContactsAccess.denied;

  @override
  Future<ContactsAccess> request() async =>
      _isIos ? _map(await fc.FlutterContacts.permissions.request(fc.PermissionType.read)) : ContactsAccess.denied;

  ContactsAccess _map(fc.PermissionStatus status) => switch (status) {
        fc.PermissionStatus.granted => ContactsAccess.full,
        fc.PermissionStatus.limited => ContactsAccess.limited,
        fc.PermissionStatus.notDetermined => ContactsAccess.notDetermined,
        _ => ContactsAccess.denied,
      };

  @override
  Future<List<DeviceContact>> readAll() async {
    final contacts = await fc.FlutterContacts.getAll(
      properties: {fc.ContactProperty.name, fc.ContactProperty.phone},
    );
    return contacts
        .where((c) => c.phones.isNotEmpty)
        .map((c) => DeviceContact(
              id: c.id ?? c.displayName ?? '',
              name: (c.displayName ?? '').trim(),
              phones: c.phones
                  .where((p) => p.number.trim().isNotEmpty)
                  .map((p) => DeviceContactPhone(
                        number: p.number.trim(),
                        label: phoneLabel(p.label.label, p.label.customLabel),
                        isMobile: const {
                          fc.PhoneLabel.mobile,
                          fc.PhoneLabel.iPhone,
                          fc.PhoneLabel.workMobile,
                        }.contains(p.label.label),
                      ))
                  .toList(),
            ))
        .where((c) => c.phones.isNotEmpty && c.name.isNotEmpty)
        .toList()
      ..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  }

  @override
  Future<List<DeviceContact>> pickMultipleNative() async {
    final picked = await picker.FlutterNativeContactPicker().selectContacts() ?? [];
    return picked
        .where((c) => (c.phoneNumbers ?? []).isNotEmpty)
        .map((c) {
          final name = (c.fullName ?? '').trim();
          final numbers = c.phoneNumbers!.map((n) => n.trim()).where((n) => n.isNotEmpty).toList();
          return DeviceContact(
            id: 'natif:$name:${numbers.first}',
            name: name,
            // Le sélecteur natif ne donne pas les libellés : le premier
            // numéro est proposé, les autres restent au choix.
            phones: [
              for (var i = 0; i < numbers.length; i++)
                DeviceContactPhone(number: numbers[i], label: 'Numéro ${i + 1}', isMobile: i == 0),
            ],
          );
        })
        .where((c) => c.phones.isNotEmpty && c.name.isNotEmpty)
        .toList();
  }

  @override
  Future<DeviceContact?> pickOneNative() async {
    final result = await _androidPicker.invokeMapMethod<String, dynamic>('pickPhone');
    if (result == null) return null;
    final number = (result['number'] as String? ?? '').trim();
    if (number.isEmpty) return null;
    final name = (result['name'] as String? ?? '').trim();
    return DeviceContact(
      id: 'natif:$name:$number',
      name: name.isEmpty ? number : name,
      phones: [
        DeviceContactPhone(
          number: number,
          label: result['label'] as String? ?? 'Numéro',
          isMobile: true,
        ),
      ],
    );
  }

  @override
  Future<void> openSettings() => fc.FlutterContacts.permissions.openSettings();
}

/// Libellé français d'un numéro (« Mobile », « Domicile »…).
String phoneLabel(fc.PhoneLabel label, String? custom) => switch (label) {
      fc.PhoneLabel.mobile => 'Mobile',
      fc.PhoneLabel.iPhone => 'iPhone',
      fc.PhoneLabel.workMobile => 'Mobile pro',
      fc.PhoneLabel.home => 'Domicile',
      fc.PhoneLabel.work => 'Travail',
      fc.PhoneLabel.main => 'Principal',
      fc.PhoneLabel.companyMain => 'Standard',
      fc.PhoneLabel.custom => (custom?.trim().isNotEmpty ?? false) ? custom!.trim() : 'Autre',
      _ => 'Autre',
    };
