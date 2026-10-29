import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'firebase_options.dart';
import 'lock.dart';
import 'notifications.dart';
import 'repo.dart';
import 'theme.dart';
import 'ui/auth.dart';
import 'ui/lock_screen.dart';
import 'ui/shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id');
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  try {
    await AppNotifier.instance.init();
  } catch (e) {
    debugPrint('Notifikasi tidak aktif: $e');
  }
  await Lock.instance.load();
  runApp(const ProviderScope(child: LuneraApp()));
}

class LuneraApp extends ConsumerWidget {
  const LuneraApp({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(prefsProvider.select((p) => p.value?.theme ?? 'system'));
    applyAccent(ref.watch(prefsProvider.select((p) => p.value?.accent ?? 'lunera')));
    return MaterialApp(
      title: appName,
      builder: appBackdrop,
      debugShowCheckedModeBanner: false,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      themeMode: switch (mode) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      home: const AuthGate(),
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
