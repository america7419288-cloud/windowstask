import 'package:flutter/material.dart';
import '../models/task.dart';

class AppColors {
  AppColors._();

  // ── MINDFUL ARCHITECT PALETTE ─────────────────────
  // Primary — Professional Indigo
  static const primary           = Color(0xFF27389A);
  static const primaryContainer  = Color(0xFF4151B3);
  static const primaryLight      = Color(0xFF5C6BC0);
  static const onPrimary         = Color(0xFFFFFFFF);

  // Secondary — Professional Slate
  static const secondary         = Color(0xFF505F76);
  static const onSecondary       = Color(0xFFFFFFFF);

  // Tertiary — Achievement Green
  static const tertiary          = Color(0xFF004E33);
  static const tertiaryContainer = Color(0xFF006846);
  static const onTertiary        = Color(0xFF5DEBAF);

  // ── SURFACE HIERARCHY ────────────────────────────
  // Light mode — subtle indigo undertone
  static const surfaceLight           = Color(0xFFF6FAFE);
  static const surfaceContainerLow    = Color(0xFFF0F4F8);
  static const surfaceContainerLowest = Color(0xFFFFFFFF);
  static const surfaceContainer       = Color(0xFFEAEEF2);
  static const surfaceContainerHigh   = Color(0xFFE4E9ED);

  // Dark mode — warm charcoal with indigo tint
  static const surfaceDark              = Color(0xFF111318);
  static const surfaceContainerLowDk    = Color(0xFF191C23);
  static const surfaceContainerLowestDk = Color(0xFF1E2128);
  static const surfaceContainerDk       = Color(0xFF232730);
  static const surfaceContainerHighDk   = Color(0xFF2A2E38);

  // ── TEXT ──────────────────────────────────────────
  static const onSurface          = Color(0xFF171C1F);
  static const onSurfaceVariant   = Color(0xFF454652);
  static const onSurfaceDark      = Color(0xFFE2E8F0);
  static const onSurfaceVariantDk = Color(0xFF9AA5B4);

  // Outline — "Ghost Border" rule: felt not seen
  static const outlineVariant = Color(0x26C5C5D4); // 15% opacity of #C5C5D4

  // Surface tint — 5% for large bg areas
  static const surfaceTint = Color(0xFF4555B7);

  // ── SEMANTIC ─────────────────────────────────────
  static const error            = Color(0xFFBA1A1A);
  static const errorContainer   = Color(0xFFFFDAD6);
  static const success          = Color(0xFF006846);
  static const successContainer = Color(0xFF89F8C7);
  static const warning          = Color(0xFF7B5800);
  static const warningContainer = Color(0xFFFFDEA0);

  // ── PRIORITY ─────────────────────────────────────
  static const priorityNone   = Color(0xFF94A3B8);
  static const priorityLow    = Color(0xFF22C55E);
  static const priorityMedium = Color(0xFFF59E0B);
  static const priorityHigh   = Color(0xFFEF4444);
  static const priorityUrgent = Color(0xFFEC4899);

  // ── XP / ACHIEVEMENT ─────────────────────────────
  static const xpGold   = Color(0xFFFFD60A);
  static const xpSilver = Color(0xFFC0C0C0);
  static const xpBronze = Color(0xFFCD7F32);

  // ── GRADIENTS ────────────────────────────────────
  static const gradientPrimary = LinearGradient(
    colors: [Color(0xFF27389A), Color(0xFF4151B3)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientMomentum = LinearGradient(
    colors: [Color(0xFF27389A), Color(0xFF3D4FC4)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientSuccess = LinearGradient(
    colors: [Color(0xFF004E33), Color(0xFF006846)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientWarm = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const gradientCool = LinearGradient(
    colors: [Color(0xFF27389A), Color(0xFF6366F1)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  // ── PRIORITY COLOR HELPER ────────────────────────
  static Color priorityColor(Priority p, {bool isDark = false}) {
    switch (p) {
      case Priority.none:   return priorityNone;
      case Priority.low:    return priorityLow;
      case Priority.medium: return priorityMedium;
      case Priority.high:   return priorityHigh;
      case Priority.urgent: return priorityUrgent;
    }
  }

  // ── AMBIENT SHADOW — never pure black ────────────
  static List<BoxShadow> ambientShadow({
    double opacity = 0.06,
    double blur = 40,
    double spread = 0,
    Offset offset = const Offset(0, 20),
  }) => [
    BoxShadow(
      color: const Color(0xFF171C1F).withValues(alpha: opacity),
      blurRadius: blur,
      spreadRadius: spread,
      offset: offset,
    ),
  ];

  // ── GHOST BORDER — 15% opacity, felt not seen ────
  static Border ghostBorder({
    double width = 1,
    bool isDark = false,
  }) => Border.all(
    color: isDark
        ? Colors.white.withValues(alpha: 0.08)
        : const Color(0xFFC5C5D4).withValues(alpha: 0.15),
    width: width,
  );

  // ── BACKWARD COMPATIBILITY ALIASES ───────────────
  static const background = surfaceLight;
  static const surface    = surfaceContainerLowest;
  static const border     = outlineVariant;
  static const textPrimary = onSurface;
  static const textMuted   = onSurfaceVariant;
  static const accent      = primary;

  static const danger = error;
  static const red    = error;
  static const orange = warning;
  static const green  = success;
  static const blue   = Color(0xFF3B82F6);
  static const purple = Color(0xFF8B5CF6);
  static const pink   = Color(0xFFEC4899);
  static const teal   = Color(0xFF14B8A6);
  static const indigo = Color(0xFF6366F1);

  static const canvasLight = surfaceLight;
  static const surfaceLight_  = surfaceContainerLowest; // avoid conflict
  static const textPrimaryLight = onSurface;
  static const textSecondaryLight = onSurfaceVariant;
  static const textTertiaryLight = onSurfaceVariant;
  static const dividerLight = outlineVariant;

  static const canvasDark = surfaceDark;
  static const textPrimaryDark = onSurfaceDark;
  static const textSecondaryDark = onSurfaceVariantDk;
  static const textTertiaryDark = onSurfaceVariantDk;
  static const dividerDark = Color(0xFF2A2E38);

  static const gradientBlue = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
  );

  /// Legacy helper — delegates to new priorityColor
  static Color getPriorityColor(Priority p) => priorityColor(p);

  static Color glassBackground(bool isDark) {
    return isDark
        ? const Color(0x99111318)
        : const Color(0xB3F6FAFE);
  }

  static BoxDecoration elevatedDecoration({
    required bool isDark,
    double borderRadius = 12,
  }) {
    return BoxDecoration(
      color: isDark ? surfaceContainerLowestDk : surfaceContainerLowest,
      borderRadius: BorderRadius.circular(borderRadius),
      border: ghostBorder(isDark: isDark),
      boxShadow: ambientShadow(
        opacity: isDark ? 0.20 : 0.06,
        blur: 12,
        offset: const Offset(0, 4),
      ),
    );
  }
}
