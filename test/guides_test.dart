import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunera/guides_data.dart';
import 'package:lunera/l10n.dart';
import 'package:lunera/theme.dart';
import 'package:lunera/ui/article_page.dart';
import 'package:lunera/ui/guides_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    L10n.notifier.value = 'en';
    SharedPreferences.setMockInitialValues({});
  });

  tearDown(() {
    L10n.notifier.value = 'en';
  });

  group('Care & HRT Guides data integrity', () {
    test('contains 13 articles with unique IDs and single start_safely entry',
        () {
      expect(guideArticles.length, equals(13));
      final ids = guideArticles.map((a) => a.id).toSet();
      expect(ids.length, equals(guideArticles.length));

      final startEntries = guideArticles.where((a) => a.isStartHere).toList();
      expect(startEntries.length, equals(1));
      expect(startEntries.first.id, equals('start_safely'));
    });

    test('every article has complete EN and ID fields and trusted references',
        () {
      for (final a in guideArticles) {
        expect(a.readMinutes, greaterThan(0), reason: a.id);
        expect(a.titleEn.trim(), isNotEmpty, reason: a.id);
        expect(a.titleId.trim(), isNotEmpty, reason: a.id);
        expect(a.subtitleEn.trim(), isNotEmpty, reason: a.id);
        expect(a.subtitleId.trim(), isNotEmpty, reason: a.id);
        expect(a.takeawaysEn, isNotEmpty, reason: a.id);
        expect(a.takeawaysId, isNotEmpty, reason: a.id);
        expect(a.sections, isNotEmpty, reason: a.id);
        expect(a.references, isNotEmpty, reason: a.id);

        for (final s in a.sections) {
          expect(s.headingEn.trim(), isNotEmpty, reason: a.id);
          expect(s.headingId.trim(), isNotEmpty, reason: a.id);
          expect(
            s.paragraphsEn.isNotEmpty || s.bulletsEn.isNotEmpty,
            isTrue,
            reason: '${a.id}:${s.headingEn}',
          );
          expect(
            s.paragraphsId.isNotEmpty || s.bulletsId.isNotEmpty,
            isTrue,
            reason: '${a.id}:${s.headingId}',
          );
          if (s.callout != null) {
            expect(s.callout!.titleEn.trim(), isNotEmpty, reason: a.id);
            expect(s.callout!.titleId.trim(), isNotEmpty, reason: a.id);
            expect(s.callout!.bodyEn.trim(), isNotEmpty, reason: a.id);
            expect(s.callout!.bodyId.trim(), isNotEmpty, reason: a.id);
          }
        }
      }
    });

    test('guideById resolves known guides and returns null for unknown IDs',
        () {
      expect(guideById('peak_trough')?.id, equals('peak_trough'));
      expect(guideById('site_rotation')?.id, equals('site_rotation'));
      expect(guideById('non_existent_guide'), isNull);
    });
  });

  group('GuidesPage & ArticlePage widget tests', () {
    testWidgets('renders Start Here card, filters categories, and opens article',
        (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: const GuidesPage(),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Care & HRT Guides'), findsOneWidget);
      expect(find.text('Start here'), findsOneWidget);
      expect(find.text('Starting HRT Safely & Navigating Independently'),
          findsOneWidget);
      expect(find.text('HRT 101: Estradiol, Testosterone & Blockers'),
          findsOneWidget);

      // Filter by Labs category
      await tester.tap(find.widgetWithText(ChoiceChip, 'Labs'));
      await tester.pumpAndSettle();

      expect(find.text('Peak, Trough & Steady State Explained'), findsOneWidget);
      expect(find.text('HRT 101: Estradiol, Testosterone & Blockers'),
          findsNothing);

      // Tap shortcut card directly into ArticlePage
      await tester.tap(find.text('Peak, Trough & Steady State Explained'));
      await tester.pumpAndSettle();

      expect(find.byType(ArticlePage), findsOneWidget);
      expect(find.text('Key takeaways'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Trusted references'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Medical Disclaimer'), findsOneWidget);
      expect(find.text('Trusted references'), findsOneWidget);
    });

    testWidgets('switches article content to Indonesian when L10n is id',
        (tester) async {
      L10n.notifier.value = 'id';
      final article = guideById('start_safely')!;

      await tester.pumpWidget(
        MaterialApp(
          theme: buildTheme(Brightness.dark),
          home: ArticlePage(article: article),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Memulai HRT dengan Aman & Menavigasi Secara Mandiri'),
          findsOneWidget);
      expect(find.text('Poin utama'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.text('Referensi tepercaya'),
        300,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.text('Referensi tepercaya'), findsOneWidget);
    });
  });
}
