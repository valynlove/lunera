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
  });
}

