import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import '../../theme/springs.dart';

class PressableScale extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scaleDown;
  final HitTestBehavior behavior;

  const PressableScale({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.scaleDown = 0.96,
    this.behavior = HitTestBehavior.opaque,
  });

  @override
  State<PressableScale> createState() => _PressableScaleState();
}

class _PressableScaleState extends State<PressableScale> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, value: 1.0, lowerBound: 0.0, upperBound: 1.0);
  }

  void _animateTo(double target) {
    if (!mounted) return;
    final simulation = SpringSimulation(
        AppSprings.snappy, _controller.value, target, _controller.velocity);
    _controller.animateWith(simulation);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: widget.behavior,
      onTapDown: (_) => _animateTo(widget.scaleDown),
      onTapUp: (_) {
        _animateTo(1.0);
        if (widget.onTap != null) widget.onTap!();
      },
      onTapCancel: () => _animateTo(1.0),
      onLongPress: widget.onLongPress,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) => Transform.scale(
          scale: _controller.value,
          alignment: Alignment.center,
          child: child,
        ),
        child: widget.child,
      ),
    );
  }
}
