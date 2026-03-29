import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../providers/template_provider.dart';
import '../theme/app_theme.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/wallpaper_presets.dart';

import '../painters/wallpaper_pattern_painter.dart';
import '../services/wallpaper_image_service.dart';
import '../models/sticker.dart';
import '../data/app_stickers.dart';
import '../widgets/shared/deco_sticker.dart';
import 'xp_audit_screen.dart';
import 'redeem_screen.dart';
import '../providers/user_context_provider.dart';
import '../providers/ai_provider.dart';
import '../models/user_context.dart';

// ─── Section definition ──────────────────────────────────────────────────────

class _SettingsSection {
  final String id;
  final String label;
  final IconData icon;
  const _SettingsSection({
    required this.id,
    required this.label,
    required this.icon,
  });
}

const _sections = <_SettingsSection>[
  _SettingsSection(id: 'appearance', label: 'Appearance', icon: Icons.palette_outlined),
  _SettingsSection(id: 'layout',     label: 'Layout & Density', icon: Icons.space_dashboard_outlined),
  _SettingsSection(id: 'wallpaper',  label: 'Wallpaper', icon: Icons.wallpaper_outlined),
  _SettingsSection(id: 'tasks',      label: 'Tasks & Defaults', icon: Icons.task_alt_outlined),
  _SettingsSection(id: 'ai',         label: 'AI Assistant', icon: Icons.auto_awesome_rounded),
  _SettingsSection(id: 'about',      label: 'About', icon: Icons.info_outline_rounded),
];

// ═══════════════════════════════════════════════════════
// SettingsScreen
// ═══════════════════════════════════════════════════════

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _active = 'appearance';
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) setState(() => _version = info.version);
  }

  Sticker _stickerFor(String id) {
    switch (id) {
      case 'appearance': return AppStickers.settingsAppearance;
      case 'layout':     return AppStickers.settingsLayout;
      case 'wallpaper':  return AppStickers.settingsWallpaper;
      case 'tasks':      return AppStickers.settingsTasks;
      case 'ai':         return AppStickers.celebration;
      case 'about':      return AppStickers.settingsAbout;
      default:           return AppStickers.settingsAppearance;
    }
  }

  _SettingsSection get _currentSection =>
      _sections.firstWhere((s) => s.id == _active);

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Row(


      children: [
        // ── Settings Nav (220px) ──────────────────────
        Container(
          width: 220,
          color: colors.surfaceElevated,
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Settings',
                style: AppTypography.headlineMD.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 20),

              Text(
                'PREFERENCES',
                style: AppTypography.micro.copyWith(
                  color: colors.textQuaternary,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 8),

              ..._sections.map((s) => _SettingsNavItem(
                section: s,
                isActive: _active == s.id,
                onTap: () => setState(() => _active = s.id),
              )),

              const Spacer(),

              // Version
              Text(
                'Taski v$_version',
                style: AppTypography.caption.copyWith(
                  color: colors.textQuaternary,
                ),
              ),
            ],
          ),
        ),

        // ── Content (flex) ────────────────────────────
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Section header
                Row(
                  children: [
                    DecoSticker(
                      sticker: _stickerFor(_active),
                      size: 48,
                    ),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _currentSection.label,
                          style: AppTypography.displayLG.copyWith(
                            color: colors.textPrimary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Container(
                          width: 32,
                          height: 3,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            gradient: AppColors.gradPrimary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 28),

                // Section content
                _buildSectionContent(_active),
              ],
            ),
          ),
        ),
      ],
    ));
  }

  Widget _buildSectionContent(String id) {
    switch (id) {
      case 'appearance': return const _AppearanceContent();
      case 'layout':     return const _LayoutDensityContent();
      case 'wallpaper':  return const _WallpaperContent();
      case 'tasks':      return const _TasksDefaultsContent();
      case 'ai':         return const _AIContent();
      case 'about':      return const _AboutContent();
      default:           return const SizedBox.shrink();
    }
  }
}

// ═══════════════════════════════════════════════════════
// _SettingsNavItem
// ═══════════════════════════════════════════════════════

