import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'theme.dart';
import 'l10n.dart';

const int kPinPbkdf2Iterations = 60000;

/// PBKDF2-HMAC-SHA256 (RFC 8018, 32-byte derived key).
String pbkdf2Sha256(String pin, List<int> saltBytes, {int iterations = kPinPbkdf2Iterations}) {
  final hmac = Hmac(sha256, utf8.encode(pin));
  final block1 = Uint8List(saltBytes.length + 4)
    ..setRange(0, saltBytes.length, saltBytes)
    ..[saltBytes.length + 3] = 1;
  var u = hmac.convert(block1).bytes;
  final out = Uint8List.fromList(u);
  for (var i = 1; i < iterations; i++) {
    u = hmac.convert(u).bytes;
    for (var j = 0; j < 32; j++) {
      out[j] ^= u[j];
    }
  }
  final sb = StringBuffer();
  for (final b in out) {
    sb.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return sb.toString();
}

String hashPinPbkdf2(String pin, String salt, {int iterations = kPinPbkdf2Iterations}) =>
    'pbkdf2\$sha256\$$iterations\$${pbkdf2Sha256(pin, utf8.encode(salt), iterations: iterations)}';

bool _constantTimeEquals(String a, String b) {
  if (a.length != b.length) return false;
  var diff = 0;
  for (var i = 0; i < a.length; i++) {
    diff |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
  }
  return diff == 0;
}

/// Memeriksa PIN terhadap hash PBKDF2 baru maupun hash SHA-256 lama (kompatibilitas mundur).
bool verifyPinHash(String pin, String salt, String storedHash) {
  if (storedHash.startsWith('pbkdf2\$')) {
    final parts = storedHash.split('\$');
    if (parts.length != 4 || parts[1] != 'sha256') return false;
    final iter = int.tryParse(parts[2]);
    if (iter == null || iter < 1000 || iter > 500000) return false;
    final actual = pbkdf2Sha256(pin, utf8.encode(salt), iterations: iter);
    return _constantTimeEquals(actual, parts[3]);
  }
  final legacy = sha256.convert(utf8.encode('$salt:$pin')).toString();
  return _constantTimeEquals(legacy, storedHash);
}

/// Ekstrak kandidat PIN 6 digit pada kalkulator samaran (hanya saat tidak ada operator aktif).
String? decoyPinCandidate({required String display, required String pinBuffer, required String? operator}) {
  if (operator != null) return null;
  if (RegExp(r'^\d{6}$').hasMatch(display)) return display;
  if (RegExp(r'^\d{6}$').hasMatch(pinBuffer)) return pinBuffer;
  return null;
}

class AppLockState {
  const AppLockState({
    this.enabled = false,
    this.bio = false,
    this.delayMin = 1,
    this.decoyCalculator = false,
    this.privacyShield = false,
  });
  final bool enabled, bio;
  final int delayMin; // kunci lagi setelah ditinggalkan sekian menit (0 = segera)
  final bool decoyCalculator; // samarkan sebagai kalkulator fungsional
  final bool privacyShield; // true = FLAG_SECURE aktif (sembunyikan preview app switcher dan cegah screenshot)
}

typedef LockState = AppLockState;

/// Kunci aplikasi dengan PIN dan Biometrik.
/// Disimpan per perangkat (offline-first) dan otomatis tersinkronkan dengan akun di Cloud Firestore
/// agar PIN di HP tidak mengunci Chrome atau perangkat lain, tapi tetap dapat dipulihkan.
class Lock {
  Lock._();
  static final instance = Lock._();

  static const int maxAttempts = 5;
  static const Duration lockoutDuration = Duration(seconds: 30);
  static const _channel = MethodChannel('com.example.ritme/app_utils');

  /// Atur perlindungan layar (FLAG_SECURE) ke native Android.
  /// Pada debug mode, otomatis dilewati agar developer tetap bisa mengambil tangkapan layar untuk testing.
  static Future<void> setSecureScreen(bool enabled, {bool forceInDebug = false}) async {
    if (kIsWeb) return;
    if (kDebugMode && enabled && !forceInDebug) {
      debugPrint('[Lock] Privacy Shield is bypassed in debug mode to allow screenshots');
      return;
    }
    try {
      await _channel.invokeMethod('setSecureScreen', {'secure': enabled});
    } catch (_) {}
  }

  final state = ValueNotifier<AppLockState>(const AppLockState());
  bool sessionUnlocked = false; // sudah dibuka di proses ini (bertahan saat aplikasi dibangun ulang karena ganti bahasa)
  final _auth = LocalAuthentication();
  SharedPreferences? _p;

  String? get _uid {
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  DateTime? get lockedUntil {
    final untilMs = _p?.getInt('lock.until') ?? 0;
    if (untilMs <= 0) return null;
    final until = DateTime.fromMillisecondsSinceEpoch(untilMs);
    return DateTime.now().isBefore(until) ? until : null;
  }

  bool get isLockedOut => lockedUntil != null;

  int get failCount => _p?.getInt('lock.fails') ?? 0;

  void _recordFailure() {
    final p = _p;
    if (p == null) return;
    final next = (p.getInt('lock.fails') ?? 0) + 1;
    if (next >= maxAttempts) {
      p.setInt('lock.fails', 0);
      p.setInt('lock.until', DateTime.now().add(lockoutDuration).millisecondsSinceEpoch);
    } else {
      p.setInt('lock.fails', next);
    }
  }

  void _clearFailures() {
    _p?.remove('lock.fails');
    _p?.remove('lock.until');
  }

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    _emit();
    if (state.value.privacyShield) {
      await setSecureScreen(true);
    }
    final uid = _uid;
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
      privacyShield: p.getBool('lock.privacyShield') ?? false,
    );
  }

  DocumentReference<Map<String, dynamic>> _doc(String uid) =>
      FirebaseFirestore.instance.collection('users').doc(uid).collection('meta').doc('security');

  Future<void> setPin(String pin) async {
    final salt = base64Url.encode(List<int>.generate(16, (_) => Random.secure().nextInt(256)));
    final hash = hashPinPbkdf2(pin, salt);
    final now = DateTime.now().millisecondsSinceEpoch;
    await _p!.setString('lock.salt', salt);
    await _p!.setString('lock.hash', hash);
    await _p!.setInt('lock.updatedAt', now);
    _clearFailures();
    _emit();

    final uid = _uid;
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

  Future<void> _upgradeLegacyHash(String upgradedHash) async {
    final p = _p;
    if (p == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await p.setString('lock.hash', upgradedHash);
    await p.setInt('lock.updatedAt', now);
    final uid = _uid;
    if (uid != null) {
      try {
        await _doc(uid).set({
          'hash': upgradedHash,
          'updatedAt': now,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Lock legacy hash upgrade sync failed: $e');
      }
    }
  }

  bool verify(String pin) {
    if (isLockedOut) return false;
    final salt = _p?.getString('lock.salt'), h = _p?.getString('lock.hash');
    if (salt == null || h == null) return false;
    if (verifyPinHash(pin, salt, h)) {
      _clearFailures();
      if (!h.startsWith('pbkdf2\$')) {
        _upgradeLegacyHash(hashPinPbkdf2(pin, salt));
      }
      return true;
    }
    _recordFailure();
    return false;
  }

  Future<void> disable() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    for (final k in const [
      'lock.salt',
      'lock.hash',
      'lock.bio',
      'lock.decoy',
      'lock.privacyShield',
      'lock.updatedAt',
      'lock.fails',
      'lock.until'
    ]) {
      await _p?.remove(k);
    }
    await setSecureScreen(false);
    _emit();

    final uid = _uid;
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

  Future<void> setPrivacyShield(bool v) async {
    await _p?.setBool('lock.privacyShield', v);
    await setSecureScreen(v);
    _emit();
  }

  Future<void> setBio(bool v) async {
    await _p?.setBool('lock.bio', v);
    _emit();
  }

  Future<void> setDecoyCalculator(bool v) async {
    await _p?.setBool('lock.decoy', v);
    _emit();

    final uid = _uid;
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

    final uid = _uid;
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
      final ok = await _auth.authenticate(
        localizedReason: tr('Open {0}', [appName]),
        options: const AuthenticationOptions(biometricOnly: true, stickyAuth: true),
      );
      if (ok) _clearFailures();
      return ok;
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
          for (final k in const ['lock.salt', 'lock.hash', 'lock.bio', 'lock.decoy', 'lock.fails', 'lock.until']) {
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
