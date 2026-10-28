import 'package:flutter_test/flutter_test.dart';
import 'package:lunera/models.dart';
import 'package:lunera/sim.dart';

void main() {
  group('Lunera Model & Simulation Tests', () {
    test('Hormone preset conversion works properly', () {
      final e2 = presetOf('estradiol');
      expect(e2.toBase(100, 'pg/mL'), equals(100));
      expect(e2.toBase(367.1, 'pmol/L'), closeTo(100, 0.1));

      final t = presetOf('testosterone');
      expect(t.toBase(5, 'ng/mL'), equals(500));
    });

    test('Number parsing handles both comma and dot formats', () {
      expect(parseNum('12.5'), equals(12.5));
      expect(parseNum('12,5'), equals(12.5));
      expect(parseNum('  40  '), equals(40.0));
      expect(parseNum('abc'), isNull);
    });

    test('Pharmacokinetic profile lookup and dose conversion', () {
      final pk = pkOf('e2_valerate');
      expect(pk, isNotNull);
      expect(pk!.name, equals('Valerat'));

      // Test mgOf
      expect(mgOf(500, 'mcg'), equals(0.5));
      expect(mgOf(1, 'g'), equals(1000));
      expect(mgOf(5, 'mg'), equals(5));
    });
  });
}
