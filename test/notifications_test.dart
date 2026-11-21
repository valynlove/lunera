import 'package:flutter_test/flutter_test.dart';
import 'package:lunera/l10n.dart';
import 'package:lunera/models.dart';
import 'package:lunera/notifications.dart';

void main() {
  group('Lunera Notifications & Preferences Tests', () {
    test('Prefs widgetHide, locale, and discreetNotify configuration', () {
      const prefs = Prefs();
      expect(prefs.widgetHide, isTrue);
      expect(prefs.locale, equals('en'));
      expect(prefs.discreetNotify, equals('wellness'));
      final updated = prefs.copy(widgetHide: false, locale: 'id', discreetNotify: 'off');
      expect(updated.widgetHide, isFalse);
      expect(updated.locale, equals('id'));
      expect(updated.discreetNotify, equals('off'));
      expect(updated.toMap()['widgetHide'], isFalse);
      expect(updated.toMap()['locale'], equals('id'));
      expect(updated.toMap()['discreetNotify'], equals('off'));
      expect(updated.toMap().containsKey('geminiApiKey'), isFalse);
      expect(updated.toMap().containsKey('asteriaMode'), isFalse);
    });

    test('Discreet notifications mask medication names across dose, low supply, and expiry alerts', () {
      final therapy = Therapy(
        id: 't1',
        hormoneId: 'estradiol',
        name: 'Estradiol Valerate 40 mg/mL',
        dose: 4,
        doseUnit: 'mg',
        start: DateTime(2026, 11, 1),
        route: 'inj',
      );
      const medSupply = Supply(
        id: 's1',
        name: 'Estradiol Valerate Vial',
        qty: 2,
        initial: 10,
        perDose: 1,
      );

      // Standard mode ('off') shows full details
      const standardPrefs = Prefs(discreetNotify: 'off');
      L10n.notifier.value = 'en';
      final (stdDoseTitle, stdDoseBody) = doseNotificationText(therapy, standardPrefs, place: 'Left thigh');
      expect(stdDoseTitle, contains('Estradiol Valerate 40 mg/mL'));
      expect(stdDoseBody, contains('4 mg'));
      expect(stdDoseBody, contains('Left thigh'));

      final (stdLowTitle, stdLowBody) = lowSupplyNotificationText(medSupply, standardPrefs);
      expect(stdLowTitle, equals('Running low'));
      expect(stdLowBody, contains('Estradiol Valerate Vial'));

      final (stdExpTitle, stdExpBody) = expiryNotificationText(medSupply, 3, standardPrefs);
      expect(stdExpTitle, equals('Medication expiring soon'));
      expect(stdExpBody, contains('Estradiol Valerate Vial'));

      // Wellness & Routine mode ('wellness') masks drug/item names in EN and ID
      const wellnessPrefs = Prefs(discreetNotify: 'wellness');
      for (final lang in ['en', 'id']) {
        L10n.notifier.value = lang;
        final (wDoseTitle, wDoseBody) = doseNotificationText(therapy, wellnessPrefs, place: 'Left thigh');
        expect('$wDoseTitle $wDoseBody', isNot(contains('Estradiol')));
        expect('$wDoseTitle $wDoseBody', isNot(contains('thigh')));

        final (wLowTitle, wLowBody) = lowSupplyNotificationText(medSupply, wellnessPrefs);
        expect('$wLowTitle $wLowBody', isNot(contains('Estradiol')));
        expect('$wLowTitle $wLowBody', isNot(contains('Vial')));
        expect(wLowTitle, equals(lang == 'id' ? 'Perlengkapan Rutin ✦' : 'Routine Supplies ✦'));

        for (final lead in [14, 3, 0]) {
          final (wExpTitle, wExpBody) = expiryNotificationText(medSupply, lead, wellnessPrefs);
          expect('$wExpTitle $wExpBody', isNot(contains('Estradiol')));
          expect('$wExpTitle $wExpBody', isNot(contains('Medication')));
          expect('$wExpTitle $wExpBody', isNot(contains('Obat')));
          expect(wExpTitle, equals(lang == 'id' ? 'Perlengkapan Rutin ✦' : 'Routine Supplies ✦'));
        }
      }

      // Minimal mode ('minimal') masks everything to neutral prompt
      const minimalPrefs = Prefs(discreetNotify: 'minimal');
      L10n.notifier.value = 'en';
      expect(doseNotificationText(therapy, minimalPrefs), equals(('Lunera ✦', 'Gentle reminder.')));
      expect(lowSupplyNotificationText(medSupply, minimalPrefs), equals(('Lunera ✦', 'Gentle reminder.')));
      expect(expiryNotificationText(medSupply, 0, minimalPrefs), equals(('Lunera ✦', 'Gentle reminder.')));
    });

    test('Snooze payload round-trip, action duration mapping, discreet preservation, and pending check', () {
      final therapy = Therapy(
        id: 't1',
        hormoneId: 'estradiol',
        name: 'Estradiol Valerate',
        dose: 4,
        doseUnit: 'mg',
        start: DateTime(2026, 11, 1),
        route: 'inj',
      );
      L10n.notifier.value = 'en';
      final (title, body) = doseNotificationText(
        therapy,
        const Prefs(discreetNotify: 'wellness'),
        place: 'Left thigh',
      );

      final payload = snoozePayload(
        therapyId: 't1',
        slot: '2026-11-21 08:00',
        title: title,
        body: body,
      );
      final parsed = parseSnoozePayload(payload);
      expect(parsed, isNotNull);
      expect(parsed!['tid'], equals('t1'));
      expect(parsed['slot'], equals('2026-11-21 08:00'));
      expect(parsed['title'], equals(title));
      expect(parsed['body'], equals(body));
      expect('$title $body', isNot(contains('Estradiol')));

      expect(parseSnoozePayload(null), isNull);
      expect(parseSnoozePayload('not json'), isNull);
      expect(parseSnoozePayload('{"k":"other","tid":"t1"}'), isNull);

      expect(snoozeMinutes('snooze_15'), equals(15));
      expect(snoozeMinutes('snooze_30'), equals(30));
      expect(snoozeMinutes('other'), isNull);
      expect(snoozeMinutes(null), isNull);

      expect(keepSnooze(payload, {'t1|2026-11-21 08:00'}), isTrue);
      expect(keepSnooze(payload, {'t1|2026-11-21 20:00'}), isFalse);
      expect(keepSnooze('invalid', {'t1|2026-11-21 08:00'}), isFalse);
    });
  });
}

