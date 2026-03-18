// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskAdapter extends TypeAdapter<Task> {
  @override
  final int typeId = 2;

  @override
  Task read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return Task(
      id: fields[0] as String,
      title: fields[1] as String,
      description: fields[2] as String,
      status: fields[3] as TaskStatus,
      priority: fields[4] as Priority,
      dueDate: fields[5] as DateTime?,
      dueHour: fields[6] as int?,
      dueMinute: fields[7] as int?,
      completedAt: fields[8] as DateTime?,
      listId: fields[9] as String?,
      tags: (fields[10] as List?)?.cast<String>(),
      subtasks: (fields[11] as List?)?.cast<Subtask>(),
      isFlagged: fields[12] as bool,
      isRecurring: fields[13] as bool,
      recurrenceRule: fields[14] as String?,
      estimatedMinutes: fields[15] as int?,
      pomodoroCount: fields[16] as int,
      attachments: (fields[17] as List?)?.cast<String>(),
      createdAt: fields[18] as DateTime,
      updatedAt: fields[19] as DateTime,
      isDeleted: fields[20] as bool,
      deletedAt: fields[21] as DateTime?,
      sortOrder: fields[22] as int,
    );
  }

  @override
  void write(BinaryWriter writer, Task obj) {
    writer
      ..writeByte(23)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.title)
      ..writeByte(2)
      ..write(obj.description)
      ..writeByte(3)
      ..write(obj.status)
      ..writeByte(4)
      ..write(obj.priority)
      ..writeByte(5)
      ..write(obj.dueDate)
      ..writeByte(6)
      ..write(obj.dueHour)
      ..writeByte(7)
      ..write(obj.dueMinute)
      ..writeByte(8)
      ..write(obj.completedAt)
      ..writeByte(9)
      ..write(obj.listId)
      ..writeByte(10)
      ..write(obj.tags)
      ..writeByte(11)
      ..write(obj.subtasks)
      ..writeByte(12)
      ..write(obj.isFlagged)
      ..writeByte(13)
      ..write(obj.isRecurring)
      ..writeByte(14)
      ..write(obj.recurrenceRule)
      ..writeByte(15)
      ..write(obj.estimatedMinutes)
      ..writeByte(16)
      ..write(obj.pomodoroCount)
      ..writeByte(17)
      ..write(obj.attachments)
      ..writeByte(18)
      ..write(obj.createdAt)
      ..writeByte(19)
      ..write(obj.updatedAt)
      ..writeByte(20)
      ..write(obj.isDeleted)
      ..writeByte(21)
      ..write(obj.deletedAt)
      ..writeByte(22)
      ..write(obj.sortOrder);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class TaskStatusAdapter extends TypeAdapter<TaskStatus> {
  @override
  final int typeId = 0;

  @override
  TaskStatus read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return TaskStatus.todo;
      case 1:
        return TaskStatus.inProgress;
      case 2:
        return TaskStatus.done;
      default:
        return TaskStatus.todo;
    }
  }

  @override
  void write(BinaryWriter writer, TaskStatus obj) {
    switch (obj) {
      case TaskStatus.todo:
        writer.writeByte(0);
        break;
      case TaskStatus.inProgress:
        writer.writeByte(1);
        break;
      case TaskStatus.done:
        writer.writeByte(2);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskStatusAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}

class PriorityAdapter extends TypeAdapter<Priority> {
  @override
  final int typeId = 1;

  @override
  Priority read(BinaryReader reader) {
    switch (reader.readByte()) {
      case 0:
        return Priority.none;
      case 1:
        return Priority.low;
      case 2:
        return Priority.medium;
      case 3:
        return Priority.high;
      case 4:
        return Priority.urgent;
      default:
        return Priority.none;
    }
  }

  @override
  void write(BinaryWriter writer, Priority obj) {
    switch (obj) {
      case Priority.none:
        writer.writeByte(0);
        break;
      case Priority.low:
        writer.writeByte(1);
        break;
      case Priority.medium:
        writer.writeByte(2);
        break;
      case Priority.high:
        writer.writeByte(3);
        break;
      case Priority.urgent:
        writer.writeByte(4);
        break;
    }
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PriorityAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
