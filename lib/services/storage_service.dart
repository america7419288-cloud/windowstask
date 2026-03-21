import 'dart:convert';
import 'dart:io' show Platform;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/task.dart';
import '../models/task_list.dart';
import '../models/tag.dart';
import '../models/app_settings.dart';
import 'export_service.dart';
import '../utils/constants.dart';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class StorageService {
  StorageService._();
  static final StorageService instance = StorageService._();

  late Box<Task> _tasksBox;
  late Box<TaskList> _listsBox;
  late Box<Tag> _tagsBox;
  late Box _settingsBox;
  late Box _profileBox;
  SharedPreferences? _prefs;

  Future<void> init() async {
    final secureStorage = FlutterSecureStorage();
    _prefs = await SharedPreferences.getInstance(); // Init earlier for fallback
    
    // We only encrypt on native platforms (Windows) for now
    // Hive on Web uses indexedDB which is already sandboxed, but we can add encryption there later if needed
    List<int>? encryptionKey;
    
    if (!kIsWeb) {
      if (Platform.isWindows) {
        // Windows DPAPI often loses keys across debug sessions. Use a secure storage + shared prefs fallback.
        String? keyBase64;
        try {
          keyBase64 = await secureStorage.read(key: 'db_encryption_key');
        } catch (e) {
          print('🔑 STORAGE ERROR Reading secure key: $e');
        }

        // Fallback to SharedPreferences if secure storage lost it (common in debug/unpackaged)
        if (keyBase64 == null) {
          keyBase64 = _prefs!.getString('db_encryption_key_backup');
          if (keyBase64 != null) {
            print('🔑 STORAGE: Recovered key from backup.');
          }
        }

        if (keyBase64 == null) {
          print('🔑 STORAGE: GENERATING NEW ENCRYPTION KEY');
          final key = Hive.generateSecureKey();
          keyBase64 = base64UrlEncode(key);
          
          try {
            await secureStorage.write(key: 'db_encryption_key', value: keyBase64);
          } catch (_) {}
          await _prefs!.setString('db_encryption_key_backup', keyBase64);
          
          encryptionKey = key;
        } else {
          print('🔑 STORAGE: SUCCESSFULLY READ EXISTING ENCRYPTION KEY');
          // Ensure it's backed up for next time in case DPAPI drops it later
          await _prefs!.setString('db_encryption_key_backup', keyBase64);
          encryptionKey = base64Url.decode(keyBase64);
        }
      } else {
        // MacOS, iOS, Android (Reliable secure storage)
        try {
          final keyBase64 = await secureStorage.read(key: 'db_encryption_key');
          if (keyBase64 == null) {
            final key = Hive.generateSecureKey();
            await secureStorage.write(key: 'db_encryption_key', value: base64UrlEncode(key));
            encryptionKey = key;
          } else {
            encryptionKey = base64Url.decode(keyBase64);
          }
        } catch (e) {
          print('🔑 STORAGE ERROR Reading key: $e');
          final key = Hive.generateSecureKey();
          encryptionKey = key;
        }
      }
    }

    final cipher = encryptionKey != null ? HiveAesCipher(encryptionKey) : null;

    _tasksBox = await Hive.openBox<Task>(AppConstants.tasksBox, encryptionCipher: cipher);
    _listsBox = await Hive.openBox<TaskList>(AppConstants.listsBox, encryptionCipher: cipher);
    _tagsBox = await Hive.openBox<Tag>(AppConstants.tagsBox, encryptionCipher: cipher);
    _settingsBox = await Hive.openBox('settings', encryptionCipher: cipher);
    _profileBox = await Hive.openBox('profile', encryptionCipher: cipher);
  }

  // ─── Tasks ───────────────────────────────────────────────────────────────

  List<Task> getAllTasks() => _tasksBox.values.toList();

  Future<void> saveTask(Task task) async {
    await _tasksBox.put(task.id, task);
    await _tasksBox.flush();
  }

  Future<void> deleteTask(String id) async {
    await _tasksBox.delete(id);
  }

  Task? getTask(String id) => _tasksBox.get(id);

  // ─── Lists ────────────────────────────────────────────────────────────────

  List<TaskList> getAllLists() => _listsBox.values.toList();

  Future<void> saveList(TaskList list) async {
    await _listsBox.put(list.id, list);
    await _listsBox.flush();
  }

  Future<void> deleteList(String id) async {
    await _listsBox.delete(id);
  }

  // ─── Tags ─────────────────────────────────────────────────────────────────

  List<Tag> getAllTags() => _tagsBox.values.toList();

  Future<void> saveTag(Tag tag) async {
    await _tagsBox.put(tag.id, tag);
    await _tagsBox.flush();
  }

  Future<void> deleteTag(String id) async {
    await _tagsBox.delete(id);
  }

  // ─── Settings ─────────────────────────────────────────────────────────────

  AppSettings getSettings() {
    final data = _settingsBox.get(AppConstants.settingsKey);
    if (data == null) {
      // Fallback to Prefs (Migration)
      if (_prefs != null) {
        final json = _prefs!.getString(AppConstants.settingsKey);
        if (json != null) {
          try {
            return AppSettings.fromJson(jsonDecode(json) as Map<String, dynamic>);
          } catch (_) {}
        }
      }
      return const AppSettings();
    }
    return AppSettings.fromJson(Map<String, dynamic>.from(data as Map));
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _settingsBox.put(AppConstants.settingsKey, settings.toJson());
    await _settingsBox.flush();
  }

  // ─── Profile ──────────────────────────────────────────────────────────────

  Map<String, dynamic>? getProfile() {
    final data = _profileBox.get('user_profile');
    if (data == null) {
      // Fallback to Prefs (Migration)
      if (_prefs != null) {
        final json = _prefs!.getString('user_profile');
        if (json != null) {
          try {
            return jsonDecode(json) as Map<String, dynamic>;
          } catch (_) {}
        }
      }
      return null;
    }
    return Map<String, dynamic>.from(data as Map);
  }

  Future<void> saveProfile(Map<String, dynamic> json) async {
    await _profileBox.put('user_profile', json);
    await _profileBox.flush();
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
