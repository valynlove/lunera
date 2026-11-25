import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lunera/l10n.dart';
import 'package:lunera/models.dart';
import 'package:lunera/notifications.dart';
import 'package:lunera/profile.dart';
import 'package:lunera/repo.dart';
import 'package:lunera/theme.dart';
import 'package:lunera/widget_sync.dart';
import 'package:lunera/ui/calendar.dart';
import 'package:lunera/ui/home.dart';
import 'package:lunera/ui/levels.dart';
import 'package:lunera/ui/more.dart';
import 'package:lunera/ui/settings_page.dart';
import 'package:lunera/ui/shell.dart';
import 'package:lunera/ui/supplies.dart';
import 'package:shared_preferences/shared_preferences.dart';

List<Override> _baseOverrides(SharedPreferences prefs) {
  final sampleTherapy = Therapy(
    id: 'th-1',
    hormoneId: 'estradiol',
    name: 'Estradiol Valerate',
    dose: 4.0,
    doseUnit: 'mg',
    start: DateTime(2026, 1, 1),
    route: 'inj',
    everyDays: 5,
    pk: 'e2_valerate',
  );
  const sampleSupply = Supply(
    id: 'sup-1',
    name: 'Estradiol Valerate 40 mg/mL',
    qty: 10,
    initial: 10,
    perDose: 0.1,
    unitLabel: 'mL',
    dosePerUnit: 40,
  );
  return [
    sharedPreferencesProvider.overrideWithValue(prefs),
    userProvider.overrideWith((ref) => Stream.value(null)),
    therapiesProvider.overrideWith((ref) => Stream.value([sampleTherapy])),
    suppliesProvider.overrideWith((ref) => Stream.value([sampleSupply])),
    logsProvider.overrideWith((ref) => Stream.value(const <DoseLog>[])),
    labsProvider.overrideWith((ref) => Stream.value(const <Lab>[])),
    targetsProvider.overrideWith((ref) => Stream.value(const <String, List<double>>{})),
    journalProvider.overrideWith((ref) => Stream.value(const <JournalEntry>[])),
    prefsProvider.overrideWith((ref) => Stream.value(const Prefs())),
    notifySyncProvider.overrideWith((ref) {}),
    widgetSyncProvider.overrideWith((ref) {}),
  ];
}

void main() {
  late SharedPreferences sharedPrefs;

  setUpAll(() async {
    await initializeDateFormatting();
    SharedPreferences.setMockInitialValues({});
    sharedPrefs = await SharedPreferences.getInstance();
  });

  group('Responsive Shell & Multi-Device Layout', () {
    testWidgets(
        'Shell adapts navigation chrome across Compact, Medium, and Expanded widths and preserves active tab',
        (tester) async {
      L10n.notifier.value = 'en';
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(overrides: _baseOverrides(sharedPrefs));
      addTearDown(container.dispose);

      // 1. Compact (360x800) -> Bottom Nav
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: buildTheme(),
            home: const Shell(),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('nav_bottom')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav_rail')), findsNothing);
      expect(find.byKey(const ValueKey('nav_sidebar')), findsNothing);

      // Switch to Supplies tab (index 3)
      await tester.tap(find.text(tr('Supplies')));
      await tester.pump();
      expect(container.read(tabProvider), equals(3));

      // 2. Medium (720x1024) -> Navigation Rail, preserves Supplies tab
      tester.view.physicalSize = const Size(720, 1024);
      await tester.pump();
      expect(find.byKey(const ValueKey('nav_rail')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav_bottom')), findsNothing);
      expect(find.byKey(const ValueKey('nav_sidebar')), findsNothing);
      expect(container.read(tabProvider), equals(3));

      // Switch to Calendar tab (index 1)
      await tester.tap(find.text(tr('Calendar')));
      await tester.pump();
      expect(container.read(tabProvider), equals(1));

      // 3. Expanded (1280x800) -> Desktop Sidebar, preserves Calendar tab
      tester.view.physicalSize = const Size(1280, 800);
      await tester.pump();
      expect(find.byKey(const ValueKey('nav_sidebar')), findsOneWidget);
      expect(find.byKey(const ValueKey('nav_rail')), findsNothing);
      expect(find.byKey(const ValueKey('nav_bottom')), findsNothing);
      expect(container.read(tabProvider), equals(1));

      // Drain Shell's 3-second update check delay timer cleanly.
      await tester.pump(const Duration(seconds: 4));
      expect(tester.takeException(), isNull);
    });

    testWidgets(
        'Primary tabs and SettingsPage render cleanly without overflow across phone, tablet, desktop, and 1.6x text scale',
        (tester) async {
      L10n.notifier.value = 'en';
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final scenarios = <(String, Size, double, bool)>[
        ('Small Phone', const Size(320, 640), 1.0, false),
        ('Standard Phone', const Size(390, 844), 1.0, false),
        ('Tablet', const Size(768, 1024), 1.0, false),
        ('Desktop', const Size(1440, 900), 1.0, false),
        ('Large Text + Reduce Motion', const Size(360, 800), 1.6, true),
      ];

      final pages = <(String, Widget)>[
        ('HomePage', const HomePage()),
        ('LevelsPage', const LevelsPage()),
        ('CalendarPage', const CalendarPage()),
        ('SuppliesPage', const SuppliesPage()),
        ('MorePage', const MorePage()),
        ('SettingsPage', const SettingsPage()),
      ];

      for (final (label, size, textScale, reduceMotion) in scenarios) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;

        for (final (pageName, page) in pages) {
          await tester.pumpWidget(
            ProviderScope(
              key: ValueKey('$label-$pageName'),
              overrides: _baseOverrides(sharedPrefs),
              child: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: TextScaler.linear(textScale),
                  disableAnimations: reduceMotion,
                ),
                child: MaterialApp(
                  theme: buildTheme(),
                  home: Scaffold(body: page),
                ),
              ),
            ),
          );
          await tester.pump();
          expect(
            tester.takeException(),
            isNull,
            reason: '$pageName failed layout check on $label ($size, scale $textScale)',
          );
        }
      }
    });

    testWidgets(
        'showSheet adapts between BottomSheet on compact and Dialog with Close button on wide windows',
        (tester) async {
      L10n.notifier.value = 'en';
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      Widget host() => MaterialApp(
            theme: buildTheme(),
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: FilledButton(
                    onPressed: () => showSheet(
                      context,
                      const Padding(
                        padding: EdgeInsets.all(12),
                        child: Text('ADAPTIVE_MODAL_CONTENT'),
                      ),
                    ),
                    child: const Text('Open Modal'),
                  ),
                ),
              ),
            ),
          );

      // Compact -> BottomSheet
      tester.view.physicalSize = const Size(360, 800);
      tester.view.devicePixelRatio = 1.0;
      await tester.pumpWidget(host());
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      expect(find.byType(Dialog), findsNothing);
      expect(find.text('ADAPTIVE_MODAL_CONTENT'), findsOneWidget);

      // Dismiss bottom sheet
      Navigator.of(tester.element(find.text('ADAPTIVE_MODAL_CONTENT'))).pop();
      await tester.pumpAndSettle();

      // Wide -> Centered Dialog with Close icon button
      tester.view.physicalSize = const Size(1024, 768);
      await tester.pumpWidget(host());
      await tester.tap(find.text('Open Modal'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.byType(BottomSheet), findsNothing);
      expect(find.text('ADAPTIVE_MODAL_CONTENT'), findsOneWidget);
      expect(find.byIcon(LucideIcons.x), findsOneWidget);

      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pumpAndSettle();
      expect(find.byType(Dialog), findsNothing);
    });
  });
}
