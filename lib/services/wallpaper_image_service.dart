import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';
import 'dart:io';

class WallpaperImageService {
  /// Returns the path/key to store in AppSettings.wallpaperImagePath
  /// Windows: returns absolute file path
  static Future<String?> pickImage() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
      withData: kIsWeb,
      withReadStream: false,
    );

    if (result == null || result.files.isEmpty) return null;

    final file = result.files.first;

    if (kIsWeb) {
      // Web support — return null for now (base64 encoding can be added)
      return null;
    } else {
      return file.path;
    }
  }

  /// Validate image size — reject files over 10MB
  static Future<bool> validateSize(String pathOrDataUri) async {
    if (kIsWeb) {
      final bytes = pathOrDataUri.length * 0.75;
      return bytes < 10 * 1024 * 1024;
    } else {
      try {
        final file = File(pathOrDataUri);
        final size = await file.length();
        return size < 10 * 1024 * 1024;
      } catch (_) {
        return false;
      }
    }
  }
}
