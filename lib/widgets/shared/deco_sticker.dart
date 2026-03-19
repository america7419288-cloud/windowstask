import 'package:flutter/material.dart';
import '../../models/sticker.dart';
import 'sticker_widget.dart';

class DecoSticker extends StatelessWidget {
  final Sticker sticker;
  final double size;
  final bool animate;

  const DecoSticker({
    super.key,
    required this.sticker,
    this.size = 64,
    this.animate = true,
  });

  @override
  Widget build(BuildContext context) {
    return StickerWidget(
      sticker: sticker,
      size: size,
      animate: animate,
    );
  }
}
