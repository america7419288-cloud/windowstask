import 'package:flutter/material.dart';

class AnimatedStrikethrough extends StatelessWidget {
  final String text;
  final TextStyle textStyle;
  final bool isStruck;
  final Color strikeColor;
  final Duration duration;

  const AnimatedStrikethrough({
    super.key,
    required this.text,
    required this.textStyle,
    required this.isStruck,
    required this.strikeColor,
    this.duration = const Duration(milliseconds: 250),
  });

  @override
  Widget build(BuildContext context) {
    // Measure the text width using TextPainter
    final tp = TextPainter(
      text: TextSpan(text: text, style: textStyle),
      maxLines: 1,
      textDirection: TextDirection.ltr,
    )..layout(maxWidth: double.infinity);

    final textWidth = tp.width;

    return Stack(
      alignment: Alignment.centerLeft,
      children: [
        Text(
          text,
          style: textStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: isStruck ? 1.0 : 0.0),
          duration: duration,
          curve: Curves.easeOutCubic,
          builder: (context, value, _) {
            return SizedBox(
              width: textWidth * value,
              child: Container(
                height: 1.5,
                color: strikeColor,
              ),
            );
          },
        ),
      ],
    );
  }
}
