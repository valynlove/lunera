import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunera/l10n.dart';
import 'package:lunera/models.dart';
import 'package:lunera/notifications.dart';
import 'package:lunera/profile.dart';
import 'package:lunera/repo.dart';
import 'package:lunera/theme.dart';
import 'package:lunera/widget_sync.dart';
import 'package:lunera/ui/sanctuary/coach_avatar.dart';
import 'package:lunera/ui/sanctuary/sanctuary_page.dart';
import 'package:lunera/ui/sanctuary/workout_page.dart';
import 'package:lunera/ui/sanctuary/workout_session_page.dart';
import 'package:lunera/workout_catalog.dart';
import 'package:lunera/workout_coach.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    L10n.notifier.value = 'en';
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    L10n.notifier.value = 'en';
  });

  group('Official Exercise Catalog & Presets', () {
    test('all exercises have complete EN/ID instructions, cues, easier variants & official refs', () {
      expect(workoutExercises.length, greaterThanOrEqualTo(16));
      final ids = <String>{};
      for (final ex in workoutExercises) {
        expect(ids.add(ex.id), isTrue, reason: 'Duplicate id: ${ex.id}');
        expect(ex.nameEn.trim(), isNotEmpty);
        expect(ex.nameId.trim(), isNotEmpty);
        expect(ex.stepsEn.length, greaterThanOrEqualTo(2));
        expect(ex.stepsId.length, equals(ex.stepsEn.length));
        expect(ex.breathCueEn.trim(), isNotEmpty);
        expect(ex.breathCueId.trim(), isNotEmpty);
        expect(ex.easierVariantEn.trim(), isNotEmpty);
        expect(ex.easierVariantId.trim(), isNotEmpty);
        expect(ex.sourceRef.trim(), isNotEmpty);
      }

      final presets = buildPresetRoutines('steady');
      expect(presets.length, equals(4));
      expect(presets.map((r) => r.category).toSet(),
          equals({'feminizing', 'masculinizing', 'bone_heart', 'recovery'}));
    });

    test('all 16 sporty CoachMood PNG assets exist on disk', () {
      expect(CoachMood.values.length, equals(16));
      for (final mood in CoachMood.values) {
        expect(
          File(mood.assetPath).existsSync(),
          isTrue,
          reason: 'Missing coach mascot asset: ${mood.assetPath}',
        );
      }
    });
  });

  group('Adaptive Personal Coach Engine', () {
    test('calibrateBaselineLevel maps comfort answers to gentle, steady, and active', () {
      expect(
        calibrateBaselineLevel(squatComfort: 0, pushupComfort: 0, plankComfort: 0),
        equals('gentle'),
      );
      expect(
        calibrateBaselineLevel(squatComfort: 1, pushupComfort: 1, plankComfort: 0),
        equals('steady'),
      );
      expect(
        calibrateBaselineLevel(squatComfort: 2, pushupComfort: 2, plankComfort: 1),
        equals('active'),
      );
    });

    test('injection-day and site-aware adaptation avoids injected zone', () {
      final now = DateTime(2026, 11, 25, 18, 0);
      final injTherapy = Therapy(
        id: 't_ev',
        hormoneId: 'estradiol',
        name: 'Estradiol Valerate',
        dose: 4,
        doseUnit: 'mg',
        start: DateTime(2026, 11, 1),
        everyDays: 7,
        route: 'inj',
      );
      final recentThighLog = DoseLog(
        id: 'log_1',
        therapyId: 't_ev',
        at: now.subtract(const Duration(hours: 6)),
        places: const ['Left thigh'],
        injType: 'im',
      );

      final rec = evaluateCoachContext(
        now: now,
        profile: const WorkoutProfile(onboarded: true, focus: 'feminizing'),
        workoutLogs: const [],
        therapies: [injTherapy],
        doseLogs: [recentThighLog],
        prefs: const Prefs(),
      );

      expect(rec.kind, equals(CoachContextKind.injectionCare));
      expect(rec.coachMood, equals(CoachMood.care));
      expect(rec.avoidedZone, equals('lower'));
      expect(rec.recommendedRoutine.category, isNot(equals('feminizing')));
      expect(rec.suggestLightMode, isTrue);

      final recentArmLog = DoseLog(
        id: 'log_2',
        therapyId: 't_ev',
        at: now.subtract(const Duration(hours: 4)),
        places: const ['Right arm'],
        injType: 'subq',
      );
      final recArm = evaluateCoachContext(
        now: now,
        profile: const WorkoutProfile(onboarded: true, focus: 'masculinizing'),
        workoutLogs: const [],
        therapies: [injTherapy],
        doseLogs: [recentArmLog],
        prefs: const Prefs(),
      );
      expect(recArm.avoidedZone, equals('upper'));
      expect(recArm.recommendedRoutine.category, equals('feminizing'));
    });

    test('trough window pre-selects Light Mode and applyLightMode scales sets down', () {
      final now = DateTime(2026, 11, 25, 22, 0);
      final injTherapy = Therapy(
        id: 't_ev',
        hormoneId: 'estradiol',
        name: 'Estradiol Valerate',
        dose: 4,
        doseUnit: 'mg',
        start: DateTime(2026, 11, 12),
        everyDays: 7,
        route: 'inj',
        times: const ['20:00'],
      );
      final priorLog = DoseLog(
        id: 'log_old',
        therapyId: 't_ev',
        at: DateTime(2026, 11, 19, 20, 0),
      );

      final rec = evaluateCoachContext(
        now: now,
        profile: const WorkoutProfile(onboarded: true, focus: 'bone_heart', level: 'steady'),
        workoutLogs: const [],
        therapies: [injTherapy],
        doseLogs: [priorLog],
        prefs: const Prefs(),
      );
      expect(rec.kind, equals(CoachContextKind.troughGentle));
      expect(rec.suggestLightMode, isTrue);

      final light = applyLightMode(rec.recommendedRoutine);
      expect(light.items.first.sets, lessThanOrEqualTo(rec.recommendedRoutine.items.first.sets));
      expect(light.items.every((i) => i.useEasierVariant), isTrue);
    });

    test('gentle restart triggers after >= 5 days away without streak penalty', () {
      final now = DateTime(2026, 11, 25, 18, 0);
      final oldLog = WorkoutSessionLog(
        id: 'wl1',
        at: now.subtract(const Duration(days: 6)),
        routineId: 'preset_bone_heart',
        routineTitle: 'Bone & Heart Care',
      );
      final rec = evaluateCoachContext(
        now: now,
        profile: const WorkoutProfile(onboarded: true, focus: 'bone_heart'),
        workoutLogs: [oldLog],
        therapies: const [],
        doseLogs: const [],
        prefs: const Prefs(),
      );
      expect(rec.kind, equals(CoachContextKind.easeBackIn));
      expect(rec.coachMood, equals(CoachMood.greet));
      expect(rec.recommendedRoutine.id, equals('preset_ease_back_in'));
      expect(rec.totalSessions, equals(1));
    });

    test('rest today is honored warmly and applyEffortFeedback calibrates gently', () {
      final now = DateTime(2026, 11, 25, 18, 0);
      final rec = evaluateCoachContext(
        now: now,
        profile: WorkoutProfile(
          onboarded: true,
          skippedDateIso: isoDateOf(now),
        ),
        workoutLogs: const [],
        therapies: const [],
        doseLogs: const [],
        prefs: const Prefs(),
      );
      expect(rec.kind, equals(CoachContextKind.restedToday));
      expect(rec.coachMood, equals(CoachMood.rest));

      const startProfile = WorkoutProfile(onboarded: true, level: 'gentle');
      final (afterFirstEasy, _) = applyEffortFeedback(startProfile, 'easy');
      expect(afterFirstEasy.level, equals('gentle'));
      expect(afterFirstEasy.consecutiveEasyCount, equals(1));

      final (afterSecondEasy, notice) = applyEffortFeedback(afterFirstEasy, 'easy');
      expect(afterSecondEasy.level, equals('steady'));
      expect(afterSecondEasy.consecutiveEasyCount, equals(0));
      expect(notice, isNotNull);

      final (afterTough, _) = applyEffortFeedback(afterSecondEasy, 'tough');
      expect(afterTough.level, equals('steady'));
    });

    test('workout notification copy respects discreet privacy settings', () {
      const profile = WorkoutProfile(notifyWorkout: true, reminderTime: '18:30');
      expect(
        workoutNotificationText(profile, const Prefs(discreetNotify: 'minimal')),
        equals(('Lunera ✦', 'Gentle reminder.')),
      );
      final (wTitle, wBody) = workoutNotificationText(
        profile,
        const Prefs(discreetNotify: 'wellness'),
      );
      expect(wTitle, equals('Movement Window ✦'));
      expect(wBody, isNot(contains('HRT')));

      final (stdTitle, stdBody) = workoutNotificationText(
        profile,
        const Prefs(discreetNotify: 'off'),
      );
      expect(stdTitle, contains('Coach'));
      expect(stdBody, contains('18:30'));
    });
  });

  group('Backup Validation Backward-Compatibility', () {
    test('Repo.validate accepts workout sections and rejects corrupted workout rows', () {
      final repo = Repo('dummy_uid');
      final validBackup = {
        'metadata': {'app': 'lunera', 'version': 1},
        'data': {
          'workoutProfile': [
            {'id': 'main', 'onboarded': true, 'focus': 'feminizing'}
          ],
          'workoutRoutines': [
            {
              'id': 'custom_1',
              'title': 'Evening Core',
              'updatedAt': '2026-11-25T10:00:00.000Z',
            }
          ],
          'workoutLogs': [
            {
              'id': 'w1',
              'routineTitle': 'Evening Core',
              'at': '2026-11-25T10:30:00.000Z',
              'durationSec': 720,
            }
          ],
        },
      };
      expect(repo.validate(validBackup), equals(3));

      final badWorkoutLog = {
        'metadata': {'app': 'lunera', 'version': 1},
        'data': {
          'workoutLogs': [
            {
              'id': 'w1',
              'routineTitle': 'Evening Core',
              'at': '2026-11-25T10:30:00.000Z',
              'durationSec': -5,
            }
          ],
        },
      };
      expect(() => repo.validate(badWorkoutLog), throwsFormatException);
    });
  });

  group('Movement Coach Widget Flow', () {
    testWidgets('SanctuaryPage lists Movement Coach and WorkoutCoachPage completes onboarding + session flow', (tester) async {
      final sp = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sp),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.dark),
            home: const SanctuaryPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(find.text('Movement Coach'), 200);
      await tester.ensureVisible(find.text('Movement Coach'));
      await tester.pumpAndSettle();
      expect(find.text('Movement Coach'), findsOneWidget);

      await tester.tap(find.text('Movement Coach'));
      await tester.pumpAndSettle();

      expect(find.byType(WorkoutCoachPage), findsOneWidget);
      expect(find.text('Personal Coach Setup'), findsOneWidget);

      // Step 1 -> Step 2 (Baseline check)
      await tester.ensureVisible(find.text('Next: Baseline check'));
      await tester.tap(find.text('Next: Baseline check'));
      await tester.pumpAndSettle();
      expect(find.text('1. Comfortable squats'), findsOneWidget);

      // Step 2 -> Step 3 (Comfort schedule)
      await tester.ensureVisible(find.text('Next: Comfort schedule'));
      await tester.tap(find.text('Next: Comfort schedule'));
      await tester.pumpAndSettle();
      expect(find.text('Preferred days'), findsOneWidget);

      // Save & open dashboard
      await tester.ensureVisible(find.text('Save & open Movement Coach'));
      await tester.tap(find.text('Save & open Movement Coach'));
      await tester.pumpAndSettle();

      expect(find.text('Movement Coach'), findsOneWidget);
      expect(find.text('Total sessions'), findsOneWidget);

      // Interactive Body check-in updates coach headline
      await tester.tap(find.text('Body check-in'));
      await tester.pumpAndSettle();
      expect(find.text('Low energy'), findsOneWidget);

      await tester.tap(find.text('Low energy'));
      await tester.pumpAndSettle();
      expect(find.text('Lighter pace selected'), findsOneWidget);
    });

    testWidgets('WorkoutSessionPage guides 2-pose diagram, completes set, and saves Effort Check', (tester) async {
      final sp = await SharedPreferences.getInstance();
      final singleItemRoutine = WorkoutRoutine(
        id: 'test_r',
        title: 'Quick Test Flow',
        category: 'recovery',
        isCustom: false,
        estimatedMinutes: 5,
        updatedAt: DateTime(2026, 11, 25),
        items: const [
          WorkoutExerciseItem(exerciseId: 'glute_bridge', sets: 1, reps: 8),
        ],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sp),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.dark),
            home: WorkoutSessionPage(routine: singleItemRoutine),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Exercise 1 of 1'), findsOneWidget);
      expect(find.text('Start pose'), findsOneWidget);
      expect(find.text('End pose'), findsOneWidget);

      // Toggle End pose & complete the single set
      await tester.tap(find.text('End pose'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Complete set'));
      await tester.pumpAndSettle();

      // Finish session -> Effort Check
      await tester.tap(find.text('Finish session'));
      await tester.pumpAndSettle();

      expect(find.text('You showed up today'), findsOneWidget);
      expect(find.text("How did today's session feel?"), findsOneWidget);

      await tester.ensureVisible(find.text('Too easy'));
      await tester.tap(find.text('Too easy'));
      await tester.pumpAndSettle();

      final saved = await WorkoutController.loadDirect();
      expect(saved.logs.length, equals(1));
      expect(saved.logs.first.effort, equals('easy'));
    });

    testWidgets('WorkoutCoachPage renders Indonesian localization cleanly', (tester) async {
      L10n.notifier.value = 'id';
      final sp = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(sp),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.dark),
            home: const WorkoutCoachPage(),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Pengaturan Pelatih Pribadi'), findsOneWidget);
      expect(find.text('Lanjut: Cek kemampuan awal'), findsOneWidget);
    });

    test('workoutWidgetBackgroundCallback toggles Rest today cleanly', () async {
      await workoutWidgetBackgroundCallback(Uri.parse('lunera://workout/rest'));
      final afterRest = await WorkoutController.loadDirect();
      expect(afterRest.profile.skippedDateIso, equals(isoDateOf(DateTime.now())));

      await workoutWidgetBackgroundCallback(Uri.parse('lunera://workout/rest'));
      final afterResume = await WorkoutController.loadDirect();
      expect(afterResume.profile.skippedDateIso, isNull);
    });
  });
}
