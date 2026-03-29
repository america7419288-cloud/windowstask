import 'package:flutter/material.dart';

enum EnergyPattern {
  morningPerson('Morning Person', '🌅', 'You have the most focus and energy in the early hours.'),
  nightOwl('Night Owl', '🌙', 'Your creativity and productivity peak late in the evening.'),
  balanced('Balanced', '⚖️', 'Your energy levels remain relatively stable throughout the day.');

  final String name;
  final String emoji;
  final String displayName;
  const EnergyPattern(this.name, this.emoji, this.displayName);
}

class UserContext {
  final TimeOfDay wakeUpTime;
  final TimeOfDay sleepTime;
  final TimeOfDay workStartTime;
  final TimeOfDay workEndTime;
  final EnergyPattern energyPattern;
  final int preferredTaskDurationMinutes;
  final String rawLifeDescription;

  const UserContext({
    this.wakeUpTime = const TimeOfDay(hour: 7, minute: 0),
    this.sleepTime = const TimeOfDay(hour: 23, minute: 0),
    this.workStartTime = const TimeOfDay(hour: 9, minute: 0),
    this.workEndTime = const TimeOfDay(hour: 17, minute: 0),
    this.energyPattern = EnergyPattern.balanced,
    this.preferredTaskDurationMinutes = 45,
    this.rawLifeDescription = '',
  });

  UserContext copyWith({
    TimeOfDay? wakeUpTime,
    TimeOfDay? sleepTime,
    TimeOfDay? workStartTime,
    TimeOfDay? workEndTime,
    EnergyPattern? energyPattern,
    int? preferredTaskDurationMinutes,
    String? rawLifeDescription,
  }) {
    return UserContext(
      wakeUpTime: wakeUpTime ?? this.wakeUpTime,
      sleepTime: sleepTime ?? this.sleepTime,
      workStartTime: workStartTime ?? this.workStartTime,
      workEndTime: workEndTime ?? this.workEndTime,
      energyPattern: energyPattern ?? this.energyPattern,
      preferredTaskDurationMinutes: preferredTaskDurationMinutes ?? this.preferredTaskDurationMinutes,
      rawLifeDescription: rawLifeDescription ?? this.rawLifeDescription,
    );
  }

  Map<String, dynamic> toJson() => {
    'wakeUpTime': '${wakeUpTime.hour}:${wakeUpTime.minute.toString().padLeft(2, "0")}',
    'sleepTime': '${sleepTime.hour}:${sleepTime.minute.toString().padLeft(2, "0")}',
    'workStartTime': '${workStartTime.hour}:${workStartTime.minute.toString().padLeft(2, "0")}',
    'workEndTime': '${workEndTime.hour}:${workEndTime.minute.toString().padLeft(2, "0")}',
    'energyPattern': energyPattern.index,
    'preferredTaskDurationMinutes': preferredTaskDurationMinutes,
    'rawLifeDescription': rawLifeDescription,
  };

  factory UserContext.fromJson(Map<String, dynamic> json) {
    TimeOfDay _parseTime(String? s) {
      if (s == null) return const TimeOfDay(hour: 0, minute: 0);
      final parts = s.split(':');
      return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
    }

    return UserContext(
      wakeUpTime: _parseTime(json['wakeUpTime']),
      sleepTime: _parseTime(json['sleepTime']),
      workStartTime: _parseTime(json['workStartTime']),
      workEndTime: _parseTime(json['workEndTime']),
      energyPattern: EnergyPattern.values[json['energyPattern'] ?? 2],
      preferredTaskDurationMinutes: json['preferredTaskDurationMinutes'] ?? 45,
      rawLifeDescription: json['rawLifeDescription'] ?? '',
    );
  }
}
