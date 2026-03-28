import 'package:flutter/material.dart';
import '../../theme/typography.dart';
import '../../theme/colors.dart';
import '../../theme/app_theme.dart';
import 'sticker_widget.dart';
import 'taski_button.dart';

class EmptyStateConfig {
  final String stickerPath;
  final String headline;
  final String subline;
  final String? ctaLabel;
  final VoidCallback? onCta;

  EmptyStateConfig({
    required this.stickerPath,
    required this.headline,
    required this.subline,
    this.ctaLabel,
    this.onCta,
  });
}

class EmptyStateWidget extends StatelessWidget {
  final EmptyStateConfig config;

  const EmptyStateWidget({super.key, required this.config});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Sticker (large, animated)
            AppStickerWidget(
              assetPath: config.stickerPath,
              size: 96,
              animate: true,
            ),
            const SizedBox(height: 24),

            // Headline
            Text(
              config.headline,
              style: AppTypography.headlineMD.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),

            // Subline
            Text(
              config.subline,
              style: AppTypography.bodyMD.copyWith(
                color: colors.textTertiary,
                height: 1.6,
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
            ),

            // CTA button
            if (config.ctaLabel != null) ...[
              const SizedBox(height: 28),
              TaskiButton(
                label: config.ctaLabel!,
                icon: Icons.add_rounded,
                onTap: config.onCta,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
