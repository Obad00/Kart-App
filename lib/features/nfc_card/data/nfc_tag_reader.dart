import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:nfc_manager/ndef_record.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_android.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

/// Ce que le téléphone peut faire en NFC.
enum NfcReaderAvailability {
  /// Lecture possible.
  enabled,

  /// Le téléphone a le NFC, mais il est coupé dans les réglages.
  disabled,

  /// Pas de NFC (ou lecture indisponible dans cette version de l'app).
  unsupported,
}

/// Lecture d'une carte NFC KART : on n'en attend que le lien gravé sur la
/// puce (https://kart.business/t/{code}). Interface séparée du paquet
/// nfc_manager pour que l'écran se teste sans téléphone.
abstract class NfcTagReader {
  const NfcTagReader();

  Future<NfcReaderAvailability> availability();

  /// Écoute jusqu'à [stop]. [onRead] reçoit le lien lu sur la puce, ou
  /// null si la puce ne contient pas de lien. [onError] est appelé si la
  /// lecture s'arrête d'elle-même (session refusée ou fermée par iOS).
  Future<void> start({
    required void Function(String? link) onRead,
    required void Function() onError,
  });

  Future<void> stop({String? message});
}

/// L'app iOS a-t-elle le droit de lire le NFC ?
///
/// true seulement si la version iOS déclare NFCReaderUsageDescription
/// (Info.plist) ET l'entitlement com.apple.developer.nfc.readersession.formats
/// (Runner.entitlements) : sans eux, ouvrir une session de lecture peut
/// faire PLANTER l'app au lieu d'échouer proprement. Et on ne peut pas s'en
/// remettre au téléphone pour le savoir : sur iOS, la disponibilité
/// renvoyée par nfc_manager ne teste que le matériel
/// (NFCTagReaderSession.readingAvailable), pas ces droits.
///
/// Les trois vont ensemble : ne jamais retirer l'un sans repasser ce
/// réglage à false (un test le vérifie).
const bool kIosNfcReadingEnabled = true;

/// Lecture réelle, via nfc_manager.
class DeviceNfcTagReader extends NfcTagReader {
  /// [manager] et [iosReadingEnabled] ne servent qu'aux tests.
  const DeviceNfcTagReader({
    NfcManager? manager,
    bool iosReadingEnabled = kIosNfcReadingEnabled,
  })  : _injected = manager,
        _iosReadingEnabled = iosReadingEnabled;

  final NfcManager? _injected;
  final bool _iosReadingEnabled;

  NfcManager get _manager => _injected ?? NfcManager.instance;

  /// Sur iPhone sans les droits de lecture, on ne touche JAMAIS à
  /// nfc_manager : ni disponibilité, ni session. Tout passe par la saisie
  /// du code.
  bool get _blockedOnIos =>
      defaultTargetPlatform == TargetPlatform.iOS && !_iosReadingEnabled;

  @override
  Future<NfcReaderAvailability> availability() async {
    if (_blockedOnIos) return NfcReaderAvailability.unsupported;

    try {
      return switch (await _manager.checkAvailability()) {
        NfcAvailability.enabled => NfcReaderAvailability.enabled,
        NfcAvailability.disabled => NfcReaderAvailability.disabled,
        NfcAvailability.unsupported => NfcReaderAvailability.unsupported,
      };
    } catch (_) {
      // Plateforme sans NFC (web, ordinateur) ou extension absente : la
      // saisie du code prend le relais.
      return NfcReaderAvailability.unsupported;
    }
  }

  @override
  Future<void> start({
    required void Function(String? link) onRead,
    required void Function() onError,
  }) async {
    // Garde-fou : même si un appelant oubliait de vérifier availability(),
    // aucune session n'est ouverte sur un iPhone sans les droits.
    if (_blockedOnIos) {
      onError();
      return;
    }

    try {
      await _manager.startSession(
        // Les cartes KART sont des NTAG (ISO 14443).
        pollingOptions: {NfcPollingOption.iso14443, NfcPollingOption.iso15693},
        alertMessageIos: 'Approchez votre carte NFC du haut du téléphone.',
        // La session reste ouverte : une carte qui n'est pas la bonne ne
        // doit pas obliger à tout recommencer.
        invalidateAfterFirstReadIos: false,
        onSessionErrorIos: (_) => onError(),
        onDiscovered: (tag) async {
          try {
            onRead(_linkOf(await _readMessage(tag)));
          } catch (_) {
            onRead(null);
          }
        },
      );
    } catch (_) {
      onError();
    }
  }

  @override
  Future<void> stop({String? message}) async {
    if (_blockedOnIos) return;

    try {
      await _manager.stopSession(alertMessageIos: message);
    } catch (_) {
      // Session déjà fermée : rien à faire.
    }
  }

  Future<NdefMessage?> _readMessage(NfcTag tag) async {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      final ndef = NdefIos.from(tag);
      return ndef?.cachedNdefMessage ?? await ndef?.readNdef();
    }
    final ndef = NdefAndroid.from(tag);
    return ndef?.cachedNdefMessage ?? await ndef?.getNdefMessage();
  }

  String? _linkOf(NdefMessage? message) {
    for (final record in message?.records ?? const <NdefRecord>[]) {
      final link = decodeNdefLink(record);
      if (link != null) return link;
    }
    return null;
  }
}

/// Préfixes d'un enregistrement NDEF « URI » : le premier octet du contenu
/// abrège le début du lien (norme NFC Forum, URI Record Type Definition).
const _uriPrefixes = <int, String>{
  0x00: '',
  0x01: 'http://www.',
  0x02: 'https://www.',
  0x03: 'http://',
  0x04: 'https://',
};

/// Lien contenu dans un enregistrement NDEF, ou null si ce n'en est pas un.
/// Gère l'enregistrement « URI » (ce qu'écrivent les applis de gravure) et
/// l'URI absolue.
String? decodeNdefLink(NdefRecord record) {
  try {
    if (record.typeNameFormat == TypeNameFormat.absoluteUri) {
      return utf8.decode(record.type);
    }

    final isUriRecord = record.typeNameFormat == TypeNameFormat.wellKnown &&
        record.type.length == 1 &&
        record.type.first == 0x55; // « U »
    if (!isUriRecord || record.payload.isEmpty) return null;

    final prefix = _uriPrefixes[record.payload.first];
    if (prefix == null) return null;
    return prefix + utf8.decode(record.payload.sublist(1));
  } catch (_) {
    return null;
  }
}
