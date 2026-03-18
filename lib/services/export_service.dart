import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:convert';
import 'export_service_stub.dart' 
    if (dart.library.html) 'export_service_web.dart'
    if (dart.library.io) 'export_service_native.dart';

class ExportService {
  static Future<void> exportToFile(Map<String, dynamic> data) async {
    final jsonString = const JsonEncoder.withIndent('  ').convert(data);
    final bytes = utf8.encode(jsonString);
    final fileName = 'taski_backup_${DateTime.now().millisecondsSinceEpoch}.json';

    if (kIsWeb) {
      downloadWeb(bytes, fileName);
    } else {
      await downloadNative(bytes, fileName);
    }
  }
}
