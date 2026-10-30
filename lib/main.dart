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
  await initializeDateFormatting('en');
  await initializeDateFormatting('id');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    await AppNotifier.instance.init();
  } catch (e) {
    debugPrint('Notifikasi tidak aktif: $e');
  }
  await Lock.instance.load();
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
    final localeCode = ref.watch(prefsProvider.select((p) => p.value?.locale ?? 'en'));
    AppLocale.code = localeCode;
    applyAccent(ref.watch(prefsProvider.select((p) => p.value?.accent ?? 'lunera')));
    return MaterialApp(
      title: appName,
      builder: appBackdrop,
      debugShowCheckedModeBanner: false,
      locale: Locale(localeCode),
      supportedLocales: AppLocale.supported,
      localizationsDelegates: const [
        AppStrings.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: buildTheme(Brightness.dark),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: ThemeMode.dark,
      home: const AppRoot(),
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
  bool minDone = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) setState(() => minDone = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    final loading = ref.watch(userProvider.select((u) => u.isLoading));
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 500),
      child: minDone && !loading
          ? const AuthGate(key: ValueKey('gate'))
          : const SplashPage(key: ValueKey('splash')),
    );
  }
}

typedef RitmeApp = LuneraApp;

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) => ref.watch(userProvider).when(
        data: (u) => u == null ? const WelcomePage() : const LockGate(child: Shell()),
        loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
        error: (e, _) => Scaffold(body: Center(child: Text('$e'))),
      );
}
