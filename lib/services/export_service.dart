import 'package:flutter/foundation.dart' show kIsWeb, compute;
import 'dart:convert';
import 'export_service_stub.dart' 
    if (dart.library.html) 'export_service_web.dart'
    if (dart.library.io) 'export_service_native.dart';

class ExportService {
  static Future<void> exportToFile(Map<String, dynamic> data) async {
    // Offload heavy JSON serialization and encoding to background isolate
    final bytes = await compute(_generateExportBytes, data);
    final fileName = 'taski_backup_${DateTime.now().millisecondsSinceEpoch}.json';

    if (kIsWeb) {
      downloadWeb(bytes, fileName);
    } else {
      await downloadNative(bytes, fileName);
    }
  }

  static List<int> _generateExportBytes(Map<String, dynamic> data) {
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    return utf8.encode(jsonString);
  }
}
