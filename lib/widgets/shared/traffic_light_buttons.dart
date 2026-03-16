import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../utils/constants.dart';

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
        children: [
          _button(AppColors.trafficRed, 'close'),
          const SizedBox(width: 8),
          _button(AppColors.trafficYellow, 'minimize'),
          const SizedBox(width: 8),
          _button(AppColors.trafficGreen, 'maximize'),
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
    // Window management is handled at app level via bitsdojo_window
  }
}
