import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';
import '../../utils/constants.dart';

class SidebarItem extends StatefulWidget {
  const SidebarItem({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
    this.badge,
    this.trailingWidget,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;
  final int? badge;
  final Widget? trailingWidget;

  @override
  State<SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<SidebarItem> {
  bool _hovered = false;

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
              Icon(
                widget.icon,
                size: AppConstants.iconInline,
                color: widget.isSelected ? accent : colors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  widget.label,
                  style: AppTypography.body.copyWith(
                    color: widget.isSelected ? accent : colors.textPrimary,
                    fontWeight:
                        widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                  ),
                ),
              ),
              if (widget.badge != null && widget.badge! > 0)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: widget.isSelected
                        ? accent
                        : colors.isDark
                            ? Colors.white.withOpacity(0.15)
                            : Colors.black.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${widget.badge}',
                    style: AppTypography.caption.copyWith(
                      color: widget.isSelected ? Colors.white : colors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              if (widget.trailingWidget != null) widget.trailingWidget!,
            ],
          ),
        ),
      ),
    );
  }
}
