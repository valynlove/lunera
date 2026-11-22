import 'package:flutter_test/flutter_test.dart';
import 'package:lunera/models.dart';
import 'package:lunera/schedule.dart';

void main() {
  group('Lunera Therapy Schedule Tests', () {
    test('Therapy schedule occurrences and cycle calculation', () {
      final dailyTherapy = Therapy(
        id: 'td1',
        hormoneId: 'other',
        name: 'Daily Med',
        dose: 1,
        doseUnit: 'tab',
        start: DateTime(2026, 11, 1),
        kind: 'interval',
        everyDays: 1,
        times: ['08:00', '20:00'],
      );
      expect(cycleOf(dailyTherapy), equals(1));
      final dailyOccs = occurrences(dailyTherapy, DateTime(2026, 11, 1), DateTime(2026, 11, 3));
      // 3 days * 2 times = 6 occurrences
      expect(dailyOccs.length, equals(6));

      final weeklyTherapy = Therapy(
        id: 'tw1',
        hormoneId: 'estradiol',
        name: 'Weekly Inj',
        dose: 5,
        doseUnit: 'mg',
        start: DateTime(2026, 11, 1), // Sunday = 7
        kind: 'weekly',
        weekdays: [7], // Sunday only
        times: ['10:00'],
      );
      expect(cycleOf(weeklyTherapy), equals(7));
      final weeklyOccs = occurrences(weeklyTherapy, DateTime(2026, 11, 1), DateTime(2026, 11, 15));
      // 3 Sundays in the range: Nov 1, Nov 8, Nov 15
      expect(weeklyOccs.length, equals(3));
    });

    test('estimateSupplyForecast calculates run-out days for meds and equipment',
        () {
      final therapy = Therapy(
        id: 't1',
        hormoneId: 'estradiol',
        name: 'Estradiol Valerate',
        dose: 4,
        doseUnit: 'mg',
        start: DateTime(2026, 11, 1),
        kind: 'interval',
        everyDays: 5,
        route: 'inj',
        supplyId: 's_med',
      );
      const vial = Supply(
        id: 's_med',
        name: 'EV Vial',
        qty: 5.0,
        initial: 5.0,
        perDose: 0.2,
      ); // 25 doses * 5 days = 125 days
      final now = DateTime(2026, 11, 22);
      final medForecast =
          estimateSupplyForecast(vial, [therapy], now: now);
      expect(medForecast, isNotNull);
      expect(medForecast!.daysLeft, equals(125));
      expect(medForecast.runOutDate, equals(DateTime(2027, 3, 27)));

      const syringes = Supply(
        id: 's_gen',
        name: '1mL Syringe',
        qty: 10,
        initial: 20,
        perDose: 1,
        kind: 'generic',
        gtype: 'syringe',
      ); // 10 shots * 5 days = 50 days
      final genForecast =
          estimateSupplyForecast(syringes, [therapy], now: now);
      expect(genForecast, isNotNull);
      expect(genForecast!.daysLeft, equals(50));
    });

    test('computeTroughLabReminder identifies next trough slot and 90-day check',
        () {
      final now = DateTime.now();
      final tomorrow = DateTime(now.year, now.month, now.day + 1, 8, 0);
      final therapy = Therapy(
        id: 't_inj',
        hormoneId: 'estradiol',
        name: 'Estradiol Enanthate',
        dose: 5,
        doseUnit: 'mg',
        start: DateTime(now.year, now.month, now.day - 6),
        kind: 'interval',
        everyDays: 7,
        times: const ['08:00'],
        route: 'inj',
      );

      final recentLab = Lab(
        id: 'l1',
        hormoneId: 'estradiol',
        at: now.subtract(const Duration(days: 30)),
        value: 150,
        unit: 'pg/mL',
      );
      final notDue = computeTroughLabReminder(
        [therapy],
        const [],
        [recentLab],
        const Prefs(),
        now: now,
      );
      expect(notDue, isNotNull);
      expect(notDue!.nextTroughSlot, isNotNull);
      expect(notDue.nextTroughSlot!.at.isAfter(now), isTrue);
      expect(notDue.daysSinceLastLab, equals(30));
      expect(notDue.isDue, isFalse);

      final oldLab = Lab(
        id: 'l2',
        hormoneId: 'estradiol',
        at: now.subtract(const Duration(days: 95)),
        value: 150,
        unit: 'pg/mL',
      );
      final due = computeTroughLabReminder(
        [therapy],
        const [],
        [oldLab],
        const Prefs(),
        now: now,
      );
      expect(due, isNotNull);
      expect(due!.isDue, isTrue);
      expect(tomorrow.isAfter(now), isTrue);
    });
  });
}

