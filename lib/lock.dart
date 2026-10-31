import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'l10n.dart';

class AppLockState {
  const AppLockState({
    this.enabled = false,
    this.bio = false,
    this.delayMin = 1,
    this.decoyCalculator = false,
  });
  final bool enabled, bio;
  final int delayMin; // kunci lagi setelah ditinggalkan sekian menit (0 = segera)
  final bool decoyCalculator; // samarkan sebagai kalkulator fungsional
}

typedef LockState = AppLockState;

/// Kunci aplikasi dengan PIN dan Biometrik.
/// Disimpan per perangkat (offline-first) dan otomatis tersinkronkan dengan akun di Cloud Firestore
/// agar PIN di HP tidak mengunci Chrome atau perangkat lain, tapi tetap dapat dipulihkan.
class Lock {
  Lock._();
  static final instance = Lock._();

  final state = ValueNotifier<AppLockState>(const AppLockState());
  bool sessionUnlocked = false; // sudah dibuka di proses ini (bertahan saat aplikasi dibangun ulang karena ganti bahasa)
  final _auth = LocalAuthentication();
  SharedPreferences? _p;

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    _emit();
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      syncWithCloud(uid);
    }
  }

  void _emit() {
    final p = _p;
    if (p == null) return;
    state.value = AppLockState(
      enabled: p.getString('lock.hash') != null,
      bio: p.getBool('lock.bio') ?? false,
      delayMin: p.getInt('lock.delay') ?? 1,
      decoyCalculator: p.getBool('lock.decoy') ?? false,
    );
  }

  String _hash(String pin, String salt) => sha256.convert(utf8.encode('$salt:$pin')).toString();

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('meta').doc('security');

  Future<void> setPin(String pin) async {
    final salt = base64Url.encode(List<int>.generate(16, (_) => Random.secure().nextInt(256)));
    final hash = _hash(pin, salt);
    final now = DateTime.now().millisecondsSinceEpoch;
    await _p!.setString('lock.salt', salt);
    await _p!.setString('lock.hash', hash);
    await _p!.setInt('lock.updatedAt', now);
    _emit();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await _doc(uid).set({
          'enabled': true,
          'salt': salt,
          'hash': hash,
          'delayMin': state.value.delayMin,
          'updatedAt': now,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Lock cloud sync failed: $e');
      }
    }
  }

  bool verify(String pin) {
    final salt = _p?.getString('lock.salt'), h = _p?.getString('lock.hash');
    return salt != null && h != null && _hash(pin, salt) == h;
  }

  Future<void> disable() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final k in const ['lock.salt', 'lock.hash', 'lock.bio', 'lock.decoy', 'lock.updatedAt']) {
      await _p?.remove(k);
    }
    _emit();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await _doc(uid).set({
          'enabled': false,
          'updatedAt': now,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Lock cloud sync disable failed: $e');
      }
    }
  }

  Future<void> setBio(bool v) async {
    await _p?.setBool('lock.bio', v);
    _emit();
  }

  Future<void> setDecoyCalculator(bool v) async {
    await _p?.setBool('lock.decoy', v);
    _emit();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && state.value.enabled) {
      try {
        await _doc(uid).set({
          'decoyCalculator': v,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Lock cloud decoy sync failed: $e');
      }
    }
  }

  Future<void> setDelay(int minutes) async {
    await _p?.setInt('lock.delay', minutes);
    _emit();

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null && state.value.enabled) {
      try {
        await _doc(uid).set({
          'delayMin': minutes,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Lock cloud delay sync failed: $e');
      }
    }
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
        localizedReason: tr('Open {0}', [appName]),
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
    } catch (_) {
      return false;
    }
  }

  /// Sinkronisasi kredensial PIN dari cloud saat login di perangkat baru.
  Future<void> syncWithCloud(String uid) async {
    if (_p == null) return;
    try {
      final snap = await _doc(uid).get();
      if (!snap.exists) return;
      final data = snap.data();
      if (data == null) return;

      final cloudEnabled = data['enabled'] as bool? ?? false;
      final cloudUpdated = data['updatedAt'] as int? ?? 0;
      final localUpdated = _p!.getInt('lock.updatedAt') ?? 0;

      if (cloudUpdated > localUpdated) {
        if (cloudEnabled) {
          final salt = data['salt'] as String?;
          final hash = data['hash'] as String?;
          final delay = data['delayMin'] as int? ?? 1;
          if (salt != null && hash != null) {
            await _p!.setString('lock.salt', salt);
            await _p!.setString('lock.hash', hash);
            await _p!.setInt('lock.delay', delay);
            await _p!.setBool('lock.decoy', data['decoyCalculator'] as bool? ?? false);
            await _p!.setInt('lock.updatedAt', cloudUpdated);
            _emit();
          }
        } else {
          for (final k in const ['lock.salt', 'lock.hash', 'lock.bio', 'lock.decoy']) {
            await _p!.remove(k);
          }
          await _p!.setInt('lock.updatedAt', cloudUpdated);
          _emit();
        }
      }
    } catch (e) {
      debugPrint('Cloud sync error for lock: $e');
    }
  }
}
