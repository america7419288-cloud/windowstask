import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart' as enc;
import 'device_fingerprint.dart';

class EncryptionService {
  EncryptionService._();
  static final instance = EncryptionService._();

  enc.Encrypter? _encrypter;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    final fingerprint = await DeviceFingerprint.get();
    final keyBytes = await DeviceFingerprint.deriveKey(fingerprint);
    final key = enc.Key(Uint8List.fromList(keyBytes));
    _encrypter = enc.Encrypter(enc.AES(key, mode: enc.AESMode.cbc));
    _initialized = true;
  }

  String encrypt(String plaintext) {
    if (_encrypter == null) {
      throw StateError('EncryptionService not initialized');
    }
    // Random IV for each encryption
    final iv = enc.IV.fromSecureRandom(16);
    final encrypted = _encrypter!.encrypt(plaintext, iv: iv);
    // Store IV + ciphertext together
    // Format: base64(iv):base64(cipher)
    return '${iv.base64}:${encrypted.base64}';
  }

  String decrypt(String ciphertext) {
    if (_encrypter == null) {
      throw StateError('EncryptionService not initialized');
    }
    try {
      final parts = ciphertext.split(':');
      if (parts.length != 2) {
        throw FormatException('Invalid ciphertext format');
      }
      final iv = enc.IV.fromBase64(parts[0]);
      final encrypted = enc.Encrypted.fromBase64(parts[1]);
      return _encrypter!.decrypt(encrypted, iv: iv);
    } catch (e) {
      throw SecurityException('Decryption failed: $e');
    }
  }

  // Encrypt a JSON map
  String encryptJson(Map<String, dynamic> data) {
    return encrypt(jsonEncode(data));
  }

  // Decrypt to JSON map
  Map<String, dynamic> decryptJson(String ciphertext) {
    final json = decrypt(ciphertext);
    return jsonDecode(json) as Map<String, dynamic>;
  }
}

class SecurityException implements Exception {
  final String message;
  SecurityException(this.message);

  @override
  String toString() => 'SecurityException: $message';
}
