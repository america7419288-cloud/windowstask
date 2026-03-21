import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/task_list.dart';
import '../services/storage_service.dart';

class ListProvider extends ChangeNotifier {
  List<TaskList> _lists = [];
  static const _uuid = Uuid();

  List<TaskList> get lists => _lists;
  List<TaskList> get activeLists =>
      _lists.where((l) => !l.isArchived).toList()..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));

  void init() {
    _lists = StorageService.instance.getAllLists();
    _lists.sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
  }

  TaskList? getById(String id) {
    try {
      return _lists.firstWhere((l) => l.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<TaskList> createList({
    required String name,
    String emoji = '📋',
    String colorHex = '007AFF',
    String? folderName,
  }) async {
    final list = TaskList(
      id: _uuid.v4(),
      name: name,
      emoji: emoji,
      colorHex: colorHex,
      sortOrder: _lists.length,
      createdAt: DateTime.now(),
      folderName: folderName,
    );
    _lists.add(list);
    await StorageService.instance.saveList(list);
    notifyListeners();
    return list;
  }

  Future<void> updateList(TaskList list) async {
    final idx = _lists.indexWhere((l) => l.id == list.id);
    if (idx != -1) {
      _lists[idx] = list;
      await StorageService.instance.saveList(list);
      notifyListeners();
    }
  }

  Future<void> deleteList(String id) async {
    _lists.removeWhere((l) => l.id == id);
    await StorageService.instance.deleteList(id);
    notifyListeners();
  }

  Future<void> archiveList(String id) async {
    final idx = _lists.indexWhere((l) => l.id == id);
    if (idx != -1) {
      _lists[idx] = _lists[idx].copyWith(isArchived: true);
      await StorageService.instance.saveList(_lists[idx]);
      notifyListeners();
    }
  }

  Future<void> reorderLists(int oldIndex, int newIndex) async {
    final active = activeLists;
    final item = active.removeAt(oldIndex);
    active.insert(newIndex, item);
    for (int i = 0; i < active.length; i++) {
      active[i] = active[i].copyWith(sortOrder: i);
    }
    for (final l in active) {
      final idx = _lists.indexWhere((x) => x.id == l.id);
      if (idx != -1) _lists[idx] = l;
      await StorageService.instance.saveList(l);
    }
    notifyListeners();
  }
}
