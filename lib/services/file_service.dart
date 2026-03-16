import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:file_picker/file_picker.dart';

class PickedFile {
  final String name;
  final String? path;
  final List<int>? bytes;
  final int size;

  const PickedFile({
    required this.name,
    this.path,
    this.bytes,
    required this.size,
  });

  String get storageKey => path ?? 'web:$name';
  bool get isWebFile => path == null;
}

class FileService {
  static Future<List<PickedFile>> pickFiles() async {
    final result = await FilePicker.platform.pickFiles(
      allowMultiple: true,
      withData: kIsWeb,
      withReadStream: false,
    );

    if (result == null || result.files.isEmpty) return [];

    return result.files.map((f) {
      if (kIsWeb) {
        return PickedFile(
          name: f.name,
          bytes: f.bytes != null ? List<int>.from(f.bytes!) : null,
          size: f.size,
        );
      } else {
        return PickedFile(
          name: f.name,
          path: f.path,
          size: f.size,
        );
      }
    }).toList();
  }
}
