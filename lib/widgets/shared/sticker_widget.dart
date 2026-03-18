import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../models/sticker.dart';
import '../../services/tgs_loader.dart';

class StickerWidget extends StatefulWidget {
  final Sticker sticker;
  final double size;
  final bool animate;         // true = looping, false = static first frame

  const StickerWidget({
    super.key,
    required this.sticker,
    this.size = 40,
    this.animate = true,
  });

  @override
  State<StickerWidget> createState() => _StickerWidgetState();
}

class _StickerWidgetState extends State<StickerWidget> {
  Uint8List? _bytes;
  bool _error = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(StickerWidget old) {
    super.didUpdateWidget(old);
    if (old.sticker.assetPath != widget.sticker.assetPath) {
      setState(() { _bytes = null; _error = false; });
      _load();
    }
  }

  Future<void> _load() async {
    try {
      final bytes = await TgsLoader.load(widget.sticker.assetPath);
      if (mounted) setState(() => _bytes = bytes);
    } catch (_) {
      if (mounted) setState(() => _error = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.size;

    // Error or not loaded yet: show emoji fallback
    if (_error) {
      return SizedBox(
        width: size, height: size,
        child: Center(
          child: Text(widget.sticker.emoji,
            style: TextStyle(fontSize: size * 0.65)),
        ),
      );
    }

    // Loading: show subtle shimmer placeholder
    if (_bytes == null) {
      return SizedBox(
        width: size, height: size,
        child: Center(
          child: SizedBox(
            width: size * 0.4, height: size * 0.4,
            child: CircularProgressIndicator(
              strokeWidth: 1.5,
              color: Theme.of(context).colorScheme.primary
                  .withValues(alpha: 0.3),
            ),
          ),
        ),
      );
    }

    // Loaded: play Lottie animation
    return SizedBox(
      width: size, height: size,
      child: Lottie.memory(
        _bytes!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        repeat: widget.animate,
        // Lottie renders TGS at the correct frame rate automatically
        errorBuilder: (_, __, ___) => Center(
          child: Text(widget.sticker.emoji,
            style: TextStyle(fontSize: size * 0.65)),
        ),
      ),
    );
  }
}
