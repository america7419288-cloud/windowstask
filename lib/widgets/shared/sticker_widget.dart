import 'dart:typed_data';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../../models/sticker.dart';
import '../../models/server_sticker.dart';
import '../../services/tgs_loader.dart';
import '../../services/store_service.dart';
import '../../theme/colors.dart';

class StickerWidget extends StatefulWidget {
  final ServerSticker? serverSticker;
  final Sticker? localSticker;
  final double size;
  final bool animate;

  const StickerWidget({
    super.key,
    this.serverSticker,
    this.localSticker,
    this.size = 40,
    this.animate = true,
  });

  @override
  State<StickerWidget> createState() => _StickerWidgetState();
}

class _StickerWidgetState extends State<StickerWidget> {
  Uint8List? _bytes;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBytes();
  }

  @override
  void didUpdateWidget(StickerWidget old) {
    super.didUpdateWidget(old);
    if (old.serverSticker?.id != widget.serverSticker?.id ||
        old.localSticker?.id != widget.localSticker?.id) {
      _loadBytes();
    }
  }

  Future<void> _loadBytes() async {
    final id = widget.serverSticker?.id ?? widget.localSticker?.id;
    if (id == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      // Use StoreService for server stickers (explicit or derived from empty assetPath)
      final useServer = widget.serverSticker != null || 
                       (widget.localSticker != null && widget.localSticker!.assetPath.isEmpty);

      if (useServer) {
        final bytes = await StoreService.instance.getStickerBytes(id);
        if (bytes != null && mounted) {
          try {
            final decompressed = GZipCodec().decode(bytes);
            setState(() {
              _bytes = Uint8List.fromList(decompressed);
              _loading = false;
            });
          } catch (e) {
            print('[StickerWidget] Decompression error for $id: $e');
            setState(() {
              _bytes = bytes; // Fallback to raw if not gzipped (unlikely for TGS)
              _loading = false;
            });
          }
        } else if (mounted) {
          setState(() => _loading = false);
        }
        return;
      }

      // Fall back to existing TgsLoader logic for bundled stickers
      // We need the raw bytes for Lottie.memory
      if (widget.localSticker != null && widget.localSticker!.assetPath.isNotEmpty) {
        final byteData = await rootBundle.load(widget.localSticker!.assetPath);
        final compressed = byteData.buffer.asUint8List();
        final decompressed = GZipCodec().decode(compressed);
        if (mounted) {
          setState(() {
            _bytes = Uint8List.fromList(decompressed);
            _loading = false;
          });
        }
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get emoji fallback
    final emoji = widget.serverSticker?.emoji ?? widget.localSticker?.emoji ?? '✨';
    final size = widget.size;

    if (_loading) {
      return _StickerShimmer(size: size);
    }

    if (_bytes == null) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Text(emoji, style: TextStyle(fontSize: size * 0.7)),
        ),
      );
    }

    return SizedBox(
      width: size,
      height: size,
      child: Lottie.memory(
        _bytes!,
        width: size,
        height: size,
        fit: BoxFit.contain,
        repeat: widget.animate,
        errorBuilder: (_, __, ___) => Center(
          child: Text(emoji, style: TextStyle(fontSize: size * 0.7)),
        ),
      ),
    );
  }
}

class _StickerShimmer extends StatelessWidget {
  final double size;
  const _StickerShimmer({required this.size});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
