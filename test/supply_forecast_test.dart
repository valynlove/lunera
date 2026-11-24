import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lunera/l10n.dart';
import 'package:lunera/models.dart';
import 'package:lunera/repo.dart';
import 'package:lunera/schedule.dart';
import 'package:lunera/theme.dart';
import 'package:lunera/ui/pickup_assistant_sheet.dart';
import 'package:lunera/ui/supplies.dart';

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

  group('estimateSupplyForecast unit tests', () {
    final dailyOralTherapy = Therapy(
      id: 'th-prog',
      hormoneId: 'progesterone',
      name: 'Progesterone Micronized',
      dose: 100.0,
      doseUnit: 'mg',
      start: DateTime(2025, 1, 1),
      route: 'oral',
      everyDays: 1,
      times: const ['22:00'],
      supplyId: 'sup-prog',
    );

    final injTherapy = Therapy(
      id: 'th-een',
      hormoneId: 'estradiol',
      name: 'Estradiol Enanthate',
      dose: 5.0,
      doseUnit: 'mg',
      start: DateTime(2025, 1, 1),
      route: 'inj',
      everyDays: 7,
      supplyId: 'sup-een',
    );

    test('evaluates to depleted when quantity is zero or less', () {
      final now = DateTime(2026, 11, 24);
      const supply = Supply(
        id: 'sup-prog',
        name: 'Progesterone 100mg',
        qty: 0,
        initial: 30,
        perDose: 1,
      );

      final forecast = estimateSupplyForecast(
        supply,
        [dailyOralTherapy],
        now: now,
      );

      expect(forecast, isNotNull);
      expect(forecast!.daysLeft, equals(0));
      expect(forecast.urgency, equals(RefillUrgency.depleted));
      expect(forecast.needsReorder, isTrue);
      expect(forecast.runOutDate, equals(now));
      expect(forecast.reorderDate, equals(now));
    });

    test('evaluates to critical when remaining days are within 7-day buffer', () {
      final now = DateTime(2026, 11, 24);
      // 5 pills left on 1 pill/day = 5 days left <= 7 days buffer
      const supply = Supply(
        id: 'sup-prog',
        name: 'Progesterone 100mg',
        qty: 5,
        initial: 30,
        perDose: 1,
      );

      final forecast = estimateSupplyForecast(
        supply,
        [dailyOralTherapy],
        now: now,
      );

      expect(forecast, isNotNull);
      expect(forecast!.daysLeft, equals(5));
      expect(forecast.urgency, equals(RefillUrgency.critical));
      expect(forecast.needsReorder, isTrue);
      expect(forecast.runOutDate, equals(DateTime(2026, 11, 29)));
      // Reorder date clamps to now because daysLeft (5) <= buffer (7)
      expect(forecast.reorderDate, equals(now));
    });

    test('evaluates to reorderSoon when remaining days are 8..14 days', () {
      final now = DateTime(2026, 11, 24);
      // 10 pills left on 1 pill/day = 10 days left
      const supply = Supply(
        id: 'sup-prog',
        name: 'Progesterone 100mg',
        qty: 10,
        initial: 30,
        perDose: 1,
      );

      final forecast = estimateSupplyForecast(
        supply,
        [dailyOralTherapy],
        now: now,
      );

      expect(forecast, isNotNull);
      expect(forecast!.daysLeft, equals(10));
      expect(forecast.urgency, equals(RefillUrgency.reorderSoon));
      expect(forecast.needsReorder, isTrue);
      expect(forecast.runOutDate, equals(DateTime(2026, 12, 4)));
      // reorder date = now + (10 - 7) = now + 3 days (Nov 27)
      expect(forecast.reorderDate, equals(DateTime(2026, 11, 27)));
    });

    test('evaluates to healthy when remaining days exceed 14 days', () {
      final now = DateTime(2026, 11, 24);
      // 28 pills left on 1 pill/day = 28 days left
      const supply = Supply(
        id: 'sup-prog',
        name: 'Progesterone 100mg',
        qty: 28,
        initial: 30,
        perDose: 1,
      );

      final forecast = estimateSupplyForecast(
        supply,
        [dailyOralTherapy],
        now: now,
      );

      expect(forecast, isNotNull);
      expect(forecast!.daysLeft, equals(28));
      expect(forecast.urgency, equals(RefillUrgency.healthy));
      expect(forecast.needsReorder, isFalse);
      expect(forecast.runOutDate, equals(DateTime(2026, 12, 22)));
    });

    test('calculates generic supply forecast across injection therapies', () {
      final now = DateTime(2026, 11, 24);
      // Syringes: 4 syringes left. Inj is every 7 days (1/7 dose per day).
      // 4 syringes / (1/7) = 28 days left.
      const syringes = Supply(
        id: 'sup-syr',
        name: '1mL Luer Lock Syringe',
        qty: 4,
        initial: 10,
        perDose: 1,
        kind: 'generic',
        gtype: 'syringe',
      );

      final forecast = estimateSupplyForecast(
        syringes,
        [injTherapy],
        now: now,
      );

      expect(forecast, isNotNull);
      expect(forecast!.daysLeft, equals(28));
      expect(forecast.urgency, equals(RefillUrgency.healthy));
    });
  });

  group('SuppliesPage Refill Horizon widget tests', () {
    final dailyOralTherapy = Therapy(
      id: 'th-prog',
      hormoneId: 'progesterone',
      name: 'Progesterone Micronized',
      dose: 100.0,
      doseUnit: 'mg',
      start: DateTime(2025, 1, 1),
      route: 'oral',
      everyDays: 1,
      times: const ['22:00'],
      supplyId: 'sup-prog',
    );

    testWidgets('renders critical reorder banner and chip when stock is under 7 days',
        (tester) async {
      const criticalSupply = Supply(
        id: 'sup-prog',
        name: 'Progesterone Micronized',
        qty: 4,
        initial: 30,
        perDose: 1,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProvider.overrideWith((ref) => Stream.value(null)),
            therapiesProvider.overrideWith((ref) => Stream.value([dailyOralTherapy])),
            suppliesProvider.overrideWith((ref) => Stream.value([criticalSupply])),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.dark),
            home: const Scaffold(
              body: SuppliesPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(SuppliesPage), findsOneWidget);
      expect(find.text(tr('1 item needs urgent reorder')), findsOneWidget);
      expect(find.textContaining('Order now • Depletes on'), findsOneWidget);

      // Tap on Open button in banner
      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      expect(find.byType(PickupAssistantSheet), findsOneWidget);
    });

    testWidgets('renders reorderSoon chip and Indonesian localization cleanly',
        (tester) async {
      L10n.notifier.value = 'id';
      const reorderSoonSupply = Supply(
        id: 'sup-prog',
        name: 'Progesterone Micronized',
        qty: 10,
        initial: 30,
        perDose: 1,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProvider.overrideWith((ref) => Stream.value(null)),
            therapiesProvider.overrideWith((ref) => Stream.value([dailyOralTherapy])),
            suppliesProvider.overrideWith((ref) => Stream.value([reorderSoonSupply])),
          ],
          child: MaterialApp(
            theme: buildTheme(Brightness.dark),
            home: const Scaffold(
              body: SuppliesPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Jendela pemesanan ulang mendekat untuk 1 barang'), findsOneWidget);
      expect(find.textContaining('Pesan sebelum'), findsOneWidget);
    });
  });
}
