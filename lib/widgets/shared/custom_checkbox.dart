import 'package:flutter/material.dart';
import '../../painters/checkbox_painter.dart';
import 'pressable_scale.dart';

class CustomCheckbox extends StatefulWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const CustomCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  State<CustomCheckbox> createState() => _CustomCheckboxState();
}

class _CustomCheckboxState extends State<CustomCheckbox> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  bool _hovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      value: widget.value ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 350),
    );
  }

  @override
  void didUpdateWidget(CustomCheckbox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != oldWidget.value) {
      if (widget.value) {
        // When checking, animate forward with easing
        _controller.animateTo(1.0, curve: Curves.easeOutCubic);
      } else {
        // When unchecking, remove checkmark fast
        _controller.animateTo(0.0, duration: const Duration(milliseconds: 150));
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
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: widget.onChanged != null ? SystemMouseCursors.click : MouseCursor.defer,
      child: PressableScale(
        onTap: widget.onChanged != null
            ? () => widget.onChanged!(!widget.value)
            : null,
        child: SizedBox(
          width: 22,
          height: 22,
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return CustomPaint(
                painter: CheckboxPainter(
                  progress: _controller.value,
                  isHovered: _hovered,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
