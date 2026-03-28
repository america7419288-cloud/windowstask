import 'package:flutter/material.dart';
import '../models/task.dart';

class AppColors {
  AppColors._();

  // ── BRAND ─────────────────────────────
  static const indigo    = Color(0xFF27389A);
  static const indigoL   = Color(0xFF4C5EC9);
  static const indigoXL  = Color(0xFF6B7FE3);
  static const indigoDim = Color(0x1427389A);
    // 8% opacity — for backgrounds

  // ── ACCENT ────────────────────────────
  static const gold      = Color(0xFFFFD60A);
  static const goldDim   = Color(0x26FFD60A);

  // ── SEMANTIC ──────────────────────────
  static const success   = Color(0xFF16A34A);
  static const successBg = Color(0xFFDCFCE7);
  static const danger    = Color(0xFFDC2626);
  static const dangerBg  = Color(0xFFFEE2E2);
  static const warning   = Color(0xFFD97706);
  static const warningBg = Color(0xFFFEF3C7);
  static const premium   = Color(0xFFDB2777);
  static const premiumBg = Color(0xFFFCE7F3);

  // ── PRIORITY ──────────────────────────
  static const pNone   = Color(0xFFC2C6E0);
  static const pLow    = Color(0xFF16A34A);
  static const pMedium = Color(0xFFD97706);
  static const pHigh   = Color(0xFFDC2626);
  static const pUrgent = Color(0xFFDB2777);

  // ── LIGHT MODE SURFACES ───────────────
  static const bgLight      = Color(0xFFF0F2F8);
  static const sidebarLight = Color(0xFF1A1D2E);
    // Dark sidebar in light mode
  static const surLight     = Color(0xFFFFFFFF);
  static const sur2Light    = Color(0xFFF5F6FA);
  static const sur3Light    = Color(0xFFECEEF6);

  // ── DARK MODE SURFACES ────────────────
  static const bgDark        = Color(0xFF0E1018);
  static const sidebarDark   = Color(0xFF0A0C14);
  static const surDark       = Color(0xFF161924);
  static const sur2Dark      = Color(0xFF1E2130);
  static const sur3Dark      = Color(0xFF252840);

  // ── SIDEBAR TEXT (always light) ───────
  static const sbText        = Color(0xFFFFFFFF);
  static const sbTextDim     = Color(0x99FFFFFF);
    // 60% white
  static const sbTextFaint   = Color(0x4DFFFFFF);
    // 30% white

  // ── LIGHT TEXT ────────────────────────
  static const t1Light = Color(0xFF0C0E1A);
  static const t2Light = Color(0xFF3D4270);
  static const t3Light = Color(0xFF8890B8);
  static const t4Light = Color(0xFFC2C6E0);

  // ── DARK TEXT ─────────────────────────
  static const t1Dark  = Color(0xFFEEF0FF);
  static const t2Dark  = Color(0xFF9AA5D0);
  static const t3Dark  = Color(0xFF5A6490);
  static const t4Dark  = Color(0xFF2E3350);

