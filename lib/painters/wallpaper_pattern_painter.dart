import 'package:flutter/material.dart';
import 'dart:math' as math;

class WallpaperPatternPainter extends CustomPainter {
  final String patternId;
  final Color color;

  const WallpaperPatternPainter({
    required this.patternId,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    switch (patternId) {
      case 'dots':
        _drawDots(canvas, size, paint..style = PaintingStyle.fill);
        break;
      case 'grid':
        _drawGrid(canvas, size, paint);
        break;
      case 'diagonal':
        _drawDiagonal(canvas, size, paint);
        break;
      case 'waves':
        _drawWaves(canvas, size, paint);
        break;
      case 'hexagon':
        _drawHexagons(canvas, size, paint);
        break;
      case 'crosshatch':
        _drawCrosshatch(canvas, size, paint);
        break;
    }
  }

  void _drawDots(Canvas canvas, Size size, Paint paint) {
    const spacing = 24.0;
    const radius = 2.0;
    for (double x = spacing / 2; x < size.width; x += spacing) {
      for (double y = spacing / 2; y < size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), radius, paint);
      }
    }
  }

  void _drawGrid(Canvas canvas, Size size, Paint paint) {
    const spacing = 32.0;
    for (double x = 0; x < size.width; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  void _drawDiagonal(Canvas canvas, Size size, Paint paint) {
    const spacing = 20.0;
    final diagonal = size.width + size.height;
    for (double offset = -size.height; offset < size.width; offset += spacing) {
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset + diagonal, diagonal),
        paint,
      );
    }
  }

  void _drawWaves(Canvas canvas, Size size, Paint paint) {
    const amplitude = 12.0;
    const frequency = 0.04;
    const verticalSpacing = 32.0;

    for (double yBase = 0; yBase < size.height + verticalSpacing; yBase += verticalSpacing) {
      final path = Path();
      bool started = false;
      for (double x = 0; x <= size.width; x++) {
        final y = yBase + amplitude * math.sin(x * frequency);
        if (!started) {
          path.moveTo(x, y);
          started = true;
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(path, paint);
    }
  }

  void _drawHexagons(Canvas canvas, Size size, Paint paint) {
    const hexSize = 20.0;
    const w = hexSize * 2;
    const h = hexSize * 1.732050808;

    for (double row = -1; row < size.height / h + 1; row++) {
      for (double col = -1; col < size.width / w + 1; col++) {
        final xOffset = row.toInt().isOdd ? w * 0.75 : 0.0;
        final cx = col * w * 1.5 + xOffset;
        final cy = row * h;
        _drawHexagon(canvas, Offset(cx, cy), hexSize, paint);
      }
    }
  }

  void _drawHexagon(Canvas canvas, Offset center, double size, Paint paint) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = math.pi / 3 * i - math.pi / 6;
      final x = center.dx + size * math.cos(angle);
      final y = center.dy + size * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  void _drawCrosshatch(Canvas canvas, Size size, Paint paint) {
    const spacing = 20.0;
    final diagonal = size.width + size.height;
    // First set: top-left to bottom-right
    for (double offset = -size.height; offset < size.width; offset += spacing) {
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset + diagonal, diagonal),
        paint,
      );
    }
    // Second set: top-right to bottom-left
    for (double offset = 0; offset < size.width + size.height; offset += spacing) {
      canvas.drawLine(
        Offset(offset, 0),
        Offset(offset - diagonal, diagonal),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(WallpaperPatternPainter oldDelegate) =>
      oldDelegate.patternId != patternId || oldDelegate.color != color;
}


