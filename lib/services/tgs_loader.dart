import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:lottie/lottie.dart';

class TgsLoader {
  // Cache decoded compositions to avoid re-parsing JSON on every rebuild
  static final Map<String, LottieComposition> _cache = {};

  // Load a .tgs asset and return parsed LottieComposition
  static Future<LottieComposition?> load(String assetPath) async {
    if (_cache.containsKey(assetPath)) {
      return _cache[assetPath];
    }
    try {
      final byteData = await rootBundle.load(assetPath);
      final compressed = byteData.buffer.asUint8List();
      final decompressed = GZipCodec().decode(compressed);
      
      final composition = await LottieComposition.fromBytes(decompressed);
      _cache[assetPath] = composition;
      return composition;
    } catch (_) {
      // Asset not found or parse error — return null, widget shows emoji fallback
      return null;
    }
  }

  // Clear cache if needed (e.g. low memory)
  static void clearCache() => _cache.clear();
}
