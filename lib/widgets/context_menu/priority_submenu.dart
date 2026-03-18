import 'dart:ui';
import 'package:flutter/material.dart';
import '../../models/task.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';
import '../shared/priority_badge.dart'; // To get colorForPriority

class PrioritySubmenu extends StatelessWidget {
  final Priority currentPriority;
  final Function(Priority) onSelect;

  const PrioritySubmenu({
    super.key,
    required this.currentPriority,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Material(
      type: MaterialType.transparency,
      child: Container(
        width: 160,
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: Priority.values.reversed.map((p) {
              return _SubmenuItem(
                priority: p,
                isSelected: p == currentPriority,
                onTap: () => onSelect(p),
              );
            }).toList(),
          ),
        ),
      ),
    ));
  }
}

class _SubmenuItem extends StatefulWidget {
  final Priority priority;
  final bool isSelected;
  final VoidCallback onTap;

  const _SubmenuItem({
    required this.priority,
    required this.isSelected,
    required this.onTap,
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
    final dotColor = PriorityBadge.colorForPriority(widget.priority);

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
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.priority == Priority.none ? colors.textSecondary.withValues(alpha: 0.4) : dotColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  PriorityBadge.labelForPriority(widget.priority),
                  style: AppTypography.caption.copyWith(
                    color: _hovered ? accent : colors.textPrimary,
                    fontSize: 13,
                  ),
                ),
              ),
              if (widget.isSelected)
                Icon(Icons.check_rounded, size: 14, color: accent),
            ],
          ),
        ),
      ),
    );
  }
}
