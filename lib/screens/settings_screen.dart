import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../models/app_settings.dart';
import '../providers/settings_provider.dart';
import '../providers/list_provider.dart';
import '../theme/app_theme.dart';
import '../theme/colors.dart';
import '../theme/typography.dart';
import '../theme/wallpaper_presets.dart';
import '../painters/wallpaper_pattern_painter.dart';

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
          width: 180,
          color: colors.sidebar,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 16),
                child: Text(
                  'SETTINGS',
                  style: AppTypography.caption.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
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
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: BoxDecoration(
                      color: isActive ? accent.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(icon, size: 16, color: isActive ? accent : colors.textSecondary),
                        const SizedBox(width: 8),
                        Text(
                          label,
                          style: AppTypography.body.copyWith(
                            fontSize: 13,
                            fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                            color: isActive ? accent : colors.textPrimary,
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
        const VerticalDivider(width: 1),
        // Right content
        Expanded(
          child: Container(
            color: colors.background,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
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

// ─── SHARED WIDGETS ──────────────────────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title;
  final List<Widget> children;
  const _SectionCard({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8, left: 4),
          child: Text(
            title.toUpperCase(),
            style: AppTypography.caption.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
              color: colors.textTertiary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: colors.surfaceElevated,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colors.border, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: children,
          ),
        ),
        const SizedBox(height: 20),
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
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: subtitle != null ? CrossAxisAlignment.start : CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: AppTypography.body.copyWith(
                      fontSize: 15, fontWeight: FontWeight.w500,
                      color: colors.textPrimary,
                    )),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(subtitle!, style: AppTypography.caption.copyWith(
                        fontSize: 13, color: colors.textTertiary,
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                                ? [BoxShadow(color: color.withOpacity(0.5), blurRadius: 6)]
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
                      color: accent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: accent.withOpacity(0.2)),
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
        color: colors.isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
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
                  color: Colors.black.withOpacity(0.08),
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
                        color: isActive ? accent.withOpacity(0.08) : colors.isDark
                            ? Colors.white.withOpacity(0.04)
                            : Colors.black.withOpacity(0.03),
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
                            color: isActive ? accent.withOpacity(0.08) : colors.isDark
                                ? Colors.white.withOpacity(0.04)
                                : Colors.black.withOpacity(0.03),
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
                                  color: colors.textTertiary.withOpacity(0.3),
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
      case TaskViewLayout.calendar: return 'Calendar';
    }
  }

  IconData _layoutIcon(TaskViewLayout l) {
    switch (l) {
      case TaskViewLayout.list:     return Icons.view_list_rounded;
      case TaskViewLayout.grid:     return Icons.grid_view_rounded;
      case TaskViewLayout.kanban:   return Icons.view_kanban_rounded;
      case TaskViewLayout.compact:  return Icons.density_small_rounded;
      case TaskViewLayout.magazine: return Icons.article_rounded;
      case TaskViewLayout.calendar: return Icons.calendar_month_rounded;
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: 'Wallpaper Type',
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: WallpaperType.values.map((type) {
                  final isActive = wallType == type;
                  return GestureDetector(
                    onTap: () => settings.setWallpaper(type),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          width: 72,
                          height: 48,
                          decoration: BoxDecoration(
                            color: colors.isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: isActive ? accent : colors.border,
                              width: isActive ? 2 : 0.5,
                            ),
                          ),
                          child: _WallpaperTypePreview(type: type),
                        ),
                        const SizedBox(height: 4),
                        Text(_typeLabel(type), style: AppTypography.caption.copyWith(
                          fontSize: 11,
                          color: isActive ? accent : colors.textSecondary,
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        )),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
        // Opacity slider (hidden for None)
        if (wallType != WallpaperType.none)
          _SectionCard(
            title: 'Opacity',
            children: [
              _SettingsRow(
                isFirst: true,
                isLast: true,
                label: 'Wallpaper Opacity',
                subtitle: 'Keep low to avoid distraction',
                control: SizedBox(
                  width: 200,
                  child: Slider(
                    value: settings.settings.wallpaperOpacity,
                    min: 0.05,
                    max: 0.40,
                    divisions: 7,
                    label: '${(settings.settings.wallpaperOpacity * 100).round()}%',
                    activeColor: accent,
                    onChanged: (v) => settings.setWallpaperOpacity(v),
                    onChangeEnd: (v) => settings.setWallpaperOpacity(v),
                  ),
                ),
              ),
            ],
          ),
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
                    'FF3B30', 'FF9500', 'FFCC00', '34C759',
                    '007AFF', 'AF52DE', 'FF2D55', '5AC8FA',
                    '8E8E93', '1C1C1E',
                  ].map((colorHex) {
                    final color = Color(int.parse('FF$colorHex', radix: 16));
                    final isSelected = settings.settings.wallpaperColorHex
                            ?.toUpperCase() ==
                        colorHex.toUpperCase();
                    return GestureDetector(
                      onTap: () => settings.setWallpaper(
                        WallpaperType.solidColor,
                        value: colorHex,
                      ),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        width: isSelected ? 40 : 36,
                        height: isSelected ? 40 : 36,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          border: isSelected
                              ? Border.all(color: Colors.white, width: 2.5)
                              : Border.all(
                                  color: Colors.black.withOpacity(0.08),
                                  width: 0.5),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: color.withOpacity(0.45),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  )
                                ]
                              : [],
                        ),
                        child: isSelected
                            ? const Icon(Icons.check,
                                size: 16, color: Colors.white)
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        // Gradient options
        if (wallType == WallpaperType.gradient)
          _SectionCard(
            title: 'Gradient',
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: WallpaperPresets.gradientIds.map((id) {
                    final gradient = WallpaperPresets.gradients[id]!;
                    final isSelected = settings.settings.wallpaperGradientId == id;
                    return GestureDetector(
                      onTap: () => settings.setWallpaper(WallpaperType.gradient, value: id),
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          gradient: gradient,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isSelected ? accent : Colors.transparent,
                            width: 2,
                          ),
                        ),
                        child: isSelected
                            ? const Center(child: Icon(Icons.check, color: Colors.white, size: 20))
                            : null,
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        // Pattern options
        if (wallType == WallpaperType.pattern)
          _SectionCard(
            title: 'Pattern',
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: WallpaperPresets.patternIds.map((id) {
                    final isSelected = settings.settings.wallpaperPatternId == id;
                    return GestureDetector(
                      onTap: () => settings.setWallpaper(WallpaperType.pattern, value: id),
                      child: Column(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: colors.isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: isSelected ? accent : colors.border,
                                width: isSelected ? 2 : 0.5,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(7),
                              child: CustomPaint(
                                painter: WallpaperPatternPainter(
                                  patternId: id,
                                  color: accent,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            WallpaperPresets.patternLabels[id] ?? id,
                            style: AppTypography.caption.copyWith(
                              fontSize: 10,
                              color: isSelected ? accent : colors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
      ],
    );
  }

  String _typeLabel(WallpaperType t) {
    switch (t) {
      case WallpaperType.none:       return 'None';
      case WallpaperType.solidColor: return 'Color';
      case WallpaperType.gradient:   return 'Gradient';
      case WallpaperType.pattern:    return 'Pattern';
    }
  }
}

class _WallpaperTypePreview extends StatelessWidget {
  final WallpaperType type;
  const _WallpaperTypePreview({required this.type});

  @override
  Widget build(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    switch (type) {
      case WallpaperType.none:
        return const Icon(Icons.block, size: 20, color: Colors.grey);
      case WallpaperType.solidColor:
        return Container(color: AppColors.blue.withOpacity(0.3));
      case WallpaperType.gradient:
        return Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
        );
      case WallpaperType.pattern:
        return CustomPaint(
          painter: WallpaperPatternPainter(patternId: 'dots', color: accent),
        );
    }
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
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
          color: isOn ? accent : colors.isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.05),
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

class _AboutSection extends StatelessWidget {
  const _AboutSection();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionCard(
          title: 'App Info',
          children: [
            _SettingsRow(
              isFirst: true,
              label: 'App Name',
              control: Text('Taski', style: AppTypography.body.copyWith(
                color: colors.textSecondary,
              )),
            ),
            _SettingsRow(
              label: 'Version',
              control: Text('1.0.0', style: AppTypography.body.copyWith(
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
