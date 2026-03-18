import 'package:flutter/material.dart';
import '../theme/colors.dart';

enum SortOption { dueDate, priority, alphabetical, createdDate, manual }

enum TaskViewLayout { list, grid, kanban, compact, magazine }

enum FontDensity { compact, normal, comfortable }

enum WallpaperType { none, solidColor, gradient, pattern, customImage }

enum StickerSize { small, normal, large, jumbo }

class AppSettings {
  final ThemeMode themeMode;
  final String accentColorHex;
  final String? defaultListId;
  final int startOfWeek;
  final int focusDuration;
  final int? dailySummaryHour;
  final int? dailySummaryMinute;
  final bool notificationsEnabled;
  final SortOption defaultSort;

  // Layout
  final double sidebarWidth;
  final FontDensity fontDensity;
  final TaskViewLayout defaultViewLayout;

  // Wallpaper
  final WallpaperType wallpaperType;
  final String? wallpaperColorHex;
  final String? wallpaperGradientId;
  final String? wallpaperPatternId;
  final double wallpaperOpacity;

  // Wallpaper brightness/dim control (0.0 = darkest, 1.0 = original)
  final double wallpaperBrightness;

  // Custom image — stored as file path on Windows, base64 key on web
  final String? wallpaperImagePath;

  // Sticker size
  final StickerSize stickerSize;

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
    this.sidebarWidth = 220,
    this.fontDensity = FontDensity.normal,
    this.defaultViewLayout = TaskViewLayout.list,
    this.wallpaperType = WallpaperType.none,
    this.wallpaperColorHex,
    this.wallpaperGradientId,
    this.wallpaperPatternId,
    this.wallpaperOpacity = 0.15,
    this.wallpaperBrightness = 0.85,
    this.wallpaperImagePath,
    this.stickerSize = StickerSize.normal,
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
    double? sidebarWidth,
    FontDensity? fontDensity,
    TaskViewLayout? defaultViewLayout,
    WallpaperType? wallpaperType,
    String? wallpaperColorHex,
    String? wallpaperGradientId,
    String? wallpaperPatternId,
    double? wallpaperOpacity,
    double? wallpaperBrightness,
    String? wallpaperImagePath,
    bool clearWallpaperImage = false,
    StickerSize? stickerSize,
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
      sidebarWidth: sidebarWidth ?? this.sidebarWidth,
      fontDensity: fontDensity ?? this.fontDensity,
      defaultViewLayout: defaultViewLayout ?? this.defaultViewLayout,
      wallpaperType: wallpaperType ?? this.wallpaperType,
      wallpaperColorHex: wallpaperColorHex ?? this.wallpaperColorHex,
      wallpaperGradientId: wallpaperGradientId ?? this.wallpaperGradientId,
      wallpaperPatternId: wallpaperPatternId ?? this.wallpaperPatternId,
      wallpaperOpacity: wallpaperOpacity ?? this.wallpaperOpacity,
      wallpaperBrightness: wallpaperBrightness ?? this.wallpaperBrightness,
      wallpaperImagePath: clearWallpaperImage
          ? null
          : (wallpaperImagePath ?? this.wallpaperImagePath),
      stickerSize: stickerSize ?? this.stickerSize,
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
        'sidebarWidth': sidebarWidth,
        'fontDensity': fontDensity.index,
        'defaultViewLayout': defaultViewLayout.index,
        'wallpaperType': wallpaperType.index,
        'wallpaperColorHex': wallpaperColorHex,
        'wallpaperGradientId': wallpaperGradientId,
        'wallpaperPatternId': wallpaperPatternId,
        'wallpaperOpacity': wallpaperOpacity,
        'wallpaperBrightness': wallpaperBrightness,
        'wallpaperImagePath': wallpaperImagePath,
        'stickerSize': stickerSize.index,
      };

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    // Safely clamp wallpaperType index to valid range
    final wtIndex = json['wallpaperType'] as int? ?? 0;
    final safeWtIndex = wtIndex.clamp(0, WallpaperType.values.length - 1);

    // Safely clamp layout index
    final vlIndex = json['defaultViewLayout'] as int? ?? 0;
    final safeVlIndex = vlIndex.clamp(0, TaskViewLayout.values.length - 1);

    return AppSettings(
      themeMode: ThemeMode.values[json['themeMode'] as int? ?? 2],
      accentColorHex: json['accentColorHex'] as String? ?? '007AFF',
      defaultListId: json['defaultListId'] as String?,
      startOfWeek: json['startOfWeek'] as int? ?? 1,
      focusDuration: json['focusDuration'] as int? ?? 25,
      dailySummaryHour: json['dailySummaryHour'] as int?,
      dailySummaryMinute: json['dailySummaryMinute'] as int?,
      notificationsEnabled: json['notificationsEnabled'] as bool? ?? true,
      defaultSort: SortOption.values[json['defaultSort'] as int? ?? 0],
      sidebarWidth: (json['sidebarWidth'] as num?)?.toDouble() ?? 220,
      fontDensity: FontDensity.values[json['fontDensity'] as int? ?? 1],
      defaultViewLayout: TaskViewLayout.values[safeVlIndex],
      wallpaperType: WallpaperType.values[safeWtIndex],
      wallpaperColorHex: json['wallpaperColorHex'] as String?,
      wallpaperGradientId: json['wallpaperGradientId'] as String?,
      wallpaperPatternId: json['wallpaperPatternId'] as String?,
      wallpaperOpacity: (json['wallpaperOpacity'] as num?)?.toDouble() ?? 0.15,
      wallpaperBrightness: (json['wallpaperBrightness'] as num?)?.toDouble() ?? 0.85,
      wallpaperImagePath: json['wallpaperImagePath'] as String?,
      stickerSize: StickerSize.values[json['stickerSize'] as int? ?? 1], // Default normal
    );
  }
}
