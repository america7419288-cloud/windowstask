import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';
import '../../utils/constants.dart';

class EmptyState extends StatefulWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.subtitle,
    this.emoji = '📭',
    this.action,
    this.actionLabel,
  });

  final String title;
  final String subtitle;
  final String emoji;
  final VoidCallback? action;
  final String? actionLabel;

  @override
  State<EmptyState> createState() => _EmptyStateState();
}

class _EmptyStateState extends State<EmptyState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulse = Tween<double>(begin: 0.92, end: 1.08).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _pulse,
            child: Text(widget.emoji, style: const TextStyle(fontSize: 64)),
          ),
          const SizedBox(height: 20),
          Text(
            widget.title,
            style: AppTypography.headline.copyWith(color: colors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            widget.subtitle,
            style: AppTypography.body.copyWith(color: colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (widget.action != null && widget.actionLabel != null) ...[
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: widget.action,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppConstants.radiusButton),
                ),
              ),
              child: Text(
                widget.actionLabel!,
                style: AppTypography.body.copyWith(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
