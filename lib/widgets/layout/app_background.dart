import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../../theme/wallpaper_presets.dart';
import '../../painters/wallpaper_pattern_painter.dart';
import '../../theme/colors.dart';

class AppBackground extends StatelessWidget {
  final Widget child;
  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final wallType = settings.settings.wallpaperType;

    // No wallpaper — zero overhead, render child directly
    if (wallType == WallpaperType.none) return child;

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final brightness = settings.wallpaperBrightness;

    // Dim overlay opacity:
    // brightness 1.0 → overlay 0.45 (wallpaper visible but content readable)
    // brightness 0.3 → overlay 0.75 (wallpaper heavily dimmed)
    final overlayOpacity = (1.0 - brightness).clamp(0.45, 0.75);

    return Stack(
      children: [
        // Layer 1: The wallpaper itself with RepaintBoundary
        // We use RepaintBoundary to isolate the complex wallpaper/dimming layers
        // from frequent content repaints (like checkbox animations).
        Positioned.fill(
          child: RepaintBoundary(
            child: Stack(
              children: [
                Positioned.fill(
                  child: _buildWallpaper(context, settings, isDark),
                ),
                Positioned.fill(
                  child: Container(
                    color: (isDark ? AppColors.canvasDark : AppColors.canvasLight)
                        .withValues(alpha: overlayOpacity),
                  ),
                ),
              ],
            ),
          ),
        ),

        // Layer 2: Main Content — fully on top
        Positioned.fill(child: child),
      ],
    );
  }

  Widget _buildWallpaper(
      BuildContext context, SettingsProvider s, bool isDark) {
    final wallType = s.settings.wallpaperType;

    switch (wallType) {
      case WallpaperType.solidColor:
        final hex = s.settings.wallpaperColorHex ?? 'CCCCCC';
        Color c;
        try {
          c = Color(int.parse('FF$hex', radix: 16));
        } catch (_) {
          c = Colors.grey;
        }
        return Container(color: c);

      case WallpaperType.gradient:
        final gradId = s.settings.wallpaperGradientId ?? 'aurora';
        final gradient = WallpaperPresets.gradients[gradId] ??
            WallpaperPresets.gradients['aurora']!;
        return Container(decoration: BoxDecoration(gradient: gradient));

      case WallpaperType.pattern:
        final patternId = s.settings.wallpaperPatternId ?? 'dots';
        final patternColor = Theme.of(context).colorScheme.primary;
        return CustomPaint(
          painter: WallpaperPatternPainter(
            patternId: patternId,
            color: patternColor,
          ),
          child: const SizedBox.expand(),
        );

      case WallpaperType.customImage:
        final path = s.settings.wallpaperImagePath;
        if (path == null) return const SizedBox.shrink();

        if (kIsWeb) {
          return const SizedBox.shrink(); 
        } else {
          final file = File(path);
          if (!file.existsSync()) return const SizedBox.shrink();
          return Image.file(
            file,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          );
        }

      case WallpaperType.none:
        return const SizedBox.shrink();
    }
  }
}
