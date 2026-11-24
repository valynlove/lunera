import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lunera/consultation_prep.dart';
import 'package:lunera/doctor_report.dart';
import 'package:lunera/models.dart';
import 'package:lunera/profile.dart';
import 'package:lunera/repo.dart';
import 'package:lunera/ui/consultation_prep_page.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('id');
  });

  group('clusterJournalSymptoms Unit Tests', () {
    final now = DateTime(2026, 11, 24, 12, 0);

    test('returns empty list when journal has no entries', () {
      final clusters = clusterJournalSymptoms(
        journal: const [],
        logs: const [],
        now: now,
      );
      expect(clusters, isEmpty);
    });

    test('ignores journal entries outside lookback window', () {
      final oldEntry = JournalEntry(
        id: 'j1',
        at: now.subtract(const Duration(days: 100)),
        symptoms: const ['fatigue'],
      );
      final clusters = clusterJournalSymptoms(
        journal: [oldEntry],
        logs: const [],
        now: now,
        lookbackDays: 90,
      );
      expect(clusters, isEmpty);
    });

    test('clusters symptoms and sorts by count descending', () {
      final entries = [
        JournalEntry(
          id: 'j1',
          at: now.subtract(const Duration(days: 5)),
          symptoms: const ['fatigue', 'hot_flashes'],
        ),
        JournalEntry(
          id: 'j2',
          at: now.subtract(const Duration(days: 12)),
          symptoms: const ['fatigue'],
        ),
        JournalEntry(
          id: 'j3',
          at: now.subtract(const Duration(days: 20)),
          symptoms: const ['fatigue'],
        ),
      ];

      final clusters = clusterJournalSymptoms(
        journal: entries,
        logs: const [],
        now: now,
      );

      expect(clusters.length, 2);
      expect(clusters[0].symptomKey, 'fatigue');
      expect(clusters[0].count, 3);
      expect(clusters[1].symptomKey, 'hot_flashes');
      expect(clusters[1].count, 1);
    });

    test('detects correlation for symptoms occurring within 1-2 days after dose', () {
      final injDose1 = DoseLog(
        id: 'l1',
        therapyId: 'ev_inj',
        at: now.subtract(const Duration(days: 14)),
        dose: 4.0,
      );
      final injDose2 = DoseLog(
        id: 'l2',
        therapyId: 'ev_inj',
        at: now.subtract(const Duration(days: 7)),
        dose: 4.0,
      );

      final entries = [
        JournalEntry(
          id: 'j1',
          at: now.subtract(const Duration(days: 13)), // 1 day after l1
          symptoms: const ['site_soreness'],
        ),
        JournalEntry(
          id: 'j2',
          at: now.subtract(const Duration(days: 6)), // 1 day after l2
          symptoms: const ['site_soreness'],
        ),
      ];

      final clusters = clusterJournalSymptoms(
        journal: entries,
        logs: [injDose1, injDose2],
        now: now,
      );

      expect(clusters.length, 1);
      expect(clusters.first.symptomKey, 'site_soreness');
      expect(clusters.first.cycleCorrelation, contains('within 1–2 days'));
      expect(clusters.first.suggestedQuestion, contains('Injection site soreness'));
    });

    test('detects correlation for symptoms occurring late in cycle (near trough)', () {
      final injDose = DoseLog(
        id: 'l1',
        therapyId: 'ev_inj',
        at: now.subtract(const Duration(days: 14)),
        dose: 4.0,
      );

      final entries = [
        JournalEntry(
          id: 'j1',
          at: now.subtract(const Duration(days: 8)), // 6 days after dose
          symptoms: const ['hot_flashes'],
        ),
        JournalEntry(
          id: 'j2',
          at: now.subtract(const Duration(days: 7)), // 7 days after dose
          symptoms: const ['hot_flashes'],
        ),
      ];

      final clusters = clusterJournalSymptoms(
        journal: entries,
        logs: [injDose],
        now: now,
      );

      expect(clusters.length, 1);
      expect(clusters.first.symptomKey, 'hot_flashes');
      expect(clusters.first.cycleCorrelation, contains('near trough'));
    });

    test('daily therapy skips false dose cycle correlation', () {
      final dailyOral = Therapy(
        id: 'oral_prog',
        hormoneId: 'progesterone',
        name: 'Progesterone',
        dose: 100.0,
        doseUnit: 'mg',
        start: now.subtract(const Duration(days: 30)),
        route: 'oral',
        everyDays: 1,
      );
      final dose = DoseLog(
        id: 'l_oral',
        therapyId: 'oral_prog',
        at: now.subtract(const Duration(days: 1)),
        dose: 100.0,
      );
      final entries = [
        JournalEntry(
          id: 'j1',
          at: now.subtract(const Duration(days: 1)),
          symptoms: const ['fatigue'],
        ),
        JournalEntry(
          id: 'j2',
          at: now.subtract(const Duration(days: 1)),
          symptoms: const ['fatigue'],
        ),
      ];

      final clusters = clusterJournalSymptoms(
        journal: entries,
        logs: [dose],
        therapies: [dailyOral],
        now: now,
      );

      expect(clusters.length, 1);
      expect(clusters.first.symptomKey, 'fatigue');
      expect(clusters.first.cycleCorrelation, isNull);
    });
  });

  group('ConsultationSession Serialization & Default Checklist', () {
    test('defaultConsultationChecklist returns 5 essential checklist items', () {
      final list = defaultConsultationChecklist();
      expect(list.length, 5);
      expect(list.every((c) => c.isDefault), isTrue);
      expect(list.every((c) => !c.isChecked), isTrue);
    });

    test('round-trip serialization toMap and fromMap preserves fields', () {
      final session = ConsultationSession(
        id: 'sess_1',
        scheduledAt: DateTime(2026, 12, 1, 10, 0),
        doctorOrClinic: 'Dr. Sarah Adams',
        questions: const [
          ConsultationQuestion(
            id: 'q1',
            text: 'Should we increase EV dose?',
            isAsked: true,
            symptomKey: 'hot_flashes',
          ),
        ],
        checklist: const [
          ConsultationChecklistItem(
            id: 'c1',
            title: 'Bring blood test results',
            isChecked: true,
            isDefault: false,
          ),
        ],
        postVisitNotes: 'Dose maintained at 4mg weekly. Retest in 3 months.',
        isCompleted: true,
      );

      final map = session.toMap();
      final restored = ConsultationSession.fromMap(map);

      expect(restored.id, 'sess_1');
      expect(restored.doctorOrClinic, 'Dr. Sarah Adams');
      expect(restored.scheduledAt, DateTime(2026, 12, 1, 10, 0));
      expect(restored.questions.length, 1);
      expect(restored.questions.first.text, 'Should we increase EV dose?');
      expect(restored.questions.first.isAsked, isTrue);
      expect(restored.questions.first.symptomKey, 'hot_flashes');
      expect(restored.checklist.length, 1);
      expect(restored.checklist.first.isChecked, isTrue);
      expect(restored.postVisitNotes, contains('Retest in 3 months'));
      expect(restored.isCompleted, isTrue);
    });
  });

  group('DoctorReport Integration with Prepared Questions', () {
    final now = DateTime(2026, 11, 24, 12, 0);

    test('buildDoctorReport includes Prepared Consultation Questions section', () {
      final report = buildDoctorReport(
        therapies: const [],
        logs: const [],
        labs: const [],
        targets: const {},
        prefs: const Prefs(),
        now: now,
        consultationQuestions: const [
          'Review estradiol trough levels',
          'Discuss tissue resting for thigh injections',
        ],
      );

      expect(report, contains('Prepared Consultation Questions'));
      expect(report, contains('Review estradiol trough levels'));
      expect(report, contains('Discuss tissue resting for thigh injections'));
    });

    test('buildDoctorReportPdf includes Prepared Consultation Questions', () async {
      final pdfBytes = await buildDoctorReportPdf(
        therapies: const [],
        logs: const [],
        labs: const [],
        targets: const {},
        prefs: const Prefs(),
        now: now,
        consultationQuestions: const [
          'Review estradiol trough levels',
        ],
      );

      expect(pdfBytes, isNotEmpty);
      final pdfString = String.fromCharCodes(pdfBytes);
      expect(pdfString, contains('Prepared Consultation Questions'));
      expect(pdfString, contains('Review estradiol trough levels'));
    });
  });

  group('ConsultationPrepPage Widget Tests', () {
    testWidgets('renders overview, symptom clusters, questions, and checklist',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      final now = DateTime.now();
      final sampleJournal = [
        JournalEntry(
          id: 'j1',
          at: now.subtract(const Duration(days: 2)),
          symptoms: const ['fatigue', 'hot_flashes'],
        ),
      ];

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            userProvider.overrideWith((ref) => Stream.value(null)),
            journalProvider.overrideWith((ref) => Stream.value(sampleJournal)),
            logsProvider.overrideWith((ref) => Stream.value(const [])),
            therapiesProvider.overrideWith((ref) => Stream.value(const [])),
            suppliesProvider.overrideWith((ref) => Stream.value(const [])),
            prefsProvider.overrideWith((ref) => Stream.value(const Prefs())),
            labsProvider.overrideWith((ref) => Stream.value(const [])),
            targetsProvider.overrideWith((ref) => Stream.value(const {})),
          ],
          child: const MaterialApp(
            home: ConsultationPrepPage(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Verify Page Title & Appointment section
      expect(find.text('Smart Consultation Prep'), findsOneWidget);
      expect(find.text('Clinical Appointment'), findsOneWidget);
      expect(find.text('Doctor or Clinic Name'), findsOneWidget);

      // Verify Symptom Patterns rendered
      expect(find.text('Observed Symptom Patterns'), findsOneWidget);
      expect(find.text('Fatigue / Low energy'), findsOneWidget);

      // Verify Add to Questions button works
      final addBtn = find.text('Add to Questions').first;
      expect(addBtn, findsOneWidget);
      await tester.tap(addBtn);
      await tester.pumpAndSettle();

      // Question should now be added to questions list
      expect(find.text('Added'), findsOneWidget);

      // Scroll down to reveal checklist and export button
      await tester.drag(find.byType(ListView), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Verify Checklist items
      expect(find.text('Documents & Visit Checklist'), findsOneWidget);
      expect(find.byType(Checkbox), findsWidgets);

      // Scroll further to export button
      await tester.drag(find.byType(ListView), const Offset(0, -400));
      await tester.pumpAndSettle();

      // Verify Export button
      expect(
        find.text('Export Doctor Summary Report (PDF / Text)'),
        findsOneWidget,
      );
    });
  });
}
