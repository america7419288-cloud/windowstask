import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';
import '../shared/pressable_scale.dart';

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
    final bool isSelected = widget.isSelected;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Stack(
          children: [
            // Background — surface shift
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? (colors.isDark ? Colors.white.withValues(alpha: 0.08) : Colors.black.withValues(alpha: 0.04))
                    : _hovered
                        ? (colors.isDark ? Colors.white.withValues(alpha: 0.04) : Colors.black.withValues(alpha: 0.02))
                        : Colors.transparent,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: 16,
                    color: isSelected ? AppColors.primary : colors.textTertiary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: AppTypography.bodyMedium.copyWith(
                        fontSize: 13.5,
                        color: isSelected ? colors.textPrimary : colors.textSecondary,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                      ),
                      overflow: TextOverflow.visible,
                      softWrap: false,
                      maxLines: 1,
                    ),
                  ),
                  // Badge
                  if (widget.badge != null && widget.badge! > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? (colors.isDark ? Colors.white.withValues(alpha: 0.12) : Colors.black.withValues(alpha: 0.08))
                            : AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '${widget.badge}',
                        style: AppTypography.micro.copyWith(
                          color: isSelected ? colors.textPrimary : AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  if (widget.trailingWidget != null) widget.trailingWidget!,
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
