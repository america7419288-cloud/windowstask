import 'package:uuid/uuid.dart';

enum AttachmentType { image, pdf, document, other }

class TaskAttachment {
  final String id;
  final String fileName;
  final String? filePath;
  final String? dataUri;
  final int fileSizeBytes;
  final AttachmentType type;
  final DateTime addedAt;

  const TaskAttachment({
    required this.id,
    required this.fileName,
    this.filePath,
    this.dataUri,
    this.fileSizeBytes = 0,
    this.type = AttachmentType.other,
    required this.addedAt,
  });

  bool get isImage => type == AttachmentType.image;
  bool get isPdf => type == AttachmentType.pdf;

  String get sizeLabel {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(fileSizeBytes / 1024 / 1024).toStringAsFixed(1)} MB';
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'fileName': fileName,
    'filePath': filePath,
    'dataUri': dataUri,
    'fileSizeBytes': fileSizeBytes,
    'type': type.index,
    'addedAt': addedAt.toIso8601String(),
  };

  factory TaskAttachment.fromJson(Map<String, dynamic> j) => TaskAttachment(
    id: j['id'] as String? ?? const Uuid().v4(),
    fileName: j['fileName'] as String? ?? 'unknown',
    filePath: j['filePath'] as String?,
    dataUri: j['dataUri'] as String?,
    fileSizeBytes: j['fileSizeBytes'] as int? ?? 0,
    type: AttachmentType.values[j['type'] as int? ?? 3],
    addedAt: j['addedAt'] != null
        ? DateTime.parse(j['addedAt'] as String)
        : DateTime.now(),
  );

  TaskAttachment copyWith({
    String? id,
    String? fileName,
    String? filePath,
    String? dataUri,
    int? fileSizeBytes,
    AttachmentType? type,
    DateTime? addedAt,
  }) {
    return TaskAttachment(
      id: id ?? this.id,
      fileName: fileName ?? this.fileName,
      filePath: filePath ?? this.filePath,
      dataUri: dataUri ?? this.dataUri,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      type: type ?? this.type,
      addedAt: addedAt ?? this.addedAt,
    );
  }

  /// Detect type from file extension
  static AttachmentType typeFromExtension(String ext) {
    final lower = ext.toLowerCase().replaceAll('.', '');
    switch (lower) {
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'webp':
      case 'bmp':
        return AttachmentType.image;
      case 'pdf':
        return AttachmentType.pdf;
      case 'doc':
      case 'docx':
      case 'txt':
      case 'rtf':
      case 'md':
        return AttachmentType.document;
      default:
        return AttachmentType.other;
    }
  }
}
