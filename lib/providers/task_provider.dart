import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../services/search_service.dart';
import '../utils/date_utils.dart';
import '../utils/constants.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  final List<_UndoAction> _undoStack = [];
  static const _uuid = Uuid();
  SortOption _sortOption = SortOption.manual;

  List<Task> get allTasks => _tasks;
  SortOption get sortOption => _sortOption;

  void init() {
    _tasks = StorageService.instance.getAllTasks();
  }

  // ─── Counts ───────────────────────────────────────────────────────────────

  int get todayCount => getTasksForNav(AppConstants.navToday).length;

  int countForList(String listId) =>
      _tasks.where((t) => t.listId == listId && !t.isDeleted && !t.isCompleted).length;

  // ─── Filtering ────────────────────────────────────────────────────────────

  List<Task> getTasksForNav(String navItem, {String? searchQuery}) {
    List<Task> base;

    switch (navItem) {
      case AppConstants.navToday:
        base = _tasks.where((t) {
          if (t.isDeleted) return false;
          if (t.dueDate == null) return false;
          return AppDateUtils.isToday(t.dueDate!) || (t.isOverdue && !t.isCompleted);
        }).toList();
        break;
      case AppConstants.navUpcoming:
        base = _tasks.where((t) {
          if (t.isDeleted) return false;
          if (t.dueDate == null) return false;
          return AppDateUtils.isWithinNextDays(t.dueDate!, 7) &&
              !AppDateUtils.isToday(t.dueDate!);
        }).toList();
        break;
      case AppConstants.navAll:
        base = _tasks.where((t) => !t.isDeleted).toList();
        break;
      case AppConstants.navCompleted:
        base = _tasks.where((t) => !t.isDeleted && t.isCompleted).toList();
        break;
      case AppConstants.navTrash:
        base = _tasks.where((t) => t.isDeleted).toList();
        break;
      case AppConstants.navHighPriority:
        base = _tasks.where((t) =>
            !t.isDeleted &&
            (t.priority == Priority.high || t.priority == Priority.urgent)).toList();
        break;
      case AppConstants.navScheduled:
        base = _tasks.where((t) =>
            !t.isDeleted && t.dueDate != null).toList();
        break;
      case AppConstants.navFlagged:
        base = _tasks.where((t) =>
            !t.isDeleted && t.isFlagged).toList();
        break;
      default:
        if (navItem.startsWith('list_')) {
          final listId = navItem.substring(5);
          base = _tasks.where((t) =>
              !t.isDeleted && t.listId == listId).toList();
        } else {
          base = [];
        }
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      base = SearchService.search(base, searchQuery);
    }

    return _sort(base);
  }

  List<Task> searchAll(String query) {
    if (query.isEmpty) return [];
    return SearchService.search(_tasks.where((t) => !t.isDeleted).toList(), query);
  }

  List<Task> _sort(List<Task> tasks) {
    final sorted = List<Task>.from(tasks);
    switch (_sortOption) {
      case SortOption.dueDate:
        sorted.sort((a, b) {
          if (a.dueDate == null && b.dueDate == null) return 0;
          if (a.dueDate == null) return 1;
          if (b.dueDate == null) return -1;
          return a.dueDate!.compareTo(b.dueDate!);
        });
        break;
      case SortOption.priority:
        sorted.sort((a, b) => b.priority.index.compareTo(a.priority.index));
        break;
      case SortOption.alphabetical:
        sorted.sort((a, b) => a.title.compareTo(b.title));
        break;
      case SortOption.createdDate:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case SortOption.manual:
        sorted.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
        break;
    }
    return sorted;
  }

  void setSortOption(SortOption option) {
    _sortOption = option;
    notifyListeners();
  }

  Task? getById(String id) {
    try {
      return _tasks.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── CRUD ─────────────────────────────────────────────────────────────────

  Future<Task> createTask({
    required String title,
    String description = '',
    Priority priority = Priority.none,
    DateTime? dueDate,
    int? dueHour,
    int? dueMinute,
    String? listId,
    List<String>? tags,
    bool isFlagged = false,
  }) async {
    final now = DateTime.now();
    final task = Task(
      id: _uuid.v4(),
      title: title,
      description: description,
      priority: priority,
      dueDate: dueDate,
      dueHour: dueHour,
      dueMinute: dueMinute,
      listId: listId,
      tags: tags ?? [],
      isFlagged: isFlagged,
      createdAt: now,
      updatedAt: now,
      sortOrder: _tasks.length,
    );
    _tasks.add(task);
    await StorageService.instance.saveTask(task);
    notifyListeners();
    return task;
  }

  Future<void> updateTask(Task task) async {
    final updated = task.copyWith(updatedAt: DateTime.now());
    final idx = _tasks.indexWhere((t) => t.id == task.id);
    if (idx != -1) {
      _tasks[idx] = updated;
      await StorageService.instance.saveTask(updated);
      notifyListeners();
    }
  }

  Future<void> toggleComplete(String id) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final task = _tasks[idx];
    final now = DateTime.now();
    final updated = task.copyWith(
      status: task.isCompleted ? TaskStatus.todo : TaskStatus.done,
      completedAt: task.isCompleted ? null : now,
      clearCompletedAt: task.isCompleted,
      updatedAt: now,
    );
    _tasks[idx] = updated;
    await StorageService.instance.saveTask(updated);
    notifyListeners();
  }

  Future<void> toggleFlag(String id) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final updated = _tasks[idx].copyWith(isFlagged: !_tasks[idx].isFlagged, updatedAt: DateTime.now());
    _tasks[idx] = updated;
    await StorageService.instance.saveTask(updated);
    notifyListeners();
  }

  Future<void> updatePriority(String id, Priority priority) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final updated = _tasks[idx].copyWith(priority: priority, updatedAt: DateTime.now());
    _tasks[idx] = updated;
    await StorageService.instance.saveTask(updated);
    notifyListeners();
  }

  Future<void> updateDueDate(String id, DateTime date) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final updated = _tasks[idx].copyWith(
      dueDate: date, 
      dueHour: date.hour,
      dueMinute: date.minute,
      updatedAt: DateTime.now()
    );
    _tasks[idx] = updated;
    await StorageService.instance.saveTask(updated);
    notifyListeners();
  }

  Future<void> moveToList(String id, String? listId) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final updated = _tasks[idx].copyWith(listId: listId, clearListId: listId == null, updatedAt: DateTime.now());
    _tasks[idx] = updated;
    await StorageService.instance.saveTask(updated);
    notifyListeners();
  }

  Future<void> updateTaskStatus(String id, TaskStatus status) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final now = DateTime.now();
    final updated = _tasks[idx].copyWith(
      status: status,
      completedAt: status == TaskStatus.done ? now : null,
      clearCompletedAt: status != TaskStatus.done,
      updatedAt: now,
    );
    _tasks[idx] = updated;
    await StorageService.instance.saveTask(updated);
    notifyListeners();
  }

  Future<void> setSticker(String taskId, String? stickerId) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final updated = _tasks[idx].copyWith(
      stickerId: stickerId,
      clearSticker: stickerId == null || stickerId.isEmpty,
      updatedAt: DateTime.now(),
    );
    _tasks[idx] = updated;
    await StorageService.instance.saveTask(updated);
    notifyListeners();
  }

  Future<void> restoreTask(String id) async => restoreFromTrash(id);

  Future<void> moveToTrash(String id) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final original = _tasks[idx];
    final updated = original.copyWith(
      isDeleted: true,
      deletedAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _tasks[idx] = updated;
    await StorageService.instance.saveTask(updated);
    _undoStack.add(_UndoAction(type: 'trash', task: original));
    notifyListeners();
  }

  Future<void> restoreFromTrash(String id) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final updated = _tasks[idx].copyWith(isDeleted: false, updatedAt: DateTime.now());
    _tasks[idx] = updated;
    await StorageService.instance.saveTask(updated);
    notifyListeners();
  }

  Future<void> permanentlyDelete(String id) async {
    _tasks.removeWhere((t) => t.id == id);
    await StorageService.instance.deleteTask(id);
    notifyListeners();
  }

  Future<void> emptyTrash() async {
    final trashed = _tasks.where((t) => t.isDeleted).toList();
    for (final t in trashed) {
      await StorageService.instance.deleteTask(t.id);
    }
    _tasks.removeWhere((t) => t.isDeleted);
    notifyListeners();
  }

  Future<void> duplicateTask(String id) async {
    final original = getById(id);
    if (original == null) return;
    final now = DateTime.now();
    final copy = original.copyWith(
      id: _uuid.v4(),
      title: '${original.title} (copy)',
      createdAt: now,
      updatedAt: now,
      clearCompletedAt: true,
      status: TaskStatus.todo,
    );
    _tasks.add(copy);
    await StorageService.instance.saveTask(copy);
    notifyListeners();
  }

  // ─── Subtasks ─────────────────────────────────────────────────────────────

  Future<void> addSubtask(String taskId, String title) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final subtask = Subtask(
      id: _uuid.v4(),
      title: title,
      createdAt: DateTime.now(),
    );
    final updated = _tasks[idx].copyWith(
      subtasks: [..._tasks[idx].subtasks, subtask],
      updatedAt: DateTime.now(),
    );
    _tasks[idx] = updated;
    await StorageService.instance.saveTask(updated);
    notifyListeners();
  }

  Future<void> toggleSubtask(String taskId, String subtaskId) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final subtasks = _tasks[idx].subtasks.map((s) {
      if (s.id == subtaskId) return s.copyWith(isCompleted: !s.isCompleted);
      return s;
    }).toList();
    final updated = _tasks[idx].copyWith(subtasks: subtasks, updatedAt: DateTime.now());
    _tasks[idx] = updated;
    await StorageService.instance.saveTask(updated);
    notifyListeners();
  }

  Future<void> deleteSubtask(String taskId, String subtaskId) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    final subtasks = _tasks[idx].subtasks.where((s) => s.id != subtaskId).toList();
    final updated = _tasks[idx].copyWith(subtasks: subtasks, updatedAt: DateTime.now());
    _tasks[idx] = updated;
    await StorageService.instance.saveTask(updated);
    notifyListeners();
  }

  // ─── Reorder ──────────────────────────────────────────────────────────────

  Future<void> reorderTasks(List<Task> tasks, int oldIndex, int newIndex) async {
    final mutable = List<Task>.from(tasks);
    final item = mutable.removeAt(oldIndex);
    mutable.insert(newIndex, item);
    for (int i = 0; i < mutable.length; i++) {
      final updated = mutable[i].copyWith(sortOrder: i);
      final idx = _tasks.indexWhere((t) => t.id == updated.id);
      if (idx != -1) _tasks[idx] = updated;
      await StorageService.instance.saveTask(updated);
    }
    notifyListeners();
  }

  // ─── Undo ─────────────────────────────────────────────────────────────────

  Future<void> undo() async {
    if (_undoStack.isEmpty) return;
    final action = _undoStack.removeLast();
    if (action.type == 'trash') {
      final idx = _tasks.indexWhere((t) => t.id == action.task.id);
      if (idx != -1) {
        _tasks[idx] = action.task;
        await StorageService.instance.saveTask(action.task);
        notifyListeners();
      }
    }
  }

  bool get canUndo => _undoStack.isNotEmpty;

  // ─── Statistics ───────────────────────────────────────────────────────────

  int get completedToday {
    final today = DateTime.now();
    return _tasks.where((t) =>
        t.isCompleted &&
        t.completedAt != null &&
        AppDateUtils.isToday(t.completedAt!)).length;
  }

  int completedInRange(DateTime from, DateTime to) {
    return _tasks.where((t) =>
        t.isCompleted &&
        t.completedAt != null &&
        !t.completedAt!.isBefore(from) &&
        !t.completedAt!.isAfter(to)).length;
  }

  Map<String, int> completionByDay(int days) {
    final result = <String, int>{};
    for (int i = days - 1; i >= 0; i--) {
      final date = DateTime.now().subtract(Duration(days: i));
      final key = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      result[key] = 0;
    }
    for (final t in _tasks) {
      if (t.isCompleted && t.completedAt != null) {
        final d = t.completedAt!;
        final key = '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
        if (result.containsKey(key)) {
          result[key] = (result[key] ?? 0) + 1;
        }
      }
    }
    return result;
  }

  int get currentStreak {
    int streak = 0;
    DateTime check = DateTime.now();

    // Safety limit: never check more than 365 days back
    for (int i = 0; i < 365; i++) {
      final checkDay = DateTime(check.year, check.month, check.day);
      final hasCompleted = _tasks.any((t) {
        if (!t.isCompleted || t.completedAt == null) return false;
        final completedDay = DateTime(
          t.completedAt!.year,
          t.completedAt!.month,
          t.completedAt!.day,
        );
        return completedDay == checkDay;
      });

      if (!hasCompleted) break;
      streak++;
      check = check.subtract(const Duration(days: 1));
    }
    return streak;
  }
}

class _UndoAction {
  final String type;
  final Task task;
  _UndoAction({required this.type, required this.task});
}
