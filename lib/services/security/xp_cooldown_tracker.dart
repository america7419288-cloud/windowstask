import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'encryption_service.dart';

class XPCooldownTracker {
  XPCooldownTracker._();
  static final instance = XPCooldownTracker._();

  // taskId → date string 'YYYY-MM-DD'
  // when XP was last earned
  final Map<String, String> _earned = {};

  // Obfuscated storage key
  static const _storageKey =
      // SHA-256 of 'xp_cooldown_tracker'
      // truncated — looks like garbage
      '7f3a9c2e1b4d8f6a';

  Future<void> init() async {
    await _load();
    _pruneExpired();
  }

  // Check if task can give XP today
  bool canEarnXP(String taskId) {
    final today = _todayKey();
    final lastEarned = _earned[taskId];
    return lastEarned != today;
  }

  // Record that task gave XP today
  Future<void> recordXPEarned(String taskId) async {
    _earned[taskId] = _todayKey();
    await _save();
  }

  // Remove entries from previous days
  void _pruneExpired() {
    final today = _todayKey();
    _earned.removeWhere((_, date) => date != today);
  }

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-'
        '${now.month.toString().padLeft(2, "0")}-'
        '${now.day.toString().padLeft(2, "0")}';
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    try {
      final json = jsonEncode(_earned);
      final encrypted = EncryptionService.instance.encrypt(json);
      await prefs.setString(_storageKey, encrypted);
    } catch (_) {}
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final encrypted = prefs.getString(_storageKey);
    if (encrypted == null) return;
    try {
      final json = EncryptionService.instance.decrypt(encrypted);
      final map = jsonDecode(json) as Map<String, dynamic>;
      _earned.clear();
      map.forEach((k, v) => _earned[k] = v as String);
    } catch (_) {
      // Decryption failed = tampered
      // Clear it and start fresh
      await prefs.remove(_storageKey);
      _earned.clear();
    }
  }
}
