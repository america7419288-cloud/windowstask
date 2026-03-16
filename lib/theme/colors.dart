import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary Accent
  static const Color blue = Color(0xFF007AFF);
  static const Color green = Color(0xFF34C759);
  static const Color orange = Color(0xFFFF9500);
  static const Color red = Color(0xFFFF3B30);
  static const Color purple = Color(0xFFAF52DE);
  static const Color pink = Color(0xFFFF2D55);
  static const Color teal = Color(0xFF5AC8FA);

  // Light Mode
  static const Color lightBackground = Color(0xFFF5F5F7);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSidebar = Color(0xFFE8E8ED);
  static const Color lightTextPrimary = Color(0xFF1D1D1F);
  static const Color lightTextSecondary = Color(0xFF6E6E73);
  static const Color lightDivider = Color(0x14000000);
  static const Color lightBorder = Color(0x1A000000);

  // Dark Mode
  static const Color darkBackground = Color(0xFF1C1C1E);
  static const Color darkSurface = Color(0xFF2C2C2E);
  static const Color darkSidebar = Color(0xFF2C2C2E);
  static const Color darkTextPrimary = Color(0xFFF5F5F7);
  static const Color darkTextSecondary = Color(0xFF8E8E93);
  static const Color darkDivider = Color(0x1FFFFFFF);
  static const Color darkBorder = Color(0x1FFFFFFF);

  // Traffic Light
  static const Color trafficRed = Color(0xFFFF5F57);
  static const Color trafficYellow = Color(0xFFFFBC2E);
  static const Color trafficGreen = Color(0xFF28C840);

  // Priority Colors
  static const Color priorityNone = Color(0xFF8E8E93);
  static const Color priorityLow = Color(0xFF34C759);
  static const Color priorityMedium = Color(0xFFFF9500);
  static const Color priorityHigh = Color(0xFFFF3B30);
  static const Color priorityUrgent = Color(0xFFAF52DE);

  static List<Color> accentColors = [
    blue,
    purple,
    pink,
    red,
    orange,
    green,
    teal,
  ];
}
