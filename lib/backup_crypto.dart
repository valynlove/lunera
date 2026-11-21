import 'dart:convert';
import 'dart:math' as math;
import 'package:cryptography/cryptography.dart';
import 'l10n.dart';

const int _pbkdf2Iterations = 150000;
const int _minIterations = 10000;
const int _maxIterations = 2000000;

bool isEncryptedBackup(dynamic raw) =>
    raw is Map && raw['format'] == 'lunera-enc';

List<int> _randomBytes(int length) {
  final rng = math.Random.secure();
  return List<int>.generate(length, (_) => rng.nextInt(256));
}

Future<SecretKey> _deriveKey(
    String passphrase, List<int> salt, int iterations) {
  final pbkdf2 = Pbkdf2(
    macAlgorithm: Hmac.sha256(),
    iterations: iterations,
    bits: 256,
  );
  return pbkdf2.deriveKeyFromPassword(password: passphrase, nonce: salt);
}

/// Mengenkripsi string JSON cadangan menggunakan PBKDF2-HMAC-SHA256 + AES-256-GCM.
Future<String> encryptBackup(String json, String passphrase) async {
  if (passphrase.isEmpty) {
    throw FormatException(tr('Passphrase cannot be empty.'));
  }
  final salt = _randomBytes(16);
  final nonce = _randomBytes(12);
  final key = await _deriveKey(passphrase, salt, _pbkdf2Iterations);
  final box = await AesGcm.with256bits().encrypt(
    utf8.encode(json),
    secretKey: key,
    nonce: nonce,
  );
  return const JsonEncoder.withIndent('  ').convert({
    'format': 'lunera-enc',
    'v': 1,
    'kdf': 'pbkdf2-sha256',
    'iter': _pbkdf2Iterations,
    'salt': base64Encode(salt),
    'nonce': base64Encode(box.nonce),
    'ct': base64Encode(box.cipherText),
    'mac': base64Encode(box.mac.bytes),
  });
}

/// Mendekripsi amplop cadangan JSON terenkripsi [env] dengan [passphrase].
Future<String> decryptBackup(Map env, String passphrase) async {
  final iter = env['iter'];
  if (env['format'] != 'lunera-enc' ||
      env['v'] != 1 ||
      env['kdf'] != 'pbkdf2-sha256' ||
      iter is! int ||
      iter < _minIterations ||
      iter > _maxIterations) {
    throw FormatException(tr('This encrypted backup is damaged or unsupported.'));
  }

  final saltStr = env['salt'];
  final nonceStr = env['nonce'];
  final ctStr = env['ct'];
  final macStr = env['mac'];
  if (saltStr is! String ||
      nonceStr is! String ||
      ctStr is! String ||
      macStr is! String) {
    throw FormatException(tr('This encrypted backup is damaged or unsupported.'));
  }

  final List<int> salt, nonce, ct, mac;
  try {
    salt = base64Decode(saltStr);
    nonce = base64Decode(nonceStr);
    ct = base64Decode(ctStr);
    mac = base64Decode(macStr);
  } on FormatException {
    throw FormatException(tr('This encrypted backup is damaged or unsupported.'));
  }

  if (salt.isEmpty || nonce.length != 12 || mac.length != 16) {
    throw FormatException(tr('This encrypted backup is damaged or unsupported.'));
  }

  final key = await _deriveKey(passphrase, salt, iter);
  final box = SecretBox(ct, nonce: nonce, mac: Mac(mac));
  try {
    final plain = await AesGcm.with256bits().decrypt(box, secretKey: key);
    return utf8.decode(plain);
  } on SecretBoxAuthenticationError {
    throw FormatException(tr('Wrong passphrase or damaged file.'));
  } on FormatException {
    throw FormatException(tr('This encrypted backup is damaged or unsupported.'));
  }
}
