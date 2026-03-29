/// XP values for actions
class XPValues {
  XPValues._();

  static const completeTask   = 10;
  static const completeHigh   = 15;
  static const completeUrgent = 20;
  static const completeAllDay = 50;
  static const maintainStreak = 5;
  static const addSubtask     = 2;
  static const completeFocus  = 25;
}

/// A single achievement definition
class Achievement {
  final String id;
  final String name;
  final String description;
  final String emoji;
  final String assetPath;
  final int xpReward;
  final AchievementTier tier;
  final AchievementCategory category;
  final int targetValue;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.assetPath,
    required this.xpReward,
    required this.tier,
    required this.category,
    this.targetValue = 1,
  });
}

enum AchievementCategory { streak, taskCount, focusTime, planning, earlyBird, perfectionist }

enum AchievementTier { bronze, silver, gold }

/// Registry of all achievements
class Achievements {
  Achievements._();

  static const List<Achievement> all = [
    Achievement(
      id: 'early_bird',
      name: 'Early Bird',
      description: 'Complete a task before 9 AM',
      emoji: '🌅',
      assetPath: 'assets/achivements/early_bird.tgs',
      xpReward: 25,
      tier: AchievementTier.bronze,
      category: AchievementCategory.earlyBird,
    ),
    Achievement(
      id: 'deep_work_master',
      name: 'Deep Work Master',
      description: 'Complete a 60-min focus session',
      emoji: '🧠',
      assetPath: 'assets/achivements/deep_work_master.tgs',
      xpReward: 50,
      tier: AchievementTier.gold,
      category: AchievementCategory.focusTime,
      targetValue: 60,
    ),
    Achievement(
      id: 'streak_7',
      name: 'Week Warrior',
      description: '7-day completion streak',
      emoji: '🔥',
      assetPath: 'assets/achivements/streak_7.tgs',
      xpReward: 100,
      tier: AchievementTier.silver,
      category: AchievementCategory.streak,
      targetValue: 7,
    ),
    Achievement(
      id: 'streak_30',
      name: 'Iron Will',
      description: '30-day completion streak',
      emoji: '⚡',
      assetPath: 'assets/achivements/streak_30.tgs',
      xpReward: 500,
      tier: AchievementTier.gold,
      category: AchievementCategory.streak,
      targetValue: 30,
    ),
    Achievement(
      id: 'century',
      name: 'Century Club',
      description: 'Complete 100 tasks',
      emoji: '💯',
      assetPath: 'assets/achivements/streak_100.tgs',
      xpReward: 200,
      tier: AchievementTier.silver,
      category: AchievementCategory.taskCount,
      targetValue: 100,
    ),
    Achievement(
      id: 'perfectionist',
      name: 'Perfectionist',
      description: 'Complete all tasks for 5 days',
      emoji: '✨',
      assetPath: 'assets/achivements/planner.tgs',
      xpReward: 150,
      tier: AchievementTier.gold,
      category: AchievementCategory.perfectionist,
      targetValue: 5,
    ),
    Achievement(
      id: 'speed_demon',
      name: 'Speed Demon',
      description: 'Complete 10 tasks in one day',
      emoji: '⚡',
      assetPath: 'assets/achivements/speed_demon.tgs',
      xpReward: 75,
      tier: AchievementTier.silver,
      category: AchievementCategory.taskCount, // Actually daily count, but we'll use taskCount for now or refine logic
      targetValue: 10,
    ),
    Achievement(
      id: 'planner',
      name: 'Master Planner',
      description: 'Use daily planning mode 7 times',
      emoji: '📋',
      assetPath: 'assets/achivements/planner.tgs',
      xpReward: 50,
      tier: AchievementTier.bronze,
      category: AchievementCategory.planning,
      targetValue: 7,
    ),
  ];

  static Achievement? findById(String id) =>
      all.where((a) => a.id == id).firstOrNull;
}
