import '../utils/constants.dart';

class UserProfile {
  final String name;
  final String? avatarPath;
  final String accentHex;
  final DateTime createdAt;
  final int totalXP;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveDate;
  final List<String> earnedBadgeIds;
  final bool hasCompletedOnboarding;
  final int streakShields;
  final List<String> unlockedStickerIds;
  final List<String> purchasedItemIds;
  final int totalTasksCompleted;
  final int totalFocusSessions;
  final int totalPlanningSessions;

  const UserProfile({
    required this.name,
    this.avatarPath,
    this.accentHex = AppConstants.defaultColorHex,
    required this.createdAt,
    this.totalXP = 0,
    this.currentStreak = 0,
    this.longestStreak = 0,
    this.lastActiveDate,
    this.earnedBadgeIds = const [],
    this.hasCompletedOnboarding = false,
    this.streakShields = 0,
    this.unlockedStickerIds = const [],
    this.purchasedItemIds = const [],
    this.totalTasksCompleted = 0,
    this.totalFocusSessions = 0,
    this.totalPlanningSessions = 0,
  });

  UserProfile copyWith({
    String? name,
    String? avatarPath,
    String? accentHex,
    DateTime? createdAt,
    int? totalXP,
    int? currentStreak,
    int? longestStreak,
    DateTime? lastActiveDate,
    List<String>? earnedBadgeIds,
    bool? hasCompletedOnboarding,
    int? streakShields,
    List<String>? unlockedStickerIds,
    List<String>? purchasedItemIds,
    int? totalTasksCompleted,
    int? totalFocusSessions,
    int? totalPlanningSessions,
    bool clearAvatar = false,
    bool clearLastActive = false,
  }) {
    return UserProfile(
      name: name ?? this.name,
      avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
      accentHex: accentHex ?? this.accentHex,
      createdAt: createdAt ?? this.createdAt,
      totalXP: totalXP ?? this.totalXP,
      currentStreak: currentStreak ?? this.currentStreak,
      longestStreak: longestStreak ?? this.longestStreak,
      lastActiveDate: clearLastActive ? null : (lastActiveDate ?? this.lastActiveDate),
      earnedBadgeIds: earnedBadgeIds ?? List.from(this.earnedBadgeIds),
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      streakShields: streakShields ?? this.streakShields,
      unlockedStickerIds: unlockedStickerIds ?? List.from(this.unlockedStickerIds),
      purchasedItemIds: purchasedItemIds ?? List.from(this.purchasedItemIds),
      totalTasksCompleted: totalTasksCompleted ?? this.totalTasksCompleted,
      totalFocusSessions: totalFocusSessions ?? this.totalFocusSessions,
      totalPlanningSessions: totalPlanningSessions ?? this.totalPlanningSessions,
    );
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'avatarPath': avatarPath,
    'accentHex': accentHex,
    'createdAt': createdAt.toIso8601String(),
    'totalXP': totalXP,
    'currentStreak': currentStreak,
    'longestStreak': longestStreak,
    'lastActiveDate': lastActiveDate?.toIso8601String(),
    'earnedBadgeIds': earnedBadgeIds,
    'hasCompletedOnboarding': hasCompletedOnboarding,
    'streakShields': streakShields,
    'unlockedStickerIds': unlockedStickerIds,
    'purchasedItemIds': purchasedItemIds,
    'totalTasksCompleted': totalTasksCompleted,
    'totalFocusSessions': totalFocusSessions,
    'totalPlanningSessions': totalPlanningSessions,
  };

  factory UserProfile.fromJson(Map<String, dynamic> j) => UserProfile(
    name: j['name'] as String? ?? 'Friend',
    avatarPath: j['avatarPath'] as String?,
    accentHex: j['accentHex'] as String? ?? AppConstants.defaultColorHex,
    createdAt: DateTime.parse(j['createdAt'] as String),
    totalXP: j['totalXP'] as int? ?? 0,
    currentStreak: j['currentStreak'] as int? ?? 0,
    longestStreak: j['longestStreak'] as int? ?? 0,
    lastActiveDate: j['lastActiveDate'] != null
        ? DateTime.parse(j['lastActiveDate'] as String)
        : null,
    earnedBadgeIds: (j['earnedBadgeIds'] as List?)
        ?.map((e) => e as String).toList() ?? [],
    hasCompletedOnboarding: j['hasCompletedOnboarding'] as bool? ?? false,
    streakShields: j['streakShields'] as int? ?? 0,
    unlockedStickerIds: (j['unlockedStickerIds'] as List?)
        ?.map((e) => e as String).toList() ?? [],
    purchasedItemIds: (j['purchasedItemIds'] as List?)
        ?.map((e) => e as String).toList() ?? [],
    totalTasksCompleted: j['totalTasksCompleted'] as int? ?? 0,
    totalFocusSessions: j['totalFocusSessions'] as int? ?? 0,
    totalPlanningSessions: j['totalPlanningSessions'] as int? ?? 0,
  );

  String get firstName => name.split(' ').first;
}
