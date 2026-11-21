import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
    this.biometricAvailable = false,
    this.biometricTypes = const [],
  });

  final bool enabled;
  final bool bio;
  final int delayMin; // kunci lagi setelah ditinggalkan sekian menit (0 = segera / grace 3 detik)
  final bool decoyCalculator; // samarkan sebagai kalkulator fungsional
  final bool privacyShield; // true = FLAG_SECURE aktif (sembunyikan preview app switcher dan cegah screenshot)
  final bool biometricAvailable; // true = perangkat memiliki biometrik terdaftar
  final List<BiometricType> biometricTypes;

  bool get biometricEnabled => enabled && bio && biometricAvailable;
  bool get hasFace => biometricTypes.contains(BiometricType.face);
  bool get hasFingerprint => biometricTypes.contains(BiometricType.fingerprint);
  bool get isFaceOnly => hasFace && !hasFingerprint;
  bool get isFingerprintOnly => hasFingerprint && !hasFace;
}

typedef LockState = AppLockState;

/// Kunci aplikasi dengan PIN 6 digit (PBKDF2-HMAC-SHA256) dan Biometrik (Fingerprint / Face Unlock).
/// Rahasia PIN & status lockout disimpan per-akun di [FlutterSecureStorage] (Android Keystore / iOS Keychain)
/// dengan migrasi otomatis dari penyimpanan lama, isolasi per-UID, lockout eksponensial bertingkat,
/// clock-rollback guard, dan sinkronisasi Cloud Firestore (offline-first).
class Lock {
  Lock._();
  static final instance = Lock._();

  static const int maxAttempts = 5;
  static const Duration lockoutDuration = Duration(seconds: 30);
  static const _channel = MethodChannel('com.example.ritme/app_utils');
  static const _secretFields = ['hash', 'salt', 'fails', 'lockoutUntil', 'lockoutTier'];

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

  /// Menentukan nilai timestamp `updatedAt` remote yang aman dari manipulasi timestamp masa depan.
  static int clampRemoteUpdatedAtMs(int remoteAtMs, {int? nowMs}) {
    final refNow = nowMs ?? DateTime.now().millisecondsSinceEpoch;
    final maxAllowed = refNow + 300000; // toleransi clock skew 5 menit
    if (remoteAtMs > maxAllowed) {
      return refNow;
    }
    return remoteAtMs;
  }

  final state = ValueNotifier<AppLockState>(const AppLockState());
  final isLocked = ValueNotifier<bool>(false);
  bool sessionUnlocked = false; // sudah dibuka di proses ini (bertahan saat aplikasi dibangun ulang karena ganti bahasa)
  bool signingOut = false; // mencegah Shell tampil sesaat antara clearLocal() dan signOutAll()

  final _auth = LocalAuthentication();
  final _secureStorage = const FlutterSecureStorage();
  final Map<String, String> _secretCache = {};
  SharedPreferences? _p;

  String? _activeUid;
  bool _hasLoaded = false;
  bool _pendingAutoLockOnEnable = false;
  StreamSubscription<User?>? _authSub;
  Future<void> _loadUserQueue = Future<void>.value();
  final Map<String, Future<void>> _inFlightLocalLoad = {};

  bool _biometricAvailable = false;
  List<BiometricType> _biometricTypes = const [];

  Future<void>? _inFlightSync;
  String? _inFlightSyncUid;
  String? _lastSyncedUid;

  bool _isAuthenticating = false;
  DateTime? _lastBiometricAuthEndedAt;

  /// Menandakan `Lock.instance.load()` telah selesai berjalan minimal sekali.
  bool get isInitialized => _hasLoaded;

  /// Memeriksa apakah kunci untuk [uid] (`null` = tamu) sudah dimuat ke memori.
  bool isLoadedFor(String? uid) => _hasLoaded && _activeUid == uid;

  /// Mengambil dan mengosongkan penanda bahwa perubahan status PIN ke aktif
  /// berasal dari pemuatan akun/sinkronisasi (bukan setup PIN interaktif).
  bool consumeAutoLockOnEnable() {
    final v = _pendingAutoLockOnEnable;
    _pendingAutoLockOnEnable = false;
    return v;
  }

  /// Menandakan apakah dialog biometrik sistem sedang aktif (atau baru saja ditutup)
  /// agar transisi lifecycle pause/resume dari dialog OS tidak memicu penguncian ulang.
  bool get isAuthenticating {
    if (_isAuthenticating) return true;
    final ended = _lastBiometricAuthEndedAt;
    if (ended != null &&
        DateTime.now().difference(ended) < const Duration(milliseconds: 1200)) {
      return true;
    }
    return false;
  }

