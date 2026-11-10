import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lunera/l10n.dart';
import 'package:lunera/models.dart';
import 'package:lunera/profile.dart';
import 'package:lunera/repo.dart';
import 'package:lunera/theme.dart';
import 'package:lunera/ui/about_sheet.dart';
import 'package:lunera/ui/app_changelog.dart';
import 'package:lunera/ui/auth.dart';
import 'package:lunera/ui/calendar.dart';
import 'package:lunera/ui/history.dart';
import 'package:lunera/ui/guided_injection.dart';
import 'package:lunera/ui/home.dart';
import 'package:lunera/ui/levels.dart';
import 'package:lunera/ui/lock_screen.dart';
import 'package:lunera/ui/more.dart';
import 'package:lunera/ui/pickup_assistant_sheet.dart';
import 'package:lunera/ui/profile_page.dart';
import 'package:lunera/ui/settings_page.dart';
import 'package:lunera/ui/sheets.dart';
import 'package:lunera/ui/site_map.dart';
import 'package:lunera/ui/splash.dart';
import 'package:lunera/ui/supplies.dart';
import 'package:lunera/update_checker.dart';

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });
  group('Lunera App Metadata & Smoke Tests', () {
    test('UpdateCheckerService version check configuration', () {
      expect(UpdateCheckerService.currentVersion, equals('2.1.0'));
    });

    test('AppChangelog releases metadata is populated and ordered', () {
      expect(AppChangelog.releases, isNotEmpty);
      expect(AppChangelog.releases.first.version, equals('2.1.0'));
      expect(AppChangelog.releases.first.isCurrent, isTrue);
      expect(AppChangelog.releases.first.changes, isNotEmpty);
    });

    testWidgets('InjectionSiteMap renders without layout exception', (tester) async {
      final therapy = Therapy(
        id: 't1',
        hormoneId: 'estradiol',
        name: 'Gestin F3',
        dose: 7.5,
        doseUnit: 'mg',
        start: DateTime(2025, 1, 1),
        route: 'inj',
      );
      const prefs = Prefs(places: defaultPlaces);

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: InjectionSiteMap(
                selectedSites: const ['Left thigh'],
                logs: const [],
                prefs: prefs,
                therapyId: therapy.id,
              ),
            ),
          ),
        ),
      );
      expect(find.byType(InjectionSiteMap), findsOneWidget);
    });

    testWidgets('DoseSheet renders compact site chips without bulky body map', (tester) async {
      final therapy = Therapy(
        id: 't1',
        hormoneId: 'estradiol',
        name: 'Gestin F3',
        dose: 7.5,
        doseUnit: 'mg',
        start: DateTime(2025, 1, 1),
        route: 'inj',
      );
      const prefs = Prefs(places: defaultPlaces);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            logsProvider.overrideWith((ref) => Stream.value(<DoseLog>[])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DoseSheet(
                  t: therapy,
                  supplies: const [],
                  prefs: prefs,
                  suggested: 'Left thigh',
                ),
              ),
            ),
          ),
        ),
      );
      expect(find.byType(DoseSheet), findsOneWidget);
      expect(find.byType(InjectionSiteMap), findsNothing);
      expect(find.text('Site'), findsOneWidget);
      expect(find.byType(FilterChip), findsWidgets);
      expect(find.text('Left thigh'), findsOneWidget);

      // Tap on another chip to toggle selection
      await tester.tap(find.text('Right thigh'));
      await tester.pumpAndSettle();
      expect(find.byType(FilterChip), findsWidgets);
    });

    testWidgets('SiteRotationSheet renders cleanly without overflow on narrow screens and Indonesian locale', (tester) async {
      L10n.notifier.value = 'id';
      addTearDown(() => L10n.notifier.value = 'en');
      tester.view.physicalSize = const Size(320, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const prefs = Prefs(places: defaultPlaces);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsProvider.overrideWith((ref) => Stream.value(prefs)),
            logsProvider.overrideWith((ref) => Stream.value(<DoseLog>[])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SiteRotationSheet(therapyId: 't1'),
            ),
          ),
        ),
      );
      expect(find.byType(SiteRotationSheet), findsOneWidget);
      expect(find.byType(InjectionSiteMap), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('CalmInjectionSheet renders guide and step timer cleanly', (tester) async {
      final therapy = Therapy(
        id: 't1',
        hormoneId: 'estradiol',
        name: 'Gestin F3',
        dose: 7.5,
        doseUnit: 'mg',
        start: DateTime(2025, 1, 1),
        route: 'inj',
      );
      const prefs = Prefs(places: defaultPlaces);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            logsProvider.overrideWith((ref) => Stream.value(<DoseLog>[])),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: CalmInjectionSheet(
                t: therapy,
                supplies: const [],
                prefs: prefs,
                suggestedPlace: 'Left thigh',
              ),
            ),
          ),
        ),
      );
      expect(find.byType(CalmInjectionSheet), findsOneWidget);
      expect(find.text('Guided Calm Injection'), findsOneWidget);
    });

    testWidgets('MorePage renders all feature hub sections cleanly', (tester) async {
      L10n.notifier.value = 'en';
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProvider.overrideWith((ref) => Stream.value(null)),
            therapiesProvider.overrideWith((ref) => Stream.value(<Therapy>[])),
            suppliesProvider.overrideWith((ref) => Stream.value(<Supply>[])),
            prefsProvider.overrideWith((ref) => Stream.value(const Prefs())),
            logsProvider.overrideWith((ref) => Stream.value(<DoseLog>[])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: MorePage(),
            ),
          ),
        ),
      );
      expect(find.byType(MorePage), findsOneWidget);
      expect(find.text(tr('Health & Journey')), findsOneWidget);
      expect(find.text(tr('Care & Assistant Tools')), findsOneWidget);
      expect(find.text(tr('System')), findsOneWidget);
      expect(find.text(tr('Settings')), findsOneWidget);

      // Tap profile card in MorePage: opens ProfilePage with zero-duration transition
      await tester.tap(find.byType(UserAvatar));
      await tester.pump();
      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets('SettingsPage renders settings sections and preferences cleanly', (tester) async {
      L10n.notifier.value = 'en';
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProvider.overrideWith((ref) => Stream.value(null)),
            prefsProvider.overrideWith((ref) => Stream.value(const Prefs())),
          ],
          child: const MaterialApp(
            home: SettingsPage(),
          ),
        ),
      );
      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.text(tr('Therapy & Clinical')), findsOneWidget);
      expect(find.text(tr('Reminders & Privacy')), findsOneWidget);
      expect(find.text(tr('Security & Privacy')), findsOneWidget);
      expect(find.text(tr('Preferences')), findsOneWidget);
      expect(find.text(tr('Appearance')), findsNothing);
    });

    testWidgets('WelcomePage renders AuthScene celestial background and brand actions', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: WelcomePage(),
        ),
      );
      expect(find.byType(WelcomePage), findsOneWidget);
      expect(find.byType(AuthScene), findsOneWidget);
      expect(find.text('Lunera'), findsOneWidget);
      expect(find.text(tr('Get started')), findsOneWidget);
      expect(find.text(tr('Log in')), findsOneWidget);
    });

    testWidgets('SignInPage renders AuthScene with darkened scrim and input fields', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: SignInPage(),
        ),
      );
      expect(find.byType(SignInPage), findsOneWidget);
      expect(find.byType(AuthScene), findsOneWidget);
      expect(find.text(tr('Welcome back')), findsOneWidget);
      expect(find.text(tr('Username or email')), findsOneWidget);
      expect(find.text(tr('Password')), findsOneWidget);
    });

    testWidgets('LockScreen renders celestial AuthScene and glowing PinPad', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: LockScreen(
            onUnlock: () {},
          ),
        ),
      );
      expect(find.byType(LockScreen), findsOneWidget);
      expect(find.byType(AuthScene), findsOneWidget);
      expect(find.byType(PinPad), findsOneWidget);
      expect(find.text(tr('Enter PIN')), findsOneWidget);
    });

    testWidgets('Update dialog renders celestial Arcane Astral card with version chip and release notes', (tester) async {
      L10n.notifier.value = 'en';
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const updateInfo = AppUpdateInfo(
        currentVersion: '1.11.37',
        latestVersion: '1.11.38',
        releaseName: 'Lunera 1.11.38 Release',
        releaseNotes: '- Revamped exit card and update card\n- Celestial starlight styling',
        downloadUrl: 'https://example.com/lunera.apk',
        releasePageUrl: 'https://example.com/releases/1.11.38',
        hasUpdate: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => UpdateCheckerService.showUpdateDialog(context, updateInfo),
                  child: const Text('Open Update Dialog'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Update Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text(tr('Update Available!')), findsOneWidget);
      expect(find.text('v1.11.37'), findsOneWidget);
      expect(find.text('v1.11.38'), findsOneWidget);
      expect(find.textContaining('Revamped exit card'), findsOneWidget);
      expect(find.text(tr('Later')), findsOneWidget);
      expect(find.text(tr('Update Now')), findsOneWidget);

      await tester.tap(find.text(tr('Later')));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
    });

    testWidgets('Exit dialog renders celestial halo card and handles cancellation', (tester) async {
      L10n.notifier.value = 'en';
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      bool? exitResult;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProvider.overrideWith((ref) => Stream.value(null)),
            therapiesProvider.overrideWith((ref) => Stream.value(<Therapy>[])),
            suppliesProvider.overrideWith((ref) => Stream.value(<Supply>[])),
            prefsProvider.overrideWith((ref) => Stream.value(const Prefs())),
            logsProvider.overrideWith((ref) => Stream.value(<DoseLog>[])),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: Center(
                  child: ElevatedButton(
                    onPressed: () async {
                      // Trigger same exit dialog structure as in shell.dart
                      final dark = Theme.of(context).brightness == Brightness.dark;
                      exitResult = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 380),
                            child: Container(
                              padding: const EdgeInsets.fromLTRB(26, 28, 26, 24),
                              decoration: BoxDecoration(
                                color: dark ? C.deepCard : Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: const Color(0xFFD6B277).withValues(alpha: dark ? 0.38 : 0.25),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: const BoxDecoration(shape: BoxShape.circle),
                                    child: const Icon(Icons.power_settings_new_rounded),
                                  ),
                                  Text(
                                    tr('Exit {0}?', [appName]),
                                    style: display(22, color: dark ? Colors.white : C.midnight, weight: FontWeight.w700),
                                  ),
                                  Text(tr('Are you sure you want to exit the application?')),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () => Navigator.of(ctx).pop(false),
                                          child: Text(tr('Cancel')),
                                        ),
                                      ),
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: () => Navigator.of(ctx).pop(true),
                                          icon: const Icon(Icons.exit_to_app_rounded, size: 18),
                                          label: Text(tr('Exit')),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                    child: const Text('Show Exit Dialog'),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Exit Dialog'));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsOneWidget);
      expect(find.text(tr('Exit {0}?', [appName])), findsOneWidget);
      expect(find.text(tr('Are you sure you want to exit the application?')), findsOneWidget);
      expect(find.text(tr('Cancel')), findsOneWidget);
      expect(find.text(tr('Exit')), findsOneWidget);

      await tester.tap(find.text(tr('Cancel')));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(exitResult, isFalse);
    });

    testWidgets('SplashPage renders celestial Arcane Astral sequence, moon emblem, and wordmark', (tester) async {
      L10n.notifier.value = 'en';
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const MaterialApp(
          home: SplashPage(),
        ),
      );

      // Verify immediate render of celestial splash elements
      expect(find.byType(SplashPage), findsOneWidget);
      expect(find.text(appName.toUpperCase()), findsOneWidget);
      expect(find.text(tr('YOUR JOURNEY, YOUR PACE.')), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
    });

    testWidgets('AboutLuneraSheet renders lore pillars, core principles, and metadata cleanly', (tester) async {
      L10n.notifier.value = 'en';
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showAboutLuneraSheet(context),
                  child: const Text('Open About Sheet'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open About Sheet'));
      await tester.pumpAndSettle();

      expect(find.byType(AboutLuneraSheet), findsOneWidget);
      expect(find.text(tr('About {0}', [appName])), findsOneWidget);
      expect(find.text(appName), findsWidgets);
      expect(find.text(tr('Brand Lore & Philosophy')), findsOneWidget);
      expect(find.text(tr('The Moon Phase Rhythms')), findsOneWidget);
      expect(find.text(tr('The Celestial Sanctuary')), findsOneWidget);
      expect(find.text(tr('The Guiding Star')), findsOneWidget);
      expect(find.text(tr('The Arcane Astral Canvas')), findsOneWidget);
      expect(find.text(tr('Core Principles')), findsOneWidget);
      expect(find.text(tr('Medical Disclaimer')), findsOneWidget);
      expect(find.text(tr('Version Changelog')), findsOneWidget);
      expect(find.text(tr('Send Feedback')), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.byType(AboutLuneraSheet), findsNothing);
    });

    testWidgets('SuppliesPage renders title and dual action row for Add Supply and Pickup Assistant', (tester) async {
      L10n.notifier.value = 'en';
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            suppliesProvider.overrideWith((ref) => Stream.value(<Supply>[])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SuppliesPage(),
            ),
          ),
        ),
      );

      // Verify title on its own
      expect(find.byType(SuppliesPage), findsOneWidget);
      expect(find.text(tr('Supplies')), findsOneWidget);

      // Verify dual action row buttons
      expect(find.text(tr('Add Supply')), findsOneWidget);
      expect(find.text(tr('Pickup Assistant')), findsOneWidget);

      // Tap on Add Supply to verify sheet opens
      await tester.tap(find.text(tr('Add Supply')));
      await tester.pumpAndSettle();
      expect(find.byType(SupplySheet), findsOneWidget);

      // Close sheet
      Navigator.of(tester.element(find.byType(SupplySheet))).pop();
      await tester.pumpAndSettle();
      expect(find.byType(SupplySheet), findsNothing);

      // Tap on Pickup Assistant to verify sheet opens
      await tester.tap(find.text(tr('Pickup Assistant')));
      await tester.pumpAndSettle();
      expect(find.byType(PickupAssistantSheet), findsOneWidget);

      // Close Pickup Assistant sheet
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
      expect(find.byType(PickupAssistantSheet), findsNothing);
    });

    testWidgets('HomePage renders streamlined dashboard, dose card, and calendar bridge', (tester) async {
      L10n.notifier.value = 'en';
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final therapy = Therapy(
        id: 'th-test',
        hormoneId: 'estradiol',
        name: 'Estradiol Enanthate',
        dose: 5.0,
        doseUnit: 'mg',
        start: DateTime(2025, 1, 1),
        route: 'inj',
        everyDays: 7,
        pk: 'e2_enanthate',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProvider.overrideWith((ref) => Stream.value(null)),
            therapiesProvider.overrideWith((ref) => Stream.value(<Therapy>[therapy])),
            suppliesProvider.overrideWith((ref) => Stream.value(<Supply>[])),
            logsProvider.overrideWith((ref) => Stream.value(<DoseLog>[])),
            prefsProvider.overrideWith((ref) => Stream.value(const Prefs())),
            journalProvider.overrideWith((ref) => Stream.value(<JournalEntry>[])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: HomePage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(DoseCard), findsOneWidget);
      expect(find.text('Estradiol Enanthate'), findsOneWidget);
      expect(find.text(tr('Log injection')), findsOneWidget);
      expect(find.text(tr('View full schedule in Calendar')), findsOneWidget);
    });

    testWidgets('LevelsPage renders streamlined header, action bar, and level panels cleanly', (tester) async {
      L10n.notifier.value = 'en';
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final therapy = Therapy(
        id: 'th-e2',
        hormoneId: 'estradiol',
        name: 'Estradiol Enanthate',
        dose: 5.0,
        doseUnit: 'mg',
        start: DateTime(2025, 1, 1),
        route: 'inj',
        everyDays: 7,
        pk: 'e2_enanthate',
      );

      final prolactinLab = Lab(
        id: 'lab-prolactin',
        hormoneId: 'prolactin',
        at: DateTime(2025, 2, 1),
        value: 14.5,
        unit: 'ng/mL',
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            therapiesProvider.overrideWith((ref) => Stream.value(<Therapy>[therapy])),
            labsProvider.overrideWith((ref) => Stream.value(<Lab>[prolactinLab])),
            targetsProvider.overrideWith((ref) => Stream.value(<String, List<double>>{'estradiol': [100.0, 200.0]})),
            logsProvider.overrideWith((ref) => Stream.value(<DoseLog>[])),
            prefsProvider.overrideWith((ref) => Stream.value(const Prefs())),
            journalProvider.overrideWith((ref) => Stream.value(<JournalEntry>[])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LevelsPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LevelsPage), findsOneWidget);
      expect(find.text(tr('Levels')), findsOneWidget);
      expect(find.text(tr('Add Lab Result')), findsOneWidget);
      expect(find.text(tr('Insights')), findsOneWidget);
      expect(find.byType(LevelPanel), findsOneWidget);
      expect(find.text(tr('Blood Tests & Lab Markers')), findsOneWidget);
      expect(find.text('Prolactin'), findsOneWidget);
    });

    testWidgets('LevelsPage renders clean empty state when no data exists', (tester) async {
      L10n.notifier.value = 'en';
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            therapiesProvider.overrideWith((ref) => Stream.value(<Therapy>[])),
            labsProvider.overrideWith((ref) => Stream.value(<Lab>[])),
            targetsProvider.overrideWith((ref) => Stream.value(<String, List<double>>{})),
            logsProvider.overrideWith((ref) => Stream.value(<DoseLog>[])),
            prefsProvider.overrideWith((ref) => Stream.value(const Prefs())),
            journalProvider.overrideWith((ref) => Stream.value(<JournalEntry>[])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: LevelsPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(LevelsPage), findsOneWidget);
      expect(find.text(tr('No level data yet')), findsOneWidget);
      expect(find.text(tr('Log a dose or add your first blood test result to view hormone curves.')), findsOneWidget);
    });

    testWidgets('CalendarPage renders weekly navigator card, tabs, and serene empty state', (tester) async {
      L10n.notifier.value = 'en';
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            therapiesProvider.overrideWith((ref) => Stream.value(<Therapy>[])),
            suppliesProvider.overrideWith((ref) => Stream.value(<Supply>[])),
            prefsProvider.overrideWith((ref) => Stream.value(const Prefs())),
            logsProvider.overrideWith((ref) => Stream.value(<DoseLog>[])),
            journalProvider.overrideWith((ref) => Stream.value(<JournalEntry>[])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: CalendarPage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CalendarPage), findsOneWidget);
      expect(find.text(tr('Calendar')), findsOneWidget);
      expect(find.text(tr('Schedule')), findsOneWidget);
      expect(find.text(tr('History')), findsOneWidget);
      expect(find.text(tr('Journal')), findsOneWidget);
      expect(find.text(tr('No doses scheduled')), findsOneWidget);
      expect(find.text(tr('Add schedule')), findsOneWidget);

      // Switch to History tab
      await tester.tap(find.text(tr('History')));
      await tester.pumpAndSettle();
      expect(find.byType(HistoryPage), findsOneWidget);
      expect(find.text(tr('No history entries yet')), findsOneWidget);
    });

    testWidgets('UserAvatar renders CircleAvatar with celestial frame overlay', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            userProvider.overrideWith((ref) => Stream.value(null)),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: UserAvatar(size: 80),
            ),
          ),
        ),
      );

      expect(find.byType(UserAvatar), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
      expect(find.byType(Image), findsOneWidget);
    });

    testWidgets('DoseSheet and LogTile support combination medication inputs and display', (tester) async {
      L10n.notifier.value = 'en';
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cycloTherapy = Therapy(
        id: 't_cyclo',
        name: 'Cyclofem',
        hormoneId: 'estradiol',
        dose: 5.0,
        doseUnit: 'mg',
        start: DateTime(2026, 10, 1),
        route: 'inj',
        pk: 'e2_cyp_susp',
        secondaryHormoneId: 'progesterone',
        secondaryDose: 25.0,
        secondaryDoseUnit: 'mg',
        secondaryPk: 'mpa_susp',
        secondaryCompound: 'mpa_susp',
      );

      final comboLog = DoseLog(
        id: 'l_combo',
        therapyId: 't_cyclo',
        at: DateTime(2026, 10, 15, 14, 0),
        dose: 5.0,
        secondaryDose: 25.0,
        places: ['Right Thigh'],
      );

      // Test LogTile renders combined dose format
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LogTile(
                l: comboLog,
                t: cycloTherapy,
                supplies: const [],
                prefs: const Prefs(),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Cyclofem'), findsOneWidget);
      expect(find.textContaining('5 mg + 25 mg'), findsOneWidget);

      // Test DoseSheet renders combination dose input
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: DoseSheet(
                  t: cycloTherapy,
                  edit: comboLog,
                  supplies: const [],
                  prefs: const Prefs(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Edit entry'), findsOneWidget);
      expect(find.text('Combination medication'), findsOneWidget);
      expect(find.text('5'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
    });

    testWidgets('Theme configures transparent page transitions to eliminate purple transition flash', (tester) async {
      final theme = buildTheme(Brightness.dark);
      expect(theme.pageTransitionsTheme, isNotNull);

      // Verify builders have transparent backgrounds/fallbacks
      final androidBuilder = theme.pageTransitionsTheme.builders[TargetPlatform.android];
      expect(androidBuilder, isA<PredictiveBackPageTransitionsBuilder>());
      expect((androidBuilder as PredictiveBackPageTransitionsBuilder).fallbackColor, Colors.transparent);

      final windowsBuilder = theme.pageTransitionsTheme.builders[TargetPlatform.windows];
      expect(windowsBuilder, isA<ZoomPageTransitionsBuilder>());
      expect((windowsBuilder as ZoomPageTransitionsBuilder).backgroundColor, Colors.transparent);

      final linuxBuilder = theme.pageTransitionsTheme.builders[TargetPlatform.linux];
      expect(linuxBuilder, isA<ZoomPageTransitionsBuilder>());
      expect((linuxBuilder as ZoomPageTransitionsBuilder).backgroundColor, Colors.transparent);
    });
  });
}

