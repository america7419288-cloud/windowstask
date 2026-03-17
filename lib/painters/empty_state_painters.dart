import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/colors.dart';

// ----- Painter for TODAY -----
class TodayEmptyPainter extends CustomPainter {
  final double animationValue;
  TodayEmptyPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = AppColors.orange.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    // A large soft circle (sun)
    canvas.drawCircle(center, size.width * 0.35, paint);

    // Radiating lines rotating slowly based on animationValue
    final linePaint = Paint()
      ..color = AppColors.orange.withOpacity(0.4)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    final baseRadius = size.width * 0.42;
    final outerRadius = size.width * 0.5;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(animationValue * math.pi * 2); // 0 to 2pi rotation

    for (int i = 0; i < 8; i++) {
      canvas.rotate((math.pi * 2) / 8);
      canvas.drawLine(Offset(0, -baseRadius), Offset(0, -outerRadius), linePaint);
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant TodayEmptyPainter oldDelegate) => oldDelegate.animationValue != animationValue;
}

// ----- Painter for UPCOMING -----
class UpcomingEmptyPainter extends CustomPainter {
  final double animationValue; // Controls a gentle pulse for one dot
  UpcomingEmptyPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final dotPaint = Paint()
      ..color = AppColors.textTertiaryLight.withOpacity(0.2)
      ..style = PaintingStyle.fill;
    
    // Pulse animation logic for a single blue highlighted dot
    final pulseScale = 1.0 + math.sin(animationValue * math.pi * 2) * 0.15;
    final bluePaint = Paint()
      ..color = AppColors.blue.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    final gridSize = size.width * 0.5;
    final startX = center.dx - gridSize / 2;
    final startY = center.dy - gridSize / 2;
    final step = gridSize / 3;

    for (int row = 0; row < 4; row++) {
      for (int col = 0; col < 4; col++) {
        final cx = startX + col * step;
        final cy = startY + row * step;
        
        // Highlight the second dot in the second row
        if (row == 1 && col == 1) {
          canvas.drawCircle(Offset(cx, cy), 5 * pulseScale, bluePaint);
        } else {
          canvas.drawCircle(Offset(cx, cy), 3, dotPaint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant UpcomingEmptyPainter oldDelegate) => oldDelegate.animationValue != animationValue;
}

// ----- Painter for ALL TASKS -----
class AllTasksEmptyPainter extends CustomPainter {
  final double animationValue; // Breathing scale (0 to 1)
  AllTasksEmptyPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    
    // Scale breathes from 0.98 to 1.02 over animationValue
    final scale = 0.98 + math.sin(animationValue * math.pi * 2) * 0.04;
    
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.scale(scale);

    void drawCard(double angle, Color color, double yOffset) {
      canvas.save();
      canvas.rotate(angle);
      final rrect = RRect.fromRectAndRadius(
        Rect.fromCenter(center: Offset(0, yOffset), width: size.width * 0.45, height: size.height * 0.25),
        const Radius.circular(8),
      );
      
      // Shadow
      canvas.drawRRect(rrect.shift(const Offset(0, 4)), Paint()
        ..color = Colors.black.withOpacity(0.04)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
      
      // Fill
      canvas.drawRRect(rrect, Paint()..color = color.withOpacity(0.15)..style = PaintingStyle.fill);
      // Stroke
      canvas.drawRRect(rrect, Paint()..color = color.withOpacity(0.4)..style = PaintingStyle.stroke..strokeWidth = 1.5);
      canvas.restore();
    }

    drawCard(-0.15, AppColors.orange, 10);
    drawCard(0.15, AppColors.teal, 5);
    drawCard(0, AppColors.blue, -10);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant AllTasksEmptyPainter oldDelegate) => oldDelegate.animationValue != animationValue;
}

// ----- Painter for SEARCH -----
class SearchEmptyPainter extends CustomPainter {
  final double animationValue; // Wobble rotation (-3 to +3 degrees)
  SearchEmptyPainter(this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final angle = math.sin(animationValue * math.pi * 2) * (3 * math.pi / 180);

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final linePaint = Paint()
      ..color = AppColors.textTertiaryLight.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final radius = size.width * 0.25;

    // Circle
    canvas.drawCircle(Offset.zero, radius, linePaint);
    
    // Magnifying glass handle
    canvas.drawLine(Offset(radius * 0.7, radius * 0.7), Offset(radius * 1.4, radius * 1.4), linePaint);
    
    // Prohibition line through it
    canvas.drawLine(Offset(-radius + 8, -radius + 8), Offset(radius - 8, radius - 8), linePaint);

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant SearchEmptyPainter oldDelegate) => oldDelegate.animationValue != animationValue;
}

// ----- Painter for COMPLETED -----
class CompletedEmptyPainter extends CustomPainter {
  final double admissionProgress; // 0 to 1 bouncy spring
  CompletedEmptyPainter(this.admissionProgress);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outlineRadius = size.width * 0.35;

    // Soft green circle background
    canvas.drawCircle(center, outlineRadius, Paint()
      ..color = AppColors.green.withOpacity(0.1)
      ..style = PaintingStyle.fill);

    // Rounded stroke green outline
    canvas.drawCircle(center, outlineRadius, Paint()
      ..color = AppColors.green.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0);

    // Checkmark draws itself based on admissionProgress
    if (admissionProgress > 0) {
      final checkPath = Path();
      // Relative points for checkmark
      final p1 = Offset(center.dx - outlineRadius * 0.4, center.dy + outlineRadius * 0.05);
      final p2 = Offset(center.dx - outlineRadius * 0.1, center.dy + outlineRadius * 0.35);
      final p3 = Offset(center.dx + outlineRadius * 0.45, center.dy - outlineRadius * 0.3);

      checkPath.moveTo(p1.dx, p1.dy);
      checkPath.lineTo(p2.dx, p2.dy);
      checkPath.lineTo(p3.dx, p3.dy);

      final metrics = checkPath.computeMetrics().first;
      final drawPath = metrics.extractPath(0, metrics.length * admissionProgress.clamp(0.0, 1.0));

      canvas.drawPath(drawPath, Paint()
        ..color = AppColors.green.withOpacity(0.8)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round);
    }
  }

  @override
  bool shouldRepaint(covariant CompletedEmptyPainter oldDelegate) => oldDelegate.admissionProgress != admissionProgress;
}
