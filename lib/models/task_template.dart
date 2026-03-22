import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'task.dart';
import 'subtask.dart';

part 'task_template.g.dart';

@HiveType(typeId: 6)
class TaskTemplate extends HiveObject {
  @HiveField(0)
  String id;
  @HiveField(1)
  String name;
  @HiveField(2)
  String emoji;
  @HiveField(3)
  String title;
  @HiveField(4)
  String description;
  @HiveField(5)
  int priorityIndex;
  @HiveField(6)
  String? listId;
  @HiveField(7)
  List<String> tags;
  @HiveField(8)
  List<String> subtaskTitles;
  @HiveField(9)
  bool isFlagged;
  @HiveField(10)
  DateTime createdAt;
  @HiveField(11)
  int? dueHour;
  @HiveField(12)
  int? dueMinute;
  @HiveField(13)
  bool hasReminder;
  @HiveField(14)
  int reminderMinutesBefore;

  Priority get priority => Priority.values[priorityIndex];

  TaskTemplate({
    required this.id,
    required this.name,
    this.emoji = '📋',
    required this.title,
    this.description = '',
    this.priorityIndex = 0,
    this.listId,
    this.tags = const [],
    this.subtaskTitles = const [],
    this.isFlagged = false,
    required this.createdAt,
    this.dueHour,
    this.dueMinute,
    this.hasReminder = false,
    this.reminderMinutesBefore = 15,
  });

  // Create from existing task
  factory TaskTemplate.fromTask(Task task, String name, {String emoji = '📋'}) {
    return TaskTemplate(
      id: const Uuid().v4(),
      name: name,
      emoji: emoji,
      title: task.title,
      description: task.description,
      priorityIndex: task.priority.index,
      listId: task.listId,
      tags: List.from(task.tags),
      subtaskTitles: task.subtasks.map((s) => s.title).toList(),
      isFlagged: task.isFlagged,
      createdAt: DateTime.now(),
      dueHour: task.dueHour,
      dueMinute: task.dueMinute,
      hasReminder: task.hasReminder,
      reminderMinutesBefore: task.reminderMinutesBefore,
    );
  }

  // Spawn new task from template
  Task toTask({DateTime? dueDate}) {
    return Task(
      id: const Uuid().v4(),
      title: title,
      description: description,
      priority: priority,
      listId: listId,
      tags: List.from(tags),
      subtasks: subtaskTitles
          .map((t) => Subtask(
                id: const Uuid().v4(),
                title: t,
                createdAt: DateTime.now(),
              ))
          .toList(),
      isFlagged: isFlagged,
      dueDate: dueDate ?? DateTime.now(),
      dueHour: dueHour,
      dueMinute: dueMinute,
      hasReminder: hasReminder,
      reminderMinutesBefore: reminderMinutesBefore,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }
}
