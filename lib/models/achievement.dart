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
  final int xpReward;
  final AchievementTier tier;

  const Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.emoji,
    required this.xpReward,
    required this.tier,
  });
}

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
      xpReward: 25,
      tier: AchievementTier.bronze,
    ),
    Achievement(
      id: 'deep_work_master',
      name: 'Deep Work Master',
      description: 'Complete a 60-min focus session',
      emoji: '🧠',
      xpReward: 50,
      tier: AchievementTier.gold,
    ),
    Achievement(
      id: 'streak_7',
      name: 'Week Warrior',
      description: '7-day completion streak',
      emoji: '🔥',
      xpReward: 100,
      tier: AchievementTier.silver,
    ),
    Achievement(
      id: 'streak_30',
      name: 'Iron Will',
      description: '30-day completion streak',
      emoji: '⚡',
      xpReward: 500,
      tier: AchievementTier.gold,
    ),
    Achievement(
      id: 'century',
      name: 'Century Club',
      description: 'Complete 100 tasks',
      emoji: '💯',
      xpReward: 200,
      tier: AchievementTier.silver,
    ),
    Achievement(
      id: 'perfectionist',
      name: 'Perfectionist',
      description: 'Complete all tasks for 5 days',
      emoji: '✨',
      xpReward: 150,
      tier: AchievementTier.gold,
    ),
    Achievement(
      id: 'speed_demon',
      name: 'Speed Demon',
      description: 'Complete 10 tasks in one day',
      emoji: '⚡',
      xpReward: 75,
      tier: AchievementTier.silver,
    ),
    Achievement(
      id: 'planner',
      name: 'Master Planner',
      description: 'Use daily planning mode 7 times',
      emoji: '📋',
      xpReward: 50,
      tier: AchievementTier.bronze,
    ),
  ];

  static Achievement? findById(String id) =>
      all.where((a) => a.id == id).firstOrNull;
}
