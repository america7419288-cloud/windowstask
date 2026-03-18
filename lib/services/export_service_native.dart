import 'package:file_picker/file_picker.dart';
import 'dart:io';

Future<void> downloadNative(List<int> bytes, String fileName) async {
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Save backup',
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: ['json'],
  );
  if (path != null) {
    final file = File(path);
    await file.writeAsBytes(bytes);
  }
}
void downloadWeb(List<int> bytes, String fileName) {}
