import 'package:hive/hive.dart';

part 'subtask.g.dart';

@HiveType(typeId: 3)
class Subtask extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool isCompleted;

  @HiveField(3)
  DateTime? dueDate;

  @HiveField(4)
  DateTime createdAt;

  Subtask({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.dueDate,
    required this.createdAt,
  });

  Subtask copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? dueDate,
    DateTime? createdAt,
  }) {
    return Subtask(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      dueDate: dueDate ?? this.dueDate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'isCompleted': isCompleted,
        'dueDate': dueDate?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory Subtask.fromJson(Map<String, dynamic> json) => Subtask(
        id: json['id'] as String,
        title: json['title'] as String,
        isCompleted: json['isCompleted'] as bool? ?? false,
        dueDate: json['dueDate'] != null
            ? DateTime.parse(json['dueDate'] as String)
            : null,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
