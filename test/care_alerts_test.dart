import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:lunera/care_alerts.dart';
import 'package:lunera/consultation_prep.dart';
import 'package:lunera/models.dart';
import 'package:lunera/profile.dart';
import 'package:lunera/repo.dart';
import 'package:lunera/ui/care_alerts_sheet.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting('en');
    await initializeDateFormatting('id');
  });

  group('evaluateCareAlerts Unit Tests', () {
    final now = DateTime(2026, 11, 24, 12, 0);

    test('returns empty alerts when everything is healthy and up to date', () {
      final alerts = evaluateCareAlerts(
        therapies: const [],
        logs: const [],
        supplies: const [],
        prefs: const Prefs(),
        consultation: const ConsultationSession(id: 'sess_1'),
        now: now,
      );
      expect(alerts, isEmpty);
    });

    test('detects depleted and critical supplies', () {
      final therapy = Therapy(
        id: 't_oral',
        name: 'Estradiol (Oral)',
        start: DateTime(2026, 1, 1),
        dose: 2.0,
        doseUnit: 'mg',
        route: 'oral',
        hormoneId: 'estradiol',
        times: const ['08:00', '20:00'], // 2 per day
      );

      const depletedSupply = Supply(
        id: 's_depleted',
        name: 'Estradiol 2mg Tablets',
        qty: 0,
        initial: 60,
        unitLabel: 'pills',
        perDose: 1.0,
      );

      const criticalSupply = Supply(
        id: 's_crit',
        name: 'Spironolactone 50mg',
        qty: 4, // 2 days left
        initial: 60,
        unitLabel: 'pills',
        perDose: 1.0,
      );

      final alerts = evaluateCareAlerts(
        therapies: [therapy],
        logs: const [],
        supplies: [depletedSupply, criticalSupply],
        prefs: const Prefs(),
        consultation: const ConsultationSession(id: 'sess_1'),
        now: now,
      );

      final supplyAlerts =
          alerts.where((a) => a.target == AlertActionTarget.supplies).toList();
      expect(supplyAlerts.length, 2);
      expect(supplyAlerts.any((a) => a.priority == AlertPriority.critical), isTrue);
      expect(supplyAlerts.any((a) => a.title.contains('Depleted')), isTrue);
      expect(supplyAlerts.any((a) => a.title.contains('Reorder Urgently')), isTrue);

      final overdueAlerts =
          alerts.where((a) => a.target == AlertActionTarget.logDose).toList();
      expect(overdueAlerts, isNotEmpty);
      expect(overdueAlerts.first.priority, AlertPriority.warning);
    });

    test('detects upcoming doctor consultation within 7 days', () {
      final consultation = ConsultationSession(
        id: 'c1',
        doctorOrClinic: 'Dr. Sarah Adams',
        scheduledAt: now.add(const Duration(days: 3)),
        questions: const [
          ConsultationQuestion(id: 'q1', text: 'Review labs'),
        ],
      );

      final alerts = evaluateCareAlerts(
        therapies: const [],
        logs: const [],
        supplies: const [],
        prefs: const Prefs(),
        consultation: consultation,
        now: now,
      );

      expect(alerts.length, 1);
      expect(alerts.first.priority, AlertPriority.info);
      expect(alerts.first.title, contains('Dr. Sarah Adams'));
      expect(alerts.first.target, AlertActionTarget.consultation);
    });
  });

  group('CareAlertsBell & CareAlertsSheet Widget Tests', () {
    testWidgets('renders CareAlertsBell and opens CareAlertsSheet on tap',
        (tester) async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            sharedPreferencesProvider.overrideWithValue(prefs),
            userProvider.overrideWith((ref) => Stream.value(null)),
            therapiesProvider.overrideWith((ref) => Stream.value(const [])),
            logsProvider.overrideWith((ref) => Stream.value(const [])),
            suppliesProvider.overrideWith((ref) => Stream.value(const [])),
            prefsProvider.overrideWith((ref) => Stream.value(const Prefs())),
          ],
          child: MaterialApp(
            home: Scaffold(
              appBar: AppBar(
                actions: const [CareAlertsBell()],
              ),
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find Bell button and tap
      expect(find.byType(CareAlertsBell), findsOneWidget);
      await tester.tap(find.byType(CareAlertsBell));
      await tester.pumpAndSettle();

      // Verify Care Alerts Sheet opens with serene empty state
      expect(find.text('Care Reminders'), findsOneWidget);
      expect(find.text('Everything is serene'), findsOneWidget);
    });
  });
}
