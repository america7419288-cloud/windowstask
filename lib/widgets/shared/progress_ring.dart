import 'package:flutter/material.dart';

class ProgressRing extends StatelessWidget {
  final double value; // 0.0 to 1.0
  final double size;
  final double strokeWidth;
  final Color? color;
  final Color? backgroundColor;

  const ProgressRing({
    super.key,
    required this.value,
    this.size = 40,
    this.strokeWidth = 4,
    this.color,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final accent = color ?? theme.colorScheme.primary;
    final bg = backgroundColor ?? accent.withValues(alpha: 0.12);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          // Background circle
          Center(
            child: SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: 1.0,
                strokeWidth: strokeWidth,
                color: bg,
              ),
            ),
          ),
          // Foreground progress
          Center(
            child: SizedBox(
              width: size,
              height: size,
              child: CircularProgressIndicator(
                value: value,
                strokeWidth: strokeWidth,
                color: accent,
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
