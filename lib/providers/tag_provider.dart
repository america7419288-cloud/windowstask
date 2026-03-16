import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/tag.dart';
import '../services/storage_service.dart';

class TagProvider extends ChangeNotifier {
  List<Tag> _tags = [];
  static const _uuid = Uuid();

  List<Tag> get tags => _tags;

  void init() {
    _tags = StorageService.instance.getAllTags();
  }

  Tag? getById(String id) {
    try {
      return _tags.firstWhere((t) => t.id == id);
    } catch (_) {
      return null;
    }
  }

  Tag? getByName(String name) {
    try {
      return _tags.firstWhere((t) => t.name.toLowerCase() == name.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  Future<Tag> createTag({required String name, String colorHex = '007AFF'}) async {
    final existing = getByName(name);
    if (existing != null) return existing;

    final tag = Tag(id: _uuid.v4(), name: name, colorHex: colorHex);
    _tags.add(tag);
    await StorageService.instance.saveTag(tag);
    notifyListeners();
    return tag;
  }

  Future<void> updateTag(Tag tag) async {
    final idx = _tags.indexWhere((t) => t.id == tag.id);
    if (idx != -1) {
      _tags[idx] = tag;
      await StorageService.instance.saveTag(tag);
      notifyListeners();
    }
  }

  Future<void> deleteTag(String id) async {
    _tags.removeWhere((t) => t.id == id);
    await StorageService.instance.deleteTag(id);
    notifyListeners();
  }
}
