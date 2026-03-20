import '../models/sticker.dart';

/// Every decorative sticker placement in the app.
/// assetPath can be null — widget falls back to emoji.
class AppStickers {

  // ── Empty states ──────────────────────────────────
  static const Sticker todayEmpty = Sticker(
    id: 'deco_today_empty',
    packId: 'decorative',
    assetPath: 'assets/stickers/deco/bear_sleep.tgs',
    name: 'Today Empty',
    emoji: '🌤️',
  );

  static const Sticker allTasksEmpty = Sticker(
    id: 'deco_all_empty',
    packId: 'decorative',
    assetPath: 'assets/stickers/deco/bear_why.tgs',
    name: 'All Empty',
    emoji: '📋',
  );

  static const Sticker upcomingEmpty = Sticker(
    id: 'deco_upcoming_empty',
    packId: 'decorative',
    assetPath: 'assets/stickers/deco/bear_honey.tgs',
    name: 'Upcoming Empty',
    emoji: '📅',
  );

  static const Sticker completedEmpty = Sticker(
    id: 'deco_completed_empty',
    packId: 'decorative',
    assetPath: 'assets/stickers/deco/bear_happy.tgs',
    name: 'Completed Empty',
    emoji: '✅',
  );

  static const Sticker trashEmpty = Sticker(
    id: 'deco_trash_empty',
    packId: 'decorative',
    assetPath: 'assets/stickers/deco/peach_womit.tgs',
    name: 'Trash Empty',
    emoji: '🗑️',
  );

  // ── Today header ──────────────────────────────────
  static const Sticker todayMorning = Sticker(
    id: 'deco_morning',
    packId: 'decorative',
    assetPath: 'assets/stickers/deco/happy_peach.tgs',
    name: 'Morning',
    emoji: '☀️',
  );

  static const Sticker todayAfternoon = Sticker(
    id: 'deco_afternoon',
    packId: 'decorative',
    assetPath: 'assets/stickers/deco/bear_work.tgs',
    name: 'Afternoon',
    emoji: '⚡',
  );

  static const Sticker todayEvening = Sticker(
    id: 'deco_evening',
    packId: 'decorative',
    assetPath: 'assets/stickers/deco/bear_bath.tgs',
    name: 'Evening',
    emoji: '🌆',
  );

  static const Sticker todayNight = Sticker(
    id: 'deco_night',
    packId: 'decorative',
    assetPath: 'assets/stickers/deco/bear_sleep.tgs',
    name: 'Night',
    emoji: '🌙',
  );

  static const Sticker todayAllDone = Sticker(
    id: 'deco_all_done',
    packId: 'decorative',
    assetPath: 'assets/stickers/deco/peach_cheer.tgs',
    name: 'All Done',
    emoji: '🎉',
  );

  // ── Task completion celebration ────────────────────
  static const Sticker celebration = Sticker(
    id: 'deco_celebrate',
    packId: 'decorative',
    assetPath: 'assets/stickers/deco/peach_dance.tgs',
    name: 'Celebrate',
    emoji: '🎊',
  );

  // ── Sidebar decoration ────────────────────────────
  static const Sticker sidebarMascot = Sticker(
    id: 'deco_mascot',
    packId: 'decorative',
    assetPath: 'assets/stickers/deco/bear_right.tgs',
    name: 'Mascot',
    emoji: '🤖',
  );

  // ── Settings header ───────────────────────────────
  static const Sticker settingsAppearance = Sticker(
    id: 'deco_settings_appearance',
    packId: 'decorative',
    assetPath: 'assets/stickers/deco/bear_care.tgs',
    name: 'Appearance',
    emoji: '🎨',
  );

  static const Sticker settingsLayout = Sticker(
    id: 'deco_settings_layout',
    packId: 'decorative',
    assetPath: 'assets/stickers/deco/bear_security.tgs',
    name: 'Layout',
    emoji: '📐',
  );

  static const Sticker settingsWallpaper = Sticker(
    id: 'deco_settings_wallpaper',
    packId: 'decorative',
    assetPath: 'assets/stickers/deco/funny.tgs',
    name: 'Wallpaper',
    emoji: '🖼️',
  );

  static const Sticker settingsTasks = Sticker(
    id: 'deco_settings_tasks',
    packId: 'decorative',
    assetPath: 'assets/stickers/deco/bear_pproductive.tgs',
    name: 'Tasks',
    emoji: '⚙️',
  );

  static const Sticker settingsAbout = Sticker(
    id: 'deco_settings_about',
    packId: 'decorative',
    assetPath: 'assets/stickers/deco/bear.tgs',
    name: 'About',
    emoji: '💡',
  );

  // ── Task Suggesters ───────────────────────────────
  static const Sticker work = Sticker(
    id: 'deco_task_work',
    packId: 'decorative',
    assetPath: 'assets/stickers/deco/bear_work.tgs',
    name: 'Work',
    emoji: '💼',
  );

  static const Sticker focus = Sticker(
    id: 'deco_task_focus',
    packId: 'decorative',
    assetPath: 'assets/stickers/deco/bear_pproductive.tgs',
    name: 'Focus',
    emoji: '🎯',
  );

  static const Sticker care = Sticker(
    id: 'deco_task_care',
    packId: 'decorative',
    assetPath: 'assets/stickers/deco/bear_care.tgs',
    name: 'Care',
    emoji: '🤍',
  );

  static const Sticker fitness = Sticker(
    id: 'deco_task_fitness',
    packId: 'decorative',
    assetPath: 'assets/stickers/deco/funny.tgs', // Using the playful one for fitness
    name: 'Fitness',
    emoji: '💪',
  );

  // ── Detail panel ──────────────────────────────────
  static const Sticker detailDefault = Sticker(
    id: 'deco_detail',
    packId: 'decorative',
    assetPath: 'assets/stickers/deco/bear_heart.tgs',
    name: 'Detail',
    emoji: '📝',
  );

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
}
