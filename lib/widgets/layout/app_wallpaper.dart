import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../../theme/wallpaper_presets.dart';
import '../../painters/wallpaper_pattern_painter.dart';
import '../../theme/colors.dart';

class AppWallpaper extends StatelessWidget {
  final Widget child;
  const AppWallpaper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final wallType = settings.settings.wallpaperType;

    // No wallpaper — render child directly, zero overhead
    if (wallType == WallpaperType.none) {
      return child;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final opacity = settings.settings.wallpaperOpacity.clamp(0.05, 0.40);

    return Stack(
      children: [
        // Layer 1: The wallpaper itself at full size
        Positioned.fill(
          child: _buildWallpaper(context, settings),
        ),

        // Layer 2: Semi-opaque surface overlay so content remains readable.
        // This is the KEY layer — it sits between the wallpaper and the
        // content, muting the wallpaper to a subtle background effect.
        Positioned.fill(
          child: Container(
            color: isDark
                ? AppColors.canvasDark.withValues(alpha: 1.0 - opacity)
                : AppColors.canvasLight.withValues(alpha: 1.0 - opacity),
          ),
        ),

        // Layer 3: All app content — fully visible on top
        Positioned.fill(
          child: child,
        ),
      ],
    );
  }

  Widget _buildWallpaper(BuildContext context, SettingsProvider s) {
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
        return Container(
          decoration: BoxDecoration(gradient: gradient),
        );

      case WallpaperType.pattern:
        final patternId = s.settings.wallpaperPatternId ?? 'dots';
        return CustomPaint(
          painter: WallpaperPatternPainter(
            patternId: patternId,
            color: Theme.of(context).colorScheme.primary,
          ),
          child: const SizedBox.expand(),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}
