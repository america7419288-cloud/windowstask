import 'package:flutter/material.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';
import '../theme/colors.dart';

class SettingsProvider extends ChangeNotifier {
  late AppSettings _settings;

  AppSettings get settings => _settings;

  void init() {
    _settings = StorageService.instance.getSettings();
  }

  ThemeMode get themeMode => _settings.themeMode;
  Color get accentColor => _settings.accentColor;
  String get accentColorHex => _settings.accentColorHex;
  int get focusDuration => _settings.focusDuration;
  bool get notificationsEnabled => _settings.notificationsEnabled;
  int get startOfWeek => _settings.startOfWeek;
  SortOption get defaultSort => _settings.defaultSort;

  Future<void> setThemeMode(ThemeMode mode) async {
    _settings = _settings.copyWith(themeMode: mode);
    await _save();
  }

  Future<void> setAccentColor(String hexColor) async {
    _settings = _settings.copyWith(accentColorHex: hexColor);
    await _save();
  }

  Future<void> setDefaultListId(String? id) async {
    _settings = _settings.copyWith(defaultListId: id, clearDefaultListId: id == null);
    await _save();
  }

  Future<void> setStartOfWeek(int day) async {
    _settings = _settings.copyWith(startOfWeek: day);
    await _save();
  }

  Future<void> setFocusDuration(int minutes) async {
    _settings = _settings.copyWith(focusDuration: minutes);
    await _save();
  }

  Future<void> setDailySummaryTime(int? hour, int? minute) async {
    _settings = _settings.copyWith(
      dailySummaryHour: hour,
      dailySummaryMinute: minute,
      clearDailySummary: hour == null,
    );
    await _save();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    _settings = _settings.copyWith(notificationsEnabled: enabled);
    await _save();
  }

  Future<void> setDefaultSort(SortOption sort) async {
    _settings = _settings.copyWith(defaultSort: sort);
    await _save();
  }

  Future<void> _save() async {
    await StorageService.instance.saveSettings(_settings);
    notifyListeners();
  }

  List<Map<String, dynamic>> get accentColorOptions => [
    {'hex': '007AFF', 'color': AppColors.blue, 'name': 'Blue'},
    {'hex': 'AF52DE', 'color': AppColors.purple, 'name': 'Purple'},
    {'hex': 'FF2D55', 'color': AppColors.pink, 'name': 'Pink'},
    {'hex': 'FF3B30', 'color': AppColors.red, 'name': 'Red'},
    {'hex': 'FF9500', 'color': AppColors.orange, 'name': 'Orange'},
    {'hex': '34C759', 'color': AppColors.green, 'name': 'Green'},
    {'hex': '5AC8FA', 'color': AppColors.teal, 'name': 'Teal'},
  ];
}
