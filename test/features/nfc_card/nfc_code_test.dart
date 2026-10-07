// Code d'une carte NFC : saisi à la main, ou lu dans le lien gravé sur la
// puce (https://kart.business/t/{code}).
import 'package:flutter_test/flutter_test.dart';
import 'package:kart_app/features/digital_card/providers/card_provider.dart';
import 'package:kart_app/features/nfc_card/models/nfc_card_status.dart';
import 'package:kart_app/features/nfc_card/utils/nfc_code.dart';

void main() {
  group('extractNfcCode', () {
    test('accepte un code saisi, en minuscules ou avec des espaces', () {
      expect(extractNfcCode('ABCD2345'), 'ABCD2345');
      expect(extractNfcCode(' abcd 2345 '), 'ABCD2345');
      expect(extractNfcCode('abcd-2345'), 'ABCD2345');
    });

    test('lit le code dans le lien gravé sur la puce', () {
      expect(extractNfcCode('https://kart.business/t/ZWLC8FDH'), 'ZWLC8FDH');
      expect(extractNfcCode('https://kart.meblo.cloud/t/zwlc8fdh?x=1'),
          'ZWLC8FDH');
    });

    test('refuse ce qui n\'est pas une carte KART', () {
      expect(extractNfcCode(null), isNull);
      expect(extractNfcCode('   '), isNull);
      expect(extractNfcCode('https://exemple.com/autre'), isNull);
      expect(extractNfcCode('https://kart.business/card/awa-diop'), isNull);
      expect(extractNfcCode('abcd!2345'), isNull);
    });

    test('un code complet fait 8 caractères', () {
      expect(isCompleteNfcCode('ABCD2345'), isTrue);
      expect(isCompleteNfcCode('ABC'), isFalse);
      expect(isCompleteNfcCode('https://kart.business/t/ZWLC8FDH'), isTrue);
    });
  });

  group('NfcCardStatus.fromJson', () {
    test('lit une réponse complète de GET /me/nfc', () {
      final status = NfcCardStatus.fromJson({
        'state': 'active',
        'has_card': true,
        'support_whatsapp': '221770000000',
        'tag': {
          'id': 7,
          'code': 'ABCD2345',
          'status': 'active',
          'tap_count': 12,
          'last_tapped_at': '2026-10-06T18:42:00.000000Z',
          'can_reactivate': false,
        },
        'order': null,
        'cancelled_order': null,
        'tags': [],
      });

      expect(status.state, NfcCardState.active);
      expect(status.supportWhatsapp, '221770000000');
      expect(status.tag!.tapCount, 12);
      expect(status.tag!.lastTappedAt, isNotNull);
    });

    test('tolère un état inconnu, un numéro vide et des champs absents', () {
      final status = NfcCardStatus.fromJson({
        'state': 'etat_futur',
        'support_whatsapp': '',
      });

      expect(status.state, NfcCardState.none);
      expect(status.supportWhatsapp, isNull);
      expect(status.hasCard, isTrue);
      expect(status.tag, isNull);
    });

    test('lit le statut d\'une commande', () {
      final status = NfcCardStatus.fromJson({
        'state': 'ordered',
        'order': {
          'id': 1,
          'status': 'in_production',
          'delivery_phone': '+221770000000',
          'delivery_address': 'Dakar',
          'created_at': '2026-10-05T10:00:00.000000Z',
        },
      });

      expect(status.order!.status, NfcOrderStatus.inProduction);
      expect(status.order!.deliveryAddress, 'Dakar');
    });
  });

  group('statistiques', () {
    test('les taps NFC sont optionnels (serveur plus ancien)', () {
      final old = CardWeeklyStats.fromJson({
        'scans_this_week': 3,
        'scans_previous_week': 1,
        'new_contacts_this_week': 0,
        'new_contacts_previous_week': 0,
      });
      expect(old, isNotNull);
      expect(old!.nfcTapsThisWeek, isNull);
      expect(old.nfcActive, isFalse);
      expect(old.showNfcTaps, isFalse);

      final recent = CardWeeklyStats.fromJson({
        'scans_this_week': 3,
        'scans_previous_week': 1,
        'nfc_taps_this_week': 2,
        'nfc_taps_previous_week': 0,
        'new_contacts_this_week': 0,
        'new_contacts_previous_week': 0,
      });
      expect(recent!.nfcTapsThisWeek, 2);
      expect(recent.showNfcTaps, isTrue);
    });

    test('la tuile NFC : carte active même à 0 tap, ou taps récents', () {
      CardWeeklyStats stats({
        bool active = false,
        int thisWeek = 0,
        int previous = 0,
      }) =>
          CardWeeklyStats.fromJson({
            'scans_this_week': 0,
            'scans_previous_week': 0,
            'new_contacts_this_week': 0,
            'new_contacts_previous_week': 0,
            'nfc_taps_this_week': thisWeek,
            'nfc_taps_previous_week': previous,
            'nfc_active': active,
          })!;

      // Pas de carte NFC, aucun tap : masquée.
      expect(stats().showNfcTaps, isFalse);
      // Carte active, encore jamais tapée : affichée à 0.
      expect(stats(active: true).showNfcTaps, isTrue);
      // Carte désactivée depuis, mais des taps récents : affichée.
      expect(stats(thisWeek: 3).showNfcTaps, isTrue);
      expect(stats(previous: 1).showNfcTaps, isTrue);
    });
  });
}
