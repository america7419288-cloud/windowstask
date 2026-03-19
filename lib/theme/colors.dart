import 'package:flutter/material.dart';
import '../models/task.dart';

class AppColors {
  AppColors._();

  // ── NEW COLOR SYSTEM ──────────────────────────────────────────
  static const background = Color(0xFFF9F9FB);
  static const surface    = Color(0xFFFFFFFF);
  static const border     = Color(0xFFE5E7EB);
  
  static const textPrimary = Color(0xFF111827);
  static const textMuted   = Color(0xFF6B7280);
  
  static const accent = Color(0xFF7C3AED); // Default accent
  static const danger = Color(0xFFEF4444);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);

  // ── PRIORITY COLORS ───────────────────────────────────────────
  static const priorityHigh   = Color(0xFFEF4444);
  static const priorityMedium = Color(0xFFF59E0B);
  static const priorityLow    = Color(0xFF3B82F6);
  static const priorityNone   = Colors.transparent;

  // ── LEGACY DEALS (to be removed or refactored) ────────────────
  static const canvasLight = background;
  static const surfaceLight = surface;
  static const textPrimaryLight = textPrimary;
  static const textSecondaryLight = textMuted;
  static const dividerLight = border;

  static const canvasDark = Color(0xFF111827); // Dark mode counterpart
  static const surfaceDark = Color(0xFF1F2937);
  static const textPrimaryDark = Color(0xFFF9FAFB);
  static const textSecondaryDark = Color(0xFF9CA3AF);
  static const dividerDark = Color(0xFF374151);

  // ── BACKWARD COMPATIBILITY ALIASES ───────────────────────────
  static const primary         = accent;
  static const blue            = Color(0xFF3B82F6);
  static const purple          = Color(0xFF8B5CF6);
  static const pink            = Color(0xFFEC4899);
  static const red             = danger;
  static const orange          = warning;
  static const green           = success;
  static const teal            = Color(0xFF14B8A6);
  static const indigo          = Color(0xFF6366F1);
  static const gradientPrimary = LinearGradient(colors: [accent, purple]);
  static const gradientBlue    = LinearGradient(colors: [Color(0xFF3B82F6), Color(0xFF2563EB)]);
  
  static const textTertiaryLight = Color(0xFF9CA3AF);
  static const textTertiaryDark  = Color(0xFF6B7280);

  static const priorityUrgent = priorityHigh;

  // Helper for Priority Colors
  static Color getPriorityColor(Priority p) {
    switch (p) {
      case Priority.high: return priorityHigh;
      case Priority.medium: return priorityMedium;
      case Priority.low: return priorityLow;
      case Priority.none: return priorityNone;
      case Priority.urgent: return priorityHigh; // Mapping urgent to high for now
    }
  }

  static BoxDecoration elevatedDecoration({
    required bool isDark,
    double borderRadius = 12,
  }) {
    return BoxDecoration(
      color: isDark ? surfaceDark : surface,
      borderRadius: BorderRadius.circular(borderRadius),
      border: Border.all(
        color: isDark ? dividerDark : border,
        width: 1.0,
      ),
      boxShadow: [
        const BoxShadow(
          color: Color(0x14000000), // 0.08 opacity black
          blurRadius: 3,
          offset: Offset(0, 1),
        ),
        const BoxShadow(
          color: Color(0x0A000000), // 0.04 opacity black
          blurRadius: 12,
          offset: Offset(0, 4),
        ),
      ],
    );
  }
}
