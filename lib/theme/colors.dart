import 'package:flutter/material.dart';
import '../models/task.dart';

class AppColors {
  AppColors._();

  // ── LIGHT MODE — warm cream paper ─────────────────────────────
  static const canvasLight          = Color(0xFFFAF9F7);
  static const surfaceLight         = Color(0xFFFFFFFF);
  static const surfaceElevatedLight = Color(0xFFF5F4F1);
  static const sidebarLight         = Color(0xFFF0EDE8);

  // ── DARK MODE — rich charcoal, warm undertones ────────────────
  static const canvasDark           = Color(0xFF1A1917);
  static const surfaceDark          = Color(0xFF242220);
  static const surfaceElevatedDark  = Color(0xFF2E2B28);
  static const sidebarDark          = Color(0xFF1E1C1A);

  // ── PRIMARY ACCENT — indigo/violet ────────────────────────────
  static const primary      = Color(0xFF6366F1);
  static const primaryLight = Color(0xFF818CF8);
  static const primaryDark  = Color(0xFF4F46E5);

  // ── VIBRANT ACCENT SYSTEM ─────────────────────────────────────
  static const blue    = Color(0xFF3B82F6);
  static const indigo  = Color(0xFF6366F1);
  static const purple  = Color(0xFF8B5CF6);
  static const pink    = Color(0xFFEC4899);
  static const red     = Color(0xFFEF4444);
  static const orange  = Color(0xFFF59E0B);
  static const yellow  = Color(0xFFFCD34D);
  static const green   = Color(0xFF22C55E);
  static const teal    = Color(0xFF14B8A6);
  static const cyan    = Color(0xFF06B6D4);
  static const pinkRed = Color(0xFFEC4899);

  // ── SEMANTIC COLORS ───────────────────────────────────────────
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger  = Color(0xFFEF4444);
  static const info    = Color(0xFF3B82F6);

  // ── PRIORITY COLORS — bold and instantly distinct ─────────────
  static Color priorityNone(bool isDark) =>
      isDark ? const Color(0xFF3A3F50) : const Color(0xFF94A3B8);
  static const priorityLow    = Color(0xFF22C55E);
  static const priorityMedium = Color(0xFFF59E0B);
  static const priorityHigh   = Color(0xFFEF4444);
  static const priorityUrgent = Color(0xFFEC4899);

  // ── GRADIENT LIBRARY ──────────────────────────────────────────
  static const gradientPrimary = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const gradientWarm = LinearGradient(
    colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const gradientCool = LinearGradient(
    colors: [Color(0xFF3B82F6), Color(0xFF6366F1)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  static const gradientSuccess = LinearGradient(
    colors: [Color(0xFF10B981), Color(0xFF059669)],
    begin: Alignment.topLeft, end: Alignment.bottomRight,
  );
  // Legacy aliases
  static const gradientBlue = gradientPrimary;

  // Priority gradients for card covers
  static LinearGradient priorityGradient(Priority p, bool isDark) {
    switch (p) {
      case Priority.none:
        return isDark
            ? const LinearGradient(colors: [Color(0xFF2E2B28), Color(0xFF242220)])
            : const LinearGradient(colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1)]);
      case Priority.low:
        return const LinearGradient(
          colors: [Color(0xFF86EFAC), Color(0xFF34D399)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        );
      case Priority.medium:
        return const LinearGradient(
          colors: [Color(0xFFFCD34D), Color(0xFFF59E0B)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        );
      case Priority.high:
        return const LinearGradient(
          colors: [Color(0xFFFCA5A5), Color(0xFFEF4444)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        );
      case Priority.urgent:
        return const LinearGradient(
          colors: [Color(0xFFF9A8D4), Color(0xFFEC4899)],
          begin: Alignment.topLeft, end: Alignment.bottomRight,
        );
    }
  }

  // ── TEXT COLORS ───────────────────────────────────────────────
  static const textPrimaryLight    = Color(0xFF1A1917);
  static const textSecondaryLight  = Color(0xFF57534E);
  static const textTertiaryLight   = Color(0xFF9CA3AF);
  static const textQuaternaryLight = Color(0xFFD1D5DB);

  static const textPrimaryDark     = Color(0xFFF5F5F4);
  static const textSecondaryDark   = Color(0xFFA8A29E);
  static const textTertiaryDark    = Color(0xFF6B7280);
  static const textQuaternaryDark  = Color(0xFF4B5563);

  // ── STRUCTURAL ────────────────────────────────────────────────
  static const dividerLight = Color(0x1A292524);
  static const dividerDark  = Color(0x1AF5F5F4);

  // ── DECORATION HELPERS ────────────────────────────────────────
  static BoxDecoration elevatedDecoration({
    required bool isDark,
    double borderRadius = 12,
    Color? tint,
  }) {
    return BoxDecoration(
      color: tint ?? (isDark ? surfaceElevatedDark : Colors.white),
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isDark
            ? Colors.white.withValues(alpha: 0.06)
            : Colors.black.withValues(alpha: 0.06),
        width: 0.75,
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }
}
