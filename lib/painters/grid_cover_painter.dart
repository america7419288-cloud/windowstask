import 'dart:math' show sin;
import 'package:flutter/material.dart';

class GridCoverPainter extends CustomPainter {
  final String taskId;   // seed for deterministic randomness
  final Color baseColor; // derived from priority color

  GridCoverPainter({required this.taskId, required this.baseColor});

  @override
  void paint(Canvas canvas, Size size) {
    // Use taskId hashCode as seed so same task always shows same pattern
    final seed = taskId.hashCode;
    final r = _SeededRandom(seed);

    final paint = Paint()
      ..color = baseColor.withValues(alpha: 0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final fillPaint = Paint()
      ..color = baseColor.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;

    // Pick one of 4 illustration styles based on seed % 4
    final style = seed.abs() % 4;

    switch (style) {
      case 0: _drawCircles(canvas, size, r, paint, fillPaint); break;
      case 1: _drawGeometric(canvas, size, r, paint, fillPaint); break;
      case 2: _drawWaves(canvas, size, r, paint); break;
      case 3: _drawDots(canvas, size, r, fillPaint); break;
    }
  }

  // Style 0: 3-5 overlapping circles of varying sizes
  void _drawCircles(Canvas c, Size s, _SeededRandom r, Paint stroke, Paint fill) {
    for (int i = 0; i < 4; i++) {
      final cx = r.nextDouble() * s.width;
      final cy = r.nextDouble() * s.height;
      final radius = 20 + r.nextDouble() * 40;
      c.drawCircle(Offset(cx, cy), radius, fill);
      c.drawCircle(Offset(cx, cy), radius, stroke);
    }
  }

  // Style 1: 2-3 rotated rectangles/diamonds
  void _drawGeometric(Canvas c, Size s, _SeededRandom r, Paint stroke, Paint fill) {
    for (int i = 0; i < 3; i++) {
      final cx = r.nextDouble() * s.width;
      final cy = r.nextDouble() * s.height;
      final size2 = 24 + r.nextDouble() * 32;
      final angle = r.nextDouble() * 3.14159 / 2;
      c.save();
      c.translate(cx, cy);
      c.rotate(angle);
      final rect = Rect.fromCenter(center: Offset.zero, width: size2, height: size2);
      c.drawRect(rect, fill);
      c.drawRect(rect, stroke);
      c.restore();
    }
  }

  // Style 2: horizontal sine waves
  void _drawWaves(Canvas c, Size s, _SeededRandom r, Paint stroke) {
    for (int w = 0; w < 3; w++) {
      final path = Path();
      final yBase = s.height * (0.25 + w * 0.25);
      final amp = 8 + r.nextDouble() * 12;
      final freq = 0.03 + r.nextDouble() * 0.02;
      path.moveTo(0, yBase);
      for (double x = 0; x <= s.width; x++) {
        path.lineTo(x, yBase + amp * sin(x * freq));
      }
      c.drawPath(path, stroke);
    }
  }

  // Style 3: grid of small dots
  void _drawDots(Canvas c, Size s, _SeededRandom r, Paint fill) {
    const spacing = 14.0;
    for (double x = spacing; x < s.width; x += spacing) {
      for (double y = spacing; y < s.height; y += spacing) {
        if (r.nextDouble() > 0.35) {
          c.drawCircle(Offset(x, y), 2.5, fill);
        }
      }
    }
  }

  @override
  bool shouldRepaint(GridCoverPainter old) => old.taskId != taskId;
}

// Deterministic pseudo-random from seed
class _SeededRandom {
  int _seed;
  _SeededRandom(this._seed);

  double nextDouble() {
    _seed = (_seed * 1664525 + 1013904223) & 0xFFFFFFFF;
    return (_seed & 0x7FFFFFFF) / 0x7FFFFFFF;
  }
}
