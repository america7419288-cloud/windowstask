import 'dart:convert';
import 'package:hive/hive.dart';
import 'subtask.dart';
import 'recurrence.dart';

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
  bool isRecurringPlaceholder = false; // kept for compatibility

  @HiveField(14)
  String? recurrenceRulePlaceholder; // kept for compatibility

  @HiveField(26)
  String? recurrenceJson;

  @HiveField(27)
  String? recurringParentId;

  @HiveField(28)
  int occurrenceIndex;

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

  @HiveField(23)
  String? stickerId;

  @HiveField(24)
  bool hasReminder;

  @HiveField(25)
  int reminderMinutesBefore;

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
    this.isRecurringPlaceholder = false,
    this.recurrenceRulePlaceholder,
    this.estimatedMinutes,
    this.pomodoroCount = 0,
    List<String>? attachments,
    required this.createdAt,
    required this.updatedAt,
    this.isDeleted = false,
    this.deletedAt,
    this.sortOrder = 0,
    this.stickerId,
    this.hasReminder = false,
    this.reminderMinutesBefore = 0,
    this.recurrenceJson,
    this.recurringParentId,
    this.occurrenceIndex = 0,
  })  : tags = tags ?? [],
        subtasks = subtasks ?? [],
        attachments = attachments ?? [];

  bool get isCompleted => status == TaskStatus.done;

  RecurrenceRule? get recurrence => recurrenceJson != null
      ? RecurrenceRule.fromJson(jsonDecode(recurrenceJson!))
      : null;

  bool get isRecurring => recurrenceJson != null;

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
    String? recurrenceJson,
    String? recurringParentId,
    int? occurrenceIndex,
    int? estimatedMinutes,
    int? pomodoroCount,
    List<String>? attachments,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isDeleted,
    DateTime? deletedAt,
    int? sortOrder,
    String? stickerId,
    bool clearDueDate = false,
    bool clearDueTime = false,
    bool clearListId = false,
    bool clearCompletedAt = false,
    bool clearSticker = false,
    bool? hasReminder,
    int? reminderMinutesBefore,
    bool? isRecurringPlaceholder,
    String? recurrenceRulePlaceholder,
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
      recurrenceJson: recurrenceJson ?? this.recurrenceJson,
      recurringParentId: recurringParentId ?? this.recurringParentId,
      occurrenceIndex: occurrenceIndex ?? this.occurrenceIndex,
      estimatedMinutes: estimatedMinutes ?? this.estimatedMinutes,
      pomodoroCount: pomodoroCount ?? this.pomodoroCount,
      attachments: attachments ?? List.from(this.attachments),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedAt: isDeleted == true ? (deletedAt ?? this.deletedAt) : null,
      sortOrder: sortOrder ?? this.sortOrder,
      stickerId: clearSticker ? null : (stickerId ?? this.stickerId),
      hasReminder: hasReminder ?? this.hasReminder,
      reminderMinutesBefore: reminderMinutesBefore ?? this.reminderMinutesBefore,
      isRecurringPlaceholder: isRecurringPlaceholder ?? this.isRecurringPlaceholder,
      recurrenceRulePlaceholder: recurrenceRulePlaceholder ?? this.recurrenceRulePlaceholder,
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
        'recurrenceJson': recurrenceJson,
        'recurringParentId': recurringParentId,
        'occurrenceIndex': occurrenceIndex,
        'estimatedMinutes': estimatedMinutes,
        'pomodoroCount': pomodoroCount,
        'attachments': attachments,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isDeleted': isDeleted,
        'deletedAt': deletedAt?.toIso8601String(),
        'sortOrder': sortOrder,
        'stickerId': stickerId,
        'hasReminder': hasReminder,
        'reminderMinutesBefore': reminderMinutesBefore,
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
        recurrenceJson: json['recurrenceJson'] as String?,
        recurringParentId: json['recurringParentId'] as String?,
        occurrenceIndex: json['occurrenceIndex'] as int? ?? 0,
        estimatedMinutes: json['estimatedMinutes'] as int?,
        pomodoroCount: json['pomodoroCount'] as int? ?? 0,
        attachments: List<String>.from(json['attachments'] as List? ?? []),
        createdAt: json['createdAt'] != null
            ? DateTime.parse(json['createdAt'] as String)
            : DateTime.now(),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'] as String)
            : DateTime.now(),
        isDeleted: json['isDeleted'] as bool? ?? false,
        deletedAt: json['deletedAt'] != null
            ? DateTime.parse(json['deletedAt'] as String)
            : null,
        sortOrder: json['sortOrder'] as int? ?? 0,
        stickerId: json['stickerId'] as String?,
        hasReminder: json['hasReminder'] as bool? ?? false,
        reminderMinutesBefore: json['reminderMinutesBefore'] as int? ?? 0,
      );
}
