import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';

class ShimmerCard extends StatefulWidget {
  const ShimmerCard({super.key});

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = context.appColors.isDark;
    final baseColor = isDark ? const Color(0xFF2C2C2E) : const Color(0xFFF2F2F7);
    final highlightColor = isDark ? const Color(0xFF3C3C3E) : const Color(0xFFFFFFFF);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      height: 72,
      decoration: BoxDecoration(
        color: baseColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: context.appColors.border, width: 0.5),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(13.5),
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return ShaderMask(
              blendMode: BlendMode.srcATop,
              shaderCallback: (bounds) {
                return LinearGradient(
                  colors: [baseColor, highlightColor, baseColor],
                  stops: const [0.0, 0.5, 1.0],
                  begin: const Alignment(-1.0, -0.3),
                  end: const Alignment(1.0, 0.3),
                  // Animate the gradient transform to sweep across
                  transform: _SlidingGradientTransform(_controller.value),
                ).createShader(bounds);
              },
              child: Container(color: baseColor),
            );
          },
        ),
      ),
    );
  }
}

class _SlidingGradientTransform extends GradientTransform {
  final double percent;
  const _SlidingGradientTransform(this.percent);

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // Sliding from -1.0 to 2.0 ensures it passes completely over the widget
    final w = bounds.width;
    final x = (percent * 3.0 - 1.0) * w;
    return Matrix4.translationValues(x, 0, 0);
  }
}
