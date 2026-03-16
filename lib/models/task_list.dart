import 'package:hive/hive.dart';

part 'task_list.g.dart';

@HiveType(typeId: 4)
class TaskList extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String name;

  @HiveField(2)
  String emoji;

  @HiveField(3)
  String colorHex;

  @HiveField(4)
  bool isArchived;

  @HiveField(5)
  int sortOrder;

  @HiveField(6)
  DateTime createdAt;

  TaskList({
    required this.id,
    required this.name,
    this.emoji = '📋',
    this.colorHex = '007AFF',
    this.isArchived = false,
    this.sortOrder = 0,
    required this.createdAt,
  });

  TaskList copyWith({
    String? id,
    String? name,
    String? emoji,
    String? colorHex,
    bool? isArchived,
    int? sortOrder,
    DateTime? createdAt,
  }) {
    return TaskList(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      colorHex: colorHex ?? this.colorHex,
      isArchived: isArchived ?? this.isArchived,
      sortOrder: sortOrder ?? this.sortOrder,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'emoji': emoji,
        'colorHex': colorHex,
        'isArchived': isArchived,
        'sortOrder': sortOrder,
        'createdAt': createdAt.toIso8601String(),
      };

  factory TaskList.fromJson(Map<String, dynamic> json) => TaskList(
        id: json['id'] as String,
        name: json['name'] as String,
        emoji: json['emoji'] as String? ?? '📋',
        colorHex: json['colorHex'] as String? ?? '007AFF',
        isArchived: json['isArchived'] as bool? ?? false,
        sortOrder: json['sortOrder'] as int? ?? 0,
        createdAt: DateTime.parse(json['createdAt'] as String),
      );
}
