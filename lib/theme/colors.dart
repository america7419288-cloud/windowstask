import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Core background & structural colors
  static const canvasLight = Color(0xFFF2F2F7);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceElevatedLight = Color(0xFFF8F8FC);
  static const sidebarLight = Color(0xFFEEEEF3);

  static const canvasDark = Color(0xFF0C0C0E);
  static const surfaceDark = Color(0xFF1C1C1E);
  static const surfaceElevatedDark = Color(0xFF2C2C2E);
  static const sidebarDark = Color(0xFF161618);

  // Accent System
  static const blue = Color(0xFF007AFF);
  static const indigo = Color(0xFF5856D6);
  static const purple = Color(0xFFAF52DE);
  static const green = Color(0xFF34C759);
  static const orange = Color(0xFFFF9500);
  static const red = Color(0xFFFF3B30);
  static const pinkRed = Color(0xFFFF2D55); // Urgent
  static const teal = Color(0xFF5AC8FA);

  // Text Colors
  static const textPrimaryLight = Color(0xFF1C1C1E);
  static const textSecondaryLight = Color(0xFF48484A);
  static const textTertiaryLight = Color(0xFF8E8E93);
  static const textQuaternaryLight = Color(0xFFC7C7CC);

  static const textPrimaryDark = Color(0xFFF2F2F7);
  static const textSecondaryDark = Color(0x99EBEBF5); // 60%
  static const textTertiaryDark = Color(0x66EBEBF5);   // 40%
  static const textQuaternaryDark = Color(0x40EBEBF5); // 25%

  // Functional Colors
  static const dividerLight = Color(0x19000000); // 10% black
  static const dividerDark = Color(0x26FFFFFF);  // 15% white

  static LinearGradient cardGradientLight() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFFFFFF), Color(0xFFFAFAFD)],
    );
  }

  static LinearGradient cardGradientDark() {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF2C2C2E), Color(0xFF262628)],
    );
  }
}
