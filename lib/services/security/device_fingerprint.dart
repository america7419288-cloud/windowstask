import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';

class DeviceFingerprint {
  static String? _cached;

  static Future<String> get() async {
    if (_cached != null) return _cached!;

    final info = DeviceInfoPlugin();
    String raw = '';

    try {
      if (!kIsWeb) {
        // Windows
        final win = await info.windowsInfo;
        raw = '${win.computerName}'
            '${win.numberOfCores}'
            '${win.systemMemoryInMegabytes}'
            '${win.productId}';
      }
    } catch (_) {
      // Fallback — not ideal but prevents
      // crash on unsupported platforms
      raw = 'taski_fallback_device_key';
    }

    // Add app-specific salt so
    // raw device values aren't enough
    // even if attacker knows the algo
    const appSalt = 'T4sk1_S3cur1ty_S4lt_2024_#@!';
    final combined = '$raw$appSalt';

    // SHA-256 the fingerprint
    final bytes = utf8.encode(combined);
    final digest = sha256.convert(bytes);
    _cached = digest.toString();
    return _cached!;
  }

  // Derive a 32-byte AES key from
  // the fingerprint using PBKDF2
  static Future<List<int>> deriveKey(String fingerprint) async {
    // Simple PBKDF2-style stretching
    // using SHA-256 iterations
    const iterations = 10000;
    final salt = utf8.encode('taski_xp_store_salt_v1');
    var key = utf8.encode(fingerprint);

    for (int i = 0; i < iterations; i++) {
      final hmac = Hmac(sha256, salt);
      key = Uint8List.fromList(hmac.convert(key).bytes);
    }

    // Return first 32 bytes for AES-256
    return key.take(32).toList();
  }
}
