import 'package:flutter/material.dart';
import '../theme/colors.dart';

enum SortOption {
  dueDate,
  priority,
  alphabetical,
  createdDate,
  manual,
}

class AppSettings {
  final ThemeMode themeMode;
  final String accentColorHex;
  final String? defaultListId;
  final int startOfWeek; // 1=Monday, 7=Sunday
  final int focusDuration; // minutes
  final int? dailySummaryHour;
  final int? dailySummaryMinute;
  final bool notificationsEnabled;
  final SortOption defaultSort;

  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.accentColorHex = '007AFF',
    this.defaultListId,
    this.startOfWeek = 1,
    this.focusDuration = 25,
    this.dailySummaryHour,
    this.dailySummaryMinute,
    this.notificationsEnabled = true,
    this.defaultSort = SortOption.manual,
  });

  Color get accentColor {
    try {
      return Color(int.parse('FF$accentColorHex', radix: 16));
    } catch (_) {
      return AppColors.blue;
    }
  }

  AppSettings copyWith({
    ThemeMode? themeMode,
    String? accentColorHex,
    String? defaultListId,
    int? startOfWeek,
    int? focusDuration,
    int? dailySummaryHour,
    int? dailySummaryMinute,
    bool? notificationsEnabled,
    SortOption? defaultSort,
    bool clearDefaultListId = false,
    bool clearDailySummary = false,
  }) {
    return AppSettings(
      themeMode: themeMode ?? this.themeMode,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      defaultListId: clearDefaultListId ? null : (defaultListId ?? this.defaultListId),
      startOfWeek: startOfWeek ?? this.startOfWeek,
      focusDuration: focusDuration ?? this.focusDuration,
      dailySummaryHour: clearDailySummary ? null : (dailySummaryHour ?? this.dailySummaryHour),
      dailySummaryMinute: clearDailySummary ? null : (dailySummaryMinute ?? this.dailySummaryMinute),
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      defaultSort: defaultSort ?? this.defaultSort,
    );
  }

  Map<String, dynamic> toJson() => {
        'themeMode': themeMode.index,
        'accentColorHex': accentColorHex,
        'defaultListId': defaultListId,
        'startOfWeek': startOfWeek,
        'focusDuration': focusDuration,
        'dailySummaryHour': dailySummaryHour,
        'dailySummaryMinute': dailySummaryMinute,
        'notificationsEnabled': notificationsEnabled,
        'defaultSort': defaultSort.index,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) => AppSettings(
        themeMode: ThemeMode.values[json['themeMode'] as int? ?? 0],
        accentColorHex: json['accentColorHex'] as String? ?? '007AFF',
        defaultListId: json['defaultListId'] as String?,
        startOfWeek: json['startOfWeek'] as int? ?? 1,
        focusDuration: json['focusDuration'] as int? ?? 25,
        dailySummaryHour: json['dailySummaryHour'] as int?,
        dailySummaryMinute: json['dailySummaryMinute'] as int?,
        notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
        defaultSort: SortOption.values[json['defaultSort'] as int? ?? 0],
      );
}
