import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light(Color accentColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.surfaceLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.onSurface,
        primary: AppColors.primary,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.light().textTheme,
      ).apply(
        bodyColor: AppColors.onSurface,
        displayColor: AppColors.onSurface,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.onSurfaceVariant,
        size: 20,
      ),
      // NO divider lines — Mindful Architect rule
      dividerColor: Colors.transparent,
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
        space: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.onSurfaceVariant,
          letterSpacing: -0.1,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return AppColors.onSurfaceVariant.withValues(alpha: 0.3);
          }
          return Colors.transparent;
        }),
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(10),
        interactive: true,
      ),
      extensions: [AppColorsExtension.light(accentColor)],
    );
  }

  static ThemeData dark(Color accentColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.surfaceDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.dark,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.onSurfaceDark,
        primary: AppColors.primaryLight,
        onPrimary: AppColors.onPrimary,
        secondary: AppColors.secondary,
        tertiary: AppColors.tertiary,
        error: AppColors.error,
      ),
      textTheme: GoogleFonts.interTextTheme(
        ThemeData.dark().textTheme,
      ).apply(
        bodyColor: AppColors.onSurfaceDark,
        displayColor: AppColors.onSurfaceDark,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.onSurfaceVariantDk,
        size: 20,
      ),
      dividerColor: Colors.transparent,
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
        space: 0,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.onSurfaceVariantDk,
          letterSpacing: -0.1,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return AppColors.onSurfaceVariantDk.withValues(alpha: 0.3);
          }
          return Colors.transparent;
        }),
        thickness: WidgetStateProperty.all(6),
        radius: const Radius.circular(10),
        interactive: true,
      ),
      extensions: [AppColorsExtension.dark(accentColor)],
    );
  }
}

// ── APP COLORS EXTENSION ─────────────────────────────
@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.accent,
    required this.background,
    required this.surface,
    required this.surfaceElevated,
    required this.sidebar,
    required this.sidebarActive,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.textQuaternary,
    required this.border,
    required this.divider,
    required this.isDark,
  });

  AppColorsExtension.light(Color accentColor)
      : accent = AppColors.primary,
        background = AppColors.surfaceLight,
        surface = AppColors.surfaceContainerLowest,
        surfaceElevated = AppColors.surfaceContainerLow,
        sidebar = AppColors.surfaceContainerLow,
        sidebarActive = AppColors.primary.withValues(alpha: 0.08),
        textPrimary = AppColors.onSurface,
        textSecondary = AppColors.secondary,
        textTertiary = AppColors.onSurfaceVariant,
        textQuaternary = AppColors.onSurfaceVariant.withValues(alpha: 0.6),
        border = Colors.transparent,
        divider = Colors.transparent,
        isDark = false;

  AppColorsExtension.dark(Color accentColor)
      : accent = AppColors.primaryLight,
        background = AppColors.surfaceDark,
        surface = AppColors.surfaceContainerLowestDk,
        surfaceElevated = AppColors.surfaceContainerLowDk,
        sidebar = AppColors.surfaceContainerLowDk,
        sidebarActive = AppColors.primaryLight.withValues(alpha: 0.12),
        textPrimary = AppColors.onSurfaceDark,
        textSecondary = AppColors.onSurfaceVariantDk,
        textTertiary = AppColors.onSurfaceVariantDk.withValues(alpha: 0.7),
        textQuaternary = AppColors.onSurfaceVariantDk.withValues(alpha: 0.4),
        border = Colors.transparent,
        divider = Colors.transparent,
        isDark = true;

  final Color accent;
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color sidebar;
  final Color sidebarActive;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color textQuaternary;
  final Color border;
  final Color divider;
  final bool isDark;

  @override
  AppColorsExtension copyWith({
    Color? accent,
    Color? background,
    Color? surface,
    Color? surfaceElevated,
    Color? sidebar,
    Color? sidebarActive,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? textQuaternary,
    Color? border,
    Color? divider,
    bool? isDark,
  }) {
    return AppColorsExtension(
      accent: accent ?? this.accent,
      background: background ?? this.background,
      surface: surface ?? this.surface,
      surfaceElevated: surfaceElevated ?? this.surfaceElevated,
      sidebar: sidebar ?? this.sidebar,
      sidebarActive: sidebarActive ?? this.sidebarActive,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      textQuaternary: textQuaternary ?? this.textQuaternary,
      border: border ?? this.border,
      divider: divider ?? this.divider,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  AppColorsExtension lerp(AppColorsExtension? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      accent: Color.lerp(accent, other.accent, t)!,
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceElevated: Color.lerp(surfaceElevated, other.surfaceElevated, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      sidebarActive: Color.lerp(sidebarActive, other.sidebarActive, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      textQuaternary: Color.lerp(textQuaternary, other.textQuaternary, t)!,
      border: Color.lerp(border, other.border, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      isDark: t > 0.5 ? other.isDark : isDark,
    );
  }
}

// ── CONTEXT EXTENSION ───────────────────────────────
extension ThemeExtensionHelper on BuildContext {
  AppColorsExtension get appColors {
    final ext = Theme.of(this).extension<AppColorsExtension>();
    if (ext != null) return ext;
    // Fallback to default light theme extension
    return AppColorsExtension.light(const Color(0xFF27389A));
  }
}
