import 'package:flutter/material.dart';
import '../../theme/typography.dart';
import '../../theme/app_theme.dart';

// Uppercase section header label
class SectionLabel extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionLabel({
    super.key,
    required this.text,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            text.toUpperCase(),
            style: AppTypography.micro.copyWith(
              color: colors.textQuaternary,
              letterSpacing: 1.5,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (trailing != null) ...[
          const SizedBox(width: 8),
          trailing!,
        ],
      ],
    );


  }
}
