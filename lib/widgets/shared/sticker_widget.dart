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

class AppStickerWidget extends StatefulWidget {
  final ServerSticker? serverSticker;
  final Sticker? localSticker;
  final String? assetPath; // Added for explicit asset path support in redesign
  final double size;
  final bool animate;

  const AppStickerWidget({
    super.key,
    this.serverSticker,
    this.localSticker,
    this.assetPath,
    this.size = 40,
    this.animate = true,
  });

  @override
  State<AppStickerWidget> createState() => _AppStickerWidgetState();
}

typedef StickerWidget = AppStickerWidget;

class _AppStickerWidgetState extends State<AppStickerWidget> {
  LottieComposition? _composition;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSticker();
  }

  @override
  void didUpdateWidget(StickerWidget old) {
    super.didUpdateWidget(old);
    if (old.serverSticker?.id != widget.serverSticker?.id ||
        old.localSticker?.id != widget.localSticker?.id ||
        old.assetPath != widget.assetPath) {
      _loadSticker();
    }
  }

  Future<void> _loadSticker() async {
    final assetPath = widget.assetPath ?? widget.localSticker?.assetPath;
    final id = widget.serverSticker?.id ?? widget.localSticker?.id;
    
    if (assetPath == null && id == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (!mounted) return;
    setState(() => _loading = true);

    try {
      LottieComposition? comp;

      // 1. Asset Path Support
      if (assetPath != null && assetPath.isNotEmpty) {
        comp = await TgsLoader.load(assetPath);
      } 
      // 2. Server Sticker Support
      else if (id != null) {
        final bytes = await StoreService.instance.getStickerBytes(id);
        if (bytes != null) {
          comp = await TgsLoader.loadFromBytes(id, bytes);
        }
      }

      if (mounted) {
        setState(() {
          _composition = comp;
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[AppStickerWidget] Error loading sticker: $e');
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final emoji = widget.serverSticker?.emoji ?? widget.localSticker?.emoji ?? '✨';
    final size = widget.size;

    if (_loading) {
      return _StickerShimmer(size: size);
    }

    if (_composition == null) {
      return SizedBox(
        width: size, height: size,
        child: Center(child: Text(emoji, style: TextStyle(fontSize: size * 0.7))),
      );
    }

    return SizedBox(
      width: size, height: size,
      child: Lottie(
        composition: _composition!,
        width: size, height: size,
        fit: BoxFit.contain,
        animate: widget.animate,
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
