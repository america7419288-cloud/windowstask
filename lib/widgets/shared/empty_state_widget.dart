import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../../theme/colors.dart';
import '../../theme/typography.dart';

class EmptyStateConfig {
  final CustomPainter Function(double animationValue) painterBuilder;
  final String headline;
  final String subline;
  final String? ctaLabel;
  final VoidCallback? onCta;

  EmptyStateConfig({
    required this.painterBuilder,
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

class _EmptyStateWidgetState extends State<EmptyStateWidget> with TickerProviderStateMixin {
  // Staggered entrance animations
  late AnimationController _entranceController;
  late Animation<double> _illusScaleZ;
  late Animation<double> _illusFade;
  late Animation<double> _headTranslateY;
  late Animation<double> _headFade;
  late Animation<double> _subTranslateY;
  late Animation<double> _subFade;
  late Animation<double> _ctaFade;

  // Looping idle animation
  late AnimationController _idleController;

  @override
  void initState() {
    super.initState();
    _setupEntranceAnimations();
    _idleController = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
  }

  void _setupEntranceAnimations() {
    _entranceController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800));
    
    // Illustration: scale 0.8->1.0 + fade, bouncy, 0ms delay
    _illusScaleZ = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.6, curve: Curves.elasticOut))
    );
    _illusFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.0, 0.4, curve: Curves.easeOut))
    );

    // Headline: translateY 12->0 + fade, gentle, 80ms delay (~0.1 start)
    _headTranslateY = Tween<double>(begin: 12.0, end: 0.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.1, 0.6, curve: Curves.easeOutCubic))
    );
    _headFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.1, 0.5, curve: Curves.easeOut))
    );

    // Subline: translateY 8->0 + fade, gentle, 140ms delay (~0.17 start)
    _subTranslateY = Tween<double>(begin: 8.0, end: 0.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.17, 0.67, curve: Curves.easeOutCubic))
    );
    _subFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entranceController, curve: const Interval(0.17, 0.57, curve: Curves.easeOut))
    );

    // CTA: fade, 220ms delay (~0.27 start)
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
    _idleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: AnimatedBuilder(
          animation: Listenable.merge([_entranceController, _idleController]),
          builder: (context, child) {
            
            // Re-inject the idle animation value into the config's painter if possible
            // Note: Since painters are created externally, we rely on them reading a value 
            // if we reconstruct them. 
            // Actually, we can just pass the idle value down through constructor, 
            // but since config holds the painter, we just use the painter as is.
            // The list view provides a new painter each build which relies on time.
            // We'll handle time inside CustomPaint using _idleController.value if we need to manually pass it.
            // But since flutter architecture makes passing animation to immutable config tricky, 
            // we will let the CustomPaint redraw on this AnimatedBuilder tick.

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Illustration
                  Transform.scale(
                    scale: _illusScaleZ.value,
                    child: Opacity(
                      opacity: _illusFade.value,
                      child: SizedBox(
                        width: 120,
                        height: 120,
                        child: CustomPaint(
                          painter: widget.config.painterBuilder(_idleController.value),
                        ),
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
              ),
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
