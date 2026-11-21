import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:lunera/backup_crypto.dart';
import 'package:lunera/repo.dart';

void main() {
  group('Encrypted JSON Backup Tests', () {
    test('encryptBackup / decryptBackup round-trip validates through Repo.validate', () async {
      final repo = Repo('dummy_uid');
      final plainMap = {
        'metadata': {'app': 'lunera', 'version': 1},
        'data': {
          'therapies': [
            {
              'id': 't1',
              'name': 'Estradiol Valerate',
              'hormoneId': 'estradiol',
              'dose': 4,
              'start': '2026-11-01T00:00:00.000Z',
            }
          ],
          'labs': [
            {
              'id': 'lab1',
              'hormoneId': 'estradiol',
              'value': 200,
              'cmp': '<',
              'at': '2026-11-01T08:00:00.000Z',
            }
          ],
        },
      };

      expect(isEncryptedBackup(plainMap), isFalse);
      expect(repo.validate(plainMap), equals(2));

      final plainJson = jsonEncode(plainMap);
      final encryptedJson = await encryptBackup(plainJson, 'CorrectHorseBattery1');
      final env = jsonDecode(encryptedJson) as Map<String, dynamic>;

      expect(isEncryptedBackup(env), isTrue);
      expect(env['format'], equals('lunera-enc'));
      expect(env['v'], equals(1));
      expect(env['kdf'], equals('pbkdf2-sha256'));
      expect(env['iter'], equals(150000));
      expect(encryptedJson, isNot(contains('Estradiol Valerate')));

      final decrypted = await decryptBackup(env, 'CorrectHorseBattery1');
      expect(repo.validate(jsonDecode(decrypted)), equals(2));
    });

    test('decryptBackup rejects wrong passphrase, tampered ciphertext, and invalid metadata', () async {
      final encryptedJson = await encryptBackup('{"metadata":{"app":"lunera"},"data":{}}', 'StrongPass123');
      final env = jsonDecode(encryptedJson) as Map<String, dynamic>;

      await expectLater(
        decryptBackup(env, 'WrongPassphrase'),
        throwsFormatException,
      );

      final tampered = Map<String, dynamic>.from(env);
      final ctBytes = base64Decode(tampered['ct'] as String);
      ctBytes[0] = ctBytes[0] ^ 0xFF;
      tampered['ct'] = base64Encode(ctBytes);
      await expectLater(
        decryptBackup(tampered, 'StrongPass123'),
        throwsFormatException,
      );

      final badIter = Map<String, dynamic>.from(env)..['iter'] = 500;
      await expectLater(
        decryptBackup(badIter, 'StrongPass123'),
        throwsFormatException,
      );

      final missingField = Map<String, dynamic>.from(env)..remove('mac');
      await expectLater(
        decryptBackup(missingField, 'StrongPass123'),
        throwsFormatException,
      );
    });
  });
}
