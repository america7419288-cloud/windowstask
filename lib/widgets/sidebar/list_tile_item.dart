import 'package:flutter/material.dart';
import '../../models/task_list.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';
import '../../utils/constants.dart';

class ListTileItem extends StatefulWidget {
  const ListTileItem({
    super.key,
    required this.list,
    required this.taskCount,
    required this.isSelected,
    required this.onTap,
    this.onEdit,
    this.onDelete,
  });

  final TaskList list;
  final int taskCount;
  final bool isSelected;
  final VoidCallback onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  @override
  State<ListTileItem> createState() => _ListTileItemState();
}

class _ListTileItemState extends State<ListTileItem> {
  bool _hovered = false;

  Color get _listColor {
    try {
      return Color(int.parse('FF${widget.list.colorHex}', radix: 16));
    } catch (_) {
      return const Color(0xFF007AFF);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;

    // Selected: solid accent bg. Hover: subtle tint.
    final bgColor = widget.isSelected
        ? accent
        : _hovered
            ? (colors.isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.black.withValues(alpha: 0.04))
            : Colors.transparent;

    final fgColor = widget.isSelected ? Colors.white : colors.textPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppConstants.animFast,
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            boxShadow: widget.isSelected
                ? [
                    BoxShadow(
                      color: accent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : [],
          ),
          child: Row(
            children: [
              Text(widget.list.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.list.name,
                  style: AppTypography.body.copyWith(
                    color: fgColor,
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.taskCount > 0)
                Text(
                  '${widget.taskCount}',
                  style: AppTypography.caption.copyWith(
                    color: widget.isSelected
                        ? Colors.white.withValues(alpha: 0.8)
                        : colors.textSecondary,
                  ),
                ),
              if (_hovered && widget.onEdit != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: GestureDetector(
                    onTap: widget.onEdit,
                    child: Icon(Icons.more_horiz,
                        size: 14,
                        color: widget.isSelected ? Colors.white.withValues(alpha: 0.7) : colors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
