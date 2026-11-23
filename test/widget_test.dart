import 'dart:async';
import 'dart:io' show File;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lunera/l10n.dart';
import 'package:lunera/lock.dart';
import 'package:lunera/models.dart';
import 'package:lunera/profile.dart';
import 'package:lunera/repo.dart';
import 'package:lunera/theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lunera/ui/about_sheet.dart';
import 'package:lunera/ui/app_changelog.dart';
import 'package:lunera/ui/auth.dart';
import 'package:lunera/ui/calendar.dart';
import 'package:lunera/ui/companion_avatar.dart';
import 'package:lunera/ui/data_page.dart';
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

class _FakeUser implements User {
  @override
  String get uid => 'test-user';

  @override
  String? get email => 'test@lunera.app';

  @override
  String? get displayName => 'Test User';

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  setUpAll(() async {
    await initializeDateFormatting();
  });
  group('Lunera App Metadata & Smoke Tests', () {
    test('UpdateCheckerService version check configuration', () {
      expect(UpdateCheckerService.currentVersion, equals('2.2.10'));
    });

    test('AppChangelog releases metadata is populated and ordered', () {
      expect(AppChangelog.releases, isNotEmpty);
      expect(AppChangelog.releases.first.version, equals('2.2.10'));
      expect(AppChangelog.releases.first.isCurrent, isTrue);
      expect(AppChangelog.releases.first.changes, isNotEmpty);
    });

    test('CompanionMood defines 20 moods and all PNG assets exist', () {
      expect(CompanionMood.values.length, equals(20));
      for (final mood in CompanionMood.values) {
        expect(
          File(mood.assetPath).existsSync(),
          isTrue,
          reason: 'Missing companion asset for ${mood.name}: ${mood.assetPath}',
        );
      }
      expect(File('assets/images/body_front.png').existsSync(), isTrue);
      expect(File('assets/images/body_back.png').existsSync(), isTrue);
    });

    testWidgets('InjectionSiteMap renders without layout exception',
        (tester) async {
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

      await tester.tap(find.text(tr('Back (Glutes)')));
      await tester.pump();
      expect(find.text(tr('Right buttock')), findsOneWidget);
    });

    testWidgets('DoseSheet renders compact site chips without bulky body map',
        (tester) async {
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

    testWidgets(
        'SiteRotationSheet renders cleanly without overflow on narrow screens and Indonesian locale',
        (tester) async {
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

    testWidgets('CalmInjectionSheet renders guide and step timer cleanly',
        (tester) async {
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

    testWidgets('MorePage renders all feature hub sections cleanly',
        (tester) async {
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
      expect(find.text(tr('Edit Profile')), findsOneWidget);
      expect(find.text(tr('Local Account')), findsOneWidget);
      expect(find.text(tr('Journey')), findsOneWidget);
      expect(find.text(tr('Therapies')), findsOneWidget);
      expect(find.text(tr('Doses')), findsOneWidget);
      expect(find.text(tr('Adherence')), findsOneWidget);
      expect(find.text(tr(tagline)), findsOneWidget);
      expect(find.text(tr('Health & Journey')), findsOneWidget);
      expect(find.text(tr('Care & Assistant Tools')), findsOneWidget);
      expect(find.text(tr('System')), findsOneWidget);
      expect(find.text(tr('Settings')), findsOneWidget);

      // Tap profile card in MorePage: opens ProfilePage with zero-duration transition
      await tester.tap(find.byType(UserAvatar));
      await tester.pump();
      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets('MorePage profile card fits narrow phone width without overflow',
        (tester) async {
      L10n.notifier.value = 'en';
      tester.view.physicalSize = const Size(360, 800);
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

      expect(tester.takeException(), isNull);
      expect(find.text(tr('Edit Profile')), findsOneWidget);
      expect(find.text(tr('Local Account')), findsOneWidget);
      expect(find.text(tr('Journey')), findsOneWidget);
      expect(find.text(tr('Adherence')), findsOneWidget);
    });

    testWidgets(
        'SettingsPage renders settings sections and preferences cleanly',
        (tester) async {
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

    testWidgets(
        'WelcomePage renders AuthScene celestial background and brand actions',
        (tester) async {
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

    testWidgets(
        'SignInPage renders AuthScene with darkened scrim and input fields',
        (tester) async {
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

    testWidgets('LockScreen renders celestial AuthScene and glowing PinPad',
        (tester) async {
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

    testWidgets(
        'Update dialog renders celestial Arcane Astral card with version chip and release notes',
        (tester) async {
      L10n.notifier.value = 'en';
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      const updateInfo = AppUpdateInfo(
        currentVersion: '1.11.37',
        latestVersion: '1.11.38',
        releaseName: 'Lunera 1.11.38 Release',
        releaseNotes:
            '- Revamped exit card and update card\n- Celestial starlight styling',
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
                  onPressed: () => UpdateCheckerService.showUpdateDialog(
                      context, updateInfo),
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

    testWidgets(
        'Exit dialog renders celestial halo card and handles cancellation',
        (tester) async {
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
                      final dark =
                          Theme.of(context).brightness == Brightness.dark;
                      exitResult = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => Dialog(
                          backgroundColor: Colors.transparent,
                          insetPadding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 24),
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 380),
                            child: Container(
                              padding:
                                  const EdgeInsets.fromLTRB(26, 28, 26, 24),
                              decoration: BoxDecoration(
                                color: dark ? C.deepCard : Colors.white,
                                borderRadius: BorderRadius.circular(28),
                                border: Border.all(
                                  color: const Color(0xFFD6B277)
                                      .withValues(alpha: dark ? 0.38 : 0.25),
                                  width: 1.2,
                                ),
                              ),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: const BoxDecoration(
                                        shape: BoxShape.circle),
                                    child: const Icon(LucideIcons.power),
                                  ),
                                  Text(
                                    tr('Exit {0}?', [appName]),
                                    style: display(22,
                                        color: dark ? Colors.white : C.midnight,
                                        weight: FontWeight.w700),
                                  ),
                                  Text(tr(
                                      'Are you sure you want to exit the application?')),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(false),
                                          child: Text(tr('Cancel')),
                                        ),
                                      ),
                                      Expanded(
                                        child: FilledButton.icon(
                                          onPressed: () =>
                                              Navigator.of(ctx).pop(true),
                                          icon: const Icon(LucideIcons.logOut,
                                              size: 18),
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
      expect(find.text(tr('Are you sure you want to exit the application?')),
          findsOneWidget);
      expect(find.text(tr('Cancel')), findsOneWidget);
      expect(find.text(tr('Exit')), findsOneWidget);

      await tester.tap(find.text(tr('Cancel')));
      await tester.pumpAndSettle();

      expect(find.byType(Dialog), findsNothing);
      expect(exitResult, isFalse);
    });

    testWidgets(
        'SplashPage renders Eternal Dusk staged splash, logo, wordmark, tagline, and invokes onFinish',
        (tester) async {
      L10n.notifier.value = 'en';
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var finished = false;
      await tester.pumpWidget(
        MaterialApp(
          home: SplashPage(onFinish: () => finished = true),
        ),
      );
      await tester.pump();

      expect(find.byType(SplashPage), findsOneWidget);
      expect(find.byType(MoonLogo), findsOneWidget);
      expect(find.text(appName.toUpperCase()), findsOneWidget);
      expect(find.text(tr('Your Journey, In Every Phase.')), findsOneWidget);
      expect(find.byIcon(LucideIcons.sparkles), findsOneWidget);
      expect(find.byType(Image), findsWidgets);
      expect(finished, isTrue);
    });

    testWidgets(
        'SplashPage adapts cleanly on compact mobile and tablet with reduced motion',
        (tester) async {
      L10n.notifier.value = 'en';
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final size in const [Size(360, 640), Size(1024, 1366)]) {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        var finished = false;
        await tester.pumpWidget(
          MediaQuery(
            data: MediaQueryData(size: size, disableAnimations: true),
            child: MaterialApp(
              home: SplashPage(
                key: ValueKey(size),
                onFinish: () => finished = true,
              ),
            ),
          ),
        );
        await tester.pump();
        expect(find.text(appName.toUpperCase()), findsOneWidget);
        expect(find.text(tr('Your Journey, In Every Phase.')), findsOneWidget);
        expect(finished, isTrue);
      }
    });

    testWidgets(
        'AboutLuneraSheet renders lore pillars, core principles, and metadata cleanly',
        (tester) async {
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
      expect(find.text(tr('The Eternal Dusk Canvas')), findsOneWidget);
      expect(find.text(tr('Core Principles')), findsOneWidget);
      expect(find.text(tr('Medical Disclaimer')), findsOneWidget);
      expect(find.text(tr('Version Changelog')), findsOneWidget);
      expect(find.text(tr('Send Feedback')), findsOneWidget);

      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pumpAndSettle();

      expect(find.byType(AboutLuneraSheet), findsNothing);
    });

    testWidgets(
        'SuppliesPage renders title and dual action row for Add Supply and Pickup Assistant',
        (tester) async {
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
      await tester.tap(find.byIcon(LucideIcons.x));
      await tester.pumpAndSettle();
      expect(find.byType(PickupAssistantSheet), findsNothing);
    });

    testWidgets(
        'HomePage renders streamlined dashboard, dose card, and calendar bridge',
        (tester) async {
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
            therapiesProvider
                .overrideWith((ref) => Stream.value(<Therapy>[therapy])),
            suppliesProvider.overrideWith((ref) => Stream.value(<Supply>[])),
            logsProvider.overrideWith((ref) => Stream.value(<DoseLog>[])),
            prefsProvider.overrideWith((ref) => Stream.value(const Prefs())),
            journalProvider
                .overrideWith((ref) => Stream.value(<JournalEntry>[])),
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
      expect(find.textContaining('Next: '), findsOneWidget);
      expect(find.text(tr('Log injection')), findsOneWidget);
      expect(find.text(tr('View full schedule in Calendar')), findsOneWidget);
    });

    testWidgets(
        'Decoy calculator LockScreen fits cleanly on landscape tablet and unlocks',
        (tester) async {
      L10n.notifier.value = 'en';
      const appUtilsChannel = MethodChannel('com.example.ritme/app_utils');
      const localAuthChannel = MethodChannel('plugins.flutter.io/local_auth');
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(appUtilsChannel, (_) async => null);
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(localAuthChannel, (call) async {
        if (call.method == 'getAvailableBiometrics') return <String>[];
        return false;
      });
      addTearDown(() {
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(appUtilsChannel, null);
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(localAuthChannel, null);
      });

      const salt = 'decoy-tablet-salt';
      final hash = hashPinPbkdf2('135790', salt, iterations: 1000);
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({
        'lock.salt': salt,
        'lock.hash': hash,
        'lock.decoy': true,
        'lock.updatedAt': 1000,
      });
      await Lock.instance.load();
      Lock.instance.sessionUnlocked = false;
      addTearDown(() async {
        await Lock.instance.clearLocal();
        Lock.instance.resetSyncCache();
      });

      tester.view.physicalSize = const Size(1280, 720);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      var unlocked = false;
      await tester.pumpWidget(
        MaterialApp(
          home: LockScreen(onUnlock: () => unlocked = true),
        ),
      );
      await tester.pumpAndSettle();

      for (final label in ['C', '7', '4', '1', '0', '=']) {
        final finder = find.descendant(
            of: find.byType(InkWell), matching: find.text(label));
        expect(finder, findsOneWidget);
        final rect = tester.getRect(finder);
        expect(rect.bottom, lessThanOrEqualTo(720.0), reason: label);
      }
      expect(find.text(tr('Forgot PIN?')), findsOneWidget);

      for (final d in ['1', '3', '5', '7', '9', '0']) {
        await tester.tap(
          find.descendant(of: find.byType(InkWell), matching: find.text(d)),
        );
        await tester.pump();
      }
      await tester.tap(
        find.descendant(of: find.byType(InkWell), matching: find.text('=')),
      );
      await tester.pumpAndSettle();
      expect(unlocked, isTrue);
    }, timeout: const Timeout(Duration(seconds: 10)));

    testWidgets(
        'HomePage shows gentle 3-step onboarding card when no therapies exist',
        (tester) async {
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
            logsProvider.overrideWith((ref) => Stream.value(<DoseLog>[])),
            prefsProvider.overrideWith((ref) => Stream.value(const Prefs())),
            journalProvider
                .overrideWith((ref) => Stream.value(<JournalEntry>[])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: HomePage(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(tr('No therapies yet')), findsOneWidget);
      expect(find.text(tr('Get started in 3 calm steps')), findsOneWidget);
      expect(find.text('1. ${tr('Add your first therapy')}'), findsOneWidget);
      expect(find.text('2. ${tr('Protect your privacy')}'), findsOneWidget);
      expect(
          find.text('3. ${tr('Read the Start Here guide')}'), findsOneWidget);
    });

    testWidgets(
        'LevelsPage renders streamlined header, action bar, and level panels cleanly',
        (tester) async {
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
            therapiesProvider
                .overrideWith((ref) => Stream.value(<Therapy>[therapy])),
            labsProvider
                .overrideWith((ref) => Stream.value(<Lab>[prolactinLab])),
            targetsProvider
                .overrideWith((ref) => Stream.value(<String, List<double>>{
                      'estradiol': [100.0, 200.0]
                    })),
            logsProvider.overrideWith((ref) => Stream.value(<DoseLog>[])),
            prefsProvider.overrideWith((ref) => Stream.value(const Prefs())),
            journalProvider
                .overrideWith((ref) => Stream.value(<JournalEntry>[])),
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

    testWidgets('LevelsPage renders clean empty state when no data exists',
        (tester) async {
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
            targetsProvider
                .overrideWith((ref) => Stream.value(<String, List<double>>{})),
            logsProvider.overrideWith((ref) => Stream.value(<DoseLog>[])),
            prefsProvider.overrideWith((ref) => Stream.value(const Prefs())),
            journalProvider
                .overrideWith((ref) => Stream.value(<JournalEntry>[])),
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
      expect(
          find.text(tr(
              'Log a dose or add your first blood test result to view hormone curves.')),
          findsOneWidget);
    });

    testWidgets('LabSheet toggles comparator choice chips cleanly',
        (tester) async {
      L10n.notifier.value = 'en';
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            prefsProvider.overrideWith((ref) => Stream.value(const Prefs())),
          ],
          child: MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: LabSheet(
                  initial: Lab(
                    id: 'l1',
                    hormoneId: 'estradiol',
                    at: DateTime(2026, 11, 1),
                    value: 1000,
                    unit: 'pg/mL',
                    cmp: '>',
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '>'))
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '='))
            .selected,
        isFalse,
      );

      await tester.tap(find.widgetWithText(ChoiceChip, '='));
      await tester.pumpAndSettle();

      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '='))
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, '>'))
            .selected,
        isFalse,
      );
    });

    testWidgets(
        'LevelPanel non-compact shows peak/trough and upcoming doses projection chip',
        (tester) async {
      L10n.notifier.value = 'en';
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final now = DateTime.now();
      final therapy = Therapy(
        id: 'th-ev',
        hormoneId: 'estradiol',
        name: 'Estradiol Valerate',
        dose: 4.0,
        doseUnit: 'mg',
        start: now.subtract(const Duration(days: 14)),
        route: 'inj',
        everyDays: 7,
        times: const ['08:00'],
        pk: 'e2_valerate',
      );
      final log = DoseLog(
        id: 'log-1',
        therapyId: 'th-ev',
        at: now.subtract(const Duration(days: 3)),
        dose: 4.0,
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            therapiesProvider
                .overrideWith((ref) => Stream.value(<Therapy>[therapy])),
            labsProvider.overrideWith((ref) => Stream.value(<Lab>[])),
            targetsProvider
                .overrideWith((ref) => Stream.value(<String, List<double>>{})),
            logsProvider.overrideWith((ref) => Stream.value(<DoseLog>[log])),
            prefsProvider.overrideWith((ref) => Stream.value(const Prefs())),
            journalProvider
                .overrideWith((ref) => Stream.value(<JournalEntry>[])),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: LevelPanel('estradiol'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text(tr('Include upcoming doses')), findsOneWidget);
      expect(find.textContaining('peak'), findsOneWidget);
      expect(
        find.text(
            tr('Projection assumes upcoming doses are taken as scheduled.')),
        findsNothing,
      );

      await tester.tap(find.text(tr('Include upcoming doses')));
      await tester.pumpAndSettle();

      expect(
        find.text(
            tr('Projection assumes upcoming doses are taken as scheduled.')),
        findsOneWidget,
      );
    });

    testWidgets(
        'CalendarPage renders weekly navigator card, tabs, and serene empty state',
        (tester) async {
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
            journalProvider
                .overrideWith((ref) => Stream.value(<JournalEntry>[])),
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

    testWidgets('UserAvatar renders CircleAvatar with celestial frame overlay',
        (tester) async {
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

    testWidgets(
        'DoseSheet and LogTile support combination medication inputs and display',
        (tester) async {
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

    testWidgets(
        'Theme configures transparent page transitions to eliminate purple transition flash',
        (tester) async {
      final theme = buildTheme(Brightness.dark);
      expect(theme.pageTransitionsTheme, isNotNull);

      // Verify builders have transparent backgrounds/fallbacks
      final androidBuilder =
          theme.pageTransitionsTheme.builders[TargetPlatform.android];
      expect(androidBuilder, isA<PredictiveBackPageTransitionsBuilder>());
      expect(
          (androidBuilder as PredictiveBackPageTransitionsBuilder)
              .fallbackColor,
          Colors.transparent);

      final windowsBuilder =
          theme.pageTransitionsTheme.builders[TargetPlatform.windows];
      expect(windowsBuilder, isA<ZoomPageTransitionsBuilder>());
      expect((windowsBuilder as ZoomPageTransitionsBuilder).backgroundColor,
          Colors.transparent);

      final linuxBuilder =
          theme.pageTransitionsTheme.builders[TargetPlatform.linux];
      expect(linuxBuilder, isA<ZoomPageTransitionsBuilder>());
      expect((linuxBuilder as ZoomPageTransitionsBuilder).backgroundColor,
          Colors.transparent);
    });

    testWidgets(
        'LockGate blocks child until checkingLock finishes and unmounts child when locked',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const appUtilsChannel = MethodChannel('com.example.ritme/app_utils');
      const localAuthChannel = MethodChannel('plugins.flutter.io/local_auth');
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(appUtilsChannel, (_) async => null);
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(localAuthChannel, (call) async {
        if (call.method == 'getAvailableBiometrics') return <String>[];
        return false;
      });
      addTearDown(() {
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(appUtilsChannel, null);
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(localAuthChannel, null);
      });

      const salt = 'gate-salt';
      final hash = hashPinPbkdf2('135790', salt, iterations: 1000);
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({});
      await Lock.instance.load();
      await Lock.instance.clearLocal();
      Lock.instance.resetSyncCache();

      final completer = Completer<void>();

      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: LockGate(
              uid: 'test-uid',
              syncCloud: (_) => completer.future,
              child: const Scaffold(body: Text('PROTECTED_SHELL')),
            ),
          ),
        ),
      );

      // During checkingLock: SplashPage shown, Shell NOT mounted
      expect(find.byType(SplashPage), findsOneWidget);
      expect(find.text('PROTECTED_SHELL'), findsNothing);
      expect(find.byType(LockScreen), findsNothing);

      // Cloud returns enabled lock: LockGate transitions directly to LockScreen without ever mounting Shell
      await Lock.instance.applyCloudLockData({
        'enabled': true,
        'salt': salt,
        'hash': hash,
        'delayMin': 0,
        'decoyCalculator': false,
        'updatedAt': 5000,
      });
      completer.complete();
      await tester.pump();
      await tester.pump();

      expect(find.byType(LockScreen), findsOneWidget);
      expect(find.text('PROTECTED_SHELL'), findsNothing);

      // Back button while locked must NOT pop LockScreen or expose child
      await tester.binding.handlePopRoute();
      await tester.pump();
      expect(find.byType(LockScreen), findsOneWidget);
      expect(find.text('PROTECTED_SHELL'), findsNothing);

      await Lock.instance.clearLocal();
      Lock.instance.resetSyncCache();
    }, timeout: const Timeout(Duration(seconds: 5)));

    testWidgets(
        'LockGate preserves tabProvider across lock/unlock and honors suppressLockDuring grace period',
        (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      const appUtilsChannel = MethodChannel('com.example.ritme/app_utils');
      const localAuthChannel = MethodChannel('plugins.flutter.io/local_auth');
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(appUtilsChannel, (_) async => null);
      tester.binding.defaultBinaryMessenger
          .setMockMethodCallHandler(localAuthChannel, (call) async {
        if (call.method == 'getAvailableBiometrics') return <String>[];
        return false;
      });
      addTearDown(() {
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(appUtilsChannel, null);
        tester.binding.defaultBinaryMessenger
            .setMockMethodCallHandler(localAuthChannel, null);
      });

      const salt = 'gate-salt-2';
      final hash = hashPinPbkdf2('246810', salt, iterations: 1000);
      FlutterSecureStorage.setMockInitialValues({});
      SharedPreferences.setMockInitialValues({
        'lock.salt': salt,
        'lock.hash': hash,
        'lock.delay': 0,
        'lock.updatedAt': 1000,
      });
      await Lock.instance.load();
      Lock.instance.sessionUnlocked = true;

      final container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(tabProvider.notifier).state = 4;

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: LockGate(
              uid: 'test-uid-2',
              syncCloud: (_) async {},
              child: Consumer(
                builder: (_, ref, __) => Scaffold(
                  body: Text('SHELL_TAB_${ref.watch(tabProvider)}'),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('SHELL_TAB_4'), findsOneWidget);

      // Lifecycle pause -> resume during suppressLockDuring must NOT trigger lock loop
      await Lock.instance.suppressLockDuring(() async {
        tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
        await tester.pump();
        tester.binding
            .handleAppLifecycleStateChanged(AppLifecycleState.resumed);
        await tester.pump();
      }, gracePeriod: const Duration(milliseconds: 30));

      expect(find.text('SHELL_TAB_4'), findsOneWidget);
      expect(find.byType(LockScreen), findsNothing);

      // Wait out real wall-clock grace period before re-locking via cloud lock update
      await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 50)));
      Lock.instance.sessionUnlocked = false;
      await Lock.instance.applyCloudLockData({
        'enabled': true,
        'salt': salt,
        'hash': hash,
        'delayMin': 0,
        'decoyCalculator': false,
        'updatedAt': 2000,
      });
      await tester.pump();

      expect(find.byType(LockScreen), findsOneWidget);
      expect(find.text('SHELL_TAB_4'), findsNothing);

      // Enter PIN to unlock -> Shell mounts again with tabProvider preserved at 4
      for (final d in ['2', '4', '6', '8', '1', '0']) {
        await tester.tap(find.text(d));
        await tester.pump();
      }
      await tester.pump();
      expect(find.text('SHELL_TAB_4'), findsOneWidget);
      expect(container.read(tabProvider), equals(4));

      await Lock.instance.clearLocal();
      Lock.instance.resetSyncCache();
    }, timeout: const Timeout(Duration(seconds: 5)));

    testWidgets(
        'DataPage and SettingsPage distinguish queuedOffline and error sync states',
        (tester) async {
      L10n.notifier.value = 'en';
      Repo.resetSyncStateForTest();
      addTearDown(Repo.resetSyncStateForTest);
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // 1. DataPage with queuedOffline and error states
      Repo.syncStateNotifier.value = const SyncState(
        status: SyncStatus.queuedOffline,
        pendingCount: 2,
      );
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('data-sync-test'),
          overrides: [
            userProvider.overrideWith((ref) => Stream.value(null)),
            backupsProvider.overrideWith((ref) => Stream.value(const [])),
          ],
          child: const MaterialApp(home: DataPage()),
        ),
      );
      await tester.pump();
      expect(
          find.text(tr('Queued offline ({0} pending)', [2])), findsOneWidget);

      Repo.syncStateNotifier.value = const SyncState(
        status: SyncStatus.error,
        errorMessage: 'Permission denied',
      );
      await tester.pump();
      expect(find.text(tr('Sync failed: {0}', ['Permission denied'])),
          findsOneWidget);

      // 2. SettingsPage with queuedOffline and error states (signed-in user)
      Repo.syncStateNotifier.value = const SyncState(
        status: SyncStatus.queuedOffline,
        pendingCount: 3,
      );
      await tester.pumpWidget(
        ProviderScope(
          key: const ValueKey('settings-sync-test'),
          overrides: [
            userProvider.overrideWith((ref) => Stream.value(_FakeUser())),
            prefsProvider.overrideWith((ref) => Stream.value(const Prefs())),
          ],
          child: const MaterialApp(home: SettingsPage()),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.scrollUntilVisible(
          find.text(tr('Real-Time Cloud Sync')), 200);
      expect(find.text(tr('Offline queued')), findsOneWidget);
      expect(
          find.text(tr(
              '{0} pending changes will sync automatically when online.', [3])),
          findsOneWidget);

      Repo.syncStateNotifier.value = const SyncState(
        status: SyncStatus.error,
        errorMessage: 'Write rejected',
      );
      await tester.pump();
      expect(find.text(tr('Sync error')), findsOneWidget);
      expect(find.text('Write rejected'), findsOneWidget);
    });
  });
}
