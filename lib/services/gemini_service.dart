import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/user_context.dart';
import '../models/ai_message.dart';
import '../models/task.dart';

class GeminiService {
  static const String _modelName = 'gemini-2.5-flash';

  GenerativeModel? _model;
  ChatSession? _chat;

  void init(String apiKey) {
    _model = GenerativeModel(
      model: _modelName,
      apiKey: apiKey,
      generationConfig: GenerationConfig(
        responseMimeType: 'application/json',
      ),
    );
    _chat = _model!.startChat();
  }

  Future<void> reset() async {
    _chat = _model?.startChat();
  }

  String _constructSystemPrompt(UserContext ctx, List<Task> currentTasks) {
    return '''
You are Taski AI, a mindful productivity assistant.
Your goal is to help the user build a perfect daily schedule using Google Gemini.

USER CONTEXT:
- Routine: Wake at ${ctx.wakeUpTime.hour}:${ctx.wakeUpTime.minute.toString().padLeft(2, "0")}, Sleep at ${ctx.sleepTime.hour}:${ctx.sleepTime.minute.toString().padLeft(2, "0")}
- Work: Starts at ${ctx.workStartTime.hour}:${ctx.workStartTime.minute.toString().padLeft(2, "0")}, Ends at ${ctx.workEndTime.hour}:${ctx.workEndTime.minute.toString().padLeft(2, "0")}
- Energy: ${ctx.energyPattern.name} (${ctx.energyPattern.displayName})
- Focus Duration: ${ctx.preferredTaskDurationMinutes} min
- Life Description: ${ctx.rawLifeDescription}

CURRENT TASKS:
${currentTasks.map((t) => "- ${t.title} (Priority: ${t.priority.name}, Duration: ${t.estimatedMinutes ?? 0}m)").join('\n')}

INSTRUCTIONS:
1. Always respond in JSON format.
2. Response Types:
   - "text": A simple text response for conversation.
   - "schedule": A list of generated tasks to add to the user's day.
   - "taskSuggestion": A specific edit to an existing task.
3. Be encouraging, mindful, and concise.

JSON SCHEMA:
{
  "type": "text" | "schedule" | "taskSuggestion",
  "content": "Your text response goes here",
  "tasks": [ // Only for "schedule" type
    {
      "title": "Task title",
      "priority": 0-4 (None, Low, Medium, High, Urgent),
      "estimatedMinutes": int,
      "scheduledTime": "HH:mm",
      "reasoning": "Why this task is here"
    }
  ],
  "suggestion": { // Only for "taskSuggestion" type
    "suggestionText": "Why I suggest this change",
    "originalTaskId": "id",
    "updatedFields": { "title": "new", "priority": 1, etc. }
  }
}
''';
  }

  Future<Map<String, dynamic>> sendMessage(String message, UserContext ctx, List<Task> currentTasks) async {
    if (_chat == null) throw Exception('Gemini not initialized');

    final systemPrompt = _constructSystemPrompt(ctx, currentTasks);
    
    // Combine system prompt with user message for context-aware generation
    final response = await _chat!.sendMessage(Content.text("$systemPrompt\n\nUSER MESSAGE: $message"));
    
    final text = response.text;
    if (text == null) throw Exception('No response from Gemini');

    try {
      // Find JSON block if it's wrapped in markdown
      String jsonStr = text;
      if (text.contains('```json')) {
        jsonStr = text.split('```json')[1].split('```')[0].trim();
      } else if (text.contains('```')) {
        jsonStr = text.split('```')[1].split('```')[0].trim();
      }
      
      return jsonDecode(jsonStr);
    } catch (e) {
      // Fallback for non-JSON or malformed responses
      return {
        "type": "text",
        "content": text,
      };
    }
  }

  Future<String> summarizePdfText(String pdfText) async {
    if (_model == null) throw Exception('Gemini not initialized');

    final prompt = '''
You are an expert document analyst and summarizing assistant.
Please analyze the following document content and provide a structured summary in JSON format.

JSON SCHEMA:
{
  "overview": "A high-level 2-3 sentence summary of the core message.",
  "key_highlights": ["Point 1", "Point 2", "Point 3", "Point 4", "Point 5"],
  "important_metrics": ["Metric A", "Metric B"], // Important numbers, dates, or specific entities.
  "takeaway": "A final 1-sentence thought on why this information matters."
}

Use professional yet accessible language.

DOCUMENT CONTENT:
$pdfText
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null) return "Error: AI returned an empty response.";

      // Parse JSON and convert to beautiful Markdown
      final data = jsonDecode(text);
      
      final buffer = StringBuffer();
      
      if (data['overview'] != null) {
        buffer.writeln('# Overview');
        buffer.writeln('${data['overview']}\n');
      }
      
      if (data['key_highlights'] != null && (data['key_highlights'] as List).isNotEmpty) {
        buffer.writeln('## Key Highlights');
        for (var point in (data['key_highlights'] as List)) {
          buffer.writeln('- $point');
        }
        buffer.writeln('');
      }

      if (data['important_metrics'] != null && (data['important_metrics'] as List).isNotEmpty) {
        buffer.writeln('## Important Details');
        for (var metric in (data['important_metrics'] as List)) {
          buffer.writeln('- $metric');
        }
        buffer.writeln('');
      }

      if (data['takeaway'] != null) {
        buffer.writeln('> **Takeaway:** ${data['takeaway']}');
      }

      return buffer.toString();
    } catch (e) {
      debugPrint('AI Summary Parse Error: $e');
      return "An issue occurred while formatting the summary. Here is the raw data:\n\n${e.toString()}";
    }
  }

  Future<List<Map<String, String>>> detectQuestions(String pdfText) async {
    if (_model == null) throw Exception('Gemini not initialized');

    final prompt = '''
Scan the following document text and find ALL numbered or bulleted questions (e.g., Q1., 1., Question 1., etc.).
Extract exactly the question number/ID and a short snippet (max 8-10 words) describing the question.

RESPOND ONLY IN A JSON LIST:
[
  {"id": "Q1", "snippet": "A trader sells two articles at..."},
  {"id": "2", "snippet": "Find the ratio of A to B if..."}
]

DOCUMENT CONTENT:
$pdfText
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      final text = response.text;
      if (text == null) return [];

      final cleaned = text.replaceAll('```json', '').replaceAll('```', '').trim();
      final List<dynamic> list = jsonDecode(cleaned);
      return list.map((i) => Map<String, String>.from(i as Map)).toList();
    } catch (e) {
      debugPrint('AI detectQuestions Error: $e');
      return [];
    }
  }

  Future<String> solveQuestion(String questionId, String pdfText) async {
    if (_model == null) throw Exception('Gemini not initialized');

    final prompt = '''
You are an expert tutor. Please solve the following specific question from the document:
QUESTION TO SOLVE: $questionId

Provide a clear, pedagogical, step-by-step explanation. Highlight the final answer clearly in **bold**. Use professional Markdown formatting.

DOCUMENT CONTEXT:
$pdfText
''';

    try {
      final response = await _model!.generateContent([Content.text(prompt)]);
      return response.text ?? "Error: AI could not solve this question.";
    } catch (e) {
      debugPrint('AI solveQuestion Error: $e');
      return "An error occurred while solving question $questionId. Error: $e";
    }
  }
}
