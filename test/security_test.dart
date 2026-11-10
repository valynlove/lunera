import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunera/lock.dart';
import 'package:lunera/models.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  group('Lunera Security & Authentication Tests', () {
    test('AppLockState default values, decoyCalculator, and privacyShield', () {
      const state = AppLockState();
      expect(state.enabled, isFalse);
      expect(state.delayMin, equals(1));
      expect(state.decoyCalculator, isFalse);
      expect(state.privacyShield, isFalse);

      const secureState = AppLockState(enabled: true, decoyCalculator: true, privacyShield: true);
      expect(secureState.decoyCalculator, isTrue);
      expect(secureState.privacyShield, isTrue);
    });

    test('Decoy calculator number formatting and candidate extraction logic', () {
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
      expect(decoyPinCandidate(display: '987654', pinBuffer: '987654', operator: null), equals('987654'));
      expect(decoyPinCandidate(display: '12345', pinBuffer: '012345', operator: null), equals('012345'));
      expect(decoyPinCandidate(display: '100000', pinBuffer: '100000', operator: '+'), isNull);
      expect(decoyPinCandidate(display: '42', pinBuffer: '42', operator: null), isNull);
    });

    test('PBKDF2-HMAC-SHA256 PIN hashing, legacy migration, and persistent lockout', () async {
      // Standard PBKDF2-HMAC-SHA256 test vector (RFC 7914 / hashlib)
      final vec1 = pbkdf2Sha256('passwd', utf8.encode('salt'), iterations: 1);
      expect(vec1, equals('55ac046e56e3089fec1691c22544b605f94185216dde0465e68b9d57c20dacbc'));

      // PBKDF2 PIN hash and verification
      final pbkdf2Hash = hashPinPbkdf2('246810', 'test-salt-123', iterations: 2000);
      expect(pbkdf2Hash, startsWith(r'pbkdf2$sha256$2000$'));
      expect(verifyPinHash('246810', 'test-salt-123', pbkdf2Hash), isTrue);
      expect(verifyPinHash('000000', 'test-salt-123', pbkdf2Hash), isFalse);

      // Legacy single-round SHA-256 verification and automatic upgrade to PBKDF2
      const legacySalt = 'legacy-salt-abc';
      final legacySha = sha256.convert(utf8.encode('$legacySalt:012345')).toString();
      SharedPreferences.setMockInitialValues({
        'lock.salt': legacySalt,
        'lock.hash': legacySha,
        'lock.updatedAt': 100,
      });
      await Lock.instance.load();
      expect(Lock.instance.verify('012345'), isTrue);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('lock.hash'), startsWith(r'pbkdf2$sha256$'));

      // Persistent 5-attempt lockout survives reload
      for (var i = 0; i < 4; i++) {
        expect(Lock.instance.verify('999999'), isFalse);
        expect(Lock.instance.isLockedOut, isFalse);
      }
      expect(Lock.instance.verify('999999'), isFalse); // 5th wrong attempt triggers lockout
      expect(Lock.instance.isLockedOut, isTrue);
      expect(Lock.instance.verify('012345'), isFalse); // Even valid PIN is blocked while locked out

      // Simulate app restart by calling load() again
      await Lock.instance.load();
      expect(Lock.instance.isLockedOut, isTrue);
      expect(Lock.instance.verify('012345'), isFalse);

      await Lock.instance.disable();
      expect(Lock.instance.isLockedOut, isFalse);
    });

    test('Lock suppression and grace period protects external activities cleanly', () async {
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

    test('Prefs backward compatibility ignores removed legacy Asteria keys cleanly', () {
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

