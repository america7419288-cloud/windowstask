import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task.dart';
import '../models/subtask.dart';
import '../models/recurrence.dart';
import 'dart:convert';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../services/search_service.dart';
import '../utils/date_utils.dart';
import '../utils/constants.dart';
import 'celebration_provider.dart';
import '../models/sticker.dart';
import '../services/reminder_service.dart';
import '../services/notification_service.dart';
import '../utils/sticker_suggester.dart';
import 'user_provider.dart';

class TaskProvider extends ChangeNotifier {
  List<Task> _tasks = [];
  final List<_UndoAction> _undoStack = [];
  static const _uuid = Uuid();
  SortOption _sortOption = SortOption.manual;
  UserProvider? _userProvider;

  set userProvider(UserProvider? up) => _userProvider = up;

  // Memoization cache
  final Map<String, List<Task>> _navCache = {};
  bool _isCacheDirty = true;

  List<Task> get allTasks => _tasks;
  SortOption get sortOption => _sortOption;

  Future<void> init() async {
    _tasks = StorageService.instance.getAllTasks();
    ReminderService.instance.updateTasks(_tasks);
    _isCacheDirty = true;
  }

  // ─── Sticker support ──────────────────────────────────────────────────────
  
  Future<void> updateSticker(String taskId, Sticker? sticker) async {
    final idx = _tasks.indexWhere((t) => t.id == taskId);
    if (idx == -1) return;
    
    final updated = _tasks[idx].copyWith(
      stickerId: sticker?.id,
      clearSticker: sticker == null,
      updatedAt: DateTime.now(),
    );
    _tasks[idx] = updated;
    await StorageService.instance.saveTask(updated);
    notifyListeners();
  }

  // ─── Counts ───────────────────────────────────────────────────────────────

  int get todayCount => getTasksForNav(AppConstants.navToday).length;

  int get todayCompletedCount =>
      getTasksForNav(AppConstants.navToday, filterMITs: false, filterHighPriority: false, filterOverdue: false).where((t) => t.isCompleted).length;

  int countForList(String listId) =>
      _tasks.where((t) => t.listId == listId && !t.isDeleted && !t.isCompleted).length;

  // ─── Filtering ────────────────────────────────────────────────────────────

