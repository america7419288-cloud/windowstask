import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ContextMenuItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;
  final Widget? trailing;
  final VoidCallback? onHoverAction;

  const ContextMenuItem({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
    this.trailing,
    this.onHoverAction,
  });

  @override
  State<ContextMenuItem> createState() => _ContextMenuItemState();
}

class _ContextMenuItemState extends State<ContextMenuItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;

    Color itemColor;
    if (widget.isDestructive) {
      itemColor = AppColors.red;
    } else {
      itemColor = _hovered ? accent : colors.textPrimary;
    }

    Color iconColor;
    if (widget.isDestructive) {
      iconColor = AppColors.red;
    } else {
      iconColor = _hovered ? accent : colors.textSecondary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      child: MouseRegion(
        onEnter: (_) {
          setState(() => _hovered = true);
          if (widget.onHoverAction != null) {
            widget.onHoverAction!();
          }
        },
        onExit: (_) => setState(() => _hovered = false),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            decoration: BoxDecoration(
              color: _hovered && !widget.isDestructive
                  ? colors.sidebarActive // uses rgba(0,122,255,0.08) logic
                  : _hovered && widget.isDestructive
                      ? AppColors.red.withValues(alpha: 0.1) // red hover
                      : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  widget.icon,
                  size: 15,
                  color: iconColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.label,
                    style: AppTypography.caption.copyWith(
                      color: itemColor,
                      fontSize: 13,
                    ),
                  ),
                ),
                if (widget.trailing != null) widget.trailing!,
              ],
            ),
          ),
        ),
      ),
    );
  }
}