  bool get isAuthenticatingBiometric => isAuthenticating;

  int _externalActivityDepth = 0;
  DateTime? _suppressLockUntil;

  /// Status apakah penguncian otomatis sedang ditangguhkan sementara
  /// (misalnya saat pengguna sedang berada di picker foto profil, kamera, atau dialog file eksternal).
  bool get isLockSuppressed {
    if (_externalActivityDepth > 0) return true;
    final until = _suppressLockUntil;
    if (until != null) {
      return DateTime.now().isBefore(until);
    }
    return false;
  }

  /// Tangguhkan penguncian otomatis sementara selama aksi eksternal berlangsung
  /// (seperti memilih foto profil, mengambil foto dengan kamera, atau mengimpor file backup).
  /// Setelah aksi selesai, diberikan grace window tambahan (default 3 detik) agar Flutter
  /// dapat kembali fokus ke layar tanpa memicu kunci seketika.
  Future<T> suppressLockDuring<T>(
    Future<T> Function() action, {
    Duration gracePeriod = const Duration(seconds: 3),
  }) async {
    _externalActivityDepth++;
    try {
      return await action();
    } finally {
      _externalActivityDepth--;
      _suppressLockUntil = DateTime.now().add(gracePeriod);
    }
  }

  /// Perpanjang jeda waktu penangguhan kunci (grace period) secara manual.
  void extendGracePeriod([Duration duration = const Duration(seconds: 3)]) {
    final target = DateTime.now().add(duration);
    if (_suppressLockUntil == null || target.isAfter(_suppressLockUntil!)) {
      _suppressLockUntil = target;
    }
  }

  String? get _uid {
    if (_activeUid != null) return _activeUid;
    try {
      return FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      return null;
    }
  }

  String get _currentUid => _uid ?? 'guest';

  String _k(String key, [String? uid]) {
    final u = uid ?? _currentUid;
    return 'lock.$key.$u';
  }

  String? _getSecret(String key) => _secretCache[key] ?? _p?.getString(key);

  int? _getSecretInt(String key) {
    final raw = _secretCache[key];
    if (raw != null) {
      final parsed = int.tryParse(raw);
      if (parsed != null) return parsed;
    }
    final legacyObj = _p?.get(key);
    if (legacyObj is int) return legacyObj;
    if (legacyObj is String) return int.tryParse(legacyObj);
    return null;
  }

  Future<void> _writeSecret(String key, String value) async {
    _secretCache[key] = value;
    if (!kIsWeb) {
      try {
        await _secureStorage.write(key: key, value: value);
        await _p?.remove(key);
        return;
      } catch (_) {
        // Fallback ke SharedPreferences pada lingkungan unit test tanpa plugin native
      }
    }
    await _p?.setString(key, value);
  }

  Future<void> _deleteSecret(String key) async {
    _secretCache.remove(key);
    await _p?.remove(key);
    if (!kIsWeb) {
      try {
        await _secureStorage.delete(key: key);
      } catch (_) {}
    }
  }

  Future<void> _loadSecretsForUid(String? uid) async {
    final targetUid = uid ?? 'guest';
    for (final field in _secretFields) {
      final key = _k(field, targetUid);
      String? val;
      var secureOk = false;
      if (!kIsWeb) {
        try {
          val = await _secureStorage.read(key: key);
          secureOk = true;
        } catch (_) {}
      }
      final legacyObj = _p?.get(key);
      final legacyVal = legacyObj?.toString();
      if (val != null) {
        _secretCache[key] = val;
        if (legacyObj != null) {
          await _p?.remove(key);
        }
      } else if (legacyVal != null) {
        _secretCache[key] = legacyVal;
        if (secureOk) {
          try {
            await _secureStorage.write(key: key, value: legacyVal);
            await _p?.remove(key);
          } catch (_) {}
        }
      } else {
        _secretCache.remove(key);
      }
    }
  }

