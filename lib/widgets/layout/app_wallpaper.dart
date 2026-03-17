import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/app_settings.dart';
import '../../providers/settings_provider.dart';
import '../../theme/wallpaper_presets.dart';
import '../../painters/wallpaper_pattern_painter.dart';

class AppWallpaper extends StatelessWidget {
  final Widget child;
  const AppWallpaper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final wallType = settings.settings.wallpaperType;

    if (wallType == WallpaperType.none) {
      return child;
    }

    return Stack(
      children: [
        // Layer 1: base background
        Positioned.fill(
          child: Container(color: Theme.of(context).colorScheme.surface),
        ),

        // Layer 2: wallpaper at low opacity
        Positioned.fill(
          child: Opacity(
            opacity: settings.settings.wallpaperOpacity.clamp(0.05, 0.40),
            child: _buildWallpaper(context, settings),
          ),
        ),

        // Layer 3: app content on top
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
