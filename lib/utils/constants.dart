class AppConstants {
  AppConstants._();

  // Window
  static const double windowMinWidth = 1200;
  static const double windowMinHeight = 800;

  // Layout
  static const double sidebarWidth = 220;
  static const double detailPanelWidth = 320;
  static const double titlebarHeight = 38;

  // Spacing (4pt grid)
  static const double sp4 = 4;
  static const double sp8 = 8;
  static const double sp12 = 12;
  static const double sp16 = 16;
  static const double sp20 = 20;
  static const double sp24 = 24;
  static const double sp32 = 32;
  static const double sp48 = 48;

  // Border Radius
  static const double radiusCard = 12;
  static const double radiusButton = 8;
  static const double radiusInput = 8;
  static const double radiusModal = 16;
  static const double radiusChip = 100;

  // Icon sizes
  static const double iconInline = 16;
  static const double iconButton = 20;
  static const double iconNav = 24;

  // Animations
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animMedium = Duration(milliseconds: 250);
  static const Duration animSlow = Duration(milliseconds: 350);

  // Hive boxes
  static const String tasksBox = 'tasks';
  static const String listsBox = 'lists';
  static const String tagsBox = 'tags';
  static const String settingsKey = 'app_settings';

  // Default pomodoro
  static const int defaultPomodoroDuration = 25;
  static const int defaultBreakDuration = 5;

  // Navigation
  static const String navToday = 'today';
  static const String navUpcoming = 'upcoming';
  static const String navAll = 'all';
  static const String navCompleted = 'completed';
  static const String navTrash = 'trash';
  static const String navHighPriority = 'high_priority';
  static const String navScheduled = 'scheduled';
  static const String navFlagged = 'flagged';
  static const String navCalendar = 'calendar';
  static const String navInsights = 'insights';
  static const String navSettings = 'settings';
  static const String navStore = 'store';

  // Emojis for lists
  static const List<String> listEmojis = [
    '📋', '📌', '🎯', '💼', '🏠', '🎓', '💡', '🚀', '❤️', '🌟',
    '📚', '🏃', '🎵', '🍕', '🌿', '🔧', '💰', '✈️', '🎨', '🛒',
  ];

  static const String defaultColorHex = '007AFF';
}
