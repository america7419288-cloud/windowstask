import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;

class TgsLoader {
  // Cache decoded bytes to avoid re-decompressing on every rebuild
  static final Map<String, Uint8List> _cache = {};

  // Load a .tgs asset and return decompressed Lottie JSON bytes
  static Future<Uint8List> load(String assetPath) async {
    if (_cache.containsKey(assetPath)) {
      return _cache[assetPath]!;
    }

    final byteData = await rootBundle.load(assetPath);
    final compressed = byteData.buffer.asUint8List();

    // Decompress gzip
    final decompressed = GZipCodec().decode(compressed);
    final result = Uint8List.fromList(decompressed);

    _cache[assetPath] = result;
    return result;
  }

  // Clear cache if needed (e.g. low memory)
  static void clearCache() => _cache.clear();
}
