import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light(Color accentColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.bgLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.indigo,
        brightness: Brightness.light,
        surface: AppColors.surLight,
        onSurface: AppColors.t1Light,
        primary: AppColors.indigo,
        onPrimary: Colors.white,
        secondary: AppColors.indigoL,
        error: AppColors.danger,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(
        ThemeData.light().textTheme,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.t2Light,
        size: 20,
      ),
      // NO divider lines
      dividerColor: Colors.transparent,
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
        space: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      extensions: [AppColorsExtension.light(accentColor)],
    );
  }

  static ThemeData dark(Color accentColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.bgDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppColors.indigo,
        brightness: Brightness.dark,
        surface: AppColors.surDark,
        onSurface: AppColors.t1Dark,
        primary: AppColors.indigoL,
        onPrimary: Colors.white,
        secondary: AppColors.indigoXL,
        error: AppColors.danger,
      ),
      textTheme: GoogleFonts.nunitoTextTheme(
        ThemeData.dark().textTheme,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.t2Dark,
        size: 20,
      ),
      dividerColor: Colors.transparent,
      dividerTheme: const DividerThemeData(
        color: Colors.transparent,
        thickness: 0,
        space: 0,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      extensions: [AppColorsExtension.dark(accentColor, DarkThemePalette.aurora)],
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
    required this.surfaceContainerHigh,
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
      : accent = AppColors.indigo,
        background = AppColors.bgLight,
        surface = AppColors.surLight,
        surfaceElevated = AppColors.sur2Light,
        surfaceContainerHigh = AppColors.sur3Light,
        sidebar = AppColors.sidebarLight, // DARK sidebar in light mode
        sidebarActive = Colors.white.withValues(alpha: .10),
        textPrimary = AppColors.t1Light,
        textSecondary = AppColors.t2Light,
        textTertiary = AppColors.t3Light,
        textQuaternary = AppColors.t4Light,
        border = Colors.transparent,
        divider = const Color(0xFF0C0E1A).withValues(alpha: .06),
        isDark = false;

  AppColorsExtension.dark(Color accentColor, DarkThemePalette palette)
      : accent = AppColors.indigoL,
        background = AppColors.bgDark,
        surface = AppColors.surDark,
        surfaceElevated = AppColors.sur2Dark,
        surfaceContainerHigh = AppColors.sur3Dark,
        sidebar = AppColors.sidebarDark,
        sidebarActive = Colors.white.withValues(alpha: .08),
        textPrimary = AppColors.t1Dark,
        textSecondary = AppColors.t2Dark,
        textTertiary = AppColors.t3Dark,
        textQuaternary = AppColors.t4Dark,
        border = Colors.transparent,
        divider = Colors.white.withValues(alpha: .06),
        isDark = true;

  final Color accent;
  final Color background;
  final Color surface;
  final Color surfaceElevated;
  final Color surfaceContainerHigh;
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
    Color? surfaceContainerHigh,
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
      surfaceContainerHigh: surfaceContainerHigh ?? this.surfaceContainerHigh,
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
      surfaceContainerHigh: Color.lerp(surfaceContainerHigh, other.surfaceContainerHigh, t)!,
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
    return AppColorsExtension.light(AppColors.indigo);
  }
}
