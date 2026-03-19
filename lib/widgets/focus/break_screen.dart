import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../providers/focus_provider.dart';
import '../../data/app_stickers.dart';
import '../shared/deco_sticker.dart';
import '../../theme/app_theme.dart';
import '../../theme/typography.dart';
import '../../theme/colors.dart';

class BreakScreen extends StatelessWidget {
  const BreakScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final focus = context.watch<FocusProvider>();
    if (!focus.isBreakMode) return const SizedBox.shrink();

    final colors = context.appColors;
    final accent = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          // Frosted glass background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                color: (colors.isDark ? Colors.black : Colors.white).withValues(alpha: 0.7),
              ),
            ),
          ),

          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Large celebration sticker
                DecoSticker(
                  sticker: AppStickers.celebration,
                  size: 200,
                  animate: true,
                ),
                const SizedBox(height: 32),

                // Title
                Text(
                  'Break Time!',
                  style: AppTypography.headline.copyWith(
                    fontSize: 36,
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 12),

                // Motivation quote
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    _getRandomQuote(),
                    textAlign: TextAlign.center,
                    style: AppTypography.body.copyWith(
                      fontSize: 18,
                      color: colors.textSecondary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
                const SizedBox(height: 48),

                // Timer
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  decoration: BoxDecoration(
                    color: AppColors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.green.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(PhosphorIcons.coffee(), color: AppColors.green, size: 24),
                      const SizedBox(width: 12),
                      Text(
                        focus.timeDisplay,
                        style: AppTypography.title1.copyWith(
                          fontSize: 48,
                          color: AppColors.green,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 64),

                // Actions
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _ActionBtn(
                      label: 'Skip Break',
                      icon: PhosphorIcons.fastForward(),
                      onTap: () => focus.skipBreak(),
                      color: colors.textTertiary,
                    ),
                    const SizedBox(width: 24),
                    _ActionBtn(
                      label: 'End Session',
                      icon: PhosphorIcons.check(),
                      onTap: () => focus.stopFocus(),
                      color: accent,
                      isPrimary: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getRandomQuote() {
    final quotes = [
      "Taking a break is part of the work.",
      "Rest is not idleness, and to lie sometimes on the grass under trees on a summer's day... is by no means a waste of time.",
      "Your mind is like a muscle. It needs rest to grow stronger.",
      "Almost everything will work again if you unplug it for a few minutes, including you.",
      "Sometimes the most productive thing you can do is relax.",
      "A rested mind is a creative mind.",
    ];
    // Simple deterministic choice based on minute to keep it stable during build
    return quotes[DateTime.now().minute % quotes.length];
  }
}

class _ActionBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final Color color;
  final bool isPrimary;

  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    required this.color,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isPrimary ? color : color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              boxShadow: isPrimary ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                )
              ] : [],
            ),
            child: Icon(
              icon,
              size: 28,
              color: isPrimary ? Colors.white : color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: AppTypography.caption.copyWith(
              color: isPrimary ? color : context.appColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