  Future<void> _migrateLegacyIfNeeded(String? uid) async {
    final p = _p;
    if (p == null) return;
    final targetUid = uid ?? 'guest';
    final scopedHash = _getSecret(_k('hash', targetUid));
    final legacyHash = p.getString('lock.hash');
    if (scopedHash == null && legacyHash != null) {
      await _writeSecret(_k('hash', targetUid), legacyHash);
      final legacySalt = p.getString('lock.salt');
      if (legacySalt != null) await _writeSecret(_k('salt', targetUid), legacySalt);
      final legacyFails = p.getInt('lock.fails');
      if (legacyFails != null) await _writeSecret(_k('fails', targetUid), legacyFails.toString());
      final legacyUntil = p.getInt('lock.until');
      if (legacyUntil != null) await _writeSecret(_k('lockoutUntil', targetUid), legacyUntil.toString());
      final legacyDelay = p.getInt('lock.delay');
      if (legacyDelay != null) await p.setInt(_k('delay', targetUid), legacyDelay);
      final legacyBio = p.getBool('lock.bio');
      if (legacyBio != null) await p.setBool(_k('bio', targetUid), legacyBio);
      final legacyDecoy = p.getBool('lock.decoy');
      if (legacyDecoy != null) await p.setBool(_k('decoy', targetUid), legacyDecoy);
      final legacyAt = p.getInt('lock.updatedAt');
      if (legacyAt != null) await p.setInt(_k('updatedAt', targetUid), legacyAt);

      for (final legacyKey in const [
        'lock.hash',
        'lock.salt',
        'lock.fails',
        'lock.until',
        'lock.delay',
        'lock.bio',
        'lock.decoy',
        'lock.updatedAt',
      ]) {
        await p.remove(legacyKey);
      }
    }
  }

  /// Waktu berakhirnya penalti lockout akibat salah mengetik PIN berulang kali (disimpan persisten).
  /// Dilengkapi penjaga manipulasi jam sistem mundur (clock-rollback guard).
  DateTime? get lockoutUntil {
    final ms = _getSecretInt(_k('lockoutUntil'));
    if (ms == null || ms <= 0) return null;
    final now = DateTime.now();
    final until = DateTime.fromMillisecondsSinceEpoch(ms);
    final diffMs = until.difference(now).inMilliseconds;
    if (diffMs <= 0) return null;
    // Maksimum penalti adalah 300 detik. Jika selisih > 305 detik, berarti jam perangkat dimundurkan.
    if (diffMs > 305000) {
      final clamped = now.add(const Duration(seconds: 300));
      unawaited(_writeSecret(_k('lockoutUntil'), clamped.millisecondsSinceEpoch.toString()));
      return clamped;
    }
    return until;
  }

  /// Alias kompatibilitas mundur untuk [lockoutUntil].
  DateTime? get lockedUntil => lockoutUntil;

  /// Apakah saat ini sedang dalam masa penalti lockout brute-force PIN.
  bool get isLockedOut => lockoutUntil != null;

  /// Sisa detik penalti lockout saat ini (0 jika tidak terkunci).
  int get remainingLockoutSeconds {
    final until = lockoutUntil;
    if (until == null) return 0;
    return (until.difference(DateTime.now()).inMilliseconds / 1000)
        .ceil()
        .clamp(1, 300);
  }

  int get failCount => _getSecretInt(_k('fails')) ?? 0;

  int get lockoutTier => _getSecretInt(_k('lockoutTier')) ?? 0;

  Future<void> _clearLockoutState([String? uid]) async {
    final targetUid = uid ?? _currentUid;
    await _deleteSecret(_k('fails', targetUid));
    await _deleteSecret(_k('lockoutUntil', targetUid));
    await _deleteSecret(_k('lockoutTier', targetUid));
  }

  void _recordFailure() {
    final uid = _currentUid;
    final next = (_getSecretInt(_k('fails', uid)) ?? 0) + 1;
    if (next >= maxAttempts) {
      final tier = (_getSecretInt(_k('lockoutTier', uid)) ?? 0) + 1;
      final penaltySec = switch (tier) {
        1 => 30,
        2 => 120,
        _ => 300,
      };
      final untilMs = DateTime.now()
          .add(Duration(seconds: penaltySec))
          .millisecondsSinceEpoch;
      unawaited(_writeSecret(_k('fails', uid), '0'));
      unawaited(_writeSecret(_k('lockoutTier', uid), tier.toString()));
      unawaited(_writeSecret(_k('lockoutUntil', uid), untilMs.toString()));
    } else {
      unawaited(_writeSecret(_k('fails', uid), next.toString()));
    }
  }

