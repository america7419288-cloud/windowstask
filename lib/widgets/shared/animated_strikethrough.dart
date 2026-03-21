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
    return Stack(
      children: [
        Text(
          text,
          style: textStyle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Positioned.fill ensures the strike layer matches the Text's bounds
        Positioned.fill(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Center(
                child: Row(
                  children: [
                    AnimatedContainer(
                      duration: duration,
                      curve: Curves.easeOutCubic,
                      width: isStruck ? constraints.maxWidth : 0,
                      height: 1.5,
                      color: strikeColor,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
