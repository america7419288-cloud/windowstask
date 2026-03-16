import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';
import '../../utils/constants.dart';

class MacOSTextField extends StatefulWidget {
  const MacOSTextField({
    super.key,
    required this.controller,
    this.placeholder,
    this.onSubmitted,
    this.onChanged,
    this.focusNode,
    this.autofocus = false,
    this.maxLines = 1,
    this.style,
    this.keyboardType,
    this.textInputAction,
    this.prefix,
    this.suffix,
  });

  final TextEditingController controller;
  final String? placeholder;
  final ValueChanged<String>? onSubmitted;
  final ValueChanged<String>? onChanged;
  final FocusNode? focusNode;
  final bool autofocus;
  final int? maxLines;
  final TextStyle? style;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Widget? prefix;
  final Widget? suffix;

  @override
  State<MacOSTextField> createState() => _MacOSTextFieldState();
}

class _MacOSTextFieldState extends State<MacOSTextField> {
  late FocusNode _focusNode;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(() {
      setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    if (widget.focusNode == null) _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AnimatedContainer(
      duration: AppConstants.animFast,
      decoration: BoxDecoration(
        color: _focused
            ? (colors.isDark ? Colors.white.withOpacity(0.08) : Colors.white)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(AppConstants.radiusInput),
        border: Border.all(
          color: _focused
              ? Theme.of(context).colorScheme.primary.withOpacity(0.5)
              : Colors.transparent,
          width: 1,
        ),
        boxShadow: _focused
            ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
                  blurRadius: 6,
                  offset: const Offset(0, 0),
                ),
              ]
            : null,
      ),
      child: Row(
        children: [
          if (widget.prefix != null) ...[
            const SizedBox(width: 8),
            widget.prefix!,
          ],
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              autofocus: widget.autofocus,
              maxLines: widget.maxLines,
              onSubmitted: widget.onSubmitted,
              onChanged: widget.onChanged,
              keyboardType: widget.keyboardType,
              textInputAction: widget.textInputAction,
              style: widget.style ??
                  AppTypography.body.copyWith(color: colors.textPrimary),
              decoration: InputDecoration(
                hintText: widget.placeholder,
                hintStyle: AppTypography.body.copyWith(
                  color: colors.textSecondary,
                ),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              ),
            ),
          ),
          if (widget.suffix != null) ...[
            widget.suffix!,
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
