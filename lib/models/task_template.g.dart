// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'task_template.dart';

// **************************************************************************
// TypeAdapterGenerator
// **************************************************************************

class TaskTemplateAdapter extends TypeAdapter<TaskTemplate> {
  @override
  final int typeId = 6;

  @override
  TaskTemplate read(BinaryReader reader) {
    final numOfFields = reader.readByte();
    final fields = <int, dynamic>{
      for (int i = 0; i < numOfFields; i++) reader.readByte(): reader.read(),
    };
    return TaskTemplate(
      id: fields[0] as String,
      name: fields[1] as String,
      emoji: fields[2] as String,
      title: fields[3] as String,
      description: fields[4] as String,
      priorityIndex: fields[5] as int,
      listId: fields[6] as String?,
      tags: (fields[7] as List).cast<String>(),
      subtaskTitles: (fields[8] as List).cast<String>(),
      isFlagged: fields[9] as bool,
      createdAt: fields[10] as DateTime,
      dueHour: fields[11] as int?,
      dueMinute: fields[12] as int?,
      hasReminder: fields[13] as bool,
      reminderMinutesBefore: fields[14] as int,
    );
  }

  @override
  void write(BinaryWriter writer, TaskTemplate obj) {
    writer
      ..writeByte(15)
      ..writeByte(0)
      ..write(obj.id)
      ..writeByte(1)
      ..write(obj.name)
      ..writeByte(2)
      ..write(obj.emoji)
      ..writeByte(3)
      ..write(obj.title)
      ..writeByte(4)
      ..write(obj.description)
      ..writeByte(5)
      ..write(obj.priorityIndex)
      ..writeByte(6)
      ..write(obj.listId)
      ..writeByte(7)
      ..write(obj.tags)
      ..writeByte(8)
      ..write(obj.subtaskTitles)
      ..writeByte(9)
      ..write(obj.isFlagged)
      ..writeByte(10)
      ..write(obj.createdAt)
      ..writeByte(11)
      ..write(obj.dueHour)
      ..writeByte(12)
      ..write(obj.dueMinute)
      ..writeByte(13)
      ..write(obj.hasReminder)
      ..writeByte(14)
      ..write(obj.reminderMinutesBefore);
  }

  @override
  int get hashCode => typeId.hashCode;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaskTemplateAdapter &&
          runtimeType == other.runtimeType &&
          typeId == other.typeId;
}
