import 'package:flutter_test/flutter_test.dart';
import 'package:lunera/models.dart';
import 'package:lunera/sim.dart';

void main() {
  group('Lunera Simulation & Pharmacokinetics Tests', () {
    test('Pharmacokinetic simulation levelAt, simSpots, and calibration calculations', () {
      final pk = pkOf('e2_valerate')!;
      final t0 = DateTime(2026, 11, 1, 8, 0);

      // Single 4 mg EV dose
      final intakes = [Intake(t0, 4.0, pk)];

      // Concentration at t0 should be 0 (dt <= 0)
      expect(levelAt(intakes, t0), equals(0.0));

      // Level 24 hours later should be strictly positive
      final t1 = t0.add(const Duration(hours: 24));
      final levelDay1 = levelAt(intakes, t1);
      expect(levelDay1, greaterThan(100.0));

      // Level after 14 days should decay significantly
      final t14 = t0.add(const Duration(days: 14));
      final levelDay14 = levelAt(intakes, t14);
      expect(levelDay14, lessThan(levelDay1));

      // Simulation spots generation
      final spots = simSpots(intakes, t0, t14, n: 10);
      expect(spots.length, equals(11));
      expect(spots.first.y, equals(0.0));

      // Calibration with sample lab test
      final labs = [
        Lab(id: 'l1', hormoneId: 'estradiol', at: t1, value: levelDay1 * 1.2, unit: 'pg/mL'),
      ];
      final (scale, count) = calibration(intakes, labs);
      expect(count, equals(1));
      expect(scale, closeTo(1.2, 0.05));
    });
  });
}

