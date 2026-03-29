import 'task.dart';

enum AIMessageRole { user, assistant }

enum AIMessageType { thinking, text, schedule, taskSuggestion }

class AISuggestion {
  final String suggestionText;
  final String? originalTaskId;
  final Map<String, dynamic>? updatedFields;

  const AISuggestion({
    required this.suggestionText,
    this.originalTaskId,
    this.updatedFields,
  });

  factory AISuggestion.fromJson(Map<String, dynamic> json) => AISuggestion(
    suggestionText: json['suggestionText'] ?? '',
    originalTaskId: json['originalTaskId'],
    updatedFields: json['updatedFields'],
  );
}

class AIMessage {
  final AIMessageRole role;
  final AIMessageType type;
  final String content;
  final DateTime timestamp;
  final List<Task>? tasks; // For schedule type
  final AISuggestion? suggestion; // For taskSuggestion type

  const AIMessage({
    required this.role,
    required this.type,
    required this.content,
    required this.timestamp,
    this.tasks,
    this.suggestion,
  });

  Map<String, dynamic> toJson() => {
    'role': role.index,
    'type': type.index,
    'content': content,
    'timestamp': timestamp.toIso8601String(),
    'tasks': tasks?.map((t) => t.toJson()).toList(),
    'suggestion': suggestion != null ? {
      'suggestionText': suggestion!.suggestionText,
      'originalTaskId': suggestion!.originalTaskId,
      'updatedFields': suggestion!.updatedFields,
    } : null,
  };
}
