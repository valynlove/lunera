import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lunera/l10n.dart';
import 'package:lunera/models.dart';
import 'package:lunera/schedule.dart';
import 'package:lunera/theme.dart';
import 'package:lunera/ui/ambient_companion.dart';
import 'package:lunera/ui/companion_avatar.dart';

void main() {
  setUp(() {
    L10n.notifier.value = 'en';
  });

  tearDown(() {
    L10n.notifier.value = 'en';
  });

  group('evaluateAmbientCompanion unit tests', () {
    final injTherapy = Therapy(
      id: 'th-inj',
      hormoneId: 'estradiol',
      name: 'Estradiol Valerate',
      dose: 4.0,
      doseUnit: 'mg',
      start: DateTime(2025, 1, 1),
      route: 'inj',
      everyDays: 5,
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

    test('evaluates to Gentle Post-Care when injection dose was logged within 24h', () {
      final now = DateTime(2026, 11, 24, 14, 0);
      final log = DoseLog(
        id: 'log-1',
        therapyId: 'th-inj',
        at: now.subtract(const Duration(hours: 3)),
        dose: 4.0,
      );

      final status = evaluateAmbientCompanion(
        now: now,
        logs: [log],
        slots: const [],
        therapies: [injTherapy],
      );

      expect(status.mood, equals(CompanionMood.care));
      expect(status.headline, equals('Gentle Post-Care'));
      expect(status.glowColor, equals(C.peony));
      expect(status.tag, equals('post_dose'));
    });

    test('evaluates to Nurturing Rhythm when oral dose was logged within 24h', () {
      final now = DateTime(2026, 11, 24, 14, 0);
      final log = DoseLog(
        id: 'log-2',
        therapyId: 'th-oral',
        at: now.subtract(const Duration(hours: 2)),
        dose: 50.0,
      );

      final status = evaluateAmbientCompanion(
        now: now,
        logs: [log],
        slots: const [],
        therapies: [oralTherapy],
      );

      expect(status.mood, equals(CompanionMood.care));
      expect(status.headline, equals('Nurturing Rhythm'));
      expect(status.glowColor, equals(C.peony));
      expect(status.tag, equals('post_dose'));
    });

    test('evaluates to Gentle Horizon when slot is pending within next 2h', () {
      final now = DateTime(2026, 11, 24, 11, 0);
      final slot = Slot(
        oralTherapy,
        now.add(const Duration(minutes: 45)),
        null,
        'upcoming',
      );

      final status = evaluateAmbientCompanion(
        now: now,
        logs: const [],
        slots: [slot],
        therapies: [oralTherapy],
      );

      expect(status.mood, equals(CompanionMood.remind));
      expect(status.headline, equals('Gentle Horizon'));
      expect(status.glowColor, equals(C.lavender));
      expect(status.tag, equals('upcoming_dose'));
    });

    test('upcoming imminent dose takes precedence over earlier dose within recovery window', () {
      final now = DateTime(2026, 11, 24, 19, 0);
      final earlierLog = DoseLog(
        id: 'log-prev',
        therapyId: 'th-oral',
        at: now.subtract(const Duration(hours: 2)),
        dose: 50.0,
      );
      final upcomingSlot = Slot(
        oralTherapy,
        now.add(const Duration(minutes: 30)),
        null,
        'upcoming',
      );

      final status = evaluateAmbientCompanion(
        now: now,
        logs: [earlierLog],
        slots: [upcomingSlot],
        therapies: [oralTherapy],
      );

      expect(status.mood, equals(CompanionMood.remind));
      expect(status.headline, equals('Gentle Horizon'));
      expect(status.tag, equals('upcoming_dose'));
    });

    test('evaluates to Quiet Night during late night hours', () {
      final now = DateTime(2026, 11, 24, 2, 30);
      final status = evaluateAmbientCompanion(
        now: now,
        logs: const [],
        slots: const [],
        therapies: [oralTherapy],
      );

      expect(status.mood, equals(CompanionMood.sleepy));
      expect(status.headline, equals('Quiet Night'));
      expect(status.glowColor, equals(C.indigo));
      expect(status.tag, equals('night'));
    });

    test('evaluates to Morning Light during morning hours', () {
      final now = DateTime(2026, 11, 24, 8, 15);
      final status = evaluateAmbientCompanion(
        now: now,
        logs: const [],
        slots: const [],
        therapies: [oralTherapy],
      );

      expect(status.mood, equals(CompanionMood.wave));
      expect(status.headline, equals('Morning Light'));
      expect(status.glowColor, equals(C.aurora));
      expect(status.tag, equals('morning'));
    });

    test('evaluates to Radiant Afternoon during afternoon hours', () {
      final now = DateTime(2026, 11, 24, 13, 0);
      final status = evaluateAmbientCompanion(
        now: now,
        logs: const [],
        slots: const [],
        therapies: [oralTherapy],
      );

      expect(status.mood, equals(CompanionMood.cheer));
      expect(status.headline, equals('Radiant Afternoon'));
      expect(status.glowColor, equals(C.coral));
      expect(status.tag, equals('afternoon'));
    });

    test('evaluates to Evening Serenity during evening twilight hours', () {
      final now = DateTime(2026, 11, 24, 19, 30);
      final status = evaluateAmbientCompanion(
        now: now,
        logs: const [],
        slots: const [],
        therapies: [oralTherapy],
      );

      expect(status.mood, equals(CompanionMood.calm));
      expect(status.headline, equals('Evening Serenity'));
      expect(status.glowColor, equals(C.lavender));
      expect(status.tag, equals('evening'));
    });
  });

  group('AmbientCompanionCard widget tests', () {
    final oralTherapy = Therapy(
      id: 'th-1',
      hormoneId: 'spironolactone',
      name: 'Spironolactone',
      dose: 50.0,
      doseUnit: 'mg',
      start: DateTime(2025, 1, 1),
      route: 'oral',
      everyDays: 1,
    );

    testWidgets('renders companion card with headline and tap prompt', (tester) async {
      final now = DateTime(2026, 11, 24, 9, 0); // Morning

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildTheme(Brightness.dark),
            home: Scaffold(
              body: AmbientCompanionCard(
                now: now,
                logs: const [],
                slots: const [],
                therapies: [oralTherapy],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(AmbientCompanionCard), findsOneWidget);
      expect(find.byType(CompanionAvatar), findsOneWidget);
      expect(find.text('Morning Light'), findsOneWidget);
      expect(find.text(tr('Tap for gentle thought')), findsOneWidget);
    });

    testWidgets('tapping card transitions to Gentle Thought affirmation and can reset',
        (tester) async {
      final now = DateTime(2026, 11, 24, 9, 0);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildTheme(Brightness.dark),
            home: Scaffold(
              body: AmbientCompanionCard(
                now: now,
                logs: const [],
                slots: const [],
                therapies: [oralTherapy],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the card to cycle to affirmation
      await tester.tap(find.text('Morning Light'));
      await tester.pumpAndSettle();

      expect(find.text('Gentle Thought'), findsOneWidget);
      expect(find.text(tr('Tap for another thought')), findsOneWidget);
      expect(find.text(companionAffirmations.first), findsOneWidget);
      expect(find.byIcon(LucideIcons.rotateCcw), findsOneWidget);

      // Tap reset button to return to status headline
      await tester.tap(find.byIcon(LucideIcons.rotateCcw));
      await tester.pumpAndSettle();

      expect(find.text('Morning Light'), findsOneWidget);
    });

    testWidgets('dismiss icon hides card from view', (tester) async {
      final now = DateTime(2026, 11, 24, 9, 0);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildTheme(Brightness.dark),
            home: Scaffold(
              body: AmbientCompanionCard(
                now: now,
                logs: const [],
                slots: const [],
                therapies: [oralTherapy],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CompanionAvatar), findsOneWidget);

      // Tap dismiss (LucideIcons.x)
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pumpAndSettle();

      // Card is dismissed and replaced by SizedBox.shrink
      expect(find.byType(CompanionAvatar), findsNothing);
      expect(find.text('Morning Light'), findsNothing);
    });

    testWidgets('renders Indonesian localization cleanly', (tester) async {
      L10n.notifier.value = 'id';
      final now = DateTime(2026, 11, 24, 2, 0); // Night

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildTheme(Brightness.dark),
            home: Scaffold(
              body: AmbientCompanionCard(
                now: now,
                logs: const [],
                slots: const [],
                therapies: [oralTherapy],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Malam yang Sunyi'), findsOneWidget);
      expect(find.text('Ketuk untuk pesan lembut'), findsOneWidget);
      expect(find.text('Tenangkan'), findsOneWidget);
      expect(find.text('Tips rawat'), findsOneWidget);
      expect(find.text('Senyum'), findsOneWidget);
    });

    testWidgets('interactive topic chips update companion content and show shortcuts',
        (tester) async {
      final now = DateTime(2026, 11, 24, 9, 0);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildTheme(Brightness.dark),
            home: Scaffold(
              body: AmbientCompanionCard(
                now: now,
                logs: const [],
                slots: const [],
                therapies: [oralTherapy],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Calm me'));
      await tester.pumpAndSettle();
      expect(find.text('Steady Breath'), findsOneWidget);
      expect(find.text('Open Breathing'), findsOneWidget);
      expect(find.text(companionCalmLines.first.$2), findsOneWidget);

      await tester.tap(find.text('Care tip'));
      await tester.pumpAndSettle();
      expect(find.text('Gentle Care Tip'), findsOneWidget);
      expect(find.text('Read Guides'), findsOneWidget);
      expect(find.text(companionCareTips.first.$2), findsOneWidget);

      await tester.tap(find.text('Smile'));
      await tester.pumpAndSettle();
      expect(find.text('Light Moment'), findsOneWidget);
      expect(find.text(companionSmileLines.first.$2), findsOneWidget);

      await tester.tap(find.byIcon(LucideIcons.rotateCcw));
      await tester.pumpAndSettle();
      expect(find.text('Morning Light'), findsOneWidget);
    });

    testWidgets('long-press triggers Quiet Hug and rapid taps trigger Playful Moment',
        (tester) async {
      final now = DateTime(2026, 11, 24, 14, 0);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            theme: buildTheme(Brightness.dark),
            home: Scaffold(
              body: AmbientCompanionCard(
                now: now,
                logs: const [],
                slots: const [],
                therapies: [oralTherapy],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.longPress(find.byType(CompanionAvatar));
      await tester.pumpAndSettle();
      expect(find.text('Quiet Hug'), findsOneWidget);
      expect(find.text(companionQuietHugLines.first), findsOneWidget);

      // 4 rapid taps trigger Playful Moment poke reaction
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.byType(AmbientCompanionCard));
        await tester.pump(const Duration(milliseconds: 80));
      }
      await tester.pumpAndSettle();
      expect(find.text('Playful Moment'), findsOneWidget);
      expect(find.text('Whoa, easy there! You startled my stardust.'), findsOneWidget);
    });
  });
}
