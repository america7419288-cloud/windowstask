import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:package_info_plus/package_info_plus.dart';
import '../models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../providers/list_provider.dart';
import '../theme/app_theme.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/wallpaper_presets.dart';
import '../painters/wallpaper_pattern_painter.dart';
import '../services/wallpaper_image_service.dart';
import '../models/sticker.dart';
import '../data/app_stickers.dart';
import '../widgets/shared/deco_sticker.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  int _selectedSection = 0;

  static const List<(String label, IconData icon)> _sections = [
    ('Appearance', Icons.palette_outlined),
    ('Layout & Density', Icons.space_dashboard_outlined),
    ('Wallpaper', Icons.wallpaper_outlined),
    ('Tasks & Defaults', Icons.task_alt_outlined),
    ('About', Icons.info_outline_rounded),
  ];

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;

    return Row(
      children: [
        // Left nav
        Container(
          width: 200,
          decoration: BoxDecoration(
            color: colors.isDark
                ? Colors.black.withValues(alpha: 0.35)
                : Colors.white.withValues(alpha: 0.55),
            border: Border(right: BorderSide(color: colors.border, width: 0.5)),
          ),
          child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                    child: Text(
                      'SETTINGS',
                      style: AppTypography.caption.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                        color: colors.textTertiary,
                      ),
                    ),
                  ),
                  ...List.generate(_sections.length, (i) {
                    final (label, icon) = _sections[i];
                    final isActive = i == _selectedSection;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedSection = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          gradient: isActive ? AppColors.gradientBlue : null,
                          color: !isActive && i == _selectedSection ? Colors.transparent : null,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: isActive && !colors.isDark ? [
                            BoxShadow(
                              color: AppColors.blue.withValues(alpha: 0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ] : [],
                        ),
                        child: Row(
                          children: [
                            Icon(icon, size: 18, color: isActive ? Colors.white : colors.textSecondary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                label,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.body.copyWith(
                                  fontSize: 14,
                                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                                  color: isActive ? Colors.white : colors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }),
            ],
          ),
        ),
        // Right content
        Expanded(
          child: Container(
            color: Colors.transparent, // ← wallpaper shows through
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Align(
                alignment: Alignment.topLeft,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: _buildSection(_selectedSection),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSection(int index) {
    switch (index) {
      case 0: return const _AppearanceSection();
      case 1: return const _LayoutDensitySection();
      case 2: return const _WallpaperSection();
      case 3: return const _TasksDefaultsSection();
      case 4: return const _AboutSection();
      default: return const SizedBox.shrink();
    }
  }
}

class _SettingsSectionHeader extends StatelessWidget {
  final Sticker sticker;
  final String title;
  const _SettingsSectionHeader({required this.sticker, required this.title});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DecoSticker(sticker: sticker, size: 48),
          const SizedBox(height: 12),
          Text(
            title,
            style: AppTypography.title1.copyWith(
              fontSize: 24,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            width: 40,
            height: 3,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── SHARED WIDGETS ──────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Row(
            children: [
              Container(
                width: 4, height: 4,
                margin: const EdgeInsets.only(right: 6, bottom: 1),
                decoration: BoxDecoration(
                  color: accent,
                  shape: BoxShape.circle,
                ),
              ),
              Text(
                title.toUpperCase(),
                style: AppTypography.micro.copyWith(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.0,
                  color: colors.textQuaternary,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.isDark
                ? const Color(0xFF2A2725).withValues(alpha: 0.90)
                : Colors.white.withValues(alpha: 0.88),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colors.isDark
                  ? Colors.white.withValues(alpha: 0.07)
                  : Colors.black.withValues(alpha: 0.07),
              width: 0.75,
            ),
            boxShadow: colors.isDark ? [] : [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.045),
                blurRadius: 12,
                offset: const Offset(0, 3),
                spreadRadius: -1,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.02),
                blurRadius: 3,
                offset: const Offset(0, 1),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _SettingsRow extends StatelessWidget {
  final String label;
  final String? subtitle;
  final Widget control;
  final bool isFirst;
  final bool isLast;
  const _SettingsRow({
    required this.label,
    this.subtitle,
    required this.control,
    this.isFirst = false,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        if (!isFirst)
          Divider(height: 1, color: colors.divider, indent: 16, endIndent: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            crossAxisAlignment: subtitle != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTypography.body.copyWith(
                      fontSize: 14, fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    )),
                    if (subtitle != null) ...[
                      const SizedBox(height: 1),
                      Text(subtitle!, style: AppTypography.caption.copyWith(
                        fontSize: 12, color: colors.textTertiary,
                      )),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              control,
            ],
          ),
        ),
      ],
    );
  }
}

// ─── APPEARANCE SECTION ───────────────────────────────────────────────────────

class _AppearanceSection extends StatelessWidget {
  const _AppearanceSection();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;

    final colorOptions = settings.accentColorOptions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SettingsSectionHeader(
          sticker: AppStickers.settingsAppearance,
          title: 'Appearance',
        ),
        _SectionCard(
          title: 'Theme',
          children: [
            _SettingsRow(
              isFirst: true,
              isLast: true,
              label: 'Appearance',
              control: _ThemeSegmentedControl(
                current: settings.themeMode,
                onChanged: settings.setThemeMode,
              ),
            ),
          ],
        ),
        _SectionCard(
          title: 'Accent Color',
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Used for buttons, highlights, and active states',
                    style: AppTypography.caption.copyWith(
                      fontSize: 13, color: colors.textTertiary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Color swatches
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: colorOptions.map((opt) {
                      final hex = opt['hex'] as String;
                      final color = opt['color'] as Color;
                      final isSelected = settings.accentColorHex.toUpperCase() == hex.toUpperCase();
                      return GestureDetector(
                        onTap: () => settings.setAccentColor(hex),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isSelected ? 32 : 28,
                          height: isSelected ? 32 : 28,
                          decoration: BoxDecoration(
                            color: color,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 2.5)
                                : null,
                            boxShadow: isSelected
                                ? [BoxShadow(color: color.withValues(alpha: 0.5), blurRadius: 6)]
                                : [],
                          ),
                          child: isSelected
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : null,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                  // Preview strip
                  Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accent.withValues(alpha: 0.2)),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: accent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, size: 12, color: Colors.white),
                        ),
                        const SizedBox(width: 10),
                        Text('Preview task', style: AppTypography.body.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w500,
                        )),
                        const Spacer(),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text('High', style: AppTypography.caption.copyWith(
                            color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11,
                          )),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _ThemeSegmentedControl extends StatelessWidget {
  final ThemeMode current;
  final void Function(ThemeMode) onChanged;
  const _ThemeSegmentedControl({required this.current, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;
    const options = [
      (ThemeMode.light, 'Light', Icons.light_mode_rounded),
      (ThemeMode.dark, 'Dark', Icons.dark_mode_rounded),
      (ThemeMode.system, 'System', Icons.brightness_auto_rounded),
    ];

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: colors.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: options.map((opt) {
          final (mode, label, icon) = opt;
          final isActive = mode == current;
          return GestureDetector(
            onTap: () => onChanged(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isActive ? (colors.isDark ? const Color(0xFF3A3A3C) : Colors.white) : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                boxShadow: isActive ? [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4, offset: const Offset(0, 1),
                )] : [],
              ),
              child: Row(
                children: [
                  Icon(icon, size: 13,
                    color: isActive ? accent : colors.textSecondary),
                  const SizedBox(width: 4),
                  Text(label, style: AppTypography.caption.copyWith(
                    fontSize: 12,
                    color: isActive ? colors.textPrimary : colors.textSecondary,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                  )),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ─── LAYOUT & DENSITY SECTION ─────────────────────────────────────────────────

class _LayoutDensitySection extends StatelessWidget {
  const _LayoutDensitySection();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SettingsSectionHeader(
          sticker: AppStickers.settingsLayout,
          title: 'Layout & Density',
        ),
        _SectionCard(
          title: 'Default View',
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: TaskViewLayout.values.map((layout) {
                  final isActive = settings.currentLayout == layout;
                  final label = _layoutLabel(layout);
                  final icon = _layoutIcon(layout);
                  return GestureDetector(
                    onTap: () => settings.setViewLayout(layout),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 100,
                      height: 72,
                      decoration: BoxDecoration(
                        color: isActive ? accent.withValues(alpha: 0.08) : colors.isDark
                            ? Colors.white.withValues(alpha: 0.04)
                            : Colors.black.withValues(alpha: 0.03),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isActive ? accent : colors.border,
                          width: isActive ? 1.5 : 0.5,
                        ),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(icon, size: 24,
                              color: isActive ? accent : colors.textSecondary),
                          const SizedBox(height: 6),
                          Text(label, style: AppTypography.caption.copyWith(
                            fontSize: 12,
                            color: isActive ? accent : colors.textSecondary,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                          )),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        _SectionCard(
          title: 'Interface Density',
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: FontDensity.values.map((density) {
                  final isActive = settings.fontDensity == density;
                  final label = _densityLabel(density);
                  final padding = _densityPadding(density);
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => settings.setFontDensity(density),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isActive ? accent.withValues(alpha: 0.08) : colors.isDark
                                ? Colors.white.withValues(alpha: 0.04)
                                : Colors.black.withValues(alpha: 0.03),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isActive ? accent : colors.border,
                              width: isActive ? 1.5 : 0.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              // Mini preview
                              ...List.generate(3, (i) => Container(
                                margin: EdgeInsets.only(bottom: padding.toDouble()),
                                height: 6,
                                decoration: BoxDecoration(
                                  color: colors.textTertiary.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(3),
                                ),
                              )),
                              const SizedBox(height: 8),
                              Text(label, style: AppTypography.caption.copyWith(
                                fontSize: 12,
                                color: isActive ? accent : colors.textSecondary,
                                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                              )),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        _SectionCard(
          title: 'Sidebar',
          children: [
            _SettingsRow(
              isFirst: true,
              isLast: true,
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
                      activeColor: accent,
                      onChanged: (v) => settings.setSidebarWidth(v),
                      onChangeEnd: (v) => settings.setSidebarWidth(v),
                    ),
                    Text(
                      '${settings.sidebarWidth.round()}px',
                      style: AppTypography.caption.copyWith(
                        fontSize: 12, color: colors.textTertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
        _SectionCard(
          title: 'Stickers',
          children: [
            _SettingsRow(
              isFirst: true,
              isLast: true,
              label: 'Sticker Size',
              subtitle: 'Adjust the scale of animated task badges',
              control: _StickerSizeSelector(
                current: settings.stickerSize,
                onChanged: settings.setStickerSize,
              ),
            ),
          ],
        ),
      ],
    );
  }

  String _layoutLabel(TaskViewLayout l) {
    switch (l) {
      case TaskViewLayout.list:     return 'List';
      case TaskViewLayout.grid:     return 'Grid';
      case TaskViewLayout.kanban:   return 'Kanban';
      case TaskViewLayout.compact:  return 'Compact';
      case TaskViewLayout.magazine: return 'Magazine';
    }
  }

  IconData _layoutIcon(TaskViewLayout l) {
    switch (l) {
      case TaskViewLayout.list:     return Icons.view_list_rounded;
      case TaskViewLayout.grid:     return Icons.grid_view_rounded;
      case TaskViewLayout.kanban:   return Icons.view_kanban_rounded;
      case TaskViewLayout.compact:  return Icons.density_small_rounded;
      case TaskViewLayout.magazine: return Icons.article_rounded;
    }
  }

  String _densityLabel(FontDensity d) {
    switch (d) {
      case FontDensity.compact:     return 'Compact';
      case FontDensity.normal:      return 'Normal';
      case FontDensity.comfortable: return 'Roomy';
    }
  }

  int _densityPadding(FontDensity d) {
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
    final accent = Theme.of(context).colorScheme.primary;
    final options = [
      (StickerSize.small, 'Small'),
      (StickerSize.normal, 'Normal'),
      (StickerSize.large, 'Large'),
      (StickerSize.jumbo, 'Jumbo'),
    ];

    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: colors.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
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
                color: isActive ? (colors.isDark ? const Color(0xFF3A3A3C) : Colors.white) : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                boxShadow: isActive ? [BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 4, offset: const Offset(0, 1),
                )] : [],
              ),
              child: Text(
                label,
                style: AppTypography.caption.copyWith(
                  fontSize: 12,
                  color: isActive ? colors.textPrimary : colors.textSecondary,
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

// ─── WALLPAPER SECTION ────────────────────────────────────────────────────────

class _WallpaperSection extends StatelessWidget {
  const _WallpaperSection();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;
    final wallType = settings.settings.wallpaperType;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SettingsSectionHeader(
          sticker: AppStickers.settingsWallpaper,
          title: 'Wallpaper',
        ),

        // ── TYPE SELECTOR ─────────────────────────────────────────
        _SectionCard(
          title: 'Background',
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Applies to the main content area only.',
                    style: AppTypography.caption.copyWith(
                      color: colors.textTertiary, fontSize: 12),
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
                              value: settings.settings.wallpaperGradientId ?? 'aurora'),
                        ),
                        const SizedBox(width: 8),
                        _WallpaperTypeTile(
                          label: 'Pattern',
                          icon: Icons.grid_4x4_rounded,
                          isActive: wallType == WallpaperType.pattern,
                          onTap: () => settings.setWallpaper(
                              WallpaperType.pattern,
                              value: settings.settings.wallpaperPatternId ?? 'dots'),
                        ),
                        const SizedBox(width: 8),
                        _WallpaperTypeTile(
                          label: 'Color',
                          icon: Icons.circle_rounded,
                          isActive: wallType == WallpaperType.solidColor,
                          onTap: () => settings.setWallpaper(
                              WallpaperType.solidColor,
                              value: settings.settings.wallpaperColorHex ?? 'A5B4FC'),
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
          ],
        ),

        // ── BRIGHTNESS SLIDER (shown for all except none) ─────────
        if (wallType != WallpaperType.none)
          _SectionCard(
            title: 'Visibility',
            children: [
              _SettingsRow(
                isFirst: true,
                isLast: true,
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
                        activeColor: accent,
                        inactiveColor: colors.border,
                        onChanged: (v) => settings.setWallpaperBrightness(v),
                        onChangeEnd: (v) => settings.setWallpaperBrightness(v),
                      ),
                    ),
                    const Icon(Icons.wb_sunny_rounded,
                        size: 18, color: Color(0xFF94A3B8)),
                  ],
                ),
              ),
            ],
          ),

        // ── GRADIENT PICKER ────────────────────────────────────────
        if (wallType == WallpaperType.gradient)
          _SectionCard(
            title: 'Gradient',
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
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
                                color: isSelected ? accent : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: isSelected
                                  ? [BoxShadow(
                                      color: accent.withValues(alpha: 0.35),
                                      blurRadius: 10)]
                                  : [BoxShadow(
                                      color: Colors.black.withValues(alpha: 0.12),
                                      blurRadius: 6,
                                      offset: const Offset(0, 2))],
                            ),
                            child: isSelected
                                ? const Center(
                                    child: Icon(Icons.check_rounded,
                                        color: Colors.white, size: 18))
                                : null,
                          ),
                          const SizedBox(height: 5),
                          Text(label,
                              style: AppTypography.caption.copyWith(
                                fontSize: 10,
                                color: isSelected ? accent : colors.textTertiary,
                                fontWeight: isSelected
                                    ? FontWeight.w700 : FontWeight.w400,
                              )),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

        // ── PATTERN PICKER ─────────────────────────────────────────
        if (wallType == WallpaperType.pattern)
          _SectionCard(
            title: 'Pattern',
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
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
                                color: isSelected ? accent : colors.border,
                                width: isSelected ? 2 : 0.75,
                              ),
                              boxShadow: isSelected
                                  ? [BoxShadow(
                                      color: accent.withValues(alpha: 0.25),
                                      blurRadius: 8)]
                                  : [],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(9),
                              child: CustomPaint(
                                painter: WallpaperPatternPainter(
                                  patternId: id,
                                  color: isSelected
                                      ? accent : colors.textTertiary,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 5),
                          Text(label,
                              style: AppTypography.caption.copyWith(
                                fontSize: 10,
                                color: isSelected ? accent : colors.textTertiary,
                                fontWeight: isSelected
                                    ? FontWeight.w700 : FontWeight.w400,
                              )),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),

        // ── SOLID COLOR PICKER ────────────────────────────────────
        if (wallType == WallpaperType.solidColor)
          _SectionCard(
            title: 'Color',
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
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
                              ? Border.all(color: accent, width: 2.5)
                              : Border.all(
                                  color: Colors.black.withValues(alpha: 0.08),
                                  width: 0.5),
                          boxShadow: isSelected
                              ? [BoxShadow(
                                  color: color.withValues(alpha: 0.5),
                                  blurRadius: 10, spreadRadius: 1)]
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
            ],
          ),

        // ── CUSTOM IMAGE ──────────────────────────────────────────
        if (wallType == WallpaperType.customImage)
          _SectionCard(
            title: 'Custom Photo',
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
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
                          border: Border.all(color: colors.border, width: 0.75),
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
                                  color: accent.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                      color: accent.withValues(alpha: 0.2)),
                                ),
                                child: Center(
                                  child: Text('Change Photo',
                                      style: AppTypography.body.copyWith(
                                          color: accent,
                                          fontWeight: FontWeight.w600)),
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
                              padding: const EdgeInsets.symmetric(horizontal: 14),
                              decoration: BoxDecoration(
                                color: AppColors.red.withValues(alpha: 0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                    color: AppColors.red.withValues(alpha: 0.2)),
                              ),
                              child: Center(
                                child: Text('Remove',
                                    style: AppTypography.body.copyWith(
                                        color: AppColors.red,
                                        fontWeight: FontWeight.w600)),
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
      ],
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
            style: AppTypography.body.copyWith(color: colors.textTertiary)),
        const SizedBox(height: 4),
        Text('JPG, PNG, WEBP',
            style: AppTypography.caption.copyWith(
                color: colors.textQuaternary, fontSize: 11)),
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
          content: const Text('Image too large. Please choose a file under 10MB.'),
          backgroundColor: AppColors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
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
    final accent = Theme.of(context).colorScheme.primary;

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
                  ? accent.withValues(alpha: 0.10)
                  : colors.surfaceElevated,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isActive ? accent : colors.border,
                width: isActive ? 1.75 : 0.75,
              ),
              boxShadow: isActive
                  ? [BoxShadow(
                      color: accent.withValues(alpha: 0.20),
                      blurRadius: 8)]
                  : [],
            ),
            child: Center(
              child: Icon(icon,
                  size: 22,
                  color: isActive ? accent : colors.textTertiary),
            ),
          ),
          const SizedBox(height: 5),
          Text(label,
              style: AppTypography.caption.copyWith(
                fontSize: 11,
                color: isActive ? accent : colors.textTertiary,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w400,
              )),
        ],
      ),
    );
  }
}

// ─── TASKS & DEFAULTS SECTION ─────────────────────────────────────────────────

class _TasksDefaultsSection extends StatelessWidget {
  const _TasksDefaultsSection();

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SettingsSectionHeader(
          sticker: AppStickers.settingsTasks,
          title: 'Tasks & Defaults',
        ),
        _SectionCard(
          title: 'Defaults',
          children: [
            _SettingsRow(
              isFirst: true,
              label: 'Start of Week',
              control: _ToggleChip(
                selected: settings.startOfWeek == 1,
                label1: 'Monday',
                label2: 'Sunday',
                onChanged: (isMon) => settings.setStartOfWeek(isMon ? 1 : 7),
              ),
            ),
            _SettingsRow(
              isLast: true,
              label: 'Focus Duration',
              subtitle: 'Pomodoro session length',
              control: SizedBox(
                width: 100,
                child: DropdownButton<int>(
                  value: settings.focusDuration,
                  dropdownColor: colors.surfaceElevated,
                  underline: const SizedBox.shrink(),
                  items: [15, 20, 25, 30, 45, 60].map((m) =>
                    DropdownMenuItem(
                      value: m,
                      child: Text('$m min', style: AppTypography.body.copyWith(
                        fontSize: 14, color: colors.textPrimary,
                      )),
                    ),
                  ).toList(),
                  onChanged: (v) { if (v != null) settings.setFocusDuration(v); },
                ),
              ),
            ),
          ],
        ),
      ],
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
    final accent = Theme.of(context).colorScheme.primary;
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _chip(context, label1, selected, () => onChanged(true), accent, colors),
        const SizedBox(width: 4),
        _chip(context, label2, !selected, () => onChanged(false), accent, colors),
      ],
    );
  }

  Widget _chip(BuildContext context, String label, bool isOn,
    VoidCallback onTap, Color accent, AppColorsExtension colors) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isOn ? accent : colors.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(label, style: AppTypography.caption.copyWith(
          fontSize: 12,
          color: isOn ? Colors.white : colors.textSecondary,
          fontWeight: isOn ? FontWeight.w600 : FontWeight.w400,
        )),
      ),
    );
  }
}

// ─── ABOUT SECTION ────────────────────────────────────────────────────────────

class _AboutSection extends StatefulWidget {
  const _AboutSection();

  @override
  State<_AboutSection> createState() => _AboutSectionState();
}

class _AboutSectionState extends State<_AboutSection> {
  String _version = '—';
  String _buildNumber = '—';
  String _appName = 'Taski';

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
        _buildNumber = info.buildNumber;
        _appName = info.appName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _SettingsSectionHeader(
          sticker: AppStickers.settingsAbout,
          title: 'About',
        ),
        _SectionCard(
          title: 'App Info',
          children: [
            _SettingsRow(
              isFirst: true,
              label: 'App Name',
              control: Text(_appName, style: AppTypography.body.copyWith(
                color: colors.textSecondary,
              )),
            ),
            _SettingsRow(
              label: 'Version',
              control: Text('$_version ($_buildNumber)', style: AppTypography.body.copyWith(
                color: colors.textSecondary,
              )),
            ),
            _SettingsRow(
              isLast: true,
              label: 'Built with',
              control: Text('Flutter 3 · Hive · Provider', style: AppTypography.body.copyWith(
                color: colors.textSecondary,
                fontSize: 13,
              )),
            ),
          ],
        ),
      ],
    );
  }
}
