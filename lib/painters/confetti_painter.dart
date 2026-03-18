import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/colors.dart';

class ConfettiParticle {
  final double angle;
  final double distance;
  final double size;
  final Color color;
  final double rotationSpin;

  ConfettiParticle({
    required this.angle,
    required this.distance,
    required this.size,
    required this.color,
    required this.rotationSpin,
  });
}

class ConfettiOverlay {
  static void show(BuildContext context, Offset globalTapPosition) {
    final overlayState = Overlay.of(context);
    late OverlayEntry entry;

    entry = OverlayEntry(
      builder: (context) {
        return _ConfettiAnimationWidget(
          position: globalTapPosition,
          onComplete: () => entry.remove(),
        );
      },
    );

    overlayState.insert(entry);
  }
}

class _ConfettiAnimationWidget extends StatefulWidget {
  final Offset position;
  final VoidCallback onComplete;

  const _ConfettiAnimationWidget({required this.position, required this.onComplete});

  @override
  State<_ConfettiAnimationWidget> createState() => _ConfettiAnimationWidgetState();
}

class _ConfettiAnimationWidgetState extends State<_ConfettiAnimationWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late List<ConfettiParticle> _particles;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    final random = math.Random();
    final colors = [
      AppColors.blue, AppColors.indigo, AppColors.purple,
      AppColors.green, AppColors.orange, AppColors.pink, AppColors.teal
    ];

    _particles = List.generate(6, (index) {
      return ConfettiParticle(
        angle: random.nextDouble() * math.pi * 2,
        distance: 20 + random.nextDouble() * 20, // 20 to 40px
        size: 4 + random.nextDouble() * 4,       // 4 to 8px
        color: colors[random.nextInt(colors.length)],
        rotationSpin: random.nextDouble() * math.pi * 4,
      );
    });

    _controller.forward().then((_) => widget.onComplete());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: _ConfettiPainter(
                particles: _particles,
                progress: Curves.easeOutCubic.transform(_controller.value),
                center: widget.position,
                opacity: 1.0 - Curves.easeInQuad.transform(_controller.value),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ConfettiPainter extends CustomPainter {
  final List<ConfettiParticle> particles;
  final double progress;
  final Offset center;
  final double opacity;

  _ConfettiPainter({
    required this.particles,
    required this.progress,
    required this.center,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (opacity <= 0) return;

    for (var particle in particles) {
      final currentDistance = particle.distance * progress;
      final dx = center.dx + math.cos(particle.angle) * currentDistance;
      final dy = center.dy + math.sin(particle.angle) * currentDistance;

      canvas.save();
      canvas.translate(dx, dy);
      canvas.rotate(particle.rotationSpin * progress);

      final paint = Paint()
        ..color = particle.color.withValues(alpha: opacity)
        ..style = PaintingStyle.fill;

      canvas.drawRect(
        Rect.fromCenter(center: Offset.zero, width: particle.size, height: particle.size),
        paint,
      );
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) => true;
}
