import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunera/guides_data.dart';
import 'package:lunera/l10n.dart';
import 'package:lunera/sanctuary_data.dart';
import 'package:lunera/theme.dart';
import 'package:lunera/ui/sanctuary/moonlight_lantern_page.dart';
import 'package:lunera/ui/sanctuary/safety_quiz_page.dart';
import 'package:lunera/ui/sanctuary/sanctuary_page.dart';
import 'package:lunera/ui/sanctuary/starlight_breath_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    L10n.notifier.value = 'en';
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    L10n.notifier.value = 'en';
  });

  group('Safety & Dosing Sense quiz bank', () {
    test('has 12 unique bilingual questions with valid answers and guide links',
        () {
      expect(safetyQuizQuestions.length, equals(12));
      final ids = safetyQuizQuestions.map((q) => q.id).toSet();
      expect(ids.length, equals(safetyQuizQuestions.length));

      for (final q in safetyQuizQuestions) {
        expect(q.questionEn.trim(), isNotEmpty, reason: q.id);
        expect(q.questionId.trim(), isNotEmpty, reason: q.id);
        expect(q.optionsEn.length, greaterThanOrEqualTo(3), reason: q.id);
        expect(q.optionsId.length, equals(q.optionsEn.length), reason: q.id);
        expect(q.correctIndex, inInclusiveRange(0, q.optionsEn.length - 1),
            reason: q.id);
        expect(q.explanationEn.trim(), isNotEmpty, reason: q.id);
        expect(q.explanationId.trim(), isNotEmpty, reason: q.id);
        if (q.relatedGuideId != null) {
          expect(guideById(q.relatedGuideId!), isNotNull,
              reason: '${q.id} -> ${q.relatedGuideId}');
        }
      }
    });

    test('switches getters between English and Indonesian', () {
      final q = safetyQuizQuestions.first;
      expect(q.question, equals(q.questionEn));
      expect(q.options, equals(q.optionsEn));
      expect(q.explanation, equals(q.explanationEn));

      L10n.notifier.value = 'id';
      expect(q.question, equals(q.questionId));
      expect(q.options, equals(q.optionsId));
      expect(q.explanation, equals(q.explanationId));
    });

    test('pickQuizRound returns 5 unique questions', () {
      final round = pickQuizRound(count: 5, random: math.Random(42));
      expect(round.length, equals(5));
      expect(round.map((q) => q.id).toSet().length, equals(5));
    });
  });

  group('SanctuaryStore persistence & no-punishment behavior', () {
    test('initial state starts at 0 sparks and allows lighting today', () async {
      final state = await SanctuaryStore.load();
      expect(state.sparks, equals(0));
      expect(state.stage, equals(0));
      expect(state.quizBest, equals(0));
      expect(state.canLightToday(DateTime(2026, 11, 22)), isTrue);
    });

    test('lights at most once per day and never decreases after skipped days',
        () async {
      final day1 = DateTime(2026, 11, 22, 9, 0);
      final afterFirst = await SanctuaryStore.lightTodaySpark(now: day1);
      expect(afterFirst.sparks, equals(1));
      expect(afterFirst.stage, equals(1));
      expect(afterFirst.canLightToday(day1), isFalse);

      // Calling again on the same day does not double-increment
      final sameDayAgain = await SanctuaryStore.lightTodaySpark(
        now: DateTime(2026, 11, 22, 22, 30),
      );
      expect(sameDayAgain.sparks, equals(1));

      // Skipping 5 days later: sparks never decay and increment by +1 cleanly
      final fiveDaysLater = DateTime(2026, 11, 27, 8, 15);
      expect(sameDayAgain.canLightToday(fiveDaysLater), isTrue);
      final next = await SanctuaryStore.lightTodaySpark(now: fiveDaysLater);
      expect(next.sparks, equals(2));
      expect(next.stage, equals(1));

      final nextDay = DateTime(2026, 11, 28, 8, 15);
      final third = await SanctuaryStore.lightTodaySpark(now: nextDay);
      expect(third.sparks, equals(3));
      expect(third.stage, equals(2));
    });

    test('recordQuizScore keeps the highest score and never lowers it',
        () async {
      expect(await SanctuaryStore.recordQuizScore(3), equals(3));
      expect(await SanctuaryStore.recordQuizScore(5), equals(5));
      expect(await SanctuaryStore.recordQuizScore(2), equals(5));

      final state = await SanctuaryStore.load();
      expect(state.quizBest, equals(5));
    });
  });

  group('Twilight Sanctuary widget tests', () {
    testWidgets('SanctuaryPage displays 3 cards and navigates to StarlightBreathPage',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: const SanctuaryPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Twilight Sanctuary'), findsOneWidget);
      expect(find.text('Starlight Ripples & Breath'), findsOneWidget);
      expect(find.text('Safety & Dosing Sense'), findsOneWidget);
      expect(find.text('Moonlight Lantern'), findsOneWidget);

      await tester.tap(find.text('Starlight Ripples & Breath'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.byType(StarlightBreathPage), findsOneWidget);
      expect(find.text('Tap anywhere on the lake to send ripples of light'),
          findsOneWidget);
      expect(find.text('Pause breath'), findsOneWidget);
    });

    testWidgets(
        'SafetyQuizPage reveals explanation, advances round, and persists best score',
        (tester) async {
      final subset = safetyQuizQuestions.take(2).toList();
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: SafetyQuizPage(questions: subset),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Question 1 of 2'), findsOneWidget);
      await tester.tap(find.text(subset[0].options[subset[0].correctIndex]));
      await tester.pumpAndSettle();

      expect(find.text('Nice work!'), findsOneWidget);
      expect(find.text(subset[0].explanation), findsOneWidget);
      expect(find.text('Read related guide'), findsOneWidget);

      await tester.ensureVisible(find.text('Next question'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Next question'));
      await tester.pumpAndSettle();

      expect(find.text('Question 2 of 2'), findsOneWidget);
      await tester.tap(find.text(subset[1].options[subset[1].correctIndex]));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('See summary'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('See summary'));
      await tester.pumpAndSettle();

      expect(find.text('Round Complete'), findsOneWidget);
      expect(find.text('2 / 2'), findsOneWidget);
      final saved = await SanctuaryStore.load();
      expect(saved.quizBest, equals(2));
    });

    testWidgets('MoonlightLanternPage lights today spark once cleanly',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: const MoonlightLanternPage(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('0 sparks lit'), findsOneWidget);
      expect(find.text("Light today's gentle spark"), findsOneWidget);

      await tester.tap(find.text("Light today's gentle spark"));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('1 spark lit'), findsOneWidget);
      expect(
        find.text("Today's spark is glowing. Come back whenever you like."),
        findsOneWidget,
      );
    });

    testWidgets('SanctuaryPage renders Indonesian localization cleanly',
        (tester) async {
      L10n.notifier.value = 'id';
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: const SanctuaryPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Suaka Senja'), findsOneWidget);
      expect(find.text('Riak Bintang & Napas Tenang'), findsOneWidget);
      expect(find.text('Kepekaan Keamanan & Dosis'), findsOneWidget);
      expect(find.text('Lentera Cahaya Bulan'), findsOneWidget);
    });
  });
}
