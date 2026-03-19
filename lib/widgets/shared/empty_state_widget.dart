import 'package:flutter/material.dart';
import '../../models/sticker.dart';
import '../../theme/typography.dart';
import '../../theme/colors.dart';
import '../../theme/app_theme.dart';
import 'deco_sticker.dart';

class EmptyStateConfig {
  final Sticker sticker;
  final String headline;
  final String subline;
  final String? ctaLabel;
  final VoidCallback? onCta;

  EmptyStateConfig({
    required this.sticker,
    required this.headline,
    required this.subline,
    this.ctaLabel,
    this.onCta,
  });
}

class EmptyStateWidget extends StatefulWidget {
  final EmptyStateConfig config;

  const EmptyStateWidget({super.key, required this.config});

  @override
  State<EmptyStateWidget> createState() => _EmptyStateWidgetState();
}

class _EmptyStateWidgetState extends State<EmptyStateWidget> with SingleTickerProviderStateMixin {
  // Staggered entrance animations
  late AnimationController _entranceController;
  late Animation<double> _illusScaleZ;
  late Animation<double> _illusFade;
  late Animation<double> _headTranslateY;
  late Animation<double> _headFade;
  late Animation<double> _subTranslateY;
  late Animation<double> _subFade;
  late Animation<double> _ctaFade;

  @override
  void initState() {
    super.initState();
    _setupEntranceAnimations();
  }

  void _setupEntranceAnimations() {
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    
    _illusScaleZ = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut))
    );
    _illusFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut))
    );

    _headTranslateY = Tween<double>(begin: 12.0, end: 0.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic))
    );
    _headFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.1, 0.5, curve: Curves.easeOut))
    );

    _subTranslateY = Tween<double>(begin: 8.0, end: 0.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.17, 0.67, curve: Curves.easeOutCubic))
    );
    _subFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.17, 0.57, curve: Curves.easeOut))
    );

    _ctaFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.27, 0.7, curve: Curves.easeOut))
    );

    _entranceController.forward();
  }

  @override
  void didUpdateWidget(EmptyStateWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.config.headline != widget.config.headline) {
      _entranceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<AppColorsExtension>()!;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
        child: AnimatedBuilder(
          animation: _entranceController,
          builder: (context, child) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Illustration — sticker
                Transform.scale(
                  scale: _illusScaleZ.value,
                  child: Opacity(
                    opacity: _illusFade.value,
                    child: DecoSticker(
                      sticker: widget.config.sticker,
                      size: 120,
                      animate: true,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Headline
                Transform.translate(
                  offset: Offset(0, _headTranslateY.value),
                  child: Opacity(
                    opacity: _headFade.value,
                    child: Text(
                      widget.config.headline,
                      style: AppTypography.title2.copyWith(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.4,
                        color: colors.textPrimary,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Subline
                Transform.translate(
                  offset: Offset(0, _subTranslateY.value),
                  child: Opacity(
                    opacity: _subFade.value,
                    child: Text(
                      widget.config.subline,
                      style: AppTypography.body.copyWith(
                        fontSize: 13.5,
                        color: colors.textTertiary,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 3,
                    ),
                  ),
                ),

                // CTA (optional)
                if (widget.config.ctaLabel != null) ...[
                  const SizedBox(height: 24),
                  Opacity(
                    opacity: _ctaFade.value,
                    child: _buildCta(context),
                  ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCta(BuildContext context) {
    final accent = Theme.of(context).colorScheme.primary;
    return GestureDetector(
      onTap: widget.config.onCta,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          gradient: AppColors.gradientPrimary,
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.30),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.config.ctaLabel!,
              style: AppTypography.bodySemibold.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_forward_rounded, size: 14, color: Colors.white),
          ],
        ),
      ),
    );
  }
}
