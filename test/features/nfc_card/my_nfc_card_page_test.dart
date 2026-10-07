// Écran « Ma carte NFC » : un rendu par état renvoyé par GET /me/nfc, le
// formulaire de commande (sans prix ni quantité), l'activation et la
// réactivation en tapant la carte ou en saisissant son code, le rappel du
// QR code et le support WhatsApp configurable.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/core/theme/app_theme.dart';
import 'package:kart_app/features/nfc_card/data/nfc_card_service.dart';
import 'package:kart_app/features/nfc_card/data/nfc_tag_reader.dart';
import 'package:kart_app/features/nfc_card/models/nfc_card_status.dart';
import 'package:kart_app/features/nfc_card/ui/my_nfc_card_page.dart';

const _whatsapp = '221770000000';

/// Faux serveur : renvoie l'état donné, enregistre les appels reçus.
class _FakeService extends NfcCardService {
  _FakeService(this.status, {this.failWith});

  NfcCardStatus status;

  /// Si renseigné, les actions échouent avec ce message.
  final String? failWith;

  final List<String> calls = [];
  Map<String, String?>? lastOrder;
  String? lastCode;
  bool fetchFails = false;

  @override
  Future<NfcCardStatus> fetch() async {
    calls.add('fetch');
    if (fetchFails) throw Exception('réseau');
    return status;
  }

  @override
  Future<NfcCardStatus> order({
    required String phone,
    required String address,
    String? notes,
  }) async {
    calls.add('order');
    lastOrder = {'phone': phone, 'address': address, 'notes': notes};
    if (failWith != null) throw Exception(failWith);
    return status = _status(
      NfcCardState.ordered,
      order: NfcOrderInfo(
        id: 1,
        status: NfcOrderStatus.pending,
        deliveryPhone: phone,
        deliveryAddress: address,
        createdAt: DateTime(2026, 10, 5),
      ),
    );
  }

  @override
  Future<NfcCardStatus> activate(String code) async {
    calls.add('activate');
    lastCode = code;
    if (failWith != null) throw Exception(failWith);
    return status = _status(
      NfcCardState.active,
      tag: NfcTagInfo(id: 7, code: code, tapCount: 0),
    );
  }

  @override
  Future<NfcCardStatus> disable(int tagId) async {
    calls.add('disable:$tagId');
    return status = _status(
      NfcCardState.disabled,
      tag: NfcTagInfo(id: tagId, code: 'ABCD2345', canReactivate: true),
    );
  }
}

NfcCardStatus _status(
  NfcCardState state, {
  NfcTagInfo? tag,
  NfcOrderInfo? order,
  NfcOrderInfo? cancelledOrder,
  String? whatsapp = _whatsapp,
  bool hasCard = true,
}) =>
    NfcCardStatus(
      state: state,
      hasCard: hasCard,
      supportWhatsapp: whatsapp,
      tag: tag,
      order: order,
      cancelledOrder: cancelledOrder,
    );

/// Faux lecteur NFC : on choisit ce que le téléphone sait faire, puis on
/// « présente » une carte avec [tap].
class _FakeReader extends NfcTagReader {
  _FakeReader([this.state = NfcReaderAvailability.unsupported]);

  final NfcReaderAvailability state;

  /// true : la lecture est refusée dès le départ (iPhone sans l'entitlement).
  bool failOnStart = false;
  bool listening = false;

  /// Nombre de sessions de lecture demandées.
  int started = 0;
  void Function(String? link)? _onRead;

  @override
  Future<NfcReaderAvailability> availability() async => state;

  @override
  Future<void> start({
    required void Function(String? link) onRead,
    required void Function() onError,
  }) async {
    started++;
    if (failOnStart) {
      onError();
      return;
    }
    listening = true;
    _onRead = onRead;
  }

  @override
  Future<void> stop({String? message}) async => listening = false;

  /// Présente une carte dont la puce contient [link].
  void tap(String? link) => _onRead?.call(link);
}

class _Harness {
  int qrOpened = 0;
  final List<Uri> opened = [];
}

