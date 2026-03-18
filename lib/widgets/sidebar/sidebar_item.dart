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
      child: PressableScale(
        scaleDown: 0.97,
        onTap: widget.onTap,
        child: Stack(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 1),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                gradient: isSelected
                    ? LinearGradient(
                        colors: [
                          accent.withValues(alpha: 0.13),
                          accent.withValues(alpha: 0.06),
                        ],
                        begin: Alignment.centerLeft,
                        end: Alignment.centerRight,
                      )
                    : null,
                color: !isSelected && _hovered
                    ? (colors.isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.black.withValues(alpha: 0.04))
                    : (!isSelected ? Colors.transparent : null),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Row(
                children: [
                  Icon(
                    widget.icon,
                    size: isSelected ? 18 : 17,
                    color: isSelected ? accent : colors.textSecondary,
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      widget.label,
                      style: AppTypography.body.copyWith(
                        fontSize: 13.5,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                        color: isSelected ? accent : colors.textPrimary,
                      ),
                    ),
                  ),
                  if (widget.badge != null && widget.badge! > 0)
                    _BadgePill(
                      count: widget.badge!,
                      isSelected: isSelected,
                      accent: accent,
                      colors: colors,
                    ),
                  if (widget.trailingWidget != null) widget.trailingWidget!,
                ],
              ),
            ),
            // Left accent bar
            if (isSelected)
              Positioned(
                left: 8,
                top: 5,
                bottom: 5,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeOutBack,
                  width: 3,
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(2),
                    boxShadow: [
                      BoxShadow(
                        color: accent.withValues(alpha: 0.5),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _BadgePill extends StatelessWidget {
  final int count;
  final bool isSelected;
  final Color accent;
  final AppColorsExtension colors;

  const _BadgePill({
    required this.count,
    required this.isSelected,
    required this.accent,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        gradient: isSelected ? AppColors.gradientPrimary : null,
        color: isSelected
            ? null
            : (colors.isDark
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.black.withValues(alpha: 0.07)),
        borderRadius: BorderRadius.circular(10),
        boxShadow: isSelected
            ? [BoxShadow(color: accent.withValues(alpha: 0.35), blurRadius: 6)]
            : [],
      ),
      child: Text(
        '$count',
        style: AppTypography.micro.copyWith(
          color: isSelected ? Colors.white : colors.textSecondary,
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
        ),
      ),
    );
  }
}
