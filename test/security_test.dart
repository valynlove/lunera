import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:local_auth/local_auth.dart';
import 'package:lunera/lock.dart';
import 'package:lunera/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Lunera Security & Authentication Tests', () {
    test(
        'AppLockState default values, decoyCalculator, privacyShield, and biometric helpers',
        () {
      const state = AppLockState();
      expect(state.enabled, isFalse);
      expect(state.delayMin, equals(1));
      expect(state.decoyCalculator, isFalse);
      expect(state.privacyShield, isFalse);
      expect(state.biometricAvailable, isFalse);
      expect(state.biometricEnabled, isFalse);
      expect(state.hasFace, isFalse);
      expect(state.hasFingerprint, isFalse);

      const faceOnly = AppLockState(
        enabled: true,
        bio: true,
        decoyCalculator: true,
        privacyShield: true,
        biometricAvailable: true,
        biometricTypes: [BiometricType.face],
      );
      expect(faceOnly.decoyCalculator, isTrue);
      expect(faceOnly.privacyShield, isTrue);
      expect(faceOnly.biometricEnabled, isTrue);
      expect(faceOnly.hasFace, isTrue);
      expect(faceOnly.isFaceOnly, isTrue);
      expect(faceOnly.isFingerprintOnly, isFalse);

      const fpOnly = AppLockState(
        enabled: true,
        bio: true,
        biometricAvailable: true,
        biometricTypes: [BiometricType.fingerprint],
      );
      expect(fpOnly.hasFingerprint, isTrue);
      expect(fpOnly.isFingerprintOnly, isTrue);
      expect(fpOnly.isFaceOnly, isFalse);
    });

    test('Decoy calculator number formatting and candidate extraction logic',
        () {
      String fmt(double v) {
        if (v.isNaN || v.isInfinite) return 'Error';
        if (v == v.roundToDouble()) return v.toInt().toString();
        return v.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
      }

      expect(fmt(10.0), equals('10'));
      expect(fmt(12.5), equals('12.5'));
      expect(fmt(1 / 3), startsWith('0.333333'));
      expect(fmt(0.0), equals('0'));

      // Candidate extraction: normal PIN, leading-zero PIN, and math operations
      expect(
          decoyPinCandidate(
              display: '987654', pinBuffer: '987654', operator: null),
          equals('987654'));
      expect(
          decoyPinCandidate(
              display: '12345', pinBuffer: '012345', operator: null),
          equals('012345'));
      expect(
          decoyPinCandidate(
              display: '100000', pinBuffer: '100000', operator: '+'),
          isNull);
      expect(decoyPinCandidate(display: '42', pinBuffer: '42', operator: null),
          isNull);
    });

    test(
        'PBKDF2-HMAC-SHA256 PIN hashing, legacy migration, and persistent tiered lockout',
        () async {
      // Standard PBKDF2-HMAC-SHA256 test vector (RFC 7914 / hashlib)
      final vec1 = pbkdf2Sha256('passwd', utf8.encode('salt'), iterations: 1);
      expect(
          vec1,
          equals(
              '55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc'));

      // PBKDF2 PIN hash and verification
      final pbkdf2Hash =
          hashPinPbkdf2('246810', 'test-salt-123', iterations: 2000);
      expect(pbkdf2Hash, startsWith(r'pbkdf2$sha256$2000$'));
      expect(verifyPinHash('246810', 'test-salt-123', pbkdf2Hash), isTrue);
      expect(verifyPinHash('000000', 'test-salt-123', pbkdf2Hash), isFalse);

      // Legacy single-round SHA-256 + unscoped keys migration and automatic upgrade to PBKDF2
      const legacySalt = 'legacy-salt-abc';
      final legacySha =
          sha256.convert(utf8.encode('$legacySalt:012345')).toString();
      SharedPreferences.setMockInitialValues({
        'lock.salt': legacySalt,
        'lock.hash': legacySha,
        'lock.updatedAt': 100,
      });
      await Lock.instance.load();
      final prefs = await SharedPreferences.getInstance();
      // Legacy unscoped keys were migrated and removed
      expect(prefs.containsKey('lock.hash'), isFalse);
      expect(prefs.containsKey('lock.salt'), isFalse);
      expect(Lock.instance.verify('012345'), isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 20));
      expect(prefs.getString('lock.hash.guest'), startsWith(r'pbkdf2$sha256$'));

      // Persistent 5-attempt tiered lockout survives reload
      for (var i = 0; i < 4; i++) {
        expect(Lock.instance.verify('999999'), isFalse);
        expect(Lock.instance.isLockedOut, isFalse);
      }
      expect(Lock.instance.verify('999999'),
          isFalse); // 5th wrong attempt triggers tier 1 (30s) lockout
      expect(Lock.instance.isLockedOut, isTrue);
      expect(Lock.instance.lockoutTier, equals(1));
      expect(Lock.instance.remainingLockoutSeconds, inInclusiveRange(1, 30));
      expect(Lock.instance.verify('012345'),
          isFalse); // Even valid PIN is blocked while locked out

      // Simulate app restart by calling load() again
      await Lock.instance.load();
      expect(Lock.instance.isLockedOut, isTrue);
      expect(Lock.instance.lockoutTier, equals(1));
      expect(Lock.instance.verify('012345'), isFalse);

      // Clock-rollback guard clamps manipulated future lockoutUntil to max 300s
      final farFuture =
          DateTime.now().add(const Duration(hours: 2)).millisecondsSinceEpoch;
      await prefs.setString('lock.lockoutUntil.guest', farFuture.toString());
      await Lock.instance.load();
      expect(Lock.instance.isLockedOut, isTrue);
      expect(Lock.instance.remainingLockoutSeconds, lessThanOrEqualTo(300));

      await Lock.instance.disable();
      expect(Lock.instance.isLockedOut, isFalse);
      expect(Lock.instance.lockoutTier, equals(0));
    });

    test(
        'Per-UID isolation keeps accounts separated and clampRemoteUpdatedAtMs guards future timestamps',
        () async {
      SharedPreferences.setMockInitialValues({});
      await Lock.instance.ensureLocalLoaded('user-a');
      await Lock.instance.setPin('111222');
      expect(Lock.instance.state.value.enabled, isTrue);
      expect(Lock.instance.verify('111222'), isTrue);

      // Switching to user-b does not inherit user-a's PIN
      await Lock.instance.ensureLocalLoaded('user-b');
      expect(Lock.instance.state.value.enabled, isFalse);
      expect(Lock.instance.verify('111222'), isFalse);

      // Switching back to user-a restores user-a's PIN cleanly
      await Lock.instance.ensureLocalLoaded('user-a');
      expect(Lock.instance.state.value.enabled, isTrue);
      expect(Lock.instance.verify('111222'), isTrue);

      // clampRemoteUpdatedAtMs clamps timestamps > now + 5 minutes
      const now = 1700000000000;
      expect(Lock.clampRemoteUpdatedAtMs(now + 60000, nowMs: now),
          equals(now + 60000));
      expect(
          Lock.clampRemoteUpdatedAtMs(now + 900000, nowMs: now), equals(now));

      await Lock.instance.clearLocal('user-a');
      await Lock.instance.clearLocal('user-b');
    });

    test(
        'Lock suppression and grace period protects external activities cleanly',
        () async {
      expect(Lock.instance.isLockSuppressed, isFalse);

      // Running within suppressLockDuring marks lock as suppressed
      final result = await Lock.instance.suppressLockDuring(() async {
        expect(Lock.instance.isLockSuppressed, isTrue);
        return 42;
      }, gracePeriod: const Duration(milliseconds: 80));

      expect(result, equals(42));
      // Immediately after completion, grace window keeps lock suppressed
      expect(Lock.instance.isLockSuppressed, isTrue);

      // Wait for grace period to expire
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(Lock.instance.isLockSuppressed, isFalse);

      // Manual extension of grace window
      Lock.instance.extendGracePeriod(const Duration(milliseconds: 80));
      expect(Lock.instance.isLockSuppressed, isTrue);
      await Future<void>.delayed(const Duration(milliseconds: 120));
      expect(Lock.instance.isLockSuppressed, isFalse);
    });

    test(
        'clearLocal wipes only local device lock keys and restores cleanly from cloud snapshot on re-login',
        () async {
      const salt = 'cloud-salt-xyz';
      final hash = hashPinPbkdf2('654321', salt, iterations: 2000);
      SharedPreferences.setMockInitialValues({
        'lock.salt': salt,
        'lock.hash': hash,
        'lock.bio': true,
        'lock.decoy': true,
        'lock.delay': 5,
        'lock.privacyShield': true,
        'lock.updatedAt': 1000,
      });
      await Lock.instance.load();
      Lock.instance.sessionUnlocked = true;
      expect(Lock.instance.state.value.enabled, isTrue);

      // clearLocal removes local keys & resets sessionUnlocked without altering remote cloud configuration
      await Lock.instance.clearLocal();
      final prefs = await SharedPreferences.getInstance();
      for (final k in const [
        'lock.salt',
        'lock.hash',
        'lock.bio',
        'lock.decoy',
        'lock.delay',
        'lock.privacyShield',
        'lock.updatedAt',
        'lock.fails',
        'lock.until',
        'lock.salt.guest',
        'lock.hash.guest',
        'lock.bio.guest',
        'lock.decoy.guest',
        'lock.delay.guest',
        'lock.updatedAt.guest',
        'lock.fails.guest',
        'lock.lockoutUntil.guest',
        'lock.lockoutTier.guest',
      ]) {
        expect(prefs.containsKey(k), isFalse);
      }
      expect(Lock.instance.state.value.enabled, isFalse);
      expect(Lock.instance.sessionUnlocked, isFalse);

      // Simulate re-login cloud sync applying intact remote PIN configuration
      await Lock.instance.applyCloudLockData({
        'enabled': true,
        'salt': salt,
        'hash': hash,
        'delayMin': 5,
        'decoyCalculator': true,
        'updatedAt': 1000,
      });
      expect(Lock.instance.state.value.enabled, isTrue);
      expect(Lock.instance.state.value.delayMin, equals(5));
      expect(Lock.instance.state.value.decoyCalculator, isTrue);
      expect(Lock.instance.verify('654321'), isTrue);

      await Lock.instance.clearLocal();
    });

    test(
        'Prefs backward compatibility ignores removed legacy Asteria keys cleanly',
        () {
      final legacyMap = <String, dynamic>{
        'locale': 'id',
        'discreetNotify': 'minimal',
        'geminiApiKey': 'legacy-secret-key',
        'asteriaMode': 'personal',
      };
      final reconstructed = Prefs.from(legacyMap);
      expect(reconstructed.locale, equals('id'));
      expect(reconstructed.discreetNotify, equals('minimal'));
      expect(reconstructed.toMap().containsKey('geminiApiKey'), isFalse);
      expect(reconstructed.toMap().containsKey('asteriaMode'), isFalse);
    });
  });
}
