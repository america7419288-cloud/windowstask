import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class CheckboxPainter extends CustomPainter {
  final double progress;
  final bool isHovered;
  final Color accentColor;
  final bool isDark;

  CheckboxPainter({
    required this.progress,
    required this.isHovered,
    required this.accentColor,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // The baseline stroke color
    final baseStrokeColor = isDark 
        ? Colors.white.withValues(alpha: 0.25)
        : Colors.black.withValues(alpha: 0.25);
    
    // Interpolate towards accent when hovered or when animating fill
    final strokeColor = Color.lerp(
      baseStrokeColor,
      accentColor,
      math.max(isHovered ? 1.0 : 0.0, progress * 2),
    )!;

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = strokeColor;

    canvas.drawCircle(center, radius - 0.75, borderPaint);

    // Accent fill sweep
    if (progress > 0) {
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = accentColor;

      final sweepProgress = (progress * 2).clamp(0.0, 1.0);
      final startAngle = -math.pi / 2;
      final sweepAngle = math.pi * 2 * sweepProgress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        fillPaint,
      );
    }

    // Checkmark draw
    if (progress > 0.5) {
      final tickProgress = ((progress - 0.5) * 2).clamp(0.0, 1.0);

      final checkPath = Path();
      final p1 = Offset(size.width * 0.28, size.height * 0.52);
      final p2 = Offset(size.width * 0.45, size.height * 0.68);
      final p3 = Offset(size.width * 0.72, size.height * 0.35);

      checkPath.moveTo(p1.dx, p1.dy);
      checkPath.lineTo(p2.dx, p2.dy);
      checkPath.lineTo(p3.dx, p3.dy);

      final metrics = checkPath.computeMetrics().first;
      final drawPath = metrics.extractPath(0, metrics.length * tickProgress);

      final tickPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = Colors.white;

      canvas.drawPath(drawPath, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CheckboxPainter oldDelegate) {
    return progress != oldDelegate.progress || 
           isHovered != oldDelegate.isHovered ||
           accentColor != oldDelegate.accentColor ||
           isDark != oldDelegate.isDark;
  }
}