  Future<void> load() async {
    _p = await SharedPreferences.getInstance();
    try {
      _activeUid = FirebaseAuth.instance.currentUser?.uid;
    } catch (_) {
      _activeUid = null;
    }
    await _loadSecretsForUid(_activeUid);
    await _migrateLegacyIfNeeded(_activeUid);
    _hasLoaded = true;
    await refreshBiometricSupport();
    if (state.value.privacyShield) {
      await setSecureScreen(true);
    }
    try {
      final uid = _activeUid;
      if (uid != null) {
        unawaited(syncWithCloud(uid));
      }
      await _authSub?.cancel();
      _authSub = FirebaseAuth.instance.authStateChanges().listen(
        (u) {
          final nextUid = u?.uid;
          if (_hasLoaded && nextUid == _activeUid) return;
          unawaited(loadForUser(nextUid));
        },
        onError: (Object e) {
          debugPrint('Auth state listener error in Lock: $e');
        },
      );
    } catch (e) {
      debugPrint('Firebase not available for lock sync: $e');
    }
  }

  /// Memuat hanya state PIN lokal untuk [uid] (cepat, tanpa menunggu jaringan Firestore)
  /// agar [LockGate] tidak me-mount UI utama sebelum status kunci lokal diketahui.
  Future<void> ensureLocalLoaded(String? uid) {
    final key = uid ?? 'guest';
    final existing = _inFlightLocalLoad[key];
    if (existing != null) return existing;

    final future = () async {
      _p = await SharedPreferences.getInstance();
      _activeUid = uid;
      await _loadSecretsForUid(uid);
      await _migrateLegacyIfNeeded(uid);
      _hasLoaded = true;
      _emit();
    }().whenComplete(() {
      _inFlightLocalLoad.remove(key);
    });

    _inFlightLocalLoad[key] = future;
    return future;
  }

  Future<void> loadForUser(String? uid) {
    _loadUserQueue = _loadUserQueue.catchError((_) {}).then((_) async {
      await ensureLocalLoaded(uid);
      if (uid != null) {
        await syncWithCloud(uid);
      }
    });
    return _loadUserQueue;
  }

  /// Periksa ketersediaan dan jenis sensor biometrik yang terdaftar di perangkat.
  Future<void> refreshBiometricSupport() async {
    if (kIsWeb) {
      _biometricAvailable = false;
      _biometricTypes = const [];
      _emit();
      return;
    }
    try {
      final canCheck = await _auth.canCheckBiometrics;
      final isSupported = await _auth.isDeviceSupported();
      if (canCheck && isSupported) {
        final enrolled = await _auth.getAvailableBiometrics();
        _biometricTypes = enrolled;
        _biometricAvailable = enrolled.isNotEmpty;
      } else {
        _biometricTypes = const [];
        _biometricAvailable = false;
      }
    } catch (e) {
      debugPrint('Failed to check biometric support: $e');
      _biometricTypes = const [];
      _biometricAvailable = false;
    }
    _emit();
  }

  void _emit({bool suppressAutoLock = false}) {
    final p = _p;
    if (p == null) return;
    final wasEnabled = state.value.enabled;
    final enabled = _getSecret(_k('hash')) != null;
    final bioPref = p.getBool(_k('bio')) ?? false;
    _pendingAutoLockOnEnable = !suppressAutoLock && !wasEnabled && enabled;
    state.value = AppLockState(
      enabled: enabled,
      bio: enabled && bioPref,
      delayMin: p.getInt(_k('delay')) ?? 1,
      decoyCalculator: p.getBool(_k('decoy')) ?? false,
      privacyShield: p.getBool('lock.privacyShield') ?? false,
      biometricAvailable: _biometricAvailable,
      biometricTypes: _biometricTypes,
    );
    _pendingAutoLockOnEnable = false;
    if (!enabled) {
      isLocked.value = false;
    }
  }

  DocumentReference<Map<String, dynamic>>? _doc(String uid) {
    try {
      return FirebaseFirestore.instance.collection('users').doc(uid).collection('meta').doc('security');
    } catch (_) {
      return null;
    }
  }

