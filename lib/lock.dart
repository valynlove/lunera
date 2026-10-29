import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';

class AppLockState {
  const AppLockState({this.enabled = false, this.bio = false, this.delayMin = 1});
  final bool enabled, bio;
  final int delayMin; // kunci lagi setelah ditinggalkan sekian menit (0 = segera)
}

/// Kunci aplikasi. Disimpan per perangkat (bukan tersinkron), supaya PIN di HP
/// tidak mengunci Chrome atau perangkat lain.
class Lock {
  Lock._();
  static final instance = Lock._();

  final state = ValueNotifier<AppLockState>(const AppLockState());
  final _auth = LocalAuthentication();
  SharedPreferences? _p;

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    _emit();
  }

  void _emit() {
    final p = _p;
    if (p == null) return;
    state.value = AppLockState(
      enabled: p.getString('lock.hash') != null,
      bio: p.getBool('lock.bio') ?? false,
      delayMin: p.getInt('lock.delay') ?? 1,
    );
  }

  String _hash(String pin, String salt) => sha256.convert(utf8.encode('$salt:$pin')).toString();

  Future<void> setPin(String pin) async {
    final salt = base64Url.encode(List<int>.generate(16, (_) => Random.secure().nextInt(256)));
    await _p!.setString('lock.salt', salt);
    await _p!.setString('lock.hash', _hash(pin, salt));
    _emit();
  }

  bool verify(String pin) {
    final salt = _p?.getString('lock.salt'), h = _p?.getString('lock.hash');
    return salt != null && h != null && _hash(pin, salt) == h;
  }

  Future<void> disable() async {
    for (final k in const ['lock.salt', 'lock.hash', 'lock.bio']) {
      await _p?.remove(k);
    }
    _emit();
  }

  Future<void> setBio(bool v) async {
    await _p?.setBool('lock.bio', v);
    _emit();
  }

  Future<void> setDelay(int minutes) async {
    await _p?.setInt('lock.delay', minutes);
    _emit();
  }

  Future<bool> bioAvailable() async {
    if (kIsWeb) return false;
    try {
      return await _auth.canCheckBiometrics && await _auth.isDeviceSupported();
    } catch (_) {
      return false;
    }
  }

  /// Gagal (termasuk belum disiapkan di Android) dianggap tidak lolos; PIN tetap bisa dipakai.
  Future<bool> authBio() async {
    try {
      return await _auth.authenticate(
        localizedReason: 'Buka $appName',
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }
}

