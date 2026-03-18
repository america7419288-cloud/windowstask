import 'package:flutter/material.dart';
import '../../../painters/checkbox_painter.dart';

class CustomCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool?> onChanged;
  final Color activeColor;
  final double size;

  const CustomCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.activeColor,
    this.size = 20.0,
  });

  @override
  State<CustomCheckbox> createState() => _CustomCheckboxState();
}

class _CustomCheckboxState extends State<CustomCheckbox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
      reverseCurve: Curves.easeIn,
    );

    if (widget.value) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CustomCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () {
          widget.onChanged(!widget.value);
        },
        child: AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            // Apply a slight spring scale effect when hovered
            final scale = _isHovered && !widget.value ? 1.05 : 1.0;
            return Transform.scale(
              scale: scale,
              child: CustomPaint(
                size: Size(widget.size, widget.size),
                painter: CheckboxPainter(
                  progress: _animation.value,
                  isHovered: _isHovered,
                  accentColor: Theme.of(context).colorScheme.primary,
                  isDark: Theme.of(context).brightness == Brightness.dark,
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