  // ── GRADIENTS ─────────────────────────
  static const gradientPrimary = LinearGradient(
    colors: [Color(0xFF4C5EC9),
             Color(0xFF27389A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientMomentum = LinearGradient(
    colors: [Color(0xFF3D52C4),
             Color(0xFF1E2B8A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientGold = LinearGradient(
    colors: [Color(0xFFFFD60A),
             Color(0xFFFFB700)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientSuccess = LinearGradient(
    colors: [Color(0xFF22C55E),
             Color(0xFF16A34A)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientSidebar = LinearGradient(
    colors: [Color(0xFF1A1D2E),
             Color(0xFF14172A)],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  // Backwards compat aliases for gradients
  static const gradPrimary = gradientPrimary;
  static const gradMomentum = gradientMomentum;
  static const gradGold = gradientGold;
  static const gradSuccess = gradientSuccess;
  static const gradSidebar = gradientSidebar;

  // ── SHADOWS ───────────────────────────
  static List<BoxShadow> shadowSM({
    bool isDark = false}) => [
    BoxShadow(
      color: isDark
        ? Colors.black.withValues(alpha:.20)
        : const Color(0xFF0C0E1A)
            .withValues(alpha:.06),
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: isDark
        ? Colors.black.withValues(alpha:.12)
        : const Color(0xFF0C0E1A)
            .withValues(alpha:.03),
      blurRadius: 3,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> shadowMD({
    bool isDark = false}) => [
    BoxShadow(
      color: isDark
        ? Colors.black.withValues(alpha:.28)
        : const Color(0xFF0C0E1A)
            .withValues(alpha:.08),
      blurRadius: 20,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: isDark
        ? Colors.black.withValues(alpha:.14)
        : const Color(0xFF0C0E1A)
            .withValues(alpha:.04),
      blurRadius: 6,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> shadowPrimary() => [
    BoxShadow(
      color: indigo.withValues(alpha:.28),
      blurRadius: 20,
      offset: const Offset(0, 6),
    ),
    BoxShadow(
      color: indigo.withValues(alpha:.14),
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> shadowGold() => [
    BoxShadow(
      color: gold.withValues(alpha:.35),
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
  ];

  // ── HELPERS ───────────────────────────
  static Color priorityColor(Priority p) {
    switch (p) {
      case Priority.none:   return pNone;
      case Priority.low:    return pLow;
      case Priority.medium: return pMedium;
      case Priority.high:   return pHigh;
      case Priority.urgent: return pUrgent;
    }
  }

  static Color priorityBg(Priority p) {
    switch (p) {
      case Priority.none:
        return const Color(0xFFF0F2F8);
      case Priority.low:    return successBg;
      case Priority.medium: return warningBg;
      case Priority.high:   return dangerBg;
      case Priority.urgent: return premiumBg;
    }
  }

  static String priorityLabel(Priority p) {
    switch (p) {
      case Priority.none:   return 'None';
      case Priority.low:    return 'Low';
      case Priority.medium: return 'Medium';
      case Priority.high:   return 'High';
      case Priority.urgent: return 'Urgent';
    }
  }

  // Legacy aliases & Sidebar tokens
  static const primary = indigo;
  static const primaryLight = indigoL;
  static const primaryDim = indigoDim;
  static const tertiary = indigoXL;
  static const accent = indigo;
  static const orange = warning;
  static const red = danger;
  static const error = danger;
  
  static const onPrimary = Colors.white;
  static const onSurface = t1Light;
  static const onSurfaceDark = t1Dark;
  static const onSurfaceVariant = t2Light;
  static const onSurfaceVariantDk = t2Dark;
  static const onTertiary = Colors.white;

  static const surfaceLight = bgLight;
  static const surfaceDark = bgDark;
  
  static const surfaceContainer = sur2Light;
  static const surfaceContainerDk = sur2Dark;
  static const surfaceContainerLow = sur2Light;
  static const surfaceContainerLowDk = sur2Dark;
  static const surfaceContainerLowest = surLight;
  static const surfaceContainerLowestDk = surDark;
  static const surfaceContainerHigh = sur3Light;
  static const surfaceContainerHighDk = sur3Dark;
  
  static const priorityMedium = warning;
  static const priorityUrgent = premium;
  static const priorityHigh = danger;
  static const xpGold = gold;
  static const blue = indigoL;
  static const purple = indigoXL;
  static const pink = premium;
  static const green = AppColors.success;
  static const teal = AppColors.success;
  static const tertiaryContainer = sur3Light;
  static const secondary = indigoL;
  static const canvasDark = bgDark;
  static const canvasLight = bgLight;
  static const textMuted = t3Light;

  static List<BoxShadow> ambientShadow({double opacity = 0.08, double blur = 8, Offset offset = const Offset(0, 2)}) => [
    BoxShadow(
      color: Colors.black.withValues(alpha: opacity),
      blurRadius: blur,
      offset: offset,
    ),
  ];

  static Color getPriorityColor(Priority p) => priorityColor(p);

  static Color glassBackground(bool isDark) => isDark 
      ? Colors.black.withValues(alpha: 0.3) 
      : Colors.white.withValues(alpha: 0.3);
  
  static final sidebarActive = Colors.white.withValues(alpha: 0.10);
  static final sidebarHover = Colors.white.withValues(alpha: 0.05);
  static const sidebarText = sbText;
  static const sidebarTextDim = sbTextDim;
  static final sidebarBorder = Colors.white.withValues(alpha: 0.08);
}

enum DarkThemePalette { aurora, obsidian }