class _SettingsNavItem extends StatelessWidget {
  final _SettingsSection section;
  final bool isActive;
  final VoidCallback onTap;

  const _SettingsNavItem({
    required this.section,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        margin: const EdgeInsets.only(bottom: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isActive ? AppColors.indigoDim : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(
              section.icon,
              size: 15,
              color: isActive ? AppColors.indigo : colors.textTertiary,
            ),
            const SizedBox(width: 10),
            Text(
              section.label,
              style: AppTypography.titleSM.copyWith(
                color: isActive ? AppColors.indigo : colors.textSecondary,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// _SettingsCard
// ═══════════════════════════════════════════════════════

class _SettingsCard extends StatelessWidget {
  final String? label;
  final Widget child;
  const _SettingsCard({this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _SectionLabel(text: label!),
          ),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
          ),
          child: child,
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel({required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Container(
          width: 4,
          height: 4,
          margin: const EdgeInsets.only(right: 6),
          decoration: BoxDecoration(
            color: AppColors.indigo,
            shape: BoxShape.circle,
          ),
        ),
        Text(
          text.toUpperCase(),
          style: AppTypography.micro.copyWith(
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
            color: colors.textQuaternary,
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════
// _SettingsRow
// ═══════════════════════════════════════════════════════

class _SettingsRow extends StatelessWidget {
  final IconData? icon;
  final String label;
  final String? subtitle;
  final Widget? value;
  final Widget? control;
  const _SettingsRow({
    this.icon,
    required this.label,
    this.subtitle,
    this.value,
    this.control,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment:
            subtitle != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: colors.textTertiary),
            const SizedBox(width: 10),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.titleSM.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitle!,
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          if (value != null) value!,
          if (control != null) control!,
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// APPEARANCE SECTION
// ═══════════════════════════════════════════════════════

class _AppearanceContent extends StatelessWidget {
  const _AppearanceContent();

  static const _accentColors = <Color>[
    Color(0xFF007AFF), // Blue
    Color(0xFFAF52DE), // Purple
    Color(0xFFFF2D55), // Pink
    Color(0xFFFF3B30), // Red
    Color(0xFFFF9500), // Orange
    Color(0xFFFFCC00), // Yellow
    Color(0xFF34C759), // Green
    Color(0xFF5AC8FA), // Teal
  ];

  static const _accentHexes = <String>[
    '007AFF', 'AF52DE', 'FF2D55', 'FF3B30',
    'FF9500', 'FFCC00', '34C759', '5AC8FA',
  ];

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colors = context.appColors;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 700),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Theme ──────────────────────────────────
          _SettingsCard(
            label: 'Theme',
            child: Row(
              children: [
                Text(
                  'Appearance',
                  style: AppTypography.bodyMD.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const Spacer(),
                // 3 pills
                Container(
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(3),
                  child: Row(
                    children: [
                      (ThemeMode.light, '☀️ Light'),
                      (ThemeMode.dark, '🌙 Dark'),
                      (ThemeMode.system, '⚙️ System'),
                    ].map((t) {
                      final isSelected = settings.themeMode == t.$1;
                      return GestureDetector(
                        onTap: () => settings.setThemeMode(t.$1),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 140),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            gradient: isSelected ? AppColors.gradPrimary : null,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            t.$2,
                            style: AppTypography.labelMD.copyWith(
                              color: isSelected
                                  ? Colors.white
                                  : colors.textSecondary,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // ── Accent Color ──────────────────────────
          _SettingsCard(
            label: 'Accent Color',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Used for buttons, highlights, and active states',
                  style: AppTypography.bodyMD.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: List.generate(_accentColors.length, (i) {
                    final c = _accentColors[i];
                    final hex = _accentHexes[i];
                    final isSelected =
                        settings.accentColorHex.toUpperCase() == hex.toUpperCase();
                    return GestureDetector(
                      onTap: () => settings.setAccentColor(hex),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        width: isSelected ? 38 : 32,
                        height: isSelected ? 38 : 32,
                        decoration: BoxDecoration(
                          color: c,
                          shape: BoxShape.circle,
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: c.withValues(alpha: .4),
                                    blurRadius: 12,
                                    spreadRadius: 2,
                                  )
                                ]
                              : [],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check_rounded,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                // Preview task
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: colors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          color: settings.accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_rounded,
                            size: 10, color: Colors.white),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Preview task',
                        style: AppTypography.titleSM.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.dangerBg,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'HIGH',
                          style: AppTypography.micro.copyWith(
                            color: AppColors.danger,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// LAYOUT & DENSITY SECTION
// ═══════════════════════════════════════════════════════

class _LayoutDensityContent extends StatelessWidget {
  const _LayoutDensityContent();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colors = context.appColors;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 700),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Default View ───────────────────────────
          _SettingsCard(
            label: 'Default View',
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: TaskViewLayout.values.map((layout) {
                final isActive = settings.currentLayout == layout;
                return GestureDetector(
                  onTap: () => settings.setViewLayout(layout),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 100,
                    height: 72,
                    decoration: BoxDecoration(
                      color: isActive
                          ? AppColors.indigoDim
                          : colors.surfaceElevated,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _layoutIcon(layout),
                          size: 24,
                          color: isActive
                              ? AppColors.indigo
                              : colors.textSecondary,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _layoutLabel(layout),
                          style: AppTypography.caption.copyWith(
                            color: isActive
                                ? AppColors.indigo
                                : colors.textSecondary,
                            fontWeight:
                                isActive ? FontWeight.w600 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Interface Density ──────────────────────
          _SettingsCard(
            label: 'Interface Density',
            child: Row(
              children: FontDensity.values.map((density) {
                final isActive = settings.fontDensity == density;
                final padAmt = _densityPadding(density);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: GestureDetector(
                      onTap: () => settings.setFontDensity(density),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppColors.indigoDim
                              : colors.surfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: [
                            ...List.generate(
                              3,
                              (i) => Container(
                                margin:
                                    EdgeInsets.only(bottom: padAmt.toDouble()),
                                height: 6,
                                decoration: BoxDecoration(
                                  color:
                                      colors.textTertiary.withValues(alpha: .3),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _densityLabel(density),
                              style: AppTypography.caption.copyWith(
                                color: isActive
                                    ? AppColors.indigo
                                    : colors.textSecondary,
                                fontWeight:
                                    isActive ? FontWeight.w600 : FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),

          // ── Sidebar Width ─────────────────────────
          _SettingsCard(
            label: 'Sidebar',
            child: _SettingsRow(
              label: 'Sidebar Width',
              subtitle: 'Or drag the sidebar edge directly',
              control: SizedBox(
                width: 200,
                child: Column(
                  children: [
                    Slider(
                      value: settings.sidebarWidth,
                      min: 180,
                      max: 320,
                      divisions: 14,
                      label: '${settings.sidebarWidth.round()}px',
                      activeColor: AppColors.indigo,
                      onChanged: (v) => settings.setSidebarWidth(v),
                    ),
                    Text(
                      '${settings.sidebarWidth.round()}px',
                      style: AppTypography.caption.copyWith(
                        color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Sticker Size ──────────────────────────
          _SettingsCard(
            label: 'Stickers',
            child: _SettingsRow(
              label: 'Sticker Size',
              subtitle: 'Adjust the scale of animated task badges',
              control: _StickerSizeSelector(
                current: settings.stickerSize,
                onChanged: settings.setStickerSize,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _layoutLabel(TaskViewLayout l) {
    switch (l) {
      case TaskViewLayout.list:     return 'List';
      case TaskViewLayout.grid:     return 'Grid';
      case TaskViewLayout.kanban:   return 'Kanban';
      case TaskViewLayout.compact:  return 'Compact';
      case TaskViewLayout.magazine: return 'Magazine';
    }
  }

  static IconData _layoutIcon(TaskViewLayout l) {
    switch (l) {
      case TaskViewLayout.list:     return Icons.view_list_rounded;
      case TaskViewLayout.grid:     return Icons.grid_view_rounded;
      case TaskViewLayout.kanban:   return Icons.view_kanban_rounded;
      case TaskViewLayout.compact:  return Icons.density_small_rounded;
      case TaskViewLayout.magazine: return Icons.article_rounded;
    }
  }

  static String _densityLabel(FontDensity d) {
    switch (d) {
      case FontDensity.compact:     return 'Compact';
      case FontDensity.normal:      return 'Normal';
      case FontDensity.comfortable: return 'Roomy';
    }
  }

  static int _densityPadding(FontDensity d) {
    switch (d) {
      case FontDensity.compact:     return 2;
      case FontDensity.normal:      return 4;
      case FontDensity.comfortable: return 6;
    }
  }
}

class _StickerSizeSelector extends StatelessWidget {
  final StickerSize current;
  final void Function(StickerSize) onChanged;
  const _StickerSizeSelector({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final options = [
      (StickerSize.small, 'Small'),
      (StickerSize.normal, 'Normal'),
      (StickerSize.large, 'Large'),
      (StickerSize.jumbo, 'Jumbo'),
    ];

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: colors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final (size, label) = opt;
          final isActive = size == current;
          return GestureDetector(
            onTap: () => onChanged(size),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                gradient: isActive ? AppColors.gradPrimary : null,
                borderRadius: BorderRadius.circular(7),
              ),
              child: Text(
                label,
                style: AppTypography.labelMD.copyWith(
                  color: isActive ? Colors.white : colors.textSecondary,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// WALLPAPER SECTION
// ═══════════════════════════════════════════════════════

class _WallpaperContent extends StatelessWidget {
  const _WallpaperContent();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colors = context.appColors;
    final wallType = settings.settings.wallpaperType;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 700),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Type Selector ──────────────────────────
          _SettingsCard(
            label: 'Background',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Applies to the main content area only.',
                  style: AppTypography.caption.copyWith(
                    color: colors.textTertiary,
                  ),
                ),
                const SizedBox(height: 16),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      _WallpaperTypeTile(
                        label: 'None',
                        icon: Icons.block_rounded,
                        isActive: wallType == WallpaperType.none,
                        onTap: () => settings.setWallpaper(WallpaperType.none),
                      ),
                      const SizedBox(width: 8),
                      _WallpaperTypeTile(
                        label: 'Gradient',
                        icon: Icons.gradient_rounded,
                        isActive: wallType == WallpaperType.gradient,
                        onTap: () => settings.setWallpaper(
                          WallpaperType.gradient,
                          value: settings.settings.wallpaperGradientId ?? 'aurora',
                        ),
                      ),
                      const SizedBox(width: 8),
                      _WallpaperTypeTile(
                        label: 'Pattern',
                        icon: Icons.grid_4x4_rounded,
                        isActive: wallType == WallpaperType.pattern,
                        onTap: () => settings.setWallpaper(
                          WallpaperType.pattern,
                          value: settings.settings.wallpaperPatternId ?? 'dots',
                        ),
                      ),
                      const SizedBox(width: 8),
                      _WallpaperTypeTile(
                        label: 'Color',
                        icon: Icons.circle_rounded,
                        isActive: wallType == WallpaperType.solidColor,
                        onTap: () => settings.setWallpaper(
                          WallpaperType.solidColor,
                          value: settings.settings.wallpaperColorHex ?? 'A5B4FC',
                        ),
                      ),
                      const SizedBox(width: 8),
                      _WallpaperTypeTile(
                        label: 'My Photo',
                        icon: Icons.photo_rounded,
                        isActive: wallType == WallpaperType.customImage,
                        onTap: () => _pickCustomImage(context, settings),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Brightness Slider ─────────────────────
          if (wallType != WallpaperType.none)
            _SettingsCard(
              label: 'Visibility',
              child: _SettingsRow(
                label: 'Background Brightness',
                subtitle: 'Lower = less distraction',
                control: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.wb_sunny_outlined,
                        size: 14, color: Color(0xFF94A3B8)),
                    SizedBox(
                      width: 160,
                      child: Slider(
                        value: settings.wallpaperBrightness,
                        min: 0.30,
                        max: 1.0,
                        divisions: 14,
                        activeColor: AppColors.indigo,
                        inactiveColor: colors.border,
                        onChanged: (v) => settings.setWallpaperBrightness(v),
                      ),
                    ),
                    const Icon(Icons.wb_sunny_rounded,
                        size: 18, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ),

          // ── Gradient Picker ───────────────────────
          if (wallType == WallpaperType.gradient)
            _SettingsCard(
              label: 'Gradient',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: WallpaperPresets.gradientIds.map((id) {
                  final gradient = WallpaperPresets.gradients[id]!;
                  final label = WallpaperPresets.gradientLabels[id] ?? id;
                  final isSelected =
                      settings.settings.wallpaperGradientId == id;
                  return GestureDetector(
                    onTap: () => settings.setWallpaper(
                        WallpaperType.gradient, value: id),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 64,
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: gradient,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.indigo
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color:
                                          AppColors.indigo.withValues(alpha: .35),
                                      blurRadius: 10,
                                    )
                                  ]
                                : [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2),
                                    )
                                  ],
                          ),
                          child: isSelected
                              ? const Center(
                                  child: Icon(Icons.check_rounded,
                                      color: Colors.white, size: 18))
                              : null,
                        ),
                        const SizedBox(height: 5),
                        Text(
                          label,
                          style: AppTypography.caption.copyWith(
                            fontSize: 10,
                            color: isSelected
                                ? AppColors.indigo
                                : colors.textTertiary,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          // ── Pattern Picker ────────────────────────
          if (wallType == WallpaperType.pattern)
            _SettingsCard(
              label: 'Pattern',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: WallpaperPresets.patternIds.map((id) {
                  final label = WallpaperPresets.patternLabels[id] ?? id;
                  final isSelected =
                      settings.settings.wallpaperPatternId == id;
                  return GestureDetector(
                    onTap: () => settings.setWallpaper(
                        WallpaperType.pattern, value: id),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 72,
                          height: 56,
                          decoration: BoxDecoration(
                            color: colors.surfaceElevated,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.indigo
                                  : colors.border,
                              width: isSelected ? 2 : 0.75,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color:
                                          AppColors.indigo.withValues(alpha: .25),
                                      blurRadius: 8,
                                    )
                                  ]
                                : [],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: CustomPaint(
                              painter: WallpaperPatternPainter(
                                patternId: id,
                                color: isSelected
                                    ? AppColors.indigo
                                    : colors.textTertiary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          label,
                          style: AppTypography.caption.copyWith(
                            fontSize: 10,
                            color: isSelected
                                ? AppColors.indigo
                                : colors.textTertiary,
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),

          // ── Solid Color Picker ────────────────────
          if (wallType == WallpaperType.solidColor)
            _SettingsCard(
              label: 'Color',
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  'A5B4FC', 'FCA5A5', 'FCD34D', '86EFAC',
                  'BAE6FD', 'F9A8D4', 'C4B5FD', 'FED7AA',
                  'D1FAE5', 'E0E7FF', 'FCE7F3', 'FEF3C7',
                ].map((hex) {
                  final color = Color(int.parse('FF$hex', radix: 16));
                  final isSelected = settings.settings.wallpaperColorHex
                          ?.toUpperCase() ==
                      hex.toUpperCase();
                  return GestureDetector(
                    onTap: () => settings.setWallpaper(
                        WallpaperType.solidColor, value: hex),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: isSelected ? 40 : 34,
                      height: isSelected ? 40 : 34,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: isSelected
                            ? Border.all(color: AppColors.indigo, width: 2.5)
                            : Border.all(
                                color: Colors.black.withValues(alpha: 0.08),
                                width: 0.5),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 10,
                                  spreadRadius: 1,
                                )
                              ]
                            : [],
                      ),
                      child: isSelected
                          ? const Icon(Icons.check_rounded,
                              size: 16, color: Colors.white)
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ),

          // ── Custom Image ──────────────────────────
          if (wallType == WallpaperType.customImage)
            _SettingsCard(
              label: 'Custom Photo',
              child: Column(
                children: [
                  GestureDetector(
                    onTap: () => _pickCustomImage(context, settings),
                    child: Container(
                      width: double.infinity,
                      height: 120,
                      decoration: BoxDecoration(
                        color: colors.surfaceElevated,
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: colors.border, width: 0.75),
                      ),
                      child: settings.settings.wallpaperImagePath != null
                          ? ClipRRect(
                              borderRadius: BorderRadius.circular(11),
                              child: Image.file(
                                File(settings.settings.wallpaperImagePath!),
                                fit: BoxFit.cover,
                                width: double.infinity,
                                height: double.infinity,
                                errorBuilder: (_, __, ___) =>
                                    _buildImagePlaceholder(colors),
                              ),
                            )
                          : _buildImagePlaceholder(colors),
                    ),
                  ),
                  if (settings.settings.wallpaperImagePath != null) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () =>
                                _pickCustomImage(context, settings),
                            child: Container(
                              height: 36,
                              decoration: BoxDecoration(
                                color:
                                    AppColors.indigo.withValues(alpha: .08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.indigo
                                        .withValues(alpha: .2)),
                              ),
                              child: Center(
                                child: Text(
                                  'Change Photo',
                                  style: AppTypography.labelMD.copyWith(
                                    color: AppColors.indigo,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () {
                            settings.setWallpaper(WallpaperType.none);
                            settings.setWallpaperImage(null);
                          },
                          child: Container(
                            height: 36,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14),
                            decoration: BoxDecoration(
                              color: AppColors.danger.withValues(alpha: .08),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                  color: AppColors.danger
                                      .withValues(alpha: .2)),
                            ),
                            child: Center(
                              child: Text(
                                'Remove',
                                style: AppTypography.labelMD.copyWith(
                                  color: AppColors.danger,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImagePlaceholder(AppColorsExtension colors) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.add_photo_alternate_rounded,
            size: 32, color: colors.textTertiary),
        const SizedBox(height: 8),
        Text('Choose from device',
            style: AppTypography.bodyMD.copyWith(color: colors.textTertiary)),
        const SizedBox(height: 4),
        Text('JPG, PNG, WEBP',
            style: AppTypography.caption.copyWith(
                color: colors.textQuaternary)),
      ],
    );
  }

  Future<void> _pickCustomImage(
      BuildContext context, SettingsProvider settings) async {
    final path = await WallpaperImageService.pickImage();
    if (path == null) return;

    final isValid = await WallpaperImageService.validateSize(path);
    if (!isValid && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
              'Image too large. Please choose a file under 10MB.'),
          backgroundColor: AppColors.danger,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
      );
      return;
    }

    await settings.setWallpaperImage(path);
  }
}

class _WallpaperTypeTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _WallpaperTypeTile({
    required this.label,
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            width: 64,
            height: 52,
            decoration: BoxDecoration(
              color: isActive
                  ? AppColors.indigo.withValues(alpha: .10)
                  : colors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive ? AppColors.indigo : colors.border,
                width: isActive ? 1.75 : 0.75,
              ),
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: AppColors.indigo.withValues(alpha: .20),
                        blurRadius: 8,
                      )
                    ]
                  : [],
            ),
            child: Center(
              child: Icon(icon,
                  size: 22,
                  color: isActive ? AppColors.indigo : colors.textTertiary),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              color: isActive ? AppColors.indigo : colors.textTertiary,
              fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════
// TASKS & DEFAULTS SECTION
// ═══════════════════════════════════════════════════════

class _TasksDefaultsContent extends StatelessWidget {
  const _TasksDefaultsContent();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colors = context.appColors;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 700),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingsCard(
            label: 'Defaults',
            child: Column(
              children: [
                _SettingsRow(
                  label: 'Start of Week',
                  control: _ToggleChip(
                    selected: settings.startOfWeek == 1,
                    label1: 'Monday',
                    label2: 'Sunday',
                    onChanged: (isMon) =>
                        settings.setStartOfWeek(isMon ? 1 : 7),
                  ),
                ),
                Divider(color: colors.divider, height: 1),
                _SettingsRow(
                  label: 'Focus Duration',
                  subtitle: 'Pomodoro session length',
                  control: SizedBox(
                    width: 100,
                    child: DropdownButton<int>(
                      value: settings.focusDuration,
                      dropdownColor: colors.surfaceElevated,
                      underline: const SizedBox.shrink(),
                      items: [15, 20, 25, 30, 45, 60]
                          .map((m) => DropdownMenuItem(
                                value: m,
                                child: Text(
                                  '$m min',
                                  style: AppTypography.bodyMD.copyWith(
                                    color: colors.textPrimary,
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (v) {
                        if (v != null) settings.setFocusDuration(v);
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
          _SettingsCard(
            label: 'Templates',
            child: const _TemplatesList(),
          ),
        ],
      ),
    );
  }
}

class _ToggleChip extends StatelessWidget {
  final bool selected;
  final String label1;
  final String label2;
  final void Function(bool) onChanged;
  const _ToggleChip({
    required this.selected,
    required this.label1,
    required this.label2,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip(context, label1, selected, () => onChanged(true), colors),
        const SizedBox(width: 4),
        _chip(context, label2, !selected, () => onChanged(false), colors),
      ],
    );
  }

  Widget _chip(BuildContext context, String label, bool isOn,
      VoidCallback onTap, AppColorsExtension colors) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          gradient: isOn ? AppColors.gradPrimary : null,
          color: isOn ? null : colors.surfaceElevated,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: AppTypography.labelMD.copyWith(
            color: isOn ? Colors.white : colors.textSecondary,
            fontWeight: isOn ? FontWeight.w600 : FontWeight.w400,
          ),
        ),
      ),
    );
  }
}

class _TemplatesList extends StatelessWidget {
  const _TemplatesList();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final templates = context.watch<TemplateProvider>().templates;

    if (templates.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: Text(
            'No templates saved yet.',
            style: AppTypography.caption.copyWith(color: colors.textTertiary),
          ),
        ),
      );
    }

    return Column(
      children: templates.map((t) {
        final isFirst = t == templates.first;
        return Column(
          children: [
            if (!isFirst)
              Divider(height: 1, color: colors.divider),
            _SettingsRow(
              label: t.name,
              subtitle: '${t.emoji} ${t.title}',
              control: GestureDetector(
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      backgroundColor: colors.surfaceElevated,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                      title: Text(
                        'Delete Template',
                        style: AppTypography.titleMD.copyWith(
                            color: colors.textPrimary),
                      ),
                      content: Text(
                        'Are you sure you want to delete "${t.name}"?',
                        style: AppTypography.bodyMD.copyWith(
                            color: colors.textSecondary),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, false),
                          child: Text('Cancel',
                              style: AppTypography.labelMD.copyWith(
                                  color: colors.textSecondary)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          child: Text('Delete',
                              style: AppTypography.labelMD.copyWith(
                                  color: AppColors.danger)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true && context.mounted) {
                    context.read<TemplateProvider>().delete(t.id);
                  }
                },
                child: Icon(
                  Icons.delete_outline_rounded,
                  size: 20,
                  color: AppColors.danger.withValues(alpha: 0.7),
                ),
              ),
            ),
          ],
        );
      }).toList(),
    );
  }
}

// ═══════════════════════════════════════════════════════
// ABOUT SECTION
// ═══════════════════════════════════════════════════════

class _AboutContent extends StatefulWidget {
  const _AboutContent();

  @override
  State<_AboutContent> createState() => _AboutContentState();
}

class _AboutContentState extends State<_AboutContent> {
  String _version = '—';

  @override
  void initState() {
    super.initState();
    _loadVersion();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = info.version;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 700),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingsCard(
            label: 'App Info',
            child: Column(
              children: [
                _SettingsRow(
                  icon: Icons.apps_rounded,
                  label: 'App Name',
                  value: Text(
                    'Taski',
                    style: AppTypography.bodyMD.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                Divider(height: 1, color: colors.divider),
                _SettingsRow(
                  icon: Icons.tag_rounded,
                  label: 'Version',
                  value: Text(
                    _version,
                    style: AppTypography.bodyMD.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
                Divider(height: 1, color: colors.divider),
                _SettingsRow(
                  icon: Icons.code_rounded,
                  label: 'Built with',
                  value: Text(
                    'Flutter 3 · Hive · Provider',
                    style: AppTypography.caption.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          _SettingsCard(
            label: 'Quick Actions',
            child: Column(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RedeemScreen()),
                  ),
                  child: _SettingsRow(
                    icon: Icons.redeem_rounded,
                    label: 'Redeem Code',
                    subtitle: 'Unlock exclusive rewards',
                    control: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: colors.textTertiary,
                    ),
                  ),
                ),
                Divider(height: 1, color: colors.divider),
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const XPAuditScreen()),
                  ),
                  child: _SettingsRow(
                    icon: Icons.history_rounded,
                    label: 'XP History',
                    subtitle: 'View your transaction ledger',
                    control: Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: colors.textTertiary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      );

  }


}
class _AIContent extends StatefulWidget {
  const _AIContent();

  @override
  State<_AIContent> createState() => _AIContentState();
}

class _AIContentState extends State<_AIContent> {
  bool _showKey = false;
  final _keyCtrl = TextEditingController();

  @override
  void dispose() {
    _keyCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ai = context.watch<AIProvider>();
    final ctxProvider = context.watch<UserContextProvider>();
    final colors = context.appColors;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 700),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _SettingsCard(
            label: 'Gemini Integration',
            child: Column(
              children: [
                _SettingsRow(
                  label: 'Gemini API Key',
                  subtitle: 'Required for all AI features',
                  control: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (ctxProvider.hasApiKey) ...[
                        Text(
                          _showKey ? (ctxProvider.apiKey ?? '') : '••••••••••••••••',
                          style: AppTypography.mono.copyWith(fontSize: 12, color: colors.textSecondary),
                        ),
                        IconButton(
                          icon: Icon(_showKey ? Icons.visibility_off_rounded : Icons.visibility_rounded, size: 16),
                          onPressed: () => setState(() => _showKey = !_showKey),
                        ),
                      ],
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: colors.surfaceElevated,
                          foregroundColor: AppColors.indigo,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onPressed: () => _showKeyEdit(context, ctxProvider),
                        child: Text(ctxProvider.hasApiKey ? 'Update' : 'Setup'),
                      ),
                    ],
                  ),
                ),
                if (ctxProvider.hasApiKey)
                  _SettingsRow(
                    label: 'Status',
                    value: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8, height: 8,
                          decoration: const BoxDecoration(color: AppColors.success, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 8),
                        Text('Connected', style: AppTypography.labelMD.copyWith(color: AppColors.success)),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          _SettingsCard(
            label: 'Profile & Context',
            child: Column(
              children: [
                _SettingsRow(
                  label: 'Daily Routine',
                  subtitle: 'Current: ${ctxProvider.context.wakeUpTime.format(context)} - ${ctxProvider.context.sleepTime.format(context)}',
                  control: TextButton(
                    onPressed: () {
                      // Navigate to routine step of onboarding or simple dialog
                    },
                    child: const Text('Edit Routine'),
                  ),
                ),
                _SettingsRow(
                  label: 'Energy Pattern',
                  value: Text(ctxProvider.context.energyPattern.name, style: AppTypography.labelMD.copyWith(color: AppColors.indigo)),
                ),
                const Divider(),
                _SettingsRow(
                  label: 'Reset Assistant',
                  subtitle: 'Clear conversation history and onboarding status',
                  control: TextButton(
                    onPressed: () async {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: const Text('Reset AI Assistant?'),
                          content: const Text('This will clear your routine preferences and chat history.'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                            TextButton(
                              onPressed: () => Navigator.pop(context, true), 
                              child: const Text('Reset', style: TextStyle(color: AppColors.danger))
                            ),
                          ],
                        ),
                      );
                      if (confirmed == true) {
                        await ctxProvider.resetOnboarding();
                        await ai.resetChat();
                      }
                    },
                    child: const Text('Reset', style: TextStyle(color: AppColors.secondary)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showKeyEdit(BuildContext context, UserContextProvider provider) {
    _keyCtrl.text = provider.apiKey ?? '';
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Update Gemini API Key'),
        content: TextField(
          controller: _keyCtrl,
          decoration: const InputDecoration(hintText: 'Paste key here...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await provider.saveApiKey(_keyCtrl.text.trim());
              if (context.mounted) Navigator.pop(context);
            }, 
            child: const Text('Save')
          ),
        ],
      ),
    );
  }
}
