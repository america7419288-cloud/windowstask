import '../models/sticker.dart';

/// Every decorative sticker placement in the app.
/// assetPath can be null — widget falls back to emoji.
class AppStickers {

  // ── Empty states ──────────────────────────────────
  static const Sticker todayEmpty = Sticker(
    id: 'deco_today_empty',
    packId: 'pack_bears',
    assetPath: 'assets/stickers/deco/bear_sleep.tgs',
    name: 'Today Empty',
    emoji: '🌤️',
  );

  static const Sticker allTasksEmpty = Sticker(
    id: 'deco_all_empty',
    packId: 'pack_bears',
    assetPath: 'assets/stickers/deco/bear_why.tgs',
    name: 'All Empty',
    emoji: '📋',
  );

  static const Sticker upcomingEmpty = Sticker(
    id: 'deco_upcoming_empty',
    packId: 'pack_misc',
    assetPath: 'assets/stickers/deco/bear_honey.tgs',
    name: 'Upcoming Empty',
    emoji: '📅',
  );

  static const Sticker completedEmpty = Sticker(
    id: 'deco_completed_empty',
    packId: 'pack_misc',
    assetPath: 'assets/stickers/deco/bear_happy.tgs',
    name: 'Completed Empty',
    emoji: '✅',
  );

  static const Sticker trashEmpty = Sticker(
    id: 'deco_trash_empty',
    packId: 'pack_peaches',
    assetPath: 'assets/stickers/deco/peach_womit.tgs',
    name: 'Trash Empty',
    emoji: '🗑️',
  );

  // ── Today header ──────────────────────────────────
  static const Sticker todayMorning = Sticker(
    id: 'deco_morning',
    packId: 'pack_misc',
    assetPath: 'assets/stickers/deco/happy_peach.tgs',
    name: 'Morning',
    emoji: '☀️',
  );

  static const Sticker todayAfternoon = Sticker(
    id: 'deco_afternoon',
    packId: 'pack_bears',
    assetPath: 'assets/stickers/deco/bear_work.tgs',
    name: 'Afternoon',
    emoji: '⚡',
  );

  static const Sticker todayEvening = Sticker(
    id: 'deco_evening',
    packId: 'pack_bears',
    assetPath: 'assets/stickers/deco/bear_bath.tgs',
    name: 'Evening',
    emoji: '🌆',
  );

  static const Sticker todayNight = Sticker(
    id: 'deco_night',
    packId: 'pack_bears',
    assetPath: 'assets/stickers/deco/bear_sleep.tgs',
    name: 'Night',
    emoji: '🌙',
  );

  static const Sticker todayAllDone = Sticker(
    id: 'deco_all_done',
    packId: 'pack_peaches',
    assetPath: 'assets/stickers/deco/peach_cheer.tgs',
    name: 'All Done',
    emoji: '🎉',
  );

  // ── Task completion celebration ────────────────────
  static const Sticker celebration = Sticker(
    id: 'deco_celebrate',
    packId: 'pack_peaches',
    assetPath: 'assets/stickers/deco/peach_dance.tgs',
    name: 'Celebrate',
    emoji: '🎊',
  );

  // ── Sidebar decoration ────────────────────────────
  static const Sticker sidebarMascot = Sticker(
    id: 'deco_mascot',
    packId: 'pack_bears',
    assetPath: 'assets/stickers/deco/bear_right.tgs',
    name: 'Mascot',
    emoji: '🤖',
  );

  // ── Settings header ───────────────────────────────
  static const Sticker settingsAppearance = Sticker(
    id: 'deco_settings_appearance',
    packId: 'pack_bears',
    assetPath: 'assets/stickers/deco/bear_care.tgs',
    name: 'Appearance',
    emoji: '🎨',
  );

  static const Sticker settingsLayout = Sticker(
    id: 'deco_settings_layout',
    packId: 'pack_bears',
    assetPath: 'assets/stickers/deco/bear_security.tgs',
    name: 'Layout',
    emoji: '📐',
  );

  static const Sticker settingsWallpaper = Sticker(
    id: 'deco_settings_wallpaper',
    packId: 'pack_bears',
    assetPath: 'assets/stickers/deco/funny.tgs',
    name: 'Wallpaper',
    emoji: '🖼️',
  );

  static const Sticker settingsTasks = Sticker(
    id: 'deco_settings_tasks',
    packId: 'pack_bears',
    assetPath: 'assets/stickers/deco/bear_pproductive.tgs',
    name: 'Tasks',
    emoji: '⚙️',
  );

  static const Sticker settingsAbout = Sticker(
    id: 'deco_settings_about',
    packId: 'pack_misc',
    assetPath: 'assets/stickers/deco/bear.tgs',
    name: 'About',
    emoji: '💡',
  );

