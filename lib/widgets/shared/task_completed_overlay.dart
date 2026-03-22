import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/celebration_provider.dart';
import '../shared/sticker_widget.dart';
import '../../data/app_stickers.dart';

class TaskCompletedOverlay extends StatefulWidget {
  const TaskCompletedOverlay({super.key});

  @override
  State<TaskCompletedOverlay> createState() => _TaskCompletedOverlayState();
}

class _TaskCompletedOverlayState extends State<TaskCompletedOverlay> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _blurAnimation;
  late Animation<double> _moveAnimation;
  
  bool _isMoving = false;
  Offset _targetOffset = Offset.zero;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.2).chain(CurveTween(curve: Curves.easeOutBack)), weight: 20),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 1.0).chain(CurveTween(curve: Curves.easeInOut)), weight: 10),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.2).chain(CurveTween(curve: Curves.easeInExpo)), weight: 30),
    ]).animate(_controller);

    _blurAnimation = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 15.0).chain(CurveTween(curve: Curves.easeOut)), weight: 20),
      TweenSequenceItem(tween: ConstantTween(15.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 15.0, end: 0.0).chain(CurveTween(curve: Curves.easeIn)), weight: 30),
    ]).animate(_controller);

    _moveAnimation = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.7, 1.0, curve: Curves.easeInOutCubic),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        context.read<CelebrationProvider>().stopCelebration();
      }
    });

    _startCelebration();
  }

  void _startCelebration() async {
    // Wait for the next frame to ensure the target key is rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final ringKey = context.read<CelebrationProvider>().progressRingKey;
      final renderBox = ringKey.currentContext?.findRenderObject() as RenderBox?;
      final screenSize = MediaQuery.of(context).size;
      
      if (renderBox != null) {
        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;
        setState(() {
          _targetOffset = Offset(
            position.dx + size.width / 2,
            position.dy + size.height / 2,
          );
        });
      } else {
        // Fallback: Move to top of screen in the middle of the header area
        setState(() {
          _targetOffset = Offset(screenSize.width / 2, 40);
        });
      }
      _controller.reset();
      _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sticker = AppStickers.randomCelebration();

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final screenSize = MediaQuery.of(context).size;
        final center = Offset(screenSize.width / 2, screenSize.height / 2);
        
        // Dynamic target tracking
        Offset target = _targetOffset;
        final ringKey = context.read<CelebrationProvider>().progressRingKey;
        final renderBox = ringKey.currentContext?.findRenderObject() as RenderBox?;
        if (renderBox != null && renderBox.attached) {
          final position = renderBox.localToGlobal(Offset.zero, ancestor: context.findRenderObject());
          final size = renderBox.size;
          target = Offset(
            position.dx + size.width / 2,
            position.dy + size.height / 2,
          );
        } else if (target == Offset.zero) {
          target = Offset(screenSize.width / 2, 60); // Default fallback
        }

        final t = _moveAnimation.value;
        final currentPos = Offset.lerp(center, target, t)!;
        final currentScale = _scaleAnimation.value;
        final currentBlur = _blurAnimation.value;
        final opacity = (1.0 - (t > 0.9 ? (t - 0.9) / 0.1 : 0.0)).clamp(0.0, 1.0);

        return Stack(
          children: [
            // Background Blur
            if (currentBlur > 0.1)
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: currentBlur, sigmaY: currentBlur),
                  child: Container(color: Colors.black.withValues(alpha: 0.15 * (currentBlur / 15))),
                ),
              ),
            
            // The Sticker
            Positioned(
              left: currentPos.dx - (160 * currentScale) / 2,
              top: currentPos.dy - (160 * currentScale) / 2,
              child: Opacity(
                opacity: opacity,
                child: Transform.scale(
                  scale: currentScale,
                  child: StickerWidget(
                    localSticker: sticker,
                    size: 160,
                    animate: true,
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
