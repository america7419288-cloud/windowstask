import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';

class ContextMenuDivider extends StatelessWidget {
  const ContextMenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
      color: colors.isDark 
          ? Colors.white.withOpacity(0.06) 
          : Colors.black.withOpacity(0.06),
    );
  }
}