Future<_Harness> _pump(
  WidgetTester tester,
  _FakeService service, {
  bool dark = true,
  String? phone = '+221771112233',
  // Par défaut, un téléphone sans NFC : tout passe par la saisie du code.
  NfcTagReader? reader,
}) async {
  final harness = _Harness();
  // Écran de téléphone : assez haut pour voir tout l'état sans défiler.
  tester.view.physicalSize = const Size(390, 1400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  await tester.pumpWidget(
    MaterialApp(
      theme: dark ? AppTheme.dark() : AppTheme.light(),
      home: MyNfcCardPage(
        service: service,
        reader: reader ?? _FakeReader(),
        initialPhone: phone,
        onShowQr: (_) => harness.qrOpened++,
        openUrl: (uri) async => harness.opened.add(uri),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return harness;
}

void main() {
  group('none', () {
    testWidgets('présente la carte, sans prix, avec commande et QR',
        (tester) async {
      final service = _FakeService(_status(NfcCardState.none));
      final harness = await _pump(tester, service);

      expect(find.text("Vous n'avez pas encore de carte NFC KART"),
          findsOneWidget);
      expect(find.text('Un tap suffit'), findsOneWidget);
      expect(find.text("Pas besoin de l'application pour vous lire"),
          findsOneWidget);
      expect(
        find.text('Toujours à jour : vos changements apparaissent sans '
            'changer de carte'),
        findsOneWidget,
      );
      expect(find.textContaining('valable à vie'), findsNothing);
      expect(find.text('Commander ma carte'), findsOneWidget);
      expect(find.text("J'ai déjà une carte"), findsOneWidget);
      // Aucun prix nulle part.
      expect(find.textContaining('FCFA'), findsNothing);
      expect(find.textContaining('Prix'), findsNothing);

      // Le QR reste accessible, quel que soit l'état NFC.
      expect(
        find.textContaining('Vous pouvez toujours partager votre carte'),
        findsOneWidget,
      );
      await tester.tap(find.text('Afficher mon QR code'));
      expect(harness.qrOpened, 1);
    });

    testWidgets('signale une dernière commande annulée', (tester) async {
      final service = _FakeService(_status(
        NfcCardState.none,
        cancelledOrder: const NfcOrderInfo(
          id: 3,
          status: NfcOrderStatus.cancelled,
        ),
      ));
      await _pump(tester, service);

      expect(find.text('Votre dernière commande a été annulée.'),
          findsOneWidget);
    });

    testWidgets('sans carte digitale, on ne peut pas commander',
        (tester) async {
      await _pump(
        tester,
        _FakeService(_status(NfcCardState.none, hasCard: false)),
      );

      expect(find.text('Commander ma carte'), findsNothing);
      expect(find.textContaining("Créez d'abord votre carte digitale"),
          findsOneWidget);
    });

    testWidgets('commande : téléphone et adresse, sans quantité ni prix',
        (tester) async {
      final service = _FakeService(_status(NfcCardState.none));
      final harness = await _pump(tester, service);

      await tester.tap(find.text('Commander ma carte'));
      await tester.pumpAndSettle();

      // Téléphone du compte prérempli ; pas de champ quantité ni de prix.
      expect(find.widgetWithText(TextFormField, '+221771112233'),
          findsOneWidget);
      expect(find.textContaining('Quantité'), findsNothing);
      expect(find.textContaining('FCFA'), findsNothing);

      // Adresse obligatoire.
      await tester.tap(find.text('Envoyer ma commande'));
      await tester.pumpAndSettle();
      expect(find.text("Indiquez l'adresse de livraison."), findsOneWidget);
      expect(service.calls, isNot(contains('order')));

      // Plusieurs cartes : on passe par le support.
      await tester.tap(find.text('Besoin de plusieurs cartes ? Contactez-nous'));
      expect(harness.opened.single.toString(),
          startsWith('https://wa.me/$_whatsapp'));

      await tester.enterText(
        find.widgetWithText(TextFormField, 'Adresse de livraison'),
        'Sacré-Cœur 3, Dakar',
      );
      await tester.tap(find.text('Envoyer ma commande'));
      await tester.pumpAndSettle();

      expect(service.lastOrder, {
        'phone': '+221771112233',
        'address': 'Sacré-Cœur 3, Dakar',
        'notes': '',
      });
      // Message de confirmation, puis l'écran passe à la commande en cours.
      expect(find.text('Commande reçue, nous vous contacterons.'),
          findsOneWidget);
      expect(find.text('Votre commande est en préparation'), findsOneWidget);
    });

    testWidgets('« J\'ai déjà une carte » active avec le code saisi',
        (tester) async {
      final service = _FakeService(_status(NfcCardState.none));
      await _pump(tester, service);

      await tester.tap(find.text("J'ai déjà une carte"));
      await tester.pumpAndSettle();

      // Code incomplet : refusé avant tout appel.
      await tester.enterText(find.byType(TextField), 'abc');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Activer'));
      await tester.pumpAndSettle();
      expect(find.text('Le code fait 8 caractères.'), findsOneWidget);
      expect(service.calls, isNot(contains('activate')));

      // Saisie tolérante : minuscules et espace.
      await tester.enterText(find.byType(TextField), 'abcd 2345');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Activer'));
      await tester.pumpAndSettle();

      expect(service.lastCode, 'ABCD2345');
      expect(find.text('Active'), findsOneWidget);
    });
  });

  group('ordered', () {
    testWidgets('affiche la frise et la livraison', (tester) async {
      await _pump(
        tester,
        _FakeService(_status(
          NfcCardState.ordered,
          order: NfcOrderInfo(
            id: 1,
            status: NfcOrderStatus.inProduction,
            deliveryPhone: '+221770000000',
            deliveryAddress: 'Sacré-Cœur 3, Dakar',
            createdAt: DateTime(2026, 10, 5),
          ),
        )),
      );

      expect(find.text('Votre commande est en préparation'), findsOneWidget);
      for (final step in ['Reçue', 'En fabrication', 'Prête', 'Livrée']) {
        expect(find.text(step), findsOneWidget);
      }
      expect(find.text('5 oct.'), findsOneWidget);
      expect(find.text('Sacré-Cœur 3, Dakar'), findsOneWidget);
      // L'étape en cours est en gras, les suivantes non.
      expect(
        tester.widget<Text>(find.text('En fabrication')).style!.fontWeight,
        FontWeight.w700,
      );
      expect(
        tester.widget<Text>(find.text('Prête')).style!.fontWeight,
        FontWeight.w500,
      );
      // Aucune action de commande ni de prix.
      expect(find.text('Commander ma carte'), findsNothing);
      expect(find.textContaining('FCFA'), findsNothing);
    });
  });

  group('ready', () {
    testWidgets('propose d\'activer avec le code, ou plus tard',
        (tester) async {
      final service = _FakeService(_status(
        NfcCardState.ready,
        tag: const NfcTagInfo(id: 7),
      ));
      await _pump(tester, service);

      expect(find.text('Votre carte NFC est arrivée !'), findsOneWidget);
      expect(find.text('Plus tard'), findsOneWidget);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Activer'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'ABCD2345');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Activer').last);
      await tester.pumpAndSettle();

      expect(service.lastCode, 'ABCD2345');
      expect(find.text('Votre carte NFC est activée.'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('affiche l\'erreur du serveur sous le champ', (tester) async {
      final service = _FakeService(
        _status(NfcCardState.ready, tag: const NfcTagInfo(id: 7)),
        failWith: 'refus',
      );
      await _pump(tester, service);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Activer'));
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'WXYZ6789');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Activer').last);
      await tester.pumpAndSettle();

      // La feuille reste ouverte avec un message, l'état ne change pas.
      expect(find.text("La carte n'a pas pu être activée. Réessayez."),
          findsOneWidget);
      expect(find.text('Votre carte NFC est arrivée !'), findsOneWidget);
    });
  });

  group('lecture de la puce', () {
    NfcCardStatus ready() =>
        _status(NfcCardState.ready, tag: const NfcTagInfo(id: 7));

    testWidgets('taper la carte l\'active avec le code lu dans son lien',
        (tester) async {
      final service = _FakeService(ready());
      final reader = _FakeReader(NfcReaderAvailability.enabled);
      await _pump(tester, service, reader: reader);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Activer'));
      await tester.pumpAndSettle();
      expect(find.text('Approchez votre carte du téléphone'), findsOneWidget);
      expect(reader.listening, isTrue);

      reader.tap('https://kart.business/t/abcd2345');
      await tester.pumpAndSettle();

      expect(service.lastCode, 'ABCD2345');
      expect(reader.listening, isFalse, reason: 'lecture arrêtée');
      expect(find.text('Votre carte NFC est activée.'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('une puce qui n\'est pas une carte KART est refusée sans appel',
        (tester) async {
      final service = _FakeService(ready());
      final reader = _FakeReader(NfcReaderAvailability.enabled);
      await _pump(tester, service, reader: reader);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Activer'));
      await tester.pumpAndSettle();

      reader.tap('https://exemple.com/autre-chose');
      await tester.pumpAndSettle();
      expect(find.text("Cette carte n'est pas une carte NFC KART."),
          findsOneWidget);
      reader.tap(null); // puce vide
      await tester.pumpAndSettle();
      expect(service.calls, isNot(contains('activate')));

      // La saisie du code reste proposée dans la même feuille.
      await tester.tap(find.text('Saisir le code'));
      await tester.pumpAndSettle();
      expect(reader.listening, isFalse);
      await tester.enterText(find.byType(TextField), 'ABCD2345');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Activer').last);
      await tester.pumpAndSettle();

      expect(service.lastCode, 'ABCD2345');
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('le refus du serveur s\'affiche et la lecture continue',
        (tester) async {
      final service = _FakeService(ready(), failWith: 'refus');
      final reader = _FakeReader(NfcReaderAvailability.enabled);
      await _pump(tester, service, reader: reader);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Activer'));
      await tester.pumpAndSettle();
      reader.tap('https://kart.business/t/WXYZ6789');
      await tester.pumpAndSettle();

      expect(find.text("La carte n'a pas pu être activée. Réessayez."),
          findsOneWidget);
      expect(find.text('Approchez votre carte du téléphone'), findsOneWidget);
      expect(reader.listening, isTrue);
    });

    testWidgets('sans NFC, on passe directement à la saisie du code',
        (tester) async {
      final service = _FakeService(ready());
      final reader = _FakeReader(NfcReaderAvailability.unsupported);
      await _pump(tester, service, reader: reader);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Activer'));
      await tester.pumpAndSettle();

      // Aucune session de lecture n'est ouverte : c'est aussi le cas d'un
      // iPhone tant que l'app n'a pas les droits de lecture NFC.
      expect(reader.started, 0);
      expect(find.text('Approchez votre carte du téléphone'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Le code est imprimé sur votre carte NFC.'),
          findsOneWidget);
    });

    testWidgets('NFC coupé : saisie du code, avec une explication',
        (tester) async {
      await _pump(tester, _FakeService(ready()),
          reader: _FakeReader(NfcReaderAvailability.disabled));

      await tester.tap(find.widgetWithText(ElevatedButton, 'Activer'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.textContaining('Le NFC est désactivé sur ce téléphone'),
          findsOneWidget);
    });

    testWidgets('lecture refusée par le téléphone : repli sur la saisie',
        (tester) async {
      // Cas d'un iPhone dont l'app n'a pas (encore) le droit de lire le NFC.
      final reader = _FakeReader(NfcReaderAvailability.enabled)
        ..failOnStart = true;
      await _pump(tester, _FakeService(ready()), reader: reader);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Activer'));
      await tester.pumpAndSettle();

      expect(find.text('Approchez votre carte du téléphone'), findsNothing);
      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('réactiver en tapant la carte retrouvée', (tester) async {
      final service = _FakeService(_status(
        NfcCardState.disabled,
        tag: const NfcTagInfo(id: 7, code: 'ABCD2345', canReactivate: true),
      ));
      final reader = _FakeReader(NfcReaderAvailability.enabled);
      await _pump(tester, service, reader: reader);

      await tester.tap(find.widgetWithText(ElevatedButton, 'Réactiver'));
      await tester.pumpAndSettle();
      expect(find.text('Réactiver ma carte'), findsOneWidget);
      expect(service.calls, isNot(contains('activate')));

      reader.tap('https://kart.business/t/ABCD2345');
      await tester.pumpAndSettle();

      expect(service.lastCode, 'ABCD2345');
      expect(find.text('Votre carte NFC est réactivée.'), findsOneWidget);
    });
  });

  group('active', () {
    testWidgets('affiche les taps et désactive après confirmation',
        (tester) async {
      final service = _FakeService(_status(
        NfcCardState.active,
        tag: NfcTagInfo(
          id: 7,
          code: 'ZWLC8FDH',
          tapCount: 128,
          lastTappedAt: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ));
      await _pump(tester, service);

      expect(find.text('Active'), findsOneWidget);
      expect(find.text('128'), findsOneWidget);
      expect(find.text('taps'), findsOneWidget);
      expect(find.text('il y a 2 heures'), findsOneWidget);
      expect(find.text('Code : ZWLC8FDH'), findsOneWidget);

      // Annuler la confirmation : rien ne se passe.
      await tester.tap(find.text('Désactiver (carte perdue)'));
      await tester.pumpAndSettle();
      expect(find.text('Désactiver la carte ?'), findsOneWidget);
      await tester.tap(find.text('Annuler'));
      await tester.pumpAndSettle();
      expect(service.calls, isNot(contains('disable:7')));

      // Confirmer : la carte est désactivée.
      await tester.tap(find.text('Désactiver (carte perdue)'));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Désactiver'));
      await tester.pumpAndSettle();

      expect(service.calls, contains('disable:7'));
      expect(find.text('Carte désactivée'), findsOneWidget);
    });
  });

  group('disabled', () {
    testWidgets('réactiver exige le code de la carte', (tester) async {
      final service = _FakeService(_status(
        NfcCardState.disabled,
        tag: const NfcTagInfo(id: 7, code: 'ABCD2345', canReactivate: true),
      ));
      final harness = await _pump(tester, service);

      expect(find.text('Carte désactivée'), findsOneWidget);
      expect(find.text('Commander une nouvelle carte'), findsOneWidget);

      // Le QR reste proposé.
      await tester.tap(find.text('Afficher mon QR code'));
      expect(harness.qrOpened, 1);

      // « Réactiver » ne réactive pas tout seul : il demande le code.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Réactiver'));
      await tester.pumpAndSettle();
      expect(service.calls, isNot(contains('activate')));
      expect(find.text('Réactiver ma carte'), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'ABCD2345');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Réactiver').last);
      await tester.pumpAndSettle();

      expect(service.lastCode, 'ABCD2345');
      expect(find.text('Votre carte NFC est réactivée.'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
    });

    testWidgets('désactivée par KART : pas de bouton Réactiver',
        (tester) async {
      await _pump(
        tester,
        _FakeService(_status(
          NfcCardState.disabled,
          tag: const NfcTagInfo(id: 7, canReactivate: false),
        )),
      );

      expect(find.widgetWithText(ElevatedButton, 'Réactiver'), findsNothing);
      expect(find.textContaining('désactivée par KART'), findsOneWidget);
    });
  });

  group('support WhatsApp', () {
    testWidgets('ouvre wa.me sur le numéro reçu du serveur', (tester) async {
      final harness = await _pump(
        tester,
        _FakeService(_status(
          NfcCardState.active,
          tag: const NfcTagInfo(id: 7, code: 'ABCD2345'),
        )),
      );

      await tester.tap(find.text('Contacter le support'));
      await tester.pumpAndSettle();

      expect(harness.opened.single.host, 'wa.me');
      expect(harness.opened.single.path, '/$_whatsapp');
    });

    testWidgets('bouton masqué si aucun numéro n\'est configuré',
        (tester) async {
      await _pump(
        tester,
        _FakeService(_status(NfcCardState.none, whatsapp: null)),
      );

      expect(find.text('Contacter le support'), findsNothing);

      await tester.tap(find.text('Commander ma carte'));
      await tester.pumpAndSettle();
      expect(find.textContaining('Besoin de plusieurs cartes'), findsNothing);
    });
  });

  group('chargement', () {
    testWidgets('erreur réseau : message et « Réessayer »', (tester) async {
      final service = _FakeService(_status(NfcCardState.none))
        ..fetchFails = true;
      await _pump(tester, service);

      expect(find.text('Réessayer'), findsOneWidget);
      expect(find.text('Commander ma carte'), findsNothing);

      service.fetchFails = false;
      await tester.tap(find.text('Réessayer'));
      await tester.pumpAndSettle();

      expect(find.text('Commander ma carte'), findsOneWidget);
    });
  });

  testWidgets('les cinq états s\'affichent sans débordement, clair et sombre',
      (tester) async {
    final states = {
      NfcCardState.none: _status(NfcCardState.none),
      NfcCardState.ordered: _status(
        NfcCardState.ordered,
        order: const NfcOrderInfo(
          id: 1,
          status: NfcOrderStatus.pending,
          deliveryPhone: '+221770000000',
          deliveryAddress: 'Sacré-Cœur 3, Dakar',
        ),
      ),
      NfcCardState.ready:
          _status(NfcCardState.ready, tag: const NfcTagInfo(id: 7)),
      NfcCardState.active: _status(
        NfcCardState.active,
        tag: const NfcTagInfo(id: 7, code: 'ABCD2345', tapCount: 1),
      ),
      NfcCardState.disabled: _status(
        NfcCardState.disabled,
        tag: const NfcTagInfo(id: 7, canReactivate: true),
      ),
    };

    for (final dark in [true, false]) {
      for (final status in states.values) {
        await _pump(tester, _FakeService(status), dark: dark);
        expect(tester.takeException(), isNull,
            reason: '${status.state} (${dark ? 'sombre' : 'clair'})');
        expect(find.text('Ma carte NFC'), findsOneWidget);
      }
    }
  });
}
