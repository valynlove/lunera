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
        Lab(id: 'l2', hormoneId: 'estradiol', at: t1, value: levelDay1 * 5.0, unit: 'pg/mL', cmp: '<'),
        Lab(id: 'l3', hormoneId: 'estradiol', at: t1, value: levelDay1 * 10.0, unit: 'pg/mL', cmp: '>'),
      ];
      final (scale, count) = calibration(intakes, labs);
      expect(count, equals(1));
      expect(scale, closeTo(1.2, 0.05));
    });

    test('Long-acting esters (e2_undecylate & t_undecanoate) extend past 150 days and decay to threshold', () {
      final t0 = DateTime(2026, 1, 1, 8, 0);
      final eun = [Intake(t0, 10.0, pkOf('e2_undecylate')!)];
      final tu = [Intake(t0, 1000.0, pkOf('t_undecanoate')!)];

      // Previously cut off at 150 days; now still positive at day 200 and drops to 0 after ~632 days
      expect(levelAt(eun, t0.add(const Duration(days: 200))), greaterThan(0.5));
      expect(levelAt(tu, t0.add(const Duration(days: 200))), greaterThan(1.0));
      expect(levelAt(eun, t0.add(const Duration(days: 700))), equals(0.0));
      expect(levelAt(tu, t0.add(const Duration(days: 700))), equals(0.0));
    });

    test('Equal-rate limit forms avoid NaN/Infinity for injection and oral models', () {
      final t0 = DateTime(2026, 11, 1, 8, 0);
      final t2 = t0.add(const Duration(days: 2));

      const injTwoEqual = PkProfile('test_inj_2eq', 'Test 2eq', false, [0.7, 500.0, 0.5, 0.5, 2.0]);
      const injAllEqual = PkProfile('test_inj_3eq', 'Test 3eq', false, [0.7, 500.0, 0.5, 0.5, 0.5]);
      const oralEqual = PkProfile('test_oral_eq', 'Test oral eq', true, [20.0, 1.5, 1.5]);

      for (final pk in [injTwoEqual, injAllEqual, oralEqual]) {
        final v = levelAt([Intake(t0, 5.0, pk)], t2);
        expect(v.isFinite, isTrue);
        expect(v, greaterThan(0.0));
      }
    });

    test('Negative and non-finite doses are ignored in simulation and intakesFor', () {
      final t0 = DateTime(2026, 11, 1, 8, 0);
      final t1 = t0.add(const Duration(days: 1));
      final pk = pkOf('e2_valerate')!;

      final badIntakes = [
        Intake(t0, -4.0, pk),
        Intake(t0, 0.0, pk),
        Intake(t0, double.infinity, pk),
        Intake(t0, double.nan, pk),
      ];
      expect(levelAt(badIntakes, t1), equals(0.0));
      expect(simSpots(badIntakes, t0, t1, n: 4).every((s) => s.y == 0.0), isTrue);

      final therapy = Therapy(
        id: 't1',
        hormoneId: 'estradiol',
        name: 'EV',
        dose: 4.0,
        doseUnit: 'mg',
        start: t0,
        route: 'inj',
        pk: 'e2_valerate',
      );
      final logs = [
        DoseLog(id: 'bad1', therapyId: 't1', at: t0, dose: -2.0),
        DoseLog(id: 'bad2', therapyId: 't1', at: t0, dose: double.nan),
        DoseLog(id: 'good', therapyId: 't1', at: t0, dose: 4.0),
      ];
      final parsed = intakesFor('estradiol', [therapy], logs);
      expect(parsed.length, equals(1));
      expect(parsed.first.dose, equals(4.0));
    });
  });
}

