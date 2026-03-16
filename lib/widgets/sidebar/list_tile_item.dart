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

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: AppConstants.animFast,
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: widget.isSelected
                ? accent.withOpacity(0.12)
                : _hovered
                    ? (colors.isDark
                        ? Colors.white.withOpacity(0.06)
                        : Colors.black.withOpacity(0.04))
                    : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Text(widget.list.emoji, style: const TextStyle(fontSize: 14)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.list.name,
                  style: AppTypography.body.copyWith(
                    color: widget.isSelected ? accent : colors.textPrimary,
                    fontWeight: widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.taskCount > 0)
                Text(
                  '${widget.taskCount}',
                  style: AppTypography.caption.copyWith(color: colors.textSecondary),
                ),
              if (_hovered && widget.onEdit != null)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: GestureDetector(
                    onTap: widget.onEdit,
                    child: Icon(Icons.more_horiz,
                        size: 14, color: colors.textSecondary),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
