import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'firebase_options.dart';
import 'l10n.dart';
import 'lock.dart';
import 'notifications.dart';
import 'profile.dart';
import 'repo.dart';
import 'theme.dart';
import 'ui/auth.dart';
import 'ui/lock_screen.dart';
import 'ui/shell.dart';
import 'ui/splash.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    await AppNotifier.instance.init();
  } catch (e) {
    debugPrint(tr('Notifications are off: {0}', [e]));
  }
  await Lock.instance.load();
  await L10n.load();
  final prefs = await SharedPreferences.getInstance();
  runApp(ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
    ],
    child: const LuneraApp(),
  ));
}

class LuneraApp extends ConsumerWidget {
  const LuneraApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    applyAccent(ref.watch(prefsProvider.select((p) => p.value?.accent ?? 'lunera')));
    return ValueListenableBuilder<String>(
      valueListenable: L10n.notifier,
      builder: (context, code, _) => MaterialApp(
        key: ValueKey(code), // bahasa berganti: bangun ulang seluruh aplikasi agar teks berganti seketika
        title: appName,
        locale: Locale(code),
        supportedLocales: const [Locale('en'), Locale('id')],
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        builder: appBackdrop,
        debugShowCheckedModeBanner: false,
        theme: buildTheme(Brightness.dark),
        darkTheme: buildTheme(Brightness.dark),
        themeMode: ThemeMode.dark,
        home: const AppRoot(),
      ),
    );
  }
}

/// Menampilkan layar pembuka sampai status masuk diketahui dan jeda minimalnya lewat.
class AppRoot extends ConsumerStatefulWidget {
  const AppRoot({super.key});
  @override
  ConsumerState<AppRoot> createState() => _AppRootState();
}

class _AppRootState extends ConsumerState<AppRoot> {
  bool _minSplashDone = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (mounted) setState(() => _minSplashDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(userProvider.select((u) => u.isLoading));
    final showSplash = loading || !_minSplashDone;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 600),
      switchInCurve: Curves.easeIn,
      switchOutCurve: Curves.easeOut,
      child: !showSplash ? const AuthGate(key: ValueKey('gate')) : const SplashPage(key: ValueKey('splash')),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(userProvider).when(
        data: (u) => u == null ? const WelcomePage() : const LockGate(child: Shell()),
        loading: () => const SplashPage(),
        error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      );
}
