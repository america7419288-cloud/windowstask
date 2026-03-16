import 'package:hive/hive.dart';
import 'subtask.dart';

part 'task.g.dart';

@HiveType(typeId: 0)
enum TaskStatus {
  @HiveField(0)
  todo,
  @HiveField(1)
  inProgress,
  @HiveField(2)
  done,
}

@HiveType(typeId: 1)
enum Priority {
  @HiveField(0)
  none,
  @HiveField(1)
  low,
  @HiveField(2)
  medium,
  @HiveField(3)
  high,
  @HiveField(4)
  urgent,
}

@HiveType(typeId: 2)
class Task extends HiveObject {
  @HiveField(0)
  String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  TaskStatus status;

  @HiveField(4)
  Priority priority;

  @HiveField(5)
  DateTime? dueDate;

  @HiveField(6)
  int? dueHour;

  @HiveField(7)
  int? dueMinute;

  @HiveField(8)
  DateTime? completedAt;

  @HiveField(9)
  String? listId;

  @HiveField(10)
  List<String> tags;

  @HiveField(11)
  List<Subtask> subtasks;

  @HiveField(12)
  bool isFlagged;

  @HiveField(13)
  bool isRecurring;

  @HiveField(14)
  String? recurrenceRule;

  @HiveField(15)
  int? estimatedMinutes;

  @HiveField(16)
  int pomodoroCount;

  @HiveField(17)
  List<String> attachments;

  @HiveField(18)
  DateTime createdAt;

  @HiveField(19)
  DateTime updatedAt;

  @HiveField(20)
  bool isDeleted;

  @HiveField(21)
  DateTime? deletedAt;

  @HiveField(22)
  int sortOrder;

  Task({
    required this.id,
    required this.title,
    this.description = '',
    this.status = TaskStatus.todo,
    this.priority = Priority.none,
    this.dueDate,
    this.dueHour,
    this.dueMinute,
    this.completedAt,
    this.listId,
    List<String>? tags,
    List<Subtask>? subtasks,
    this.isFlagged = false,
    this.isRecurring = false,
    this.recurrenceRule,
    this.estimatedMinutes,
    this.pomodoroCount = 0,
    List<String>? attachments,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.deletedAt,
    this.sortOrder = 0,
  })  : tags = tags ?? [],
        subtasks = subtasks ?? [],
        attachments = attachments ?? [];

  bool get isCompleted => status == TaskStatus.done;

  bool get isOverdue {
    if (dueDate == null) return false;
    if (isCompleted) return false;
    final now = DateTime.now();
    final due = dueDate!;
    if (dueHour != null && dueMinute != null) {
      final dueDateTime = DateTime(due.year, due.month, due.day, dueHour!, dueMinute!);
      return dueDateTime.isBefore(now);
    }
    return DateTime(due.year, due.month, due.day).isBefore(
        DateTime(now.year, now.month, now.day));
  }

  double get subtaskProgress {
    if (subtasks.isEmpty) return 0;
    final completed = subtasks.where((s) => s.isCompleted).length;
    return completed / subtasks.length;
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    TaskStatus? status,
    Priority? priority,
    DateTime? dueDate,
    int? dueHour,
    int? dueMinute,
    DateTime? completedAt,
    String? listId,
    List<String>? tags,
    List<Subtask>? subtasks,
    bool? isFlagged,
    bool? isRecurring,
    String? recurrenceRule,
    int? estimatedMinutes,
    int? pomodoroCount,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    DateTime? deletedAt,
    int? sortOrder,
    bool clearDueDate = false,
    bool clearDueTime = false,
    bool clearListId = false,
    bool clearCompletedAt = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      dueDate: clearDueDate ? null : (dueDate ?? this.dueDate),
      dueHour: clearDueTime ? null : (dueHour ?? this.dueHour),
      dueMinute: clearDueTime ? null : (dueMinute ?? this.dueMinute),
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      listId: clearListId ? null : (listId ?? this.listId),
      tags: tags ?? List.from(this.tags),
      subtasks: subtasks ?? List.from(this.subtasks),
      isFlagged: isFlagged ?? this.isFlagged,
      isRecurring: isRecurring ?? this.isRecurring,
      recurrenceRule: recurrenceRule ?? this.recurrenceRule,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      pomodoroCount: pomodoroCount ?? this.pomodoroCount,
      attachments: attachments ?? List.from(this.attachments),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: deletedAt ?? this.deletedAt,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'status': status.index,
        'priority': priority.index,
        'dueDate': dueDate?.toIso8601String(),
        'dueHour': dueHour,
        'dueMinute': dueMinute,
        'completedAt': completedAt?.toIso8601String(),
        'listId': listId,
        'tags': tags,
        'subtasks': subtasks.map((s) => s.toJson()).toList(),
        'isFlagged': isFlagged,
        'isRecurring': isRecurring,
        'recurrenceRule': recurrenceRule,
        'estimatedMinutes': estimatedMinutes,
        'pomodoroCount': pomodoroCount,
        'attachments': attachments,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isDeleted': isDeleted,
        'deletedAt': deletedAt?.toIso8601String(),
        'sortOrder': sortOrder,
      };

  factory Task.fromJson(Map<String, dynamic> json) => Task(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String? ?? '',
        status: TaskStatus.values[json['status'] as int? ?? 0],
        priority: Priority.values[json['priority'] as int? ?? 0],
        dueDate: json['dueDate'] != null
            ? DateTime.parse(json['dueDate'] as String)
            : null,
        dueHour: json['dueHour'] as int?,
        dueMinute: json['dueMinute'] as int?,
        completedAt: json['completedAt'] != null
            ? DateTime.parse(json['completedAt'] as String)
            : null,
        listId: json['listId'] as String?,
        tags: List<String>.from(json['tags'] as List? ?? []),
        subtasks: (json['subtasks'] as List?)
                ?.map((s) => Subtask.fromJson(s as Map<String, dynamic>))
                .toList() ??
            [],
        isFlagged: json['isFlagged'] as bool? ?? false,
        isRecurring: json['isRecurring'] as bool? ?? false,
        recurrenceRule: json['recurrenceRule'] as String?,
        estimatedMinutes: json['estimatedMinutes'] as int?,
        pomodoroCount: json['pomodoroCount'] as int? ?? 0,
        attachments: List<String>.from(json['attachments'] as List? ?? []),
        createdAt: DateTime.parse(json['createdAt'] as String),
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        isDeleted: json['isDeleted'] as bool? ?? false,
        deletedAt: json['deletedAt'] != null
            ? DateTime.parse(json['deletedAt'] as String)
            : null,
        sortOrder: json['sortOrder'] as int? ?? 0,
      );
}
