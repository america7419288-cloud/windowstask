import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';
import '../../utils/constants.dart';

class TagChip extends StatelessWidget {
  const TagChip({
    super.key,
    required this.label,
    required this.colorHex,
    this.onDelete,
    this.isSmall = false,
  });

  final String label;
  final String colorHex;
  final VoidCallback? onDelete;
  final bool isSmall;

  Color get _color {
    try {
      return Color(int.parse('FF$colorHex', radix: 16));
    } catch (_) {
      return const Color(0xFF007AFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _color;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isSmall ? 6 : 8,
        vertical: isSmall ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppConstants.radiusChip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: AppTypography.caption.copyWith(
              fontSize: isSmall ? 10 : 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
          if (onDelete != null) ...[
            const SizedBox(width: 4),
            GestureDetector(
              onTap: onDelete,
              child: Icon(Icons.close_rounded, size: 10, color: color.withValues(alpha: 0.7)),
            ),
          ],
        ],
      ),
    );
  }
}