  List<Task> getTasksForNav(
    String navItem, {
    String? searchQuery,
    bool filterMITs = false,
    bool filterHighPriority = false,
    bool filterOverdue = false,
    List<String> mitIds = const [],
  }) {
    // Return cached result if query and filters are null/empty and cache is clean
    final bool canCache = (searchQuery == null || searchQuery.isEmpty) && 
                         !filterMITs && !filterHighPriority && !filterOverdue;
    
    if (canCache && !_isCacheDirty && _navCache.containsKey(navItem)) {
      return _navCache[navItem]!;
    }

    List<Task> base;

    switch (navItem) {
      case AppConstants.navToday:
        final now = DateTime.now();
        final todayStart = DateTime(now.year, now.month, now.day);
        final todayEnd = todayStart.add(const Duration(days: 1));
        
        var filtered = _tasks.where((t) {
          if (t.isDeleted || t.isCompleted) return false;
          if (t.dueDate == null) return false;
          return t.dueDate!.isBefore(todayEnd);
        }).toList();

        // Apply quick filters
        if (filterMITs) {
          filtered = filtered.where((t) => mitIds.contains(t.id)).toList();
        }
        if (filterHighPriority) {
          filtered = filtered.where((t) => t.priority == Priority.high || t.priority == Priority.urgent).toList();
        }
        if (filterOverdue) {
          filtered = filtered.where((t) => t.isOverdue).toList();
        }

        base = filtered;
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
        final active = _tasks.where((t) => !t.isDeleted && !t.isCompleted).toList();
        final completed = _tasks.where((t) => !t.isDeleted && t.isCompleted).toList();
        return [..._sort(active), ..._sort(completed)];
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
            !t.isDeleted && !t.isCompleted && t.dueDate != null).toList();
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

    final result = _sort(base);
    
    if (canCache) {
      _navCache[navItem] = result;
      if (_navCache.length > 20) _navCache.clear(); // Simple eviction
    }
    
    return result;
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
    _isCacheDirty = true;
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
    String? recurrenceJson,
  }) async {
    final now = DateTime.now();
    final autoStickerId = StickerSuggester.suggest(title);
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
      recurrenceJson: recurrenceJson,
      stickerId: autoStickerId,
      createdAt: now,
      updatedAt: now,
      sortOrder: _tasks.length,
    );
    _tasks.add(task);
    await StorageService.instance.saveTask(task);
    ReminderService.instance.updateTasks(_tasks);
    _isCacheDirty = true;
    notifyListeners();
    return task;
  }

  Future<void> addTask(Task task) async {
    _tasks.add(task);
    await StorageService.instance.saveTask(task);
    ReminderService.instance.updateTasks(_tasks);
    _isCacheDirty = true;
    notifyListeners();
  }

  Future<void> updateTask(Task task) async {
    _updateTask(task.id, (t) => t.copyWith(
      title: task.title,
      description: task.description,
      status: task.status,
      priority: task.priority,
      dueDate: task.dueDate,
      dueHour: task.dueHour,
      dueMinute: task.dueMinute,
      listId: task.listId,
      tags: task.tags,
      subtasks: task.subtasks,
      isFlagged: task.isFlagged,
      recurrenceJson: task.recurrenceJson,
      recurringParentId: task.recurringParentId,
      occurrenceIndex: task.occurrenceIndex,
      estimatedMinutes: task.estimatedMinutes,
      pomodoroCount: task.pomodoroCount,
      attachments: task.attachments,
      isDeleted: task.isDeleted,
      deletedAt: task.deletedAt,
      sortOrder: task.sortOrder,
      stickerId: task.stickerId,
      hasReminder: task.hasReminder,
      reminderMinutesBefore: task.reminderMinutesBefore,
    ));
  }

  Future<void> updateTitle(String id, String title) async {
    _updateTask(id, (t) => t.copyWith(title: title));
  }

  Future<void> updateDescription(String id, String description) async {
    _updateTask(id, (t) => t.copyWith(description: description));
  }

  void _updateTask(String id, Task Function(Task) transform) {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    _tasks[idx] = transform(_tasks[idx]).copyWith(updatedAt: DateTime.now());
    try {
      StorageService.instance.saveTask(_tasks[idx]);
    } catch (e) {
      debugPrint('❌ TASK_PROVIDER: Failed to save task: $e');
    }
    ReminderService.instance.updateTasks(_tasks);
    _isCacheDirty = true;
    notifyListeners();
  }

  Future<void> toggleComplete(String id, {CelebrationProvider? celebration}) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final task = _tasks[idx];
    final wasCompleted = task.isCompleted;
    final now = DateTime.now();
    final updated = task.copyWith(
      status: wasCompleted ? TaskStatus.todo : TaskStatus.done,
      completedAt: wasCompleted ? null : now,
      clearCompletedAt: wasCompleted,
      updatedAt: now,
    );
    _tasks[idx] = updated;
    await StorageService.instance.saveTask(updated);

    if (!wasCompleted && updated.isCompleted) {
      NotificationService.instance.cancelNotification(id);
    }

    // Spawn next recurring instance
    if (!wasCompleted && updated.isCompleted && updated.isRecurring && updated.dueDate != null) {
      await _spawnNextOccurrence(updated);
    }

    _isCacheDirty = true;

    // Award XP
    if (!wasCompleted && updated.isCompleted) {
      _userProvider?.recordTaskCompletion(updated);
    }

    notifyListeners();

    if (!wasCompleted && celebration != null) {
      final todayTasks = getTasksForNav(AppConstants.navToday);
      final remaining = todayTasks.where((t) => !t.isCompleted).length;
      if (remaining == 0 && todayTasks.isNotEmpty) {
        celebration.triggerCelebration();
      }
    }
  }

  Future<void> updateTaskCompletion(String id, bool completed) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final now = DateTime.now();
    final updated = _tasks[idx].copyWith(
      status: completed ? TaskStatus.done : TaskStatus.todo,
      completedAt: completed ? now : null,
      clearCompletedAt: !completed,
      updatedAt: now,
    );
    _tasks[idx] = updated;
    await StorageService.instance.saveTask(updated);

    if (completed) {
      NotificationService.instance.cancelNotification(id);
    }

    // Spawn next recurring instance
    if (completed && updated.isRecurring && updated.dueDate != null) {
      await _spawnNextOccurrence(updated);
    }

    _isCacheDirty = true;
    
    // Award XP
    if (completed) {
      _userProvider?.recordTaskCompletion(updated);
    }

    notifyListeners();
  }
  Future<void> toggleFlag(String id) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final updated = _tasks[idx].copyWith(isFlagged: !_tasks[idx].isFlagged, updatedAt: DateTime.now());
    _tasks[idx] = updated;
    await StorageService.instance.saveTask(updated);
    _isCacheDirty = true;
    notifyListeners();
  }

  Future<void> updatePriority(String id, Priority priority) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final updated = _tasks[idx].copyWith(priority: priority, updatedAt: DateTime.now());
    _tasks[idx] = updated;
    await StorageService.instance.saveTask(updated);
    _isCacheDirty = true;
    notifyListeners();
  }

  // --- Bulk Actions ---

  Future<void> bulkComplete(List<String> ids) async {
    for (final id in ids) {
      await toggleComplete(id);
    }
  }

  Future<void> bulkDelete(List<String> ids) async {
    for (final id in ids) {
      await moveToTrash(id);
    }
  }

  Future<void> bulkSetPriority(List<String> ids, Priority priority) async {
    for (final id in ids) {
      await updatePriority(id, priority);
    }
  }

  Future<void> bulkMoveToList(List<String> ids, String? listId) async {
    for (final id in ids) {
      await moveToList(id, listId);
    }
  }

  Future<void> bulkUpdateDueDate(List<String> ids, DateTime? dueDate) async {
    for (final id in ids) {
      final task = getById(id);
      if (task != null) {
        final updated = task.copyWith(
          dueDate: dueDate,
          updatedAt: DateTime.now(),
        );
        final idx = _tasks.indexWhere((t) => t.id == id);
        if (idx != -1) {
          _tasks[idx] = updated;
          await StorageService.instance.saveTask(updated);
        }
      }
    }
    ReminderService.instance.updateTasks(_tasks);
    notifyListeners();
  }

  Future<void> bulkFlag(List<String> ids) async {
    for (final id in ids) {
      await toggleFlag(id);
    }
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
    _isCacheDirty = true;
    notifyListeners();
  }

  Future<void> moveToList(String id, String? listId) async {
    final idx = _tasks.indexWhere((t) => t.id == id);
    if (idx == -1) return;
    final updated = _tasks[idx].copyWith(listId: listId, clearListId: listId == null, updatedAt: DateTime.now());
    _tasks[idx] = updated;
    await StorageService.instance.saveTask(updated);
    _isCacheDirty = true;
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

    if (status == TaskStatus.done) {
      NotificationService.instance.cancelNotification(id);
    }

    // Spawn next recurring instance
    if (status == TaskStatus.done && updated.isRecurring && updated.dueDate != null) {
      await _spawnNextOccurrence(updated);
    }

    _isCacheDirty = true;

    // Award XP
    if (status == TaskStatus.done) {
      _userProvider?.recordTaskCompletion(updated);
    }

    notifyListeners();
  }

  Future<void> setSticker(String taskId, String? stickerId) async {
    _updateTask(taskId, (t) => t.copyWith(
      stickerId: stickerId,
      clearSticker: stickerId == null || stickerId.isEmpty,
    ));
  }

  Future<void> updateDueTime(String id, int hour, int minute) async {
    _updateTask(id, (t) => t.copyWith(dueHour: hour, dueMinute: minute));
  }

  Future<void> clearDueTime(String id) async {
    _updateTask(id, (t) => t.copyWith(
      clearDueTime: true,
      hasReminder: false,
    ));
  }

  Future<void> setReminder(String id, bool enabled, int minutesBefore) async {
    _updateTask(id, (t) => t.copyWith(
      hasReminder: enabled,
      reminderMinutesBefore: minutesBefore,
    ));
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
    _isCacheDirty = true;
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
    _isCacheDirty = true;
    notifyListeners();
  }

  Future<void> emptyTrash() async {
    final trashed = _tasks.where((t) => t.isDeleted).toList();
    for (final t in trashed) {
      await StorageService.instance.deleteTask(t.id);
    }
    _tasks.removeWhere((t) => t.isDeleted);
    _isCacheDirty = true;
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
    _isCacheDirty = true;
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
    _isCacheDirty = true;
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
        _isCacheDirty = true;
        notifyListeners();
      }
    }
  }

  bool get canUndo => _undoStack.isNotEmpty;

  // ─── Statistics ───────────────────────────────────────────────────────────

  int get completedToday {
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

  Future<void> _spawnNextOccurrence(Task completed) async {
    final rule = completed.recurrence;
    if (rule == null) return;

    // Check end conditions
    if (rule.endDate != null && DateTime.now().isAfter(rule.endDate!)) {
      return;
    }
    if (rule.maxOccurrences != null && completed.occurrenceIndex >= rule.maxOccurrences!) {
      return;
    }

    final nextDueDate = rule.nextDate(completed.dueDate!);

    final nextTask = Task(
      id: _uuid.v4(),
      title: completed.title,
      description: completed.description,
      listId: completed.listId,
      priority: completed.priority,
      tags: List.from(completed.tags),
      dueDate: nextDueDate,
      dueHour: completed.dueHour,
      dueMinute: completed.dueMinute,
      hasReminder: completed.hasReminder,
      reminderMinutesBefore: completed.reminderMinutesBefore,
      recurrenceJson: completed.recurrenceJson,
      recurringParentId: completed.recurringParentId ?? completed.id,
      occurrenceIndex: completed.occurrenceIndex + 1,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    _tasks.add(nextTask);
    await StorageService.instance.saveTask(nextTask);
    ReminderService.instance.updateTasks(_tasks);
    notifyListeners();
  }

  Future<void> setRecurrence(String id, RecurrenceRule? rule) async {
    _updateTask(id, (t) => t.copyWith(
      recurrenceJson: rule != null ? jsonEncode(rule.toJson()) : null,
    ));
  }
}

class _UndoAction {
  final String type;
  final Task task;
  _UndoAction({required this.type, required this.task});
}
