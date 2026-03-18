import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';
import '../../utils/constants.dart';

enum MacOSButtonStyle { primary, secondary, ghost, danger }

class MacOSButton extends StatefulWidget {
  const MacOSButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = MacOSButtonStyle.primary,
    this.isSmall = false,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final MacOSButtonStyle style;
  final bool isSmall;
  final bool isLoading;

  @override
  State<MacOSButton> createState() => _MacOSButtonState();
}

class _MacOSButtonState extends State<MacOSButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;

    Color bg;
    Color fg;
    Border? border;

    switch (widget.style) {
      case MacOSButtonStyle.primary:
        bg = accent;
        fg = Colors.white;
        break;
      case MacOSButtonStyle.secondary:
        bg = colors.isDark ? Colors.white.withValues(alpha: 0.1) : Colors.black.withValues(alpha: 0.06);
        fg = colors.textPrimary;
        break;
      case MacOSButtonStyle.ghost:
        bg = Colors.transparent;
        fg = accent;
        border = Border.all(color: accent.withValues(alpha: 0.5));
        break;
      case MacOSButtonStyle.danger:
        bg = const Color(0xFFFF3B30);
        fg = Colors.white;
        break;
    }

    if (_pressed) bg = bg.withValues(alpha: 0.8);

    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onPressed?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: AppConstants.animFast,
        padding: EdgeInsets.symmetric(
          horizontal: widget.isSmall ? 10 : 14,
          vertical: widget.isSmall ? 5 : 7,
        ),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppConstants.radiusButton),
          border: border,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (widget.isLoading) ...[
              SizedBox(
                width: 12,
                height: 12,
                child: CircularProgressIndicator(strokeWidth: 2, color: fg),
              ),
              const SizedBox(width: 6),
            ] else if (widget.icon != null) ...[
              Icon(widget.icon, size: 14, color: fg),
              const SizedBox(width: 5),
            ],
            Text(
              widget.label,
              style: (widget.isSmall ? AppTypography.caption : AppTypography.body).copyWith(
                color: fg,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MacOSIconButton extends StatefulWidget {
  const MacOSIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.size = 32,
    this.iconSize = 16,
    this.color,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final double size;
  final double iconSize;
  final Color? color;

  @override
  State<MacOSIconButton> createState() => _MacOSIconButtonState();
}

class _MacOSIconButtonState extends State<MacOSIconButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    Widget btn = MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: AppConstants.animFast,
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: _hovered
                ? (colors.isDark
                    ? Colors.white.withValues(alpha: 0.08)
                    : Colors.black.withValues(alpha: 0.05))
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(
            widget.icon,
            size: widget.iconSize,
            color: widget.color ?? colors.textSecondary,
          ),
        ),
      ),
    );

    if (widget.tooltip != null) {
      btn = Tooltip(message: widget.tooltip!, child: btn);
    }
    return btn;
  }
}
