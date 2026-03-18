import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light(Color accentColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.canvasLight,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.light,
        surface: AppColors.surfaceLight,
        onSurface: AppColors.textPrimaryLight,
        primary: accentColor,
        error: AppColors.red,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: AppColors.textPrimaryLight,
        displayColor: AppColors.textPrimaryLight,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textSecondaryLight,
        size: 20,
      ),
      dividerColor: AppColors.dividerLight,
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerLight,
        thickness: 0.5,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: AppColors.textSecondaryLight,
          letterSpacing: -0.1,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return AppColors.textTertiaryLight.withValues(alpha: 0.5);
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
      scaffoldBackgroundColor: AppColors.canvasDark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: accentColor,
        brightness: Brightness.dark,
        surface: AppColors.surfaceDark,
        onSurface: AppColors.textPrimaryDark,
        primary: accentColor,
        error: AppColors.red,
      ),
      textTheme: GoogleFonts.plusJakartaSansTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.textPrimaryDark,
        displayColor: AppColors.textPrimaryDark,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.textSecondaryDark,
        size: 20,
      ),
      dividerColor: AppColors.dividerDark,
      dividerTheme: const DividerThemeData(
        color: AppColors.dividerDark,
        thickness: 0.5,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          color: AppColors.textSecondaryDark,
          letterSpacing: -0.1,
        ),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return AppColors.textTertiaryDark.withValues(alpha: 0.5);
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
      : accent = accentColor,
        background = AppColors.canvasLight,
        surface = AppColors.surfaceLight,
        surfaceElevated = AppColors.surfaceElevatedLight,
        sidebar = AppColors.sidebarLight,
        sidebarActive = accentColor.withValues(alpha: 0.08),
        textPrimary = AppColors.textPrimaryLight,
        textSecondary = AppColors.textSecondaryLight,
        textTertiary = AppColors.textTertiaryLight,
        textQuaternary = AppColors.textQuaternaryLight,
        border = AppColors.dividerLight,
        divider = AppColors.dividerLight,
        isDark = false;

  AppColorsExtension.dark(Color accentColor)
      : accent = accentColor,
        background = AppColors.canvasDark,
        surface = AppColors.surfaceDark,
        surfaceElevated = AppColors.surfaceElevatedDark,
        sidebar = AppColors.sidebarDark,
        sidebarActive = accentColor.withValues(alpha: 0.15),
        textPrimary = AppColors.textPrimaryDark,
        textSecondary = AppColors.textSecondaryDark,
        textTertiary = AppColors.textTertiaryDark,
        textQuaternary = AppColors.textQuaternaryDark,
        border = AppColors.dividerDark,
        divider = AppColors.dividerDark,
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

extension ThemeExtensionHelper on BuildContext {
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>()!;
}
