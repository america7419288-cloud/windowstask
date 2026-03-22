import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../models/task.dart';
import '../models/task_template.dart';

class TemplateProvider extends ChangeNotifier {
  late Box<TaskTemplate> _box;
  List<TaskTemplate> _templates = [];

  List<TaskTemplate> get templates => List.unmodifiable(_templates);

  Future<void> init() async {
    _box = await Hive.openBox<TaskTemplate>('task_templates');
    _templates = _box.values.toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> save(TaskTemplate t) async {
    await _box.put(t.id, t);
    final idx = _templates.indexWhere((x) => x.id == t.id);
    if (idx >= 0) {
      _templates[idx] = t;
    } else {
      _templates.insert(0, t);
    }
    notifyListeners();
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    _templates.removeWhere((t) => t.id == id);
    notifyListeners();
  }

  Future<TaskTemplate> saveFromTask(Task task, String name, String emoji) async {
    final t = TaskTemplate.fromTask(task, name, emoji: emoji);
    await save(t);
    return t;
  }
}
