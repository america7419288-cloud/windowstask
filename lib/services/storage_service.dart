import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/task_list.dart';
import '../models/tag.dart';
import '../models/app_settings.dart';
import 'export_service.dart';
import '../utils/constants.dart';

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  late Box<Task> _tasksBox;
  late Box<TaskList> _listsBox;
  late Box<Tag> _tagsBox;
  SharedPreferences? _prefs;

  Future<void> init() async {
    _tasksBox = await Hive.openBox<Task>(AppConstants.tasksBox);
    _listsBox = await Hive.openBox<TaskList>(AppConstants.listsBox);
    _tagsBox = await Hive.openBox<Tag>(AppConstants.tagsBox);
    _prefs = await SharedPreferences.getInstance();
  }

  // ─── Tasks ───────────────────────────────────────────────────────────────

  List<Task> getAllTasks() => _tasksBox.values.toList();

  Future<void> saveTask(Task task) async {
    await _tasksBox.put(task.id, task);
  }

  Future<void> deleteTask(String id) async {
    await _tasksBox.delete(id);
  }

  Task? getTask(String id) => _tasksBox.get(id);

  // ─── Lists ────────────────────────────────────────────────────────────────

  List<TaskList> getAllLists() => _listsBox.values.toList();

  Future<void> saveList(TaskList list) async {
    await _listsBox.put(list.id, list);
  }

  Future<void> deleteList(String id) async {
    await _listsBox.delete(id);
  }

  // ─── Tags ─────────────────────────────────────────────────────────────────

  List<Tag> getAllTags() => _tagsBox.values.toList();

  Future<void> saveTag(Tag tag) async {
    await _tagsBox.put(tag.id, tag);
  }

  Future<void> deleteTag(String id) async {
    await _tagsBox.delete(id);
  }

  // ─── Settings ─────────────────────────────────────────────────────────────

  AppSettings getSettings() {
    if (_prefs == null) return const AppSettings();
    final json = _prefs!.getString(AppConstants.settingsKey);
    if (json == null) return const AppSettings();
    try {
      return AppSettings.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return const AppSettings();
    }
  }

  Future<void> saveSettings(AppSettings settings) async {
    if (_prefs == null) return;
    await _prefs!.setString(AppConstants.settingsKey, jsonEncode(settings.toJson()));
  }

  // ─── Focus Stats ─────────────────────────────────────────────────────────

  Map<String, int> getFocusStats() {
    if (_prefs == null) return {};
    final json = _prefs!.getString('focus_stats');
    if (json == null) return {};
    try {
      return Map<String, int>.from(jsonDecode(json) as Map);
    } catch (_) {
      return {};
    }
  }

  Future<void> saveFocusSession(int minutes) async {
    if (_prefs == null) return;
    final stats = getFocusStats();
    final today = DateTime.now().toIso8601String().split('T')[0];
    stats[today] = (stats[today] ?? 0) + minutes;
    await _prefs!.setString('focus_stats', jsonEncode(stats));
  }

  // ─── Daily Planning ───────────────────────────────────────────────────────

  DateTime? getLastPlanningDate() {
    if (_prefs == null) return null;
    final iso = _prefs!.getString('last_planning_date');
    if (iso == null) return null;
    return DateTime.tryParse(iso);
  }

  Future<void> saveLastPlanningDate(DateTime date) async {
    if (_prefs == null) return;
    await _prefs!.setString('last_planning_date', date.toIso8601String());
  }

  // ─── Export / Import ──────────────────────────────────────────────────────

  Future<void> exportAll() async {
    final data = <String, dynamic>{
      'tasks': _tasksBox.values.map((t) => t.toJson()).toList(),
      'lists': _listsBox.values.map((l) => l.toJson()).toList(),
      'tags': _tagsBox.values.map((t) => t.toJson()).toList(),
      'settings': getSettings().toJson(), // Retained settings export
      'export_date': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
    
    await ExportService.exportToFile(data);
  }

  Future<void> importAll(Map<String, dynamic> data) async {
    // Clear existing
    await _tasksBox.clear();
    await _listsBox.clear();
    await _tagsBox.clear();

    final tasks = (data['tasks'] as List?)
            ?.map((t) => Task.fromJson(t as Map<String, dynamic>))
            .toList() ??
        [];
    for (final task in tasks) {
      await _tasksBox.put(task.id, task);
    }

    final lists = (data['lists'] as List?)
            ?.map((l) => TaskList.fromJson(l as Map<String, dynamic>))
            .toList() ??
        [];
    for (final list in lists) {
      await _listsBox.put(list.id, list);
    }

    final tags = (data['tags'] as List?)
            ?.map((t) => Tag.fromJson(t as Map<String, dynamic>))
            .toList() ??
        [];
    for (final tag in tags) {
      await _tagsBox.put(tag.id, tag);
    }
  }
}
