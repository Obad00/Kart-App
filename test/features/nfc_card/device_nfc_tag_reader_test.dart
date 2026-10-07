// Sur iPhone, tant que l'app ne déclare pas NFCReaderUsageDescription et
// l'entitlement de lecture, ouvrir une session NFC peut la faire planter.
// DeviceNfcTagReader ne doit donc JAMAIS toucher à nfc_manager dans ce cas :
// ni pour tester la disponibilité, ni pour ouvrir ou fermer une session.
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

  test('la lecture NFC est désactivée sur iOS dans cette version', () {
    // À passer à true avec Info.plist et l'entitlement (commit iOS).
    expect(kIosNfcReadingEnabled, isFalse);
  });

  group('iPhone sans les droits de lecture', () {
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);

    test('la disponibilité répond « indisponible » sans interroger le téléphone',
        () async {
      final manager = _SpyManager(NfcAvailability.enabled);
      final reader = DeviceNfcTagReader(manager: manager);

      expect(await reader.availability(), NfcReaderAvailability.unsupported);
      expect(manager.calls, 0);

      debugDefaultTargetPlatformOverride = null;
    });

    test('aucune session n\'est ouverte, même si on appelle start()', () async {
      final manager = _SpyManager(NfcAvailability.enabled);
      final reader = DeviceNfcTagReader(manager: manager);
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

    test('avec le réglage par défaut de l\'app, rien n\'est appelé non plus',
        () async {
      // Sans faux gestionnaire : si le lecteur touchait au vrai
      // nfc_manager, l'appel échouerait ici (pas de téléphone) — il doit
      // répondre sans même essayer.
      const reader = DeviceNfcTagReader();

      expect(await reader.availability(), NfcReaderAvailability.unsupported);

      debugDefaultTargetPlatformOverride = null;
    });
  });

  group('iPhone une fois les droits déclarés', () {
    test('la disponibilité et la session passent par nfc_manager', () async {
      debugDefaultTargetPlatformOverride = TargetPlatform.iOS;
      final manager = _SpyManager(NfcAvailability.enabled);
      final reader =
          DeviceNfcTagReader(manager: manager, iosReadingEnabled: true);

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