  // ── Task Suggesters ───────────────────────────────
  static const Sticker work = Sticker(
    id: 'deco_task_work',
    packId: 'pack_bears',
    assetPath: 'assets/stickers/deco/bear_work.tgs',
    name: 'Work',
    emoji: '💼',
  );

  static const Sticker focus = Sticker(
    id: 'deco_task_focus',
    packId: 'pack_bears',
    assetPath: 'assets/stickers/deco/bear_pproductive.tgs',
    name: 'Focus',
    emoji: '🎯',
  );

  static const Sticker care = Sticker(
    id: 'deco_task_care',
    packId: 'pack_bears',
    assetPath: 'assets/stickers/deco/bear_care.tgs',
    name: 'Care',
    emoji: '🤍',
  );

  static const Sticker fitness = Sticker(
    id: 'deco_task_fitness',
    packId: 'pack_misc',
    assetPath: 'assets/stickers/deco/funny.tgs', // Using the playful one for fitness
    name: 'Fitness',
    emoji: '💪',
  );

  // ── Detail panel ──────────────────────────────────
  static const Sticker detailDefault = Sticker(
    id: 'deco_detail',
    packId: 'pack_misc',
    assetPath: 'assets/stickers/deco/bear_heart.tgs',
    name: 'Detail',
    emoji: '📝',
  );

  // ── Insights screen ─────────────────────────────────
  static const Sticker insightsStreak = Sticker(
    id: 'deco_insights_streak',
    packId: 'pack_frogs',
    assetPath: 'assets/stickers/frog_muscular_glow.tgs',
    name: 'Streak',
    emoji: '🔥',
  );

  static const Sticker insightsChart = Sticker(
    id: 'deco_insights_chart',
    packId: 'pack_misc',
    assetPath: 'assets/stickers/bear_pproductive.tgs',
    name: 'Chart',
    emoji: '📊',
  );

  static const Sticker insightsWeek = Sticker(
    id: 'deco_insights_week',
    packId: 'pack_bees',
    assetPath: 'assets/stickers/bee_chill_sunflower.tgs',
    name: 'Week',
    emoji: '📅',
  );

  static const Sticker insightsMonth = Sticker(
    id: 'deco_insights_month',
    packId: 'pack_space',
    assetPath: 'assets/stickers/astronaut_smiling.tgs',
    name: 'Month',
    emoji: '🗓️',
  );

  // ── Group headers ──────────────────────────────────
  static const Sticker groupOverdue = Sticker(
    id: 'deco_group_overdue',
    packId: 'pack_peaches',
    assetPath: 'assets/stickers/angry_peach.tgs',
    name: 'Overdue',
    emoji: '⚠️',
  );

  static const Sticker groupToday = Sticker(
    id: 'deco_group_today',
    packId: 'pack_misc',
    assetPath: 'assets/stickers/sun_happy_plain.tgs',
    name: 'Today',
    emoji: '☀️',
  );

  static const Sticker groupTomorrow = Sticker(
    id: 'deco_group_tomorrow',
    packId: 'pack_weather',
    assetPath: 'assets/stickers/weather_happy_sun_cloud.tgs',
    name: 'Tomorrow',
    emoji: '🌤️',
  );

  static const Sticker groupLater = Sticker(
    id: 'deco_group_later',
    packId: 'pack_bees',
    assetPath: 'assets/stickers/bee_sleeping.tgs',
    name: 'Later',
    emoji: '💤',
  );

  static const Sticker groupNoDueDate = Sticker(
    id: 'deco_group_nodue',
    packId: 'pack_frogs',
    assetPath: 'assets/stickers/frog_thinking.tgs',
    name: 'No Due Date',
    emoji: '🤔',
  );

  // ── Quote card ─────────────────────────────────────
  static const Sticker quoteSticker = Sticker(
    id: 'deco_quote',
    packId: 'pack_misc',
    assetPath: 'assets/stickers/bear_care.tgs',
    name: 'Quote',
    emoji: '💬',
  );

