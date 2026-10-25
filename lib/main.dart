import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'notifications.dart';
import 'repo.dart';
import 'theme.dart';
import 'ui/auth.dart';
import 'ui/pin_lock_gate.dart';
import 'ui/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('en');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(const ProviderScope(child: LuneraApp()));

  AppNotifier.instance.init().catchError((e) {
    debugPrint('Notification init error: $e');
  });
}

class LuneraApp extends ConsumerWidget {
  const LuneraApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(prefsProvider.select((p) => p.value?.theme ?? 'system'));
    applyAccent(ref.watch(prefsProvider.select((p) => p.value?.accent ?? 'lagoon')));

    return MaterialApp(
      title: 'Lunera',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: switch (mode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      locale: const Locale('en', ''),
      home: const AuthGate(),
    );
  }
}

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncUser = ref.watch(userProvider);
    return asyncUser.when(
      data: (user) => user != null ? const AppLockGate(child: Shell()) : const SignInPage(),
      loading: () {
        final current = FirebaseAuth.instance.currentUser;
        return current != null ? const AppLockGate(child: Shell()) : const SignInPage();
      },
      error: (_, __) => const SignInPage(),
    );
  }
}
