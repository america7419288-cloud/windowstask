import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/ai_message.dart';
import '../models/task.dart';
import '../models/user_context.dart';
import '../services/gemini_service.dart';
import 'task_provider.dart';
import 'user_context_provider.dart';

class AIProvider extends ChangeNotifier {
  final GeminiService _gemini = GeminiService();
  final List<AIMessage> _messages = [];
  bool _isLoading = false;

  List<AIMessage> get messages => _messages;
  bool get isLoading => _isLoading;

  void init(String apiKey) {
    _gemini.init(apiKey);
  }

  Future<void> resetChat() async {
    _messages.clear();
    await _gemini.reset();
    notifyListeners();
  }

  Future<void> sendMessage(BuildContext context, String text) async {
    if (text.trim().isEmpty) return;

    final userMessage = AIMessage(
      role: AIMessageRole.user,
      type: AIMessageType.text,
      content: text,
      timestamp: DateTime.now(),
    );
    _messages.add(userMessage);
    _isLoading = true;
    notifyListeners();

    try {
      final userCtx = Provider.of<UserContextProvider>(context, listen: false).context;
      final currentTasks = Provider.of<TaskProvider>(context, listen: false).allTasks;
      
      final response = await _gemini.sendMessage(text, userCtx, currentTasks);
      
      final aiMessage = _parseResponse(response);
      _messages.add(aiMessage);
    } catch (e) {
      _messages.add(AIMessage(
        role: AIMessageRole.assistant,
        type: AIMessageType.text,
        content: "Sorry, I encountered an error: $e",
        timestamp: DateTime.now(),
      ));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> generateSchedule(BuildContext context) async {
    await sendMessage(context, "Please build me a perfect daily schedule based on my routine and current tasks.");
  }

  Future<String> summarizePdfText(String text) async {
    return await _gemini.summarizePdfText(text);
  }

  Future<List<Map<String, String>>> detectQuestions(String text) async {
    return await _gemini.detectQuestions(text);
  }

  Future<String> solveQuestion(String questionId, String text) async {
    return await _gemini.solveQuestion(questionId, text);
  }

  AIMessage _parseResponse(Map<String, dynamic> response) {
    final typeStr = response['type'] ?? 'text';
    final type = AIMessageType.values.firstWhere(
      (e) => e.name == typeStr,
      orElse: () => AIMessageType.text,
    );

    List<Task>? tasks;
    if (type == AIMessageType.schedule && response['tasks'] != null) {
      tasks = (response['tasks'] as List).map((t) {
        final timeStr = t['scheduledTime'] as String?;
        DateTime? scheduledTime;
        if (timeStr != null) {
          final parts = timeStr.split(':');
          final now = DateTime.now();
          scheduledTime = DateTime(now.year, now.month, now.day, int.parse(parts[0]), int.parse(parts[1]));
        }

        return Task(
          id: DateTime.now().millisecondsSinceEpoch.toString() + (t['title'] ?? ''),
          title: t['title'] ?? '',
          priority: Priority.values[(t['priority'] ?? 0) % Priority.values.length],
          estimatedMinutes: t['estimatedMinutes'] ?? 30,
          dueDate: scheduledTime ?? DateTime.now(),
          reasoning: t['reasoning'] ?? '',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      }).toList().cast<Task>();
    }

    AISuggestion? suggestion;
    if (type == AIMessageType.taskSuggestion && response['suggestion'] != null) {
      suggestion = AISuggestion.fromJson(response['suggestion']);
    }

    return AIMessage(
      role: AIMessageRole.assistant,
      type: type,
      content: response['content'] ?? '',
      timestamp: DateTime.now(),
      tasks: tasks,
      suggestion: suggestion,
    );
  }

  Future<void> acceptAllTasks(BuildContext context, List<Task> tasks) async {
    final taskProvider = Provider.of<TaskProvider>(context, listen: false);
    for (final task in tasks) {
      taskProvider.createTask(
        title: task.title,
        priority: task.priority,
        estimatedMinutes: task.estimatedMinutes,
        dueDate: task.dueDate,
        reasoning: task.reasoning,
      );
    }
    _messages.add(AIMessage(
      role: AIMessageRole.assistant,
      type: AIMessageType.text,
      content: "Great! I've added all those tasks to your schedule. Is there anything else you'd like to adjust?",
      timestamp: DateTime.now(),
    ));
    notifyListeners();
  }
}
