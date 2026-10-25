import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../repo.dart';
import '../theme.dart';

class BiometricService {
  static final _auth = LocalAuthentication();

  static Future<bool> isAvailable() async {
    try {
      final canBio = await _auth.canCheckBiometrics;
      final supported = await _auth.isDeviceSupported();
      return canBio || supported;
    } catch (_) {
      return false;
    }
  }

  static Future<bool> isAppLockEnabled() async {
    try {
      final sp = await SharedPreferences.getInstance();
      return sp.getBool('lunera_app_lock') ?? false;
    } catch (_) {
      return false;
    }
  }

  static Future<void> setAppLockEnabled(bool enabled) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setBool('lunera_app_lock', enabled);
    } catch (_) {}
  }

  static Future<bool> authenticate() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Scan fingerprint or face to unlock Lunera',
        options: const AuthenticationOptions(
          stickyAuth: true,
          biometricOnly: false,
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      debugPrint('Biometric auth error: $e');
      return false;
    }
  }
}

class AppLockGate extends ConsumerStatefulWidget {
  const AppLockGate({super.key, required this.child});
  final Widget child;

  @override
  ConsumerState<AppLockGate> createState() => _AppLockGateState();
}

class _AppLockGateState extends ConsumerState<AppLockGate> with WidgetsBindingObserver {
  bool _initialized = false;
  bool _locked = true;
  DateTime? _pausedTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initAndCheckLock();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _pausedTime = DateTime.now();
    } else if (state == AppLifecycleState.resumed) {
      if (_pausedTime != null) {
        final elapsed = DateTime.now().difference(_pausedTime!);
        _pausedTime = null;
        // Mencegah terkunci saat memilih foto dari galeri (kembali kurang dari 3 detik)
        if (elapsed.inSeconds >= 3) {
          _lockAppAndAuth();
        }
      }
    }
  }

  Future<void> _initAndCheckLock() async {
    final localLock = await BiometricService.isAppLockEnabled();
    final firestoreLock = ref.read(prefsProvider).value?.appLock ?? false;
    final isEnabled = localLock || firestoreLock;

    if (mounted) {
      setState(() {
        _initialized = true;
        _locked = isEnabled;
      });
      if (isEnabled) {
        _promptAuth();
      }
    }
  }

  Future<void> _lockAppAndAuth() async {
    final localLock = await BiometricService.isAppLockEnabled();
    final firestoreLock = ref.read(prefsProvider).value?.appLock ?? false;
    if ((localLock || firestoreLock) && mounted) {
      setState(() => _locked = true);
      _promptAuth();
    }
  }

  Future<void> _promptAuth() async {
    final ok = await BiometricService.authenticate();
    if (ok && mounted) {
      setState(() => _locked = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final prefs = ref.watch(prefsProvider).value;
    final isLockConfigured = (prefs?.appLock ?? false);

    // Jika belum inisialisasi lokal, tampilkan layar pengunci aman
    if (!_initialized) {
      return const Scaffold(
        body: SafeArea(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                LuneraLogo(size: 88, showText: true, showTagline: true),
                SizedBox(height: 36),
                CircularProgressIndicator(color: C.lavender),
              ],
            ),
          ),
        ),
      );
    }

    if (!isLockConfigured && !_locked) {
      return widget.child;
    }

    if (!_locked) {
      return widget.child;
    }

    // Tampilan layar kunci biometrik
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const LuneraLogo(size: 90, showText: true, showTagline: true),
                gap(36),
                const Icon(Icons.lock_rounded, size: 48, color: C.lavender),
                gap(12),
                Text('App Locked', style: display(22)),
                gap(8),
                Text(
                  'Use biometrics or fingerprint to unlock Lunera.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: .7)),
                ),
                gap(28),
                pillButton('Unlock', _promptAuth, icon: Icons.fingerprint_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
