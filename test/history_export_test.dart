import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lunera/history_export.dart';
import 'package:lunera/models.dart';
import 'package:lunera/repo.dart';

void main() {
  group('Dose History Export & Import Tests', () {
    final injTherapy = Therapy(
      id: 't_inj',
      hormoneId: 'estradiol',
      name: 'Estradiol Valerate',
      dose: 5,
      doseUnit: 'mg',
      start: DateTime(2026, 10, 1),
      route: 'injection',
      injType: 'im',
    );

    final comboTherapy = Therapy(
      id: 't_combo',
      hormoneId: 'estradiol',
      name: 'Cyclofem',
      dose: 5,
      doseUnit: 'mg',
      start: DateTime(2026, 10, 1),
      route: 'injection',
      injType: 'im',
      secondaryHormoneId: 'progestin',
      secondaryDose: 25,
      secondaryDoseUnit: 'mg',
    );

    final oralTherapy = Therapy(
      id: 't_oral',
      hormoneId: 'antiandrogen',
      name: 'Spironolactone',
      dose: 50,
      doseUnit: 'mg',
      start: DateTime(2026, 10, 1),
      route: 'oral',
    );

    final takenInj = DoseLog(
      id: 'l_1',
      therapyId: 't_inj',
      at: DateTime(2026, 11, 20, 8, 30),
      places: const ['Left thigh', 'Right thigh'],
      dose: 4.5,
      injType: 'subq',
      note: 'Smooth, "no pain"\nLine 2',
      usedSupplies: const {'s_1': 1},
    );

    final skippedOral = DoseLog(
      id: 'l_2',
      therapyId: 't_oral',
      at: DateTime(2026, 11, 19, 20, 0),
      skipped: true,
      note: '=SUM(A1:A5)',
    );

    final comboLog = DoseLog(
      id: 'l_3',
      therapyId: 't_combo',
      at: DateTime(2026, 11, 21, 9, 15),
      places: const ['Left buttock'],
      dose: 5,
      secondaryDose: 25,
    );

    final orphanLog = DoseLog(
      id: 'l_4',
      therapyId: 't_deleted',
      at: DateTime(2026, 11, 18, 7, 0),
      dose: 2,
    );

    test('exportDoseHistoryCsv formats header, descending order, combination, skipped, deleted therapy, RFC 4180 escaping, and formula protection', () {
      final csv = exportDoseHistoryCsv(
        [takenInj, skippedOral, comboLog, orphanLog],
        [injTherapy, comboTherapy, oralTherapy],
      );

      final lines = csv.split('\r\n');
      expect(
        lines.first,
        equals(
          'date,time,timestamp,therapy,route,injection_type,status,dose,dose_unit,secondary_dose,secondary_dose_unit,sites,note',
        ),
      );

      final idxCombo = csv.indexOf('2026-11-21,09:15');
      final idxInj = csv.indexOf('2026-11-20,08:30');
      final idxOral = csv.indexOf('2026-11-19,20:00');
      final idxOrphan = csv.indexOf('2026-11-18,07:00');

      expect(idxCombo, greaterThan(0));
      expect(idxInj, greaterThan(idxCombo));
      expect(idxOral, greaterThan(idxInj));
      expect(idxOrphan, greaterThan(idxOral));

      expect(
        csv,
        contains(
          '2026-11-21,09:15,${comboLog.at.toIso8601String()},Cyclofem,injection,im,taken,5,mg,25,mg,Left buttock,',
        ),
      );

      expect(
        csv,
        contains(
          '2026-11-20,08:30,${takenInj.at.toIso8601String()},Estradiol Valerate,injection,subq,taken,4.5,mg,,,Left thigh; Right thigh,"Smooth, ""no pain""\nLine 2"',
        ),
      );

      expect(
        csv,
        contains(
          "2026-11-19,20:00,${skippedOral.at.toIso8601String()},Spironolactone,oral,,skipped,,,,,,'=SUM(A1:A5)",
        ),
      );

      expect(
        csv,
        contains(
          '2026-11-18,07:00,${orphanLog.at.toIso8601String()},Therapy deleted,,,taken,2,,,,,',
        ),
      );

      final formulaUnitTherapy = Therapy(
        id: 't_formula',
        hormoneId: 'estradiol',
        name: 'Test',
        dose: 2,
        doseUnit: '=CMD()',
        secondaryHormoneId: 'progesterone',
        secondaryDose: 10,
        secondaryDoseUnit: '+SUM(1)',
        start: DateTime(2026, 10, 1),
      );
      final formulaUnitLog = DoseLog(
        id: 'l_formula',
        therapyId: 't_formula',
        at: DateTime(2026, 11, 21, 10, 0),
        dose: 2,
        secondaryDose: 10,
      );
      final formulaCsv = exportDoseHistoryCsv([formulaUnitLog], [formulaUnitTherapy]);
      expect(formulaCsv, contains(",'=CMD(),10,'+SUM(1),"));
    });

    test('exportDoseHistoryJson outputs valid standalone JSON rejected by full-backup validate()', () {
      final exportedAt = DateTime(2026, 11, 21, 17, 0);
      final jsonText = exportDoseHistoryJson(
        [takenInj, skippedOral, comboLog, orphanLog],
        [injTherapy, comboTherapy, oralTherapy],
        now: exportedAt,
      );

      final decoded = jsonDecode(jsonText) as Map<String, dynamic>;
      final metadata = decoded['metadata'] as Map<String, dynamic>;
      expect(metadata['app'], equals('lunera'));
      expect(metadata['export_type'], equals('dose_history'));
      expect(metadata['version'], equals(1));
      expect(metadata['exported_at'], equals(exportedAt.toIso8601String()));
      expect(metadata['count'], equals(4));

      final entries = decoded['entries'] as List<dynamic>;
      expect(entries, hasLength(4));

      final first = entries[0] as Map<String, dynamic>;
      expect(first['id'], equals('l_3'));
      expect(first['therapy'], equals('Cyclofem'));
      expect(first['route'], equals('injection'));
      expect(first['injection_type'], equals('im'));
      expect(first['status'], equals('taken'));
      expect(first['dose'], equals(5));
      expect(first['dose_unit'], equals('mg'));
      expect(first['secondary_dose'], equals(25));
      expect(first['secondary_dose_unit'], equals('mg'));
      expect(first['sites'], equals(['Left buttock']));

      final second = entries[1] as Map<String, dynamic>;
      expect(second['id'], equals('l_1'));
      expect(second['injection_type'], equals('subq'));
      expect(second['sites'], equals(['Left thigh', 'Right thigh']));
      expect(second['note'], equals('Smooth, "no pain"\nLine 2'));

      final third = entries[2] as Map<String, dynamic>;
      expect(third['id'], equals('l_2'));
      expect(third['status'], equals('skipped'));
      expect(third['dose'], isNull);
      expect(third['dose_unit'], isNull);

      final fourth = entries[3] as Map<String, dynamic>;
      expect(fourth['id'], equals('l_4'));
      expect(fourth['therapy'], equals('Therapy deleted'));
      expect(fourth['route'], equals(''));

      expect(() => Repo('dummy_uid').validate(decoded), throwsFormatException);
    });

    test('parseDoseHistoryImport round-trips JSON, computes merge counts, and preserves existing usedSupplies', () {
      final jsonText = exportDoseHistoryJson(
        [takenInj, skippedOral, comboLog, orphanLog],
        [injTherapy, comboTherapy, oralTherapy],
      );

      final result = parseDoseHistoryImport(
        jsonText,
        therapies: [injTherapy, comboTherapy, oralTherapy],
        existingLogs: [takenInj],
      );

      expect(result.logs, hasLength(4));
      expect(result.updatedCount, equals(1));
      expect(result.newCount, equals(3));

      final byId = {for (final l in result.logs) l.id: l};
      expect(byId['l_1']!.usedSupplies, equals(const {'s_1': 1}));
      expect(byId['l_1']!.places, equals(['Left thigh', 'Right thigh']));
      expect(byId['l_1']!.note, equals('Smooth, "no pain"\nLine 2'));
      expect(byId['l_2']!.skipped, isTrue);
      expect(byId['l_2']!.dose, isNull);
      expect(byId['l_3']!.secondaryDose, equals(25));
      expect(byId['l_4']!.therapyId, equals('t_deleted'));
    });

    test('parseDoseHistoryImport round-trips CSV with RFC 4180 quotes, formula unescaping, cross-device name matching, and idempotent re-import', () {
      final csv = exportDoseHistoryCsv(
        [takenInj, skippedOral, comboLog, orphanLog],
        [injTherapy, comboTherapy, oralTherapy],
      );

      // Simulate another device with different therapy IDs but matching therapy names
      final deviceInj = injTherapy.copy();
      final renamedDeviceTherapies = [
        Therapy(
          id: 'other_inj',
          hormoneId: deviceInj.hormoneId,
          name: 'estradiol valerate',
          dose: deviceInj.dose,
          doseUnit: deviceInj.doseUnit,
          start: deviceInj.start,
          route: 'injection',
        ),
        Therapy(
          id: 'other_combo',
          hormoneId: comboTherapy.hormoneId,
          name: 'Cyclofem',
          dose: comboTherapy.dose,
          doseUnit: comboTherapy.doseUnit,
          start: comboTherapy.start,
          route: 'injection',
        ),
        Therapy(
          id: 'other_oral',
          hormoneId: oralTherapy.hormoneId,
          name: 'Spironolactone',
          dose: oralTherapy.dose,
          doseUnit: oralTherapy.doseUnit,
          start: oralTherapy.start,
          route: 'oral',
        ),
      ];

      final firstImport = parseDoseHistoryImport(
        '\uFEFF$csv',
        therapies: renamedDeviceTherapies,
        existingLogs: const [],
      );

      expect(firstImport.newCount, equals(4));
      expect(firstImport.updatedCount, equals(0));
      expect(firstImport.logs, hasLength(4));

      final importedInj = firstImport.logs.firstWhere((l) => l.therapyId == 'other_inj');
      expect(importedInj.dose, equals(4.5));
      expect(importedInj.injType, equals('subq'));
      expect(importedInj.places, equals(['Left thigh', 'Right thigh']));
      expect(importedInj.note, equals('Smooth, "no pain"\nLine 2'));

      final importedOral = firstImport.logs.firstWhere((l) => l.therapyId == 'other_oral');
      expect(importedOral.skipped, isTrue);
      expect(importedOral.note, equals('=SUM(A1:A5)'));

      final importedCombo = firstImport.logs.firstWhere((l) => l.therapyId == 'other_combo');
      expect(importedCombo.secondaryDose, equals(25));

      final importedOrphan = firstImport.logs.firstWhere((l) => l.therapyId == 'deleted_therapy');
      expect(importedOrphan.dose, equals(2));

      // Re-importing same CSV merges cleanly with zero new duplicates
      final secondImport = parseDoseHistoryImport(
        csv,
        therapies: renamedDeviceTherapies,
        existingLogs: firstImport.logs,
      );
      expect(secondImport.newCount, equals(0));
      expect(secondImport.updatedCount, equals(4));
    });

    test('parseDoseHistoryImport rejects full backups, malformed headers, negative doses, and empty files', () {
      final fullBackup = jsonEncode({
        'metadata': {'app': 'lunera', 'version': 1},
        'data': {'logs': []},
      });
      expect(
        () => parseDoseHistoryImport(fullBackup, therapies: const [], existingLogs: const []),
        throwsA(isA<FormatException>().having(
          (e) => e.message,
          'message',
          contains('full backup'),
        )),
      );

      expect(
        () => parseDoseHistoryImport('   ', therapies: const [], existingLogs: const []),
        throwsFormatException,
      );

      expect(
        () => parseDoseHistoryImport(
          'foo,bar\n1,2',
          therapies: const [],
          existingLogs: const [],
        ),
        throwsFormatException,
      );

      expect(
        () => parseDoseHistoryImport(
          'date,time,timestamp,therapy,status,dose\n2026-11-21,09:00,,Cyclofem,taken,-5',
          therapies: const [],
          existingLogs: const [],
        ),
        throwsFormatException,
      );
    });

    test('_describeLog falls back to therapy injType when therapy route is canonical "inj"', () {
      final t = Therapy(
        id: 't_inj_short',
        hormoneId: 'estradiol',
        name: 'EV',
        dose: 5.0,
        doseUnit: 'mg',
        start: DateTime.now(),
        route: 'inj',
        injType: 'subq',
      );
      final l = DoseLog(
        id: 'l_inj_no_type',
        therapyId: 't_inj_short',
        at: DateTime.now(),
      );
      final json = exportDoseHistoryJson([l], [t]);
      final decoded = jsonDecode(json);
      final entry = decoded['entries'][0];
      expect(entry['route'], equals('inj'));
      expect(entry['injection_type'], equals('subq'));
    });
  });
}