  // ── Celebration variety ────────────────────────────
  static const List<Sticker> celebrationStickers = [
    celebration,
    Sticker(id: 'cele_frog_thumbs', packId: 'decorative', assetPath: 'assets/stickers/frog_thumbs_up_giant.tgs', name: 'Frog Thumbs', emoji: '👍'),
    Sticker(id: 'cele_astronaut_party', packId: 'decorative', assetPath: 'assets/stickers/astronaut_party_moon.tgs', name: 'Astronaut Party', emoji: '🎉'),
    Sticker(id: 'cele_bee_thumbs', packId: 'decorative', assetPath: 'assets/stickers/bee_thumbs_up_giant.tgs', name: 'Bee Thumbs', emoji: '🐝'),
    Sticker(id: 'cele_speaker_party', packId: 'decorative', assetPath: 'assets/stickers/speaker_party.tgs', name: 'Speaker Party', emoji: '🔊'),
    Sticker(id: 'cele_bear_happy', packId: 'decorative', assetPath: 'assets/stickers/bear_happy.tgs', name: 'Bear Happy', emoji: '🐻'),
    Sticker(id: 'cele_sunflower', packId: 'decorative', assetPath: 'assets/stickers/sunflower_happy.tgs', name: 'Sunflower Happy', emoji: '🌻'),
    Sticker(id: 'cele_duck', packId: 'decorative', assetPath: 'assets/stickers/duck_happy.tgs', name: 'Duck Happy', emoji: '🦆'),
    Sticker(id: 'cele_cactus_thumbs', packId: 'decorative', assetPath: 'assets/stickers/cactus_double_thumbs_up.tgs', name: 'Cactus Thumbs', emoji: '🌵'),
    Sticker(id: 'cele_peach_cheer', packId: 'decorative', assetPath: 'assets/stickers/peach_cheer.tgs', name: 'Peach Cheer', emoji: '🎊'),
  ];

  // ── Planning floating stickers ─────────────────────
  static const List<Sticker> floatingStickers = [
    Sticker(id: 'float_clover', packId: 'decorative', assetPath: 'assets/stickers/clover_winking.tgs', name: 'Clover', emoji: '🍀'),
    Sticker(id: 'float_bee_flowers', packId: 'decorative', assetPath: 'assets/stickers/bee_flowers.tgs', name: 'Bee Flowers', emoji: '🌸'),
    Sticker(id: 'float_pigeon', packId: 'decorative', assetPath: 'assets/stickers/pigeon_thumbs_up.tgs', name: 'Pigeon', emoji: '🕊️'),
    Sticker(id: 'float_blender', packId: 'decorative', assetPath: 'assets/stickers/blender_happy.tgs', name: 'Blender', emoji: '🎉'),
  ];

  static final Map<String, Sticker> _registry = {
    todayEmpty.id: todayEmpty,
    allTasksEmpty.id: allTasksEmpty,
    upcomingEmpty.id: upcomingEmpty,
    completedEmpty.id: completedEmpty,
    trashEmpty.id: trashEmpty,
    todayMorning.id: todayMorning,
    todayAfternoon.id: todayAfternoon,
    todayEvening.id: todayEvening,
    todayNight.id: todayNight,
    todayAllDone.id: todayAllDone,
    celebration.id: celebration,
    sidebarMascot.id: sidebarMascot,
    settingsAppearance.id: settingsAppearance,
    settingsLayout.id: settingsLayout,
    settingsWallpaper.id: settingsWallpaper,
    settingsTasks.id: settingsTasks,
    settingsAbout.id: settingsAbout,
    work.id: work,
    focus.id: focus,
    care.id: care,
    fitness.id: fitness,
    detailDefault.id: detailDefault,
    insightsStreak.id: insightsStreak,
    insightsChart.id: insightsChart,
    insightsWeek.id: insightsWeek,
    insightsMonth.id: insightsMonth,
    groupOverdue.id: groupOverdue,
    groupToday.id: groupToday,
    groupTomorrow.id: groupTomorrow,
    groupLater.id: groupLater,
    groupNoDueDate.id: groupNoDueDate,
    quoteSticker.id: quoteSticker,
    for (final s in celebrationStickers) s.id: s,
    for (final s in floatingStickers) s.id: s,
  };

  static Sticker? getById(String id) => _registry[id];

  static List<Sticker> get allStickers => _registry.values.toList();

  // Helper: get time-based sticker for Today header
  static Sticker todayHeaderSticker({
    required bool allDone,
  }) {
    if (allDone) return todayAllDone;
    final hour = DateTime.now().hour;
    if (hour >= 5 && hour < 12) return todayMorning;
    if (hour >= 12 && hour < 17) return todayAfternoon;
    if (hour >= 17 && hour < 21) return todayEvening;
    return todayNight;
  }

  // Helper: get group header sticker
  static Sticker? groupSticker(String label) {
    switch (label) {
      case 'Overdue': return groupOverdue;
      case 'Today': return groupToday;
      case 'Tomorrow': return groupTomorrow;
      case 'This Week': return groupTomorrow;
      case 'Later': return groupLater;
      case 'No Due Date': return groupNoDueDate;
      default: return null;
    }
  }

  // Helper: random celebration sticker
  static Sticker randomCelebration() {
    final index = DateTime.now().millisecondsSinceEpoch % celebrationStickers.length;
    return celebrationStickers[index];
  }
}
