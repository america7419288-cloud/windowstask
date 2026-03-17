import 'package:flutter/material.dart';
import '../../theme/typography.dart';

class CustomTooltip extends StatelessWidget {
  final Widget child;
  final String message;

  const CustomTooltip({super.key, required this.child, required this.message});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: message,
      waitDuration: const Duration(milliseconds: 600),
      showDuration: const Duration(milliseconds: 1500),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1C1C1E),
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      textStyle: AppTypography.caption.copyWith(
        color: Colors.white,
        fontWeight: FontWeight.w500,
      ),
      preferBelow: true,
      verticalOffset: 24,
      child: child,
    );
  }
}
