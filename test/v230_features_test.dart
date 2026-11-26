import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lunera/care_alerts.dart';
import 'package:lunera/consultation_prep.dart';
import 'package:lunera/cycle_insights.dart';
import 'package:lunera/l10n.dart';
import 'package:lunera/milestones.dart';
import 'package:lunera/models.dart';
import 'package:lunera/moments.dart';
import 'package:lunera/profile.dart';
import 'package:lunera/repo.dart';
import 'package:lunera/schedule.dart';
import 'package:lunera/theme.dart';
import 'package:lunera/travel_shift.dart';
import 'package:lunera/ui/journey_timeline_page.dart';
import 'package:lunera/ui/sanctuary/starlight_breath_page.dart';
import 'package:lunera/ui/travel_shift_sheet.dart';
import 'package:lunera/voice_pitch.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    await initializeDateFormatting();
  });

  setUp(() {
    L10n.notifier.value = 'en';
    SharedPreferences.setMockInitialValues({});
  });

  group('v2.3.0 Backward Compatibility & Backup Validation', () {
    test('legacy v2.2.x backup JSON passes validate and uses safe defaults', () {
      final legacyBackup = {
        'metadata': {'app': 'lunera', 'version': 1},
        'data': {
          'supplies': [
            {
              'id': 'sup_legacy',
              'name': 'EV Vial',
              'qty': 5.0,
              'initial': 5.0,
              'perDose': 0.1,
              'unitLabel': 'mL',
            },
          ],
          'prefs': [
            {
              'id': 'main',
              'theme': 'dark',
              'locale': 'en',
            },
          ],
        },
      };
      expect(Repo('u1').validate(legacyBackup), 2);

      final sup = Supply.from(
        'sup_legacy',
        (legacyBackup['data']!['supplies']! as List).first as Map<String, dynamic>,
      );
      expect(sup.openedAt, isNull);
      expect(sup.beyondUseDays, 28);
      expect(sup.deadSpace, isNull);
      expect(sup.doses, 50);

      final prefs = Prefs.from(
        (legacyBackup['data']!['prefs']! as List).first as Map<String, dynamic>,
      );
      expect(prefs.nextLabDate, isNull);
      expect(prefs.careAllergies, '');
      expect(prefs.careClinicInfo, '');
    });

    test('v2.3.0 Supply & Prefs fields round-trip and validate cleanly', () {
      final opened = DateTime(2026, 11, 1);
      final labDate = DateTime(2026, 12, 20);
      final sup = Supply(
        id: 'v1',
        name: 'Estradiol Enanthate',
        qty: 3.0,
        initial: 5.0,
        perDose: 0.1,
        unitLabel: 'mL',
        openedAt: opened,
        beyondUseDays: 30,
        deadSpace: 0.05,
      );
      expect(sup.effectivePerDose, closeTo(0.15, 1e-6));
      expect(sup.doses, 20);
      expect(sup.openExpiry, DateTime(2026, 12, 1));

      final prefs = Prefs(
        nextLabDate: labDate,
        careAllergies: 'Sesame oil sensitivity',
        careClinicInfo: 'Twilight Clinic 555-0192',
      );
      final backup = {
        'metadata': {'app': 'lunera', 'version': 1},
        'data': {
          'supplies': [
            {'id': 'v1', ...sup.toMap()},
          ],
          'prefs': [
            {'id': 'main', ...prefs.toMap()},
          ],
        },
      };
      expect(Repo('u1').validate(backup), 2);

      final badBackup = {
        'metadata': {'app': 'lunera', 'version': 1},
        'data': {
          'supplies': [
            {'id': 'v1', 'name': 'Bad', 'qty': 1.0, 'deadSpace': -0.5},
          ],
        },
      };
      expect(() => Repo('u1').validate(badBackup), throwsFormatException);
    });
  });

  group('v2.3.0 Smart Vial, Lab Countdown & Open-Vial Alerts', () {
    test('estimateSupplyForecast caps daysLeft by openExpiry', () {
      final now = DateTime(2026, 11, 20);
      final s = Supply(
        id: 'v1',
        name: 'EV 40mg/mL',
        qty: 4.0,
        initial: 5.0,
        perDose: 0.1,
        unitLabel: 'mL',
        openedAt: DateTime(2026, 10, 26),
        beyondUseDays: 28,
      );
      final th = Therapy(
        id: 't1',
        hormoneId: 'estradiol',
        name: 'EV',
        dose: 4,
        doseUnit: 'mg',
        start: DateTime(2026, 10, 1),
        everyDays: 7,
        supplyId: 'v1',
        route: 'inj',
      );
      final forecast = estimateSupplyForecast(s, [th], now: now);
      expect(forecast, isNotNull);
      expect(forecast!.daysLeft, 3);
      expect(forecast.urgency, RefillUrgency.critical);
    });

    test('computeTroughLabReminder respects custom nextLabDate', () {
      final now = DateTime(2026, 11, 20, 9);
      final th = Therapy(
        id: 't1',
        hormoneId: 'estradiol',
        name: 'EV',
        dose: 4,
        doseUnit: 'mg',
        start: DateTime(2026, 11, 1),
        everyDays: 7,
        route: 'inj',
        times: const ['20:00'],
      );
      final reminder = computeTroughLabReminder(
        [th],
        const [],
        const [],
        Prefs(nextLabDate: DateTime(2026, 11, 25)),
        now: now,
      );
      expect(reminder, isNotNull);
      expect(reminder!.isCustomDate, isTrue);
      expect(reminder.daysUntilTarget, 5);
      expect(reminder.isDue, isTrue);
    });

    test('evaluateCareAlerts emits open-vial warning and critical alerts', () {
      final now = DateTime(2026, 11, 26);
      final soon = Supply(
        id: 's1',
        name: 'EV Vial A',
        qty: 2,
        initial: 5,
        perDose: 0.1,
        openedAt: DateTime(2026, 11, 1),
        beyondUseDays: 28,
      );
      final expired = Supply(
        id: 's2',
        name: 'EV Vial B',
        qty: 2,
        initial: 5,
        perDose: 0.1,
        openedAt: DateTime(2026, 10, 20),
        beyondUseDays: 28,
      );
      final alerts = evaluateCareAlerts(
        therapies: const [],
        logs: const [],
        supplies: [soon, expired],
        prefs: const Prefs(),
        consultation: const ConsultationSession(id: 'c1'),
        now: now,
      );
      expect(alerts.any((a) => a.id == 'openvial_soon_s1'), isTrue);
      expect(alerts.any((a) => a.id == 'openvial_exp_s2'), isTrue);
    });
  });

  group('v2.3.0 Cycle Insights, Monthly Recap, Care Card, Travel & Voice 30d', () {
    test('analyzeCyclePhaseInsights maps peak vs trough mood and symptoms', () {
      final now = DateTime(2026, 11, 26, 12);
      final th = Therapy(
        id: 't1',
        hormoneId: 'estradiol',
        name: 'EV',
        dose: 4,
        doseUnit: 'mg',
        start: DateTime(2026, 11, 1),
        everyDays: 7,
        route: 'inj',
        pk: 'e2_valerate',
      );
      final logs = [
        DoseLog(id: 'l1', therapyId: 't1', at: DateTime(2026, 11, 12, 20)),
        DoseLog(id: 'l2', therapyId: 't1', at: DateTime(2026, 11, 19, 20)),
      ];
      final journal = [
        JournalEntry(
          id: 'j1',
          at: DateTime(2026, 11, 14, 10),
          mood: 'happy',
          symptoms: const ['steady_energy'],
        ),
        JournalEntry(
          id: 'j2',
          at: DateTime(2026, 11, 21, 10),
          mood: 'happy',
          symptoms: const ['calm_focus'],
        ),
        JournalEntry(
          id: 'j3',
          at: DateTime(2026, 11, 19, 14),
          mood: 'low',
          symptoms: const ['fatigue'],
        ),
        JournalEntry(
          id: 'j4',
          at: DateTime(2026, 11, 26, 10),
          mood: 'low',
          symptoms: const ['fatigue'],
        ),
      ];

      final report = analyzeCyclePhaseInsights(
        therapies: [th],
        logs: logs,
        journal: journal,
        now: now,
      );
      expect(report, isNotNull);
      expect(report!.hasEnoughData, isTrue);
      expect(report.buckets[HormoneCyclePhase.peak]!.avgMood, 5.0);
      expect(report.buckets[HormoneCyclePhase.trough]!.avgMood, 2.0);
      expect(report.clinicianNote, isNotNull);
    });

    test('computeMonthlyCalmRecap aggregates month totals gently', () {
      final recap = computeMonthlyCalmRecap(
        year: 2026,
        month: 11,
        logs: [
          DoseLog(id: 'd1', therapyId: 't1', at: DateTime(2026, 11, 5)),
          DoseLog(id: 'd2', therapyId: 't1', at: DateTime(2026, 10, 5)),
        ],
        journal: [
          JournalEntry(id: 'j1', at: DateTime(2026, 11, 6), mood: 'calm'),
          JournalEntry(id: 'j2', at: DateTime(2026, 11, 8), mood: 'calm'),
        ],
        workoutLogs: [
          WorkoutSessionLog(
            id: 'w1',
            at: DateTime(2026, 11, 7),
            routineId: 'r1',
            routineTitle: 'Gentle',
            durationSec: 600,
          ),
        ],
        milestones: [
          TransitionMilestone(id: 'm1', at: DateTime(2026, 11, 10), title: '3M'),
        ],
        moments: [
          Moment(id: 'mo1', at: DateTime(2026, 11, 12), title: 'Smile'),
        ],
      );
      expect(recap.dosesLogged, 1);
      expect(recap.journalCheckIns, 2);
      expect(recap.movementSessions, 1);
      expect(recap.movementMinutes, 10);
      expect(recap.milestonesAndMoments, 2);
      expect(recap.topMoodKey, 'calm');
    });

    test('formatQuickCareCard includes regimen, labs, allergies & clinic', () {
      final txt = formatQuickCareCard(
        therapies: [
          Therapy(
            id: 't1',
            hormoneId: 'estradiol',
            name: 'EV',
            dose: 4,
            doseUnit: 'mg',
            start: DateTime(2026, 11, 1),
            everyDays: 7,
            route: 'inj',
          ),
        ],
        labs: [
          Lab(
            id: 'lab1',
            hormoneId: 'estradiol',
            at: DateTime(2026, 11, 10),
            value: 190,
            unit: 'pg/mL',
          ),
        ],
        targets: const {
          'estradiol': [100, 200],
        },
        prefs: const Prefs(
          careAllergies: 'None known',
          careClinicInfo: 'Dr. Aria',
        ),
        now: DateTime(2026, 11, 26),
      );
      expect(txt, contains('EV: 4 mg'));
      expect(txt, contains('190 pg/mL'));
      expect(txt, contains('None known'));
      expect(txt, contains('Dr. Aria'));
    });

    test('computeTimezoneShiftPlan handles multi-hour and half-hour shifts', () {
      final steps = computeTimezoneShiftPlan(
        baseTimeHHmm: '20:00',
        originUtcOffsetHours: 7.0,
        destUtcOffsetHours: 1.0,
        departureDate: DateTime(2026, 11, 26),
        maxShiftHoursPerDay: 2.0,
      );
      expect(steps.first.timeHHmm, '14:00');
      expect(steps.last.timeHHmm, '20:00');
      expect(steps.last.remainingShiftMinutes, 0);
      expect(steps.length, 4);

      final halfHour = computeTimezoneShiftPlan(
        baseTimeHHmm: '08:00',
        originUtcOffsetHours: 7.0,
        destUtcOffsetHours: 5.5,
        departureDate: DateTime(2026, 11, 26),
        maxShiftHoursPerDay: 2.0,
      );
      expect(halfHour.first.timeHHmm, '06:30');
      expect(halfHour.last.timeHHmm, '08:00');
    });

    test('computeVoice30DaySummary returns median and delta', () {
      final now = DateTime(2026, 11, 26);
      final res = computeVoice30DaySummary([
        VoiceTestResult(
          id: '3',
          at: DateTime(2026, 11, 25),
          avgHz: 205,
          minHz: 185,
          maxHz: 225,
          category: VoicePitchCategory.softHigh,
        ),
        VoiceTestResult(
          id: '2',
          at: DateTime(2026, 11, 15),
          avgHz: 195,
          minHz: 175,
          maxHz: 215,
          category: VoicePitchCategory.softHigh,
        ),
        VoiceTestResult(
          id: '1',
          at: DateTime(2026, 11, 5),
          avgHz: 185,
          minHz: 165,
          maxHz: 205,
          category: VoicePitchCategory.neutral,
        ),
      ], now: now);
      expect(res.count30d, 3);
      expect(res.medianHz, 195);
      expect(res.deltaFromFirstHz, 20);
    });
  });

  group('v2.3.0 Widget Smoke & Responsive Floor Tests', () {
    testWidgets('TravelShiftSheet renders cleanly on 320dp screen', (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 720));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildTheme(Brightness.dark),
            home: const Scaffold(
              body: SingleChildScrollView(child: TravelShiftSheet()),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Travel & Timezone Helper'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('StarlightBreathPage switches presets and honors reduceMotion',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: const MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: StarlightBreathPage(),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('Box 4-4-4-4'), findsOneWidget);
      await tester.tap(find.text('Box 4-4-4-4'));
      await tester.pump();
      expect(tester.takeException(), isNull);
    });

    testWidgets('JourneyTimelinePage handles empty state at 320dp and 1.6x textScale',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final sp = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sp),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.dark),
            home: const MediaQuery(
              data: MediaQueryData(textScaler: TextScaler.linear(1.6)),
              child: JourneyTimelinePage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Journey Timeline'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
