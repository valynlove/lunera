import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lunera/l10n.dart';
import 'package:lunera/models.dart';
import 'package:lunera/repo.dart';
import 'package:lunera/schedule.dart';
import 'package:lunera/theme.dart';
import 'package:lunera/ui/calendar.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });

  setUp(() {
    L10n.notifier.value = 'en';
  });

  tearDown(() {
    L10n.notifier.value = 'en';
  });

  group('Trough Window & Month Grid logic unit tests', () {
    final injTherapy = Therapy(
      id: 'th-een',
      hormoneId: 'estradiol',
      name: 'Estradiol Enanthate',
      dose: 5.0,
      doseUnit: 'mg',
      start: DateTime(2025, 1, 1),
      route: 'inj',
      everyDays: 7,
    );

    final oralTherapy = Therapy(
      id: 'th-oral',
      hormoneId: 'spironolactone',
      name: 'Spironolactone',
      dose: 50.0,
      doseUnit: 'mg',
      start: DateTime(2025, 1, 1),
      route: 'oral',
      everyDays: 1,
    );

    final prnTherapy = Therapy(
      id: 'th-prn',
      hormoneId: 'estradiol',
      name: 'Estradiol Gel PRN',
      dose: 0.75,
      doseUnit: 'mg',
      start: DateTime(2025, 1, 1),
      route: 'transdermal_gel',
      kind: 'asneeded',
    );

    test('isTroughEligibleSlot returns true for injection and cyclical therapies', () {
      final slotInj = Slot(injTherapy, DateTime(2026, 11, 24), null, 'upcoming');
      final slotOral = Slot(oralTherapy, DateTime(2026, 11, 24), null, 'upcoming');
      final slotPrn = Slot(prnTherapy, DateTime(2026, 11, 24), null, 'upcoming');

      expect(isTroughEligibleSlot(slotInj), isTrue);
      expect(isTroughEligibleSlot(slotOral), isFalse);
      expect(isTroughEligibleSlot(slotPrn), isFalse);
    });

    test('computeTroughWindows extracts target date and therapy', () {
      final slot1 = Slot(injTherapy, DateTime(2026, 11, 24, 10, 0), null, 'upcoming');
      final slot2 = Slot(oralTherapy, DateTime(2026, 11, 24, 12, 0), null, 'upcoming');

      final windows = computeTroughWindows([slot1, slot2]);
      expect(windows.length, equals(1));
      expect(windows.first.therapy.id, equals('th-een'));
      expect(windows.first.targetDate, equals(DateTime(2026, 11, 24)));
    });

    test('buildMonthGridDays produces a clean 7-column grid spanning all days', () {
      final gridNov2026 = buildMonthGridDays(DateTime(2026, 11, 1));
      expect(gridNov2026.length % 7, equals(0));
      expect(gridNov2026.any((d) => d.day == 1 && d.month == 11), isTrue);
      expect(gridNov2026.any((d) => d.day == 30 && d.month == 11), isTrue);
    });
  });

  group('CalendarPage Pharmacokinetic Timeline widget tests', () {
    final injTherapy = Therapy(
      id: 'th-een',
      hormoneId: 'estradiol',
      name: 'Estradiol Enanthate',
      dose: 5.0,
      doseUnit: 'mg',
      start: DateTime(2025, 1, 1),
      route: 'inj',
      everyDays: 7,
    );

    testWidgets('toggles between Week View and Month View cleanly', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProvider.overrideWith((ref) => Stream.value(null)),
            therapiesProvider.overrideWith((ref) => Stream.value([injTherapy])),
            suppliesProvider.overrideWith((ref) => Stream.value(<Supply>[])),
            prefsProvider.overrideWith((ref) => Stream.value(const Prefs())),
            logsProvider.overrideWith((ref) => Stream.value(<DoseLog>[])),
            journalProvider.overrideWith((ref) => Stream.value(<JournalEntry>[])),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.dark),
            home: const Scaffold(
              body: CalendarPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalendarPage), findsOneWidget);
      expect(find.byIcon(LucideIcons.calendar), findsOneWidget);

      // Tap toggle to switch to Month View
      await tester.tap(find.byIcon(LucideIcons.calendar));
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.calendarRange), findsOneWidget);

      // Tap toggle to switch back to Week View
      await tester.tap(find.byIcon(LucideIcons.calendarRange));
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.calendar), findsOneWidget);
    });

    testWidgets('renders Optimal Trough Lab Window card on injection dose day',
        (tester) async {
      final now = DateTime.now();
      final todayTherapy = Therapy(
        id: 'th-een',
        hormoneId: 'estradiol',
        name: 'Estradiol Enanthate',
        dose: 5.0,
        doseUnit: 'mg',
        start: DateTime(now.year, now.month, now.day),
        route: 'inj',
        everyDays: 7,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProvider.overrideWith((ref) => Stream.value(null)),
            therapiesProvider.overrideWith((ref) => Stream.value([todayTherapy])),
            suppliesProvider.overrideWith((ref) => Stream.value(<Supply>[])),
            prefsProvider.overrideWith((ref) => Stream.value(const Prefs())),
            logsProvider.overrideWith((ref) => Stream.value(<DoseLog>[])),
            journalProvider.overrideWith((ref) => Stream.value(<JournalEntry>[])),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.dark),
            home: const Scaffold(
              body: CalendarPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(tr('Optimal Trough Lab Window')), findsOneWidget);
      expect(find.byIcon(LucideIcons.flaskConical), findsOneWidget);
      expect(find.textContaining('Estradiol Enanthate'), findsWidgets);
    });

    testWidgets('renders Indonesian localization cleanly on Month view and Trough card',
        (tester) async {
      L10n.notifier.value = 'id';
      final now = DateTime.now();
      final todayTherapy = Therapy(
        id: 'th-een',
        hormoneId: 'estradiol',
        name: 'Estradiol Enanthate',
        dose: 5.0,
        doseUnit: 'mg',
        start: DateTime(now.year, now.month, now.day),
        route: 'inj',
        everyDays: 7,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProvider.overrideWith((ref) => Stream.value(null)),
            therapiesProvider.overrideWith((ref) => Stream.value([todayTherapy])),
            suppliesProvider.overrideWith((ref) => Stream.value(<Supply>[])),
            prefsProvider.overrideWith((ref) => Stream.value(const Prefs())),
            logsProvider.overrideWith((ref) => Stream.value(<DoseLog>[])),
            journalProvider.overrideWith((ref) => Stream.value(<JournalEntry>[])),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.dark),
            home: const Scaffold(
              body: CalendarPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Waktu Tes Lab Trough Terbaik'), findsOneWidget);
    });
  });
}
