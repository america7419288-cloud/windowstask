import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/task_list.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MoveToListSubmenu extends StatelessWidget {
  final List<TaskList> activeLists;
  final String? currentListId;
  final Function(String?) onSelect;

  const MoveToListSubmenu({
    super.key,
    required this.activeLists,
    required this.currentListId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    Widget content;

    if (activeLists.isEmpty) {
      content = Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Text(
          'No other lists available.',
          style: AppTypography.caption.copyWith(color: colors.textSecondary),
        ),
      );
    } else {
      content = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // "Inbox" option (no list)
          _SubmenuItem(
            name: 'Inbox',
            iconOrEmoji: Icon(PhosphorIcons.tray(), size: 14, color: colors.textSecondary),
            isSelected: currentListId == null,
            onTap: () => onSelect(null),
          ),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 0),
            color: colors.isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.06),
          ),
          ...activeLists.map((list) {
            return _SubmenuItem(
              name: list.name,
              iconOrEmoji: Text(list.emoji, style: const TextStyle(fontSize: 12)),
              isSelected: list.id == currentListId,
              onTap: () => onSelect(list.id),
              colorHex: list.colorHex,
            );
          }),
        ],
      );

      // Scrollable bounds if many lists
      if (activeLists.length > 5) {
        content = ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 240),
          child: SingleChildScrollView(
            child: content,
          ),
        );
      }
    }

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: 200,
        padding: const EdgeInsets.symmetric(vertical: 6),
      decoration: BoxDecoration(
        color: colors.isDark 
            ? const Color(0xFF242426).withValues(alpha: 0.94)
            : const Color(0xFFF8F8FC).withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: colors.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.08), 
            width: 0.5),
        boxShadow: [
          BoxShadow(
            color: colors.isDark ? Colors.black.withValues(alpha: 0.40) : Colors.black.withValues(alpha: 0.12),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: colors.isDark ? Colors.black.withValues(alpha: 0.20) : Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: content,
        ),
      ),
    ));
  }
}

class _SubmenuItem extends StatefulWidget {
  final String name;
  final Widget iconOrEmoji;
  final bool isSelected;
  final VoidCallback onTap;
  final String? colorHex;

  const _SubmenuItem({
    required this.name,
    required this.iconOrEmoji,
    required this.isSelected,
    required this.onTap,
    this.colorHex,
  });

  @override
  State<_SubmenuItem> createState() => _SubmenuItemState();
}

class _SubmenuItemState extends State<_SubmenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;
    final listColor = widget.colorHex != null ? Color(int.parse('FF${widget.colorHex}', radix: 16)) : colors.textPrimary;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        behavior: HitTestBehavior.opaque,
        child: Container(
          height: 34,
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: _hovered ? colors.sidebarActive : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 16,
                child: Center(child: widget.iconOrEmoji),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.name,
                  style: AppTypography.caption.copyWith(
                    color: _hovered ? accent : colors.textPrimary,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.colorHex != null) ...[
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(color: listColor, shape: BoxShape.circle),
                ),
              ],
              if (widget.isSelected) ...[
                const SizedBox(width: 8),
                Icon(Icons.check_rounded, size: 14, color: accent),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
