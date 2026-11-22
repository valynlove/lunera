import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lunera/doctor_report.dart';
import 'package:lunera/l10n.dart';
import 'package:lunera/models.dart';
import 'package:lunera/schedule.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  group('Doctor Visit Summary Tests', () {
    test('buildDoctorReport formats therapies, adherence, labs with comparators, estimates, and excludes private notes', () {
      L10n.notifier.value = 'en';
      final today = DateTime.now();
      final now = DateTime(today.year, today.month, today.day, 22, 0);
      final start = DateTime(today.year, today.month, today.day - 4);

      final therapy = Therapy(
        id: 't_ev',
        hormoneId: 'estradiol',
        name: 'Estradiol Valerate',
        dose: 4.0,
        doseUnit: 'mg',
        start: start,
        kind: 'interval',
        everyDays: 1,
        times: const ['08:00'],
        route: 'inj',
        pk: 'e2_valerate',
      );

      final day1 = DateTime(start.year, start.month, start.day, 8, 0);
      final day2 = DateTime(start.year, start.month, start.day + 1, 8, 0);
      final logs = [
        DoseLog(
          id: 'log1',
          therapyId: 't_ev',
          at: day1,
          slot: slotKey(day1),
          note: 'SECRET_DOSE_NOTE_DO_NOT_LEAK',
        ),
        DoseLog(
          id: 'log2',
          therapyId: 't_ev',
          at: day2,
          slot: slotKey(day2),
          skipped: true,
        ),
      ];

      final labs = [
        Lab(
          id: 'lab_t',
          hormoneId: 'testosterone',
          at: now.subtract(const Duration(days: 5)),
          value: 15,
          unit: 'ng/dL',
          cmp: '<',
          note: 'SECRET_LAB_NOTE_DO_NOT_LEAK',
        ),
        Lab(
          id: 'lab_e2',
          hormoneId: 'estradiol',
          at: now.subtract(const Duration(days: 5)),
          value: 180,
          unit: 'pg/mL',
        ),
        Lab(
          id: 'lab_old',
          hormoneId: 'estradiol',
          at: now.subtract(const Duration(days: 200)),
          value: 999,
          unit: 'pg/mL',
        ),
      ];

      final targets = <String, List<double>>{
        'estradiol': [100.0, 200.0],
        'testosterone': [10.0, 50.0],
      };

      final report = buildDoctorReport(
        therapies: [therapy],
        logs: logs,
        labs: labs,
        targets: targets,
        prefs: const Prefs(),
        now: now,
        months: 3,
      );

      expect(report, contains('Estradiol Valerate'));
      // 5 days inclusive (start..today) at 08:00 before 22:00 => 1 taken / 5 = 20%
      expect(report, contains('1 / 5 (20%)'));
      expect(report, contains('1 skipped'));
      expect(report, contains('< 15 ng/dL'));
      // Censored lab (< 15 ng/dL) must NOT get target status label
      expect(report, isNot(contains('< 15 ng/dL (In range)')));
      // Exact lab gets target status
      expect(report, contains('180 pg/mL (In range)'));
      // Old lab (> 3 months ago) excluded
      expect(report, isNot(contains('999 pg/mL')));
      // Model estimate included
      expect(report, contains('model estimate, not a lab result'));
      // Free-text notes excluded for privacy
      expect(report, isNot(contains('SECRET_DOSE_NOTE_DO_NOT_LEAK')));
      expect(report, isNot(contains('SECRET_LAB_NOTE_DO_NOT_LEAK')));
    });

    test('buildDoctorReportPdf generates valid A4 PDF document bytes',
        () async {
      L10n.notifier.value = 'en';
      final now = DateTime(2026, 11, 22, 12, 0);
      final therapy = Therapy(
        id: 't_ev',
        hormoneId: 'estradiol',
        name: 'Estradiol Valerate',
        dose: 4.0,
        doseUnit: 'mg',
        start: DateTime(2026, 10, 1),
        kind: 'interval',
        everyDays: 5,
        times: const ['08:00'],
        route: 'inj',
        pk: 'e2_valerate',
      );
      final pdfBytes = await buildDoctorReportPdf(
        therapies: [therapy],
        logs: const [],
        labs: [
          Lab(
            id: 'l1',
            hormoneId: 'estradiol',
            at: DateTime(2026, 11, 15),
            value: 165,
            unit: 'pg/mL',
          ),
        ],
        targets: const {
          'estradiol': [100.0, 200.0]
        },
        prefs: const Prefs(),
        now: now,
      );
      expect(pdfBytes.length, greaterThan(500));
      expect(String.fromCharCodes(pdfBytes.take(5)), equals('%PDF-'));
    });
  });
}
