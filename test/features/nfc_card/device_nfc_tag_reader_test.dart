// Sur iPhone, si l'app ne déclare pas NFCReaderUsageDescription et
// l'entitlement de lecture, ouvrir une session NFC peut la faire planter.
// DeviceNfcTagReader ne doit donc JAMAIS toucher à nfc_manager dans ce cas :
// ni pour tester la disponibilité, ni pour ouvrir ou fermer une session.
// Le réglage kIosNfcReadingEnabled n'est à true que si les deux
// déclarations sont présentes dans le projet iOS.
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/features/nfc_card/data/nfc_tag_reader.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:nfc_manager/nfc_manager_ios.dart';

/// Faux nfc_manager : compte les appels, ne parle à aucun téléphone.
class _SpyManager implements NfcManager {
  _SpyManager([this.result = NfcAvailability.enabled]);

  final NfcAvailability result;
  int availabilityChecks = 0;
  int sessionsStarted = 0;
  int sessionsStopped = 0;

  int get calls => availabilityChecks + sessionsStarted + sessionsStopped;

  @override
  Future<NfcAvailability> checkAvailability() async {
    availabilityChecks++;
    return result;
  }

  @override
  Future<bool> isAvailable() async => result == NfcAvailability.enabled;

  @override
  Future<void> startSession({
    required Set<NfcPollingOption> pollingOptions,
    required void Function(NfcTag tag) onDiscovered,
    String? alertMessageIos,
    bool invalidateAfterFirstReadIos = true,
    void Function(NfcReaderSessionErrorIos)? onSessionErrorIos,
    bool noPlatformSoundsAndroid = false,
  }) async {
    sessionsStarted++;
  }

  @override
  Future<void> stopSession({
    String? alertMessageIos,
    String? errorMessageIos,
  }) async {
    sessionsStopped++;
  }
}

void main() {
  tearDown(() => debugDefaultTargetPlatformOverride = null);

  test('la lecture NFC sur iOS va de pair avec Info.plist et l\'entitlement',
      () {
    // Ouvrir une session sans ces deux déclarations peut faire planter
    // l'app : le réglage ne doit être à true que si elles sont présentes.
    final plist = File('ios/Runner/Info.plist').readAsStringSync();
    final entitlements =
        File('ios/Runner/Runner.entitlements').readAsStringSync();

    final declared = plist.contains('<key>NFCReaderUsageDescription</key>') &&
        RegExp(
          r'<key>com\.apple\.developer\.nfc\.readersession\.formats</key>\s*'
          r'<array>\s*<string>TAG</string>\s*</array>',
        ).hasMatch(entitlements);

    expect(kIosNfcReadingEnabled, declared);
    expect(kIosNfcReadingEnabled, isTrue);
    expect(plist, contains("KART lit votre carte NFC pour l'activer"));
  });

  group('iPhone sans les droits de lecture', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);

    test('la disponibilité répond « indisponible » sans interroger le téléphone',
        () async {
      final manager = _SpyManager(NfcAvailability.enabled);
      final reader =
          DeviceNfcTagReader(manager: manager, iosReadingEnabled: false);

      expect(await reader.availability(), NfcReaderAvailability.unsupported);
      expect(manager.calls, 0);

      debugDefaultTargetPlatformOverride = null;
    });

    test('aucune session n\'est ouverte, même si on appelle start()', () async {
      final manager = _SpyManager(NfcAvailability.enabled);
      final reader =
          DeviceNfcTagReader(manager: manager, iosReadingEnabled: false);
      var errors = 0;
      var reads = 0;

      await reader.start(onRead: (_) => reads++, onError: () => errors++);
      await reader.stop();

      // L'appelant est prévenu (il bascule sur la saisie du code)...
      expect(errors, 1);
      expect(reads, 0);
      // ...et nfc_manager n'a jamais été appelé.
      expect(manager.sessionsStarted, 0);
      expect(manager.calls, 0);

      debugDefaultTargetPlatformOverride = null;
    });

    test('sans faux gestionnaire non plus, rien n\'est appelé', () async {
      // Si le lecteur touchait au vrai nfc_manager, l'appel échouerait ici
      // (pas de téléphone) — il doit répondre sans même essayer.
      const reader = DeviceNfcTagReader(iosReadingEnabled: false);

      expect(await reader.availability(), NfcReaderAvailability.unsupported);

      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('iPhone une fois les droits déclarés', () {
    test('un iPhone sans puce NFC reste sur la saisie du code', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final manager = _SpyManager(NfcAvailability.unsupported);

      expect(
        await DeviceNfcTagReader(manager: manager).availability(),
        NfcReaderAvailability.unsupported,
      );
      expect(manager.sessionsStarted, 0);

      debugDefaultTargetPlatformOverride = null;
    });

    test('la disponibilité et la session passent par nfc_manager', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final manager = _SpyManager(NfcAvailability.enabled);
      // Réglage par défaut de l'app (kIosNfcReadingEnabled).
      final reader = DeviceNfcTagReader(manager: manager);

      expect(await reader.availability(), NfcReaderAvailability.enabled);
      await reader.start(onRead: (_) {}, onError: () {});
      await reader.stop();

      expect(manager.availabilityChecks, 1);
      expect(manager.sessionsStarted, 1);
      expect(manager.sessionsStopped, 1);

      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('Android', () {
    test('lit la disponibilité réelle du téléphone', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;

      for (final (result, expected) in [
        (NfcAvailability.enabled, NfcReaderAvailability.enabled),
        (NfcAvailability.disabled, NfcReaderAvailability.disabled),
        (NfcAvailability.unsupported, NfcReaderAvailability.unsupported),
      ]) {
        final manager = _SpyManager(result);
        expect(
          await DeviceNfcTagReader(manager: manager).availability(),
          expected,
        );
        expect(manager.sessionsStarted, 0, reason: 'tester ≠ ouvrir');
      }

      debugDefaultTargetPlatformOverride = null;
    });

    test('ouvre une session quand on démarre la lecture', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.android;
      final manager = _SpyManager();

      await DeviceNfcTagReader(manager: manager)
          .start(onRead: (_) {}, onError: () {});

      expect(manager.sessionsStarted, 1);

      debugDefaultTargetPlatformOverride = null;
    });
  });
}
