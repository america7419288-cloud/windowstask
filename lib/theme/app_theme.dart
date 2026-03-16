import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light(Color accentColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: accentColor,
        secondary: accentColor,
        surface: AppColors.lightSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.lightTextPrimary,
      ),
      scaffoldBackgroundColor: AppColors.lightBackground,
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme).apply(
        bodyColor: AppColors.lightTextPrimary,
        displayColor: AppColors.lightTextPrimary,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.lightTextSecondary,
        size: 20,
      ),
      dividerColor: AppColors.lightDivider,
      dividerTheme: const DividerThemeData(
        color: AppColors.lightDivider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.lightTextSecondary,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentColor;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: AppColors.lightTextSecondary.withOpacity(0.5), width: 1.5),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.lightTextSecondary.withOpacity(0.3)),
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.all(4),
      ),
      extensions: const [AppColorsExtension.light()],
    );
  }

  static ThemeData dark(Color accentColor) {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: accentColor,
        secondary: accentColor,
        surface: AppColors.darkSurface,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.darkTextPrimary,
      ),
      scaffoldBackgroundColor: AppColors.darkBackground,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).apply(
        bodyColor: AppColors.darkTextPrimary,
        displayColor: AppColors.darkTextPrimary,
      ),
      iconTheme: const IconThemeData(
        color: AppColors.darkTextSecondary,
        size: 20,
      ),
      dividerColor: AppColors.darkDivider,
      dividerTheme: const DividerThemeData(
        color: AppColors.darkDivider,
        thickness: 1,
        space: 1,
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: InputBorder.none,
        focusedBorder: InputBorder.none,
        enabledBorder: InputBorder.none,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        hintStyle: GoogleFonts.inter(
          fontSize: 13,
          color: AppColors.darkTextSecondary,
        ),
      ),
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accentColor;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(Colors.white),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        side: BorderSide(color: AppColors.darkTextSecondary.withOpacity(0.5), width: 1.5),
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStateProperty.all(AppColors.darkTextSecondary.withOpacity(0.3)),
        radius: const Radius.circular(4),
        thickness: WidgetStateProperty.all(4),
      ),
      extensions: const [AppColorsExtension.dark()],
    );
  }
}

@immutable
class AppColorsExtension extends ThemeExtension<AppColorsExtension> {
  const AppColorsExtension({
    required this.background,
    required this.surface,
    required this.sidebar,
    required this.textPrimary,
    required this.textSecondary,
    required this.divider,
    required this.border,
    required this.isDark,
  });

  const AppColorsExtension.light()
      : background = AppColors.lightBackground,
        surface = AppColors.lightSurface,
        sidebar = AppColors.lightSidebar,
        textPrimary = AppColors.lightTextPrimary,
        textSecondary = AppColors.lightTextSecondary,
        divider = AppColors.lightDivider,
        border = AppColors.lightBorder,
        isDark = false;

  const AppColorsExtension.dark()
      : background = AppColors.darkBackground,
        surface = AppColors.darkSurface,
        sidebar = AppColors.darkSidebar,
        textPrimary = AppColors.darkTextPrimary,
        textSecondary = AppColors.darkTextSecondary,
        divider = AppColors.darkDivider,
        border = AppColors.darkBorder,
        isDark = true;

  final Color background;
  final Color surface;
  final Color sidebar;
  final Color textPrimary;
  final Color textSecondary;
  final Color divider;
  final Color border;
  final bool isDark;

  @override
  AppColorsExtension copyWith({
    Color? background,
    Color? surface,
    Color? sidebar,
    Color? textPrimary,
    Color? textSecondary,
    Color? divider,
    Color? border,
    bool? isDark,
  }) {
    return AppColorsExtension(
      background: background ?? this.background,
      surface: surface ?? this.surface,
      sidebar: sidebar ?? this.sidebar,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      divider: divider ?? this.divider,
      border: border ?? this.border,
      isDark: isDark ?? this.isDark,
    );
  }

  @override
  AppColorsExtension lerp(AppColorsExtension? other, double t) {
    if (other is! AppColorsExtension) return this;
    return AppColorsExtension(
      background: Color.lerp(background, other.background, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      sidebar: Color.lerp(sidebar, other.sidebar, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      divider: Color.lerp(divider, other.divider, t)!,
      border: Color.lerp(border, other.border, t)!,
      isDark: t > 0.5 ? other.isDark : isDark,
    );
  }
}

extension ThemeExtensionHelper on BuildContext {
  AppColorsExtension get appColors =>
      Theme.of(this).extension<AppColorsExtension>()!;
}
