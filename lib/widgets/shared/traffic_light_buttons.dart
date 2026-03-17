import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../layout/window_controls.dart';

class TrafficLightButtons extends StatefulWidget {
  const TrafficLightButtons({super.key});

  @override
  State<TrafficLightButtons> createState() => _TrafficLightButtonsState();
}

class _TrafficLightButtonsState extends State<TrafficLightButtons> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _button(AppColors.red, 'close'),
          const SizedBox(width: 8),
          _button(AppColors.orange, 'minimize'),
          const SizedBox(width: 8),
          _button(AppColors.green, 'maximize'),
        ],
      ),
    );
  }

  Widget _button(Color color, String action) {
    return GestureDetector(
      onTap: () => _handleAction(action),
      child: Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: _hovered ? color : color.withOpacity(0.6),
          shape: BoxShape.circle,
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
    );
  }

  void _handleAction(String action) {
    handleWindowAction(action);
  }
}
