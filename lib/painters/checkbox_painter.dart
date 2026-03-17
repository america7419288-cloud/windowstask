import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class CheckboxPainter extends CustomPainter {
  final double progress;
  final bool isHovered;

  CheckboxPainter({required this.progress, required this.isHovered});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // The baseline stroke color
    final baseStrokeColor = AppColors.textTertiaryLight.withOpacity(0.5);
    // Interpolate towards green when hovered or when animating fill
    final strokeColor = Color.lerp(
      baseStrokeColor,
      AppColors.green,
      math.max(isHovered ? 1.0 : 0.0, progress * 2), // Green kicks in early in progress
    )!;

    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = strokeColor;

    canvas.drawCircle(center, radius - 0.75, borderPaint);

    // Green fill sweep (step 1: from 0.0 -> 0.5)
    if (progress > 0) {
      final fillPaint = Paint()
        ..style = PaintingStyle.fill
        ..color = AppColors.green;

      final sweepProgress = (progress * 2).clamp(0.0, 1.0);
      final startAngle = -math.pi / 2; // Start from top
      final sweepAngle = math.pi * 2 * sweepProgress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        true,
        fillPaint,
      );
    }

    // Checkmark draw (step 2: from 0.5 -> 1.0)
    if (progress > 0.5) {
      final tickProgress = ((progress - 0.5) * 2).clamp(0.0, 1.0);

      final checkPath = Path();
      // Precise tick coordinates for a satisfying checkmark within the circle
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
    return progress != oldDelegate.progress || isHovered != oldDelegate.isHovered;
  }
}