  Future<void> setPin(String pin) async {
    final salt = base64Url.encode(List<int>.generate(16, (_) => Random.secure().nextInt(256)));
    final hash = hashPinPbkdf2(pin, salt);
    final now = DateTime.now().millisecondsSinceEpoch;
    final uid = _currentUid;
    await _writeSecret(_k('salt', uid), salt);
    await _writeSecret(_k('hash', uid), hash);
    await _p!.setInt(_k('updatedAt', uid), now);
    await _clearLockoutState(uid);
    _emit(suppressAutoLock: true);

    final userUid = _uid;
    if (userUid != null) {
      try {
        await _doc(userUid)?.set({
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

  Future<void> _upgradeLegacyHash(String upgradedHash, String uid) async {
    final p = _p;
    if (p == null) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    await _writeSecret(_k('hash', uid), upgradedHash);
    await p.setInt(_k('updatedAt', uid), now);
    final userUid = _uid;
    if (userUid != null && userUid == uid) {
      try {
        await _doc(userUid)?.set({
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
    final uid = _currentUid;
    final salt = _getSecret(_k('salt', uid));
    final h = _getSecret(_k('hash', uid));
    if (salt == null || h == null) return false;
    if (verifyPinHash(pin, salt, h)) {
      unawaited(_clearLockoutState(uid));
      if (!h.startsWith('pbkdf2\$')) {
        unawaited(_upgradeLegacyHash(hashPinPbkdf2(pin, salt), uid));
      }
      return true;
    }
    _recordFailure();
    return false;
  }

  /// Menghapus kredensial dan status kunci hanya pada perangkat ini tanpa mengubah konfigurasi cloud.
  Future<void> clearLocal([String? uid]) async {
    final targetUid = uid ?? _currentUid;
    await _deleteSecret(_k('salt', targetUid));
    await _deleteSecret(_k('hash', targetUid));
    await _clearLockoutState(targetUid);
    for (final k in [
      _k('bio', targetUid),
      _k('decoy', targetUid),
      _k('delay', targetUid),
      _k('updatedAt', targetUid),
      // Bersihkan juga kunci legacy tidak terscope bila masih tersisa
      'lock.salt',
      'lock.hash',
      'lock.bio',
      'lock.decoy',
      'lock.delay',
      'lock.updatedAt',
      'lock.fails',
      'lock.until',
    ]) {
      await _p?.remove(k);
    }
    if (targetUid == _currentUid) {
      await _p?.remove('lock.privacyShield');
      sessionUnlocked = false;
      _lastSyncedUid = null;
      isLocked.value = false;
      await setSecureScreen(false);
      _emit();
    }
  }

  Future<void> disable() async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final uid = _currentUid;
    await _deleteSecret(_k('salt', uid));
    await _deleteSecret(_k('hash', uid));
    await _clearLockoutState(uid);
    await _p?.remove(_k('bio', uid));
    await _p?.remove(_k('decoy', uid));
    await _p?.remove('lock.privacyShield');
    await _p?.setInt(_k('updatedAt', uid), now);
    sessionUnlocked = false;
    isLocked.value = false;
    await setSecureScreen(false);
    _emit();

    final userUid = _uid;
    if (userUid != null) {
      try {
        await _doc(userUid)?.set({
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
    await _p?.setBool(_k('bio'), v);
    _emit();
  }

  /// Aktifkan atau nonaktifkan pembuka kunci biometrik untuk pengguna saat ini.
  /// Saat diaktifkan, pengguna wajib memverifikasi biometrik terlebih dahulu.
  Future<bool> setBiometric(bool enabled, {String? localizedReason}) async {
    final p = _p;
    if (p == null) return false;
    if (enabled) {
      await refreshBiometricSupport();
      if (!_biometricAvailable) return false;
      final ok = await authBio(localizedReason: localizedReason);
      if (!ok) return false;
    }
    await p.setBool(_k('bio', _currentUid), enabled);
    _emit();
    return true;
  }

  Future<void> setDecoyCalculator(bool v) async {
    await _p?.setBool(_k('decoy'), v);
    _emit();

    final userUid = _uid;
    if (userUid != null && state.value.enabled) {
      try {
        await _doc(userUid)?.set({
          'decoyCalculator': v,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Lock cloud decoy sync failed: $e');
      }
    }
  }

  Future<void> setDelay(int minutes) async {
    final clamped = minutes.clamp(0, 60);
    await _p?.setInt(_k('delay'), clamped);
    await _p?.setInt(_k('updatedAt'), DateTime.now().millisecondsSinceEpoch);
    _emit();

    final userUid = _uid;
    if (userUid != null && state.value.enabled) {
      try {
        await _doc(userUid)?.set({
          'delayMin': clamped,
          'updatedAt': DateTime.now().millisecondsSinceEpoch,
        }, SetOptions(merge: true));
      } catch (e) {
        debugPrint('Lock cloud delay sync failed: $e');
      }
    }
  }

  Future<bool> bioAvailable() async {
    await refreshBiometricSupport();
    return _biometricAvailable;
  }

  /// Gagal (termasuk belum disiapkan di Android) dianggap tidak lolos; PIN tetap bisa dipakai.
  /// Dilindungi mutex _isAuthenticating, cooldown 1200ms pasca-dialog, dan blokir saat lockout aktif.
  Future<bool> authBio({String? localizedReason}) async {
    if (kIsWeb || _isAuthenticating || isLockedOut) return false;
    _isAuthenticating = true;
    try {
      final ok = await _auth.authenticate(
        localizedReason: localizedReason ?? tr('Open {0}', [appName]),
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: false,
        ),
      );
      if (ok) {
        await _clearLockoutState();
      }
      return ok;
    } catch (_) {
      return false;
    } finally {
      _isAuthenticating = false;
      _lastBiometricAuthEndedAt = DateTime.now();
    }
  }

  bool hasSyncedFor(String uid) => _lastSyncedUid == uid;

  /// Reset penanda sinkronisasi per sesi (mis. saat uji unit atau pergantian akun).
  void resetSyncCache() {
    _inFlightSync = null;
    _inFlightSyncUid = null;
    _lastSyncedUid = null;
  }

  /// Sinkronisasi kredensial PIN dari cloud saat startup atau login di perangkat baru.
  Future<void> syncWithCloud(String uid, {Duration timeout = const Duration(seconds: 4)}) {
    if (_p == null) return Future.value();
    if (_inFlightSync != null && _inFlightSyncUid == uid) {
      return _inFlightSync!;
    }
    _inFlightSyncUid = uid;
    late final Future<void> run;
    run = _performCloudSync(uid, timeout: timeout).whenComplete(() {
      if (identical(_inFlightSync, run)) {
        _inFlightSync = null;
        _inFlightSyncUid = null;
      }
    });
    _inFlightSync = run;
    return run;
  }

  Future<void> _performCloudSync(String uid, {required Duration timeout}) async {
    if (_p == null) return;
    try {
      final doc = _doc(uid);
      if (doc == null) return;
      DocumentSnapshot<Map<String, dynamic>> snap;
      try {
        snap = await doc.get().timeout(timeout);
      } catch (_) {
        // Offline-First: fallback ke cache lokal Firestore jika server tidak terjangkau / timeout.
        snap = await doc.get(const GetOptions(source: Source.cache));
      }
      _lastSyncedUid = uid;
      if (!snap.exists) return;
      await applyCloudLockData(snap.data(), uid: uid);
    } catch (e) {
      debugPrint('Cloud sync error for lock: $e');
    }
  }

  /// Menerapkan snapshot konfigurasi kunci dari cloud ke penyimpanan lokal bila lebih baru.
  Future<void> applyCloudLockData(Map<String, dynamic>? data, {String? uid}) async {
    if (_p == null || data == null) return;
    final targetUid = uid ?? _currentUid;

    final cloudEnabled = data['enabled'] as bool? ?? false;
    final rawCloudUpdated = (data['updatedAt'] as num?)?.toInt() ?? 0;
    final cloudUpdated = clampRemoteUpdatedAtMs(rawCloudUpdated);
    final localUpdated = _p!.getInt(_k('updatedAt', targetUid)) ?? 0;

    if (cloudUpdated > localUpdated) {
      if (cloudEnabled) {
        final salt = data['salt'] as String?;
        final hash = data['hash'] as String?;
        final delay = ((data['delayMin'] as num?)?.toInt() ?? 1).clamp(0, 60);
        if (salt != null && hash != null && salt.isNotEmpty && hash.isNotEmpty) {
          await _writeSecret(_k('salt', targetUid), salt);
          await _writeSecret(_k('hash', targetUid), hash);
          await _p!.setInt(_k('delay', targetUid), delay);
          await _p!.setBool(_k('decoy', targetUid), data['decoyCalculator'] as bool? ?? false);
          await _p!.setInt(_k('updatedAt', targetUid), cloudUpdated);
          if (targetUid == _currentUid) _emit();
        }
      } else {
        await _deleteSecret(_k('salt', targetUid));
        await _deleteSecret(_k('hash', targetUid));
        await _clearLockoutState(targetUid);
        for (final k in [_k('bio', targetUid), _k('decoy', targetUid), _k('delay', targetUid)]) {
          await _p!.remove(k);
        }
        await _p!.setInt(_k('updatedAt', targetUid), cloudUpdated);
        if (targetUid == _currentUid) _emit();
      }
    }
  }
}
