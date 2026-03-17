import 'package:flutter/material.dart';

class WallpaperPresets {
  WallpaperPresets._();

  static const Map<String, LinearGradient> gradients = {
    'aurora': LinearGradient(
      colors: [Color(0xFF00C9FF), Color(0xFF92FE9D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'sunset': LinearGradient(
      colors: [Color(0xFFFF6B6B), Color(0xFFFFE66D)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'ocean': LinearGradient(
      colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'lavender': LinearGradient(
      colors: [Color(0xFFA18CD1), Color(0xFFFBC2EB)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'forest': LinearGradient(
      colors: [Color(0xFF134E5E), Color(0xFF71B280)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'peach': LinearGradient(
      colors: [Color(0xFFFFD89B), Color(0xFF19547B)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'midnight': LinearGradient(
      colors: [Color(0xFF232526), Color(0xFF414345)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    'rose': LinearGradient(
      colors: [Color(0xFFf953c6), Color(0xFFb91d73)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  };

  static const List<String> gradientIds = [
    'aurora', 'sunset', 'ocean', 'lavender', 'forest', 'peach', 'midnight', 'rose'
  ];

  static const List<String> patternIds = [
    'dots', 'grid', 'diagonal', 'waves', 'hexagon', 'crosshatch'
  ];

  static const Map<String, String> patternLabels = {
    'dots': 'Dots',
    'grid': 'Grid',
    'diagonal': 'Diagonal',
    'waves': 'Waves',
    'hexagon': 'Hexagon',
    'crosshatch': 'Crosshatch',
  };

  static const Map<String, String> gradientLabels = {
    'aurora': 'Aurora',
    'sunset': 'Sunset',
    'ocean': 'Ocean',
    'lavender': 'Lavender',
    'forest': 'Forest',
    'peach': 'Peach',
    'midnight': 'Midnight',
    'rose': 'Rose',
  };
}
